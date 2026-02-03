This repository provides a Vagrant-based sandbox for running AI coding assistants (Codex, Claude Code) in isolation:
- `Vagrantfile` - VM configuration (Ubuntu 24.04, dev tools, AI CLI tools, SSH agent forwarding)
- `Brewfile` - macOS dependencies (Vagrant, VirtualBox)
- `setup.sh` - One-time setup script (installs deps, configures gitignore)
- `Makefile` - Common tasks (`make help` for list)

## Features
- **`yolo-claude` and `yolo-codex` aliases** - Run AI assistants in fully autonomous mode
- **SSH agent forwarding** - Your host's SSH agent works inside the VM for authentication and commit signing
- Git signing key and user identity are auto-configured from host's `git config`
- Global gitignore patterns are copied from host

## Commands

    make setup      # Run setup.sh
    make validate   # Validate Vagrantfile and lint setup.sh
    make validate VAGRANT_VALIDATE_FLAGS=--ignore-provider  # Validate without provider checks (CI)

## Rules of engagement
- Run `make validate` on any changes to `Vagrantfile` or `setup.sh`. Note: requires `shellcheck` installed (`brew install shellcheck`). Use `VAGRANT_VALIDATE_FLAGS=--ignore-provider` in CI or environments without a provider.
- Make sure README.md and AGENTS.md are up-to-date with any code changes.
- This is a shared and open source project, don't add or commit any secrets or private information.
