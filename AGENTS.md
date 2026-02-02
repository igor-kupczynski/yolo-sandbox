This repository provides a Vagrant-based sandbox for running AI coding assistants (Codex, Claude Code) in isolation.

## Repository Structure

- `Vagrantfile` - VM configuration (Ubuntu 24.04, dev tools, AI CLI tools)
- `Brewfile` - macOS dependencies (Vagrant, VirtualBox)
- `setup.sh` - One-time setup script (installs deps, configures gitignore)
- `Makefile` - Common tasks (`make help` for list)

## Commands

```bash
make setup      # Run setup.sh
make validate   # Validate Vagrantfile and lint setup.sh
```

Run `make validate` on any changes to `Vagrantfile` or `setup.sh`.

Make sure README.md and AGENTS.md are up-to-date with any code changes. 
