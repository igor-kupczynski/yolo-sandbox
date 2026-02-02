#!/usr/bin/env bash
#
# Setup script for yolo-sandbox
# Installs dependencies and configures global gitignore
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing dependencies via Homebrew..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

echo "==> Configuring global gitignore..."

# Get or create global excludes file
EXCLUDES_FILE=$(git config --global core.excludesfile 2>/dev/null || true)

if [[ -z "$EXCLUDES_FILE" ]]; then
    EXCLUDES_FILE="$HOME/.gitignore_global"
    git config --global core.excludesfile "$EXCLUDES_FILE"
    echo "    Set core.excludesfile to $EXCLUDES_FILE"
fi

# Expand ~ to full path if needed
EXCLUDES_FILE="${EXCLUDES_FILE/#\~/$HOME}"

# Create the file if it doesn't exist
touch "$EXCLUDES_FILE"

# Add entries if not already present
for entry in "Vagrantfile" ".vagrant/"; do
    if ! grep -qxF "$entry" "$EXCLUDES_FILE" 2>/dev/null; then
        echo "$entry" >> "$EXCLUDES_FILE"
        echo "    Added '$entry' to $EXCLUDES_FILE"
    else
        echo "    '$entry' already in $EXCLUDES_FILE"
    fi
done

echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Copy the Vagrantfile to your project:"
echo "     cp $SCRIPT_DIR/Vagrantfile /path/to/your/project/"
echo ""
echo "  2. Start the VM:"
echo "     cd /path/to/your/project"
echo "     vagrant up"
echo ""
echo "  3. SSH into the VM and run your AI coding assistant:"
echo "     vagrant ssh"
echo "     codex    # for OpenAI Codex"
echo "     claude   # for Claude Code"
