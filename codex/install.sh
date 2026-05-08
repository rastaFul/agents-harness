#!/bin/bash
# Install Harness agents into a project for OpenAI Codex
# Usage: ./install.sh <target-project-dir>
set -euo pipefail

TARGET="${1:?Usage: ./install.sh <target-project-dir>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "❌ Directory $TARGET does not exist"
  exit 1
fi

echo "📦 Installing Harness agents (Codex format) into $TARGET..."

# Copy AGENTS.md
cp "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"

# Copy .agents/skills/
cp -r "$SCRIPT_DIR/.agents" "$TARGET/.agents"

# Copy steering
cp -r "$SCRIPT_DIR/steering" "$TARGET/steering"

echo ""
echo "✅ Installed successfully!"
echo ""
echo "Usage:"
echo "  cd $TARGET"
echo "  codex                         # Start Codex session"
echo ""
echo "The agent will read AGENTS.md automatically and operate in spec-driven mode."
echo "Use \$harness-gates or \$feedback-loop to explicitly invoke skills."
echo ""
echo "Optional: Start sandbox for SonarQube and isolated execution:"
echo "  cd $(dirname "$SCRIPT_DIR")/docker"
echo "  ./sandbox-run.sh $TARGET"
