# yolo-sandbox

Run [Codex](https://github.com/openai/codex) and [Claude Code](https://github.com/anthropics/claude-code) in an isolated VM environment.

AI coding assistants with terminal access are powerful but can execute destructive commands. This project provides a Vagrant-based sandbox that isolates the operating system while keeping your code accessible.

## Quick Start

```bash
# One-time setup (installs Vagrant, VirtualBox, configures gitignore)
./setup.sh

# Copy Vagrantfile to your project
cp Vagrantfile /path/to/your/project/

# Start the VM
cd /path/to/your/project
vagrant up

# SSH in and use your AI assistant
vagrant ssh
yolo-codex   # codex --yolo
yolo-claude  # claude --dangerously-skip-permissions

# When you are done
vagrant down
```

## What's Included

The VM comes pre-configured with:
- Ubuntu 24.04
- Node.js, Python 3, Go
- Codex and Claude Code CLI tools
- Git, gh CLI, Docker
- Zsh with oh-my-zsh
- Modern CLI tools (ripgrep, fd, bat, fzf, delta)

## Provider Options

VirtualBox is the default provider. Alternatives:

```bash
# Use a different provider
vagrant up --provider=parallels
vagrant up --provider=vmware_desktop
vagrant up --provider=qemu

# Set a default provider
export VAGRANT_DEFAULT_PROVIDER=parallels
```

## Sync Behavior

By default, your project directory is two-way synced to `/app` in the VM. Changes made on either side are reflected immediately.

For extra safety, you can switch to one-way sync (host → VM only) by editing the Vagrantfile:

```ruby
config.vm.synced_folder ".", "/app", type: "rsync"
```

## Git Commit Signing

If you have SSH commit signing configured on your host, it works automatically in the VM via SSH agent forwarding:

1. **Your signing key** is read from `git config` during `vagrant up`
2. **SSH agent forwarding** connects to your host's SSH agent
3. **When you commit**, the signing request is forwarded to your host

Works with any SSH agent: standard `ssh-agent`, 1Password, Secretive, etc.

**What gets passed to the VM:**
- `user.signingkey` - your SSH public key for signing
- `user.name` and `user.email` - your Git identity
- `core.excludesfile` content - your global gitignore patterns

**Security:**
- Only public key strings are passed (no files mounted from home)
- Private keys never leave your host machine

## Safety Notes

The VM isolates the operating system, **not your code**. The AI assistant can still:
- Modify files in your synced project directory
- Delete files in your synced project directory
- Run git commands that affect your repository

The sandbox prevents:
- System-wide changes to your host machine
- Installation of packages on your host
- Access to files outside the synced directory

**Always commit or backup important changes before letting an AI assistant work on your code.**

## Attribution

Inspired by [Running Claude Code Dangerously, Safely](https://blog.emilburzo.com/2026/01/running-claude-code-dangerously-safely/) by Emil Burzo.

## License

MIT
