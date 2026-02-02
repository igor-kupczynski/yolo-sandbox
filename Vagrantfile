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

vm_name = File.basename(Dir.getwd)

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

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
sudo -u vagrant -H bash -lc "npm install -g @openai/codex @anthropic-ai/claude-code typescript ts-node --no-audit --no-fund"

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
