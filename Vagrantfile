require 'base64'

# Codex/Claude Code VM sandbox (macOS-friendly).
#
# Quick start:
# 1) vagrant up
# 2) vagrant ssh
# 3) codex or claude
#
# Provider selection:
# - Default: VirtualBox. Override with `vagrant up --provider=parallels|vmware_desktop|qemu`
# - To set a default: export VAGRANT_DEFAULT_PROVIDER=virtualbox
#
# Sync behavior:
# - Current: two-way sync (host <-> VM) for convenience.
# - Safer: use type: "rsync" for one-way host -> VM sync (see Vagrant docs).
#
# Safety note:
# - The VM isolates the OS, not your repo. Destructive actions still affect /app.

# Read git config from host (runs during vagrant up, on host machine)
def read_git_config(key)
  `git config --global #{key} 2>/dev/null`.strip
rescue
  ""
end

git_signing_key = read_git_config("user.signingkey")
git_user_name = read_git_config("user.name")
git_user_email = read_git_config("user.email")

# Read global gitignore from host (runs during vagrant up)
git_ignore_path = `git config --global core.excludesfile 2>/dev/null`.strip
git_ignore_path = File.expand_path(git_ignore_path) unless git_ignore_path.empty?
git_ignore_content_b64 = ""
if !git_ignore_path.empty? && File.exist?(git_ignore_path)
  git_ignore_content_b64 = Base64.strict_encode64(File.read(git_ignore_path))
end

vm_name = File.basename(Dir.getwd)

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.ssh.forward_agent = true

  # Uncomment if you need to expose a port from the VM to your host.
  # config.vm.network "forwarded_port", guest: 3000, host: 3000, auto_correct: true

  # Two-way sync so your edits on host and in the VM stay in sync.
  # If you prefer one-way sync for extra safety, switch to type: "rsync".
  config.vm.synced_folder ".", "/app", type: "virtualbox"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
    vb.gui = false
    vb.name = vm_name
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
  end

  config.vm.provision "shell", inline: <<-SHELL
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip \
  less procps sudo fzf zsh man-db gnupg2 \
  gh jq nano vim \
  ripgrep fd-find bat \
  nodejs npm \
  python3 python3-venv python3-pip pipx \
  docker.io

# Preserve SSH agent socket for sudo operations (needed for SSH agent forwarding)
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/ssh_auth_sock
chmod 0440 /etc/sudoers.d/ssh_auth_sock

GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n1)
GO_ARCH=$(dpkg --print-architecture)

case "$GO_ARCH" in
  amd64|arm64) ;;
  *)
    echo "Unsupported architecture for Go: $GO_ARCH" >&2
    exit 1
  ;;
esac

curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tgz
rm /tmp/go.tgz

GIT_DELTA_VERSION="0.18.2"

if ! command -v delta >/dev/null 2>&1; then
  ARCH=$(dpkg --print-architecture)
  curl -fsSL -o "/tmp/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" \
    "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  dpkg -i "/tmp/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
  rm "/tmp/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"
fi

sudo -u vagrant -H bash -lc "npm config set prefix /home/vagrant/.npm-global"
sudo -u vagrant -H bash -lc "npm install -g @openai/codex typescript ts-node --no-audit --no-fund"

# Install Claude Code
sudo -u vagrant -H bash -lc "curl -fsSL https://claude.ai/install.sh | bash"

if [ ! -x /home/vagrant/.local/bin/uv ]; then
  sudo -u vagrant -H bash -lc "pipx install uv"
fi

usermod -aG docker vagrant || true
chsh -s /usr/bin/zsh vagrant
chown -R vagrant:vagrant /app

if command -v delta >/dev/null 2>&1; then
  sudo -u vagrant -H git config --global core.pager "delta"
  sudo -u vagrant -H git config --global interactive.diffFilter "delta --color-only"
  sudo -u vagrant -H git config --global delta.navigate true
fi

# Git commit signing with SSH (for 1Password agent forwarding)
# Values read from host's git config during vagrant up
SIGNING_KEY="#{git_signing_key}"
GIT_NAME="#{git_user_name}"
GIT_EMAIL="#{git_user_email}"

if [ -n "$SIGNING_KEY" ]; then
  sudo -u vagrant -H git config --global gpg.format ssh
  sudo -u vagrant -H git config --global user.signingkey "$SIGNING_KEY"
  sudo -u vagrant -H git config --global commit.gpgsign true
  sudo -u vagrant -H git config --global tag.gpgsign true
  echo "Git signing configured with key: $SIGNING_KEY"
fi

[ -n "$GIT_NAME" ] && sudo -u vagrant -H git config --global user.name "$GIT_NAME"
[ -n "$GIT_EMAIL" ] && sudo -u vagrant -H git config --global user.email "$GIT_EMAIL"

# Global gitignore (base64 encoded, read from host during vagrant up)
GIT_IGNORE_B64="#{git_ignore_content_b64}"
if [ -n "$GIT_IGNORE_B64" ]; then
  echo "$GIT_IGNORE_B64" | base64 -d > /home/vagrant/.gitignore_global
  chown vagrant:vagrant /home/vagrant/.gitignore_global
  sudo -u vagrant -H git config --global core.excludesfile /home/vagrant/.gitignore_global
  echo "Global gitignore configured"
fi

ZSH_IN_DOCKER_VERSION="1.2.0"

if [ ! -d /home/vagrant/.oh-my-zsh ]; then
  sudo -u vagrant -H sh -c \
    "$(curl -fsSL https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -x
fi

if ! grep -q "Codex VM niceties" /home/vagrant/.zshrc 2>/dev/null; then
  cat <<'ZSH' >> /home/vagrant/.zshrc
# Codex VM niceties
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export PATH="/usr/local/go/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

HISTSIZE=10000
SAVEHIST=10000
setopt inc_append_history
setopt share_history

if [[ $- == *i* ]] && [ -d /app ]; then
  cd /app
fi

alias ll='ls -alF'
alias gs='git status -sb'
alias yolo-claude='claude --dangerously-skip-permissions'
alias yolo-codex='codex --yolo'

if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
fi

if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi
ZSH

  chown vagrant:vagrant /home/vagrant/.zshrc
fi
  SHELL
end
