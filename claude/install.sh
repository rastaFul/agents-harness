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

# Install snip (token filter for Claude Code)
install_snip() {
  if command -v snip &>/dev/null; then
    echo "✅ snip already installed: $(snip --version)"
    return
  fi

  echo "📦 Installing snip..."
  local OS ARCH URL
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  [[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
  [[ "$ARCH" == "aarch64" ]] && ARCH="arm64"

  local VERSION="0.15.0"
  URL="https://github.com/edouard-claude/snip/releases/download/v${VERSION}/snip_${VERSION}_${OS}_${ARCH}.tar.gz"

  local TMP
  TMP="$(mktemp -d)"
  if curl -fsSL "$URL" -o "$TMP/snip.tar.gz"; then
    tar -xzf "$TMP/snip.tar.gz" -C "$TMP"
    mkdir -p "$HOME/.local/bin"
    mv "$TMP/snip" "$HOME/.local/bin/snip"
    chmod +x "$HOME/.local/bin/snip"
    rm -rf "$TMP"

    # Ensure PATH
    for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if [ -f "$RC" ] && ! grep -q '\.local/bin' "$RC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
      fi
    done
    export PATH="$HOME/.local/bin:$PATH"
    echo "✅ snip installed: $(snip --version)"
  else
    echo "⚠️  snip download failed — skipping (token compression unavailable)"
    rm -rf "$TMP"
    return
  fi
}

install_snip

# Hook snip into Claude Code settings
if command -v snip &>/dev/null; then
  snip init --agent claude-code 2>/dev/null && echo "✅ snip hook registered in Claude Code" || true
fi

# Install Playwright MCP (E2E gate)
install_playwright_mcp() {
  echo "📦 Installing @playwright/mcp globally..."
  if npm install -g @playwright/mcp@latest &>/dev/null; then
    echo "✅ @playwright/mcp installed"
  else
    echo "⚠️  @playwright/mcp install failed — E2E gate unavailable"
    return
  fi

  # Register MCP server in user-scope Claude Code config
  if command -v claude &>/dev/null; then
    if claude mcp list 2>/dev/null | grep -q "playwright"; then
      echo "✅ playwright MCP already registered"
    else
      claude mcp add playwright -s user -- npx @playwright/mcp@latest 2>/dev/null \
        && echo "✅ playwright MCP registered (user scope)" \
        || echo "⚠️  playwright MCP registration failed — run manually: claude mcp add playwright -s user -- npx @playwright/mcp@latest"
    fi
  else
    echo "⚠️  claude CLI not found — skip MCP registration"
  fi
}

install_playwright_mcp

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
