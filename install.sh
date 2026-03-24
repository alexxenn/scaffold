#!/bin/bash
# Scaffold — Install Script
# Copies skills to ~/.claude/commands/ and optionally merges hooks

set -e

COMMANDS_DIR="$HOME/.claude/commands"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Scaffold — Installer"
echo "===================="

# Create commands directory if it doesn't exist
mkdir -p "$COMMANDS_DIR"

# Copy all skill files
echo "Installing skills to $COMMANDS_DIR..."
for file in "$SCRIPT_DIR/commands/"*.md; do
    name=$(basename "$file")
    if [ -f "$COMMANDS_DIR/$name" ]; then
        echo "  ⚠  $name already exists — overwrite? (y/N)"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            cp "$file" "$COMMANDS_DIR/$name"
            echo "  ✓  $name (updated)"
        else
            echo "  →  $name (skipped)"
        fi
    else
        cp "$file" "$COMMANDS_DIR/$name"
        echo "  ✓  $name"
    fi
done

echo ""
echo "Skills installed: $(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l) files"

# Hooks setup
echo ""
echo "Install hooks? This adds session reminders, agent model logging, and danger detection."
echo "If you have an existing settings.json, you will need to merge manually. (y/N)"
read -r answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    mkdir -p "$HOME/.claude"
    if [ -f "$SETTINGS_FILE" ]; then
        echo "  ⚠  $SETTINGS_FILE already exists."
        echo "  Hooks file saved to: $HOME/.claude/settings.hooks.json"
        echo "  Merge it manually with your existing settings.json."
        cp "$SCRIPT_DIR/hooks/settings.json" "$HOME/.claude/settings.hooks.json"
    else
        cp "$SCRIPT_DIR/hooks/settings.json" "$SETTINGS_FILE"
        echo "  ✓  Hooks installed to $SETTINGS_FILE"
    fi
fi

echo ""
echo "Done. Restart Claude Code to load the new skills."
echo ""
echo "Quick start:"
echo "  /project-setup <name>   — Bootstrap a new project"
echo "  /preload                — Load context at session start"
echo "  /decide <decision>      — Research + debate any architecture decision"
echo "  /route-model            — See the 3-tier model routing table"
