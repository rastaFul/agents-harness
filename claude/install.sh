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

# Copy dev-quality gate templates (dependency-cruiser, jscpd, Stryker,
# commitlint, husky/lint-staged pre-commit setup). Files only — this does
# NOT install devDependencies or run husky init, see printed instructions.
if [ -d "$SCRIPT_DIR/templates" ]; then
  cp -r "$SCRIPT_DIR/templates" "$TARGET/templates"
fi

# Copy sandbox docker files (needed by both local sandbox-run.sh AND
# .github/workflows/gates.yml — same Dockerfile in both places is the
# mechanism that keeps local gates and CI gates from drifting apart)
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
mkdir -p "$TARGET/.harness-sandbox"
cp -r "$REPO_ROOT/docker" "$TARGET/.harness-sandbox/docker"

# Copy CI workflow template
mkdir -p "$TARGET/.github/workflows"
cp "$REPO_ROOT/.github/workflows/gates.yml" "$TARGET/.github/workflows/gates.yml"
echo "✅ CI workflow installed at .github/workflows/gates.yml (builds .harness-sandbox/docker/Dockerfile.sandbox — same image used locally)"

# Copy CODEOWNERS (decided: single maintainer, always @rastaFul — QUESTIONS.pt-BR.md #11)
if [ -f "$REPO_ROOT/.github/CODEOWNERS" ] && [ ! -f "$TARGET/.github/CODEOWNERS" ]; then
  cp "$REPO_ROOT/.github/CODEOWNERS" "$TARGET/.github/CODEOWNERS"
  echo "✅ .github/CODEOWNERS installed (owner: @rastaFul)"
elif [ -f "$TARGET/.github/CODEOWNERS" ]; then
  echo "ℹ️  $TARGET/.github/CODEOWNERS already exists — not overwriting"
fi

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

# Install claude-auto-retry (resume autonomous sessions after subscription rate limit)
install_claude_auto_retry() {
  if command -v claude-auto-retry &>/dev/null; then
    echo "✅ claude-auto-retry already installed"
  else
    echo "📦 Installing claude-auto-retry..."
    if ! npm install -g claude-auto-retry &>/dev/null; then
      echo "⚠️  claude-auto-retry install failed — autonomous rate-limit resume unavailable"
      return
    fi
    if command -v tmux &>/dev/null || { echo "📦 tmux missing — install manually (apt/brew install tmux) before using autonomous mode"; }; then
      :
    fi
    claude-auto-retry install &>/dev/null \
      && echo "✅ claude-auto-retry shell wrapper installed (restart shell or source rc file)" \
      || echo "⚠️  claude-auto-retry install step failed — run manually: claude-auto-retry install"
  fi

  # Config: force re-grounding via STATE.md on resume instead of a blind "continue"
  local CFG="$HOME/.claude-auto-retry.json"
  if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<'JSON'
{
  "retryMessage": "Rate limit reset. Re-read .specs/project/STATE.md and .specs/audit/execution.md before continuing, then resume from the last checkpoint.",
  "maxRetries": 5,
  "pollIntervalSeconds": 10,
  "marginSeconds": 90
}
JSON
    echo "✅ ~/.claude-auto-retry.json written (retryMessage forces STATE.md re-read)"
  else
    echo "ℹ️  ~/.claude-auto-retry.json already exists — not overwriting"
  fi
}

install_claude_auto_retry

# Install Lighthouse CI (perf/a11y gate — reports, no threshold decided yet, see .specs/QUESTIONS.md)
install_perf_a11y_tools() {
  if command -v lhci &>/dev/null; then
    echo "✅ @lhci/cli already installed"
  else
    echo "📦 Installing @lhci/cli globally..."
    npm install -g @lhci/cli &>/dev/null \
      && echo "✅ @lhci/cli installed" \
      || echo "⚠️  @lhci/cli install failed — Lighthouse gate unavailable"
  fi

  if [ -f "$TARGET/package.json" ]; then
    (cd "$TARGET" && npm install -D axe-playwright &>/dev/null) \
      && echo "✅ axe-playwright added as devDependency (see skills/perf-a11y-gates/scripts/axe-snippet.md to wire it into your Playwright test)" \
      || echo "⚠️  axe-playwright install failed — add manually: npm install -D axe-playwright"
  else
    echo "ℹ️  no package.json in $TARGET yet — skipping axe-playwright devDependency install, add later with: npm install -D axe-playwright"
  fi
}

install_perf_a11y_tools

# Install infra-quality/policy/security/cost gate CLIs directly on the host
# (tflint, terraform-docs, polaris, pluto, kubeconform, kube-linter,
# conftest, osv-scanner, syft, grype, infracost, semgrep) — these already
# ran for real in .harness-sandbox/docker/Dockerfile.sandbox (CI), this
# closes the gap where the exact same skills/*-gates scripts reported
# SKIPPED locally for lack of the binary (see rastaFul infra-platform
# .specs/project/DECISIONS.md D-2026-09-15-2/3).
if [ -f "$REPO_ROOT/scripts/install-gate-tools.sh" ]; then
  echo "📦 Installing infra/policy/security/cost gate tools on host..."
  bash "$REPO_ROOT/scripts/install-gate-tools.sh" || echo "⚠️  install-gate-tools.sh had failures — see output above, gates degrade to SKIPPED per-tool, never a false PASS"
fi

# Dev-quality gate bundle (dependency-cruiser, sonarjs, jscpd, Stryker,
# husky/lint-staged/commitlint) — DECIDED (QUESTIONS.pt-BR.md #17, 2026-09):
# auto-install everywhere a package.json exists, same policy as
# axe-playwright above. Previously document-only, a policy inconsistency
# the user explicitly flagged and asked to resolve toward "always auto
# install, since these are dependencies I always want as gates."
#
# BUG FOUND AND FIXED via a real product-repo rollout (rastafinancas,
# 2026-09-08): lint-staged 17+ hard-requires git >=2.32.0 and refuses to
# run at all below that — confirmed live, this machine's git is 2.25.1
# (an entirely ordinary case: any dev machine not on a very recent distro/
# WSL image). Without pinning, the FIRST commit after rollout fails
# outright with "lint-staged requires at least Git version 2.32.0" — not a
# soft warning, a hard block on every future commit. Pinned to
# lint-staged@16 (last major line without that floor) instead of chasing
# a system-wide git upgrade, which is a much bigger, more invasive change
# than this template should make unilaterally on someone's machine.
install_dev_quality_bundle() {
  if [ ! -f "$TARGET/package.json" ]; then
    echo "ℹ️  no package.json in $TARGET yet — skipping dev-quality bundle install, add later with:"
    echo "   npm install -D husky lint-staged@16 @commitlint/cli @commitlint/config-conventional dependency-cruiser eslint-plugin-sonarjs jscpd @stryker-mutator/core @stryker-mutator/jest-runner"
    return
  fi

  echo "📦 Installing dev-quality bundle devDependencies into $TARGET..."
  if (cd "$TARGET" && npm install -D husky lint-staged@16 @commitlint/cli @commitlint/config-conventional dependency-cruiser eslint-plugin-sonarjs jscpd @stryker-mutator/core @stryker-mutator/jest-runner &>/dev/null); then
    echo "✅ dev-quality bundle devDependencies installed"
  else
    echo "⚠️  dev-quality bundle install failed — install manually: npm install -D husky lint-staged@16 @commitlint/cli @commitlint/config-conventional dependency-cruiser eslint-plugin-sonarjs jscpd @stryker-mutator/core @stryker-mutator/jest-runner"
    return
  fi

  if (cd "$TARGET" && bash "$TARGET/templates/dev-quality/husky/setup-husky.sh") &>/dev/null; then
    echo "✅ husky hooks activated + dev-quality configs placed at project root"
  else
    echo "⚠️  husky setup failed — run manually: bash templates/dev-quality/husky/setup-husky.sh"
  fi

  echo "ℹ️  eslint-plugin-sonarjs installed but NOT auto-wired into your ESLint config (config shape varies too much per project) — add plugin+rules manually, see skills/code-gates/SKILL.md"
}

install_dev_quality_bundle

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
echo ""
echo "Autonomous mode: always launch with --remote-control, e.g.:"
echo "  claude --agent harness-infra --remote-control --name $(basename "$TARGET")-autonomous"
