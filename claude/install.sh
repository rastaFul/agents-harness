#!/bin/bash
# Install Harness agents into a project for Claude Code
# Usage: ./install.sh <target-project-dir>
set -euo pipefail

TARGET="${1:?Usage: ./install.sh <target-project-dir>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "❌ Directory $TARGET does not exist"
  exit 1
fi

echo "📦 Installing Harness agents (Claude Code format) into $TARGET..."

# Copy CLAUDE.md
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"

# Copy .claude/agents/
mkdir -p "$TARGET/.claude/agents"
cp "$SCRIPT_DIR/.claude/agents/"*.md "$TARGET/.claude/agents/"

# Copy skills
cp -r "$SCRIPT_DIR/skills" "$TARGET/skills"

# Copy steering
cp -r "$SCRIPT_DIR/steering" "$TARGET/steering"

echo ""
echo "✅ Installed successfully!"
echo ""
echo "Usage:"
echo "  cd $TARGET"
echo "  claude --agent harness-dev    # For development tasks"
echo "  claude --agent harness-infra  # For infrastructure tasks"
echo ""
echo "Optional: Start sandbox for SonarQube and isolated execution:"
echo "  cd $(dirname "$SCRIPT_DIR")/docker"
echo "  ./sandbox-run.sh $TARGET"
