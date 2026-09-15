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

# Install infra-quality/policy/security/cost gate CLIs directly on the host
# (tflint, terraform-docs, polaris, pluto, kubeconform, kube-linter,
# conftest, osv-scanner, syft, grype, infracost, semgrep) — same tools
# already baked into .harness-sandbox/docker/Dockerfile.sandbox for CI,
# shared with the Claude Code installer so both agent CLIs get real gates
# locally instead of SKIPPED (see rastaFul infra-platform .specs/project/
# DECISIONS.md D-2026-09-15-2/3).
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$REPO_ROOT/scripts/install-gate-tools.sh" ]; then
  echo "📦 Installing infra/policy/security/cost gate tools on host..."
  bash "$REPO_ROOT/scripts/install-gate-tools.sh" || echo "⚠️  install-gate-tools.sh had failures — see output above, gates degrade to SKIPPED per-tool, never a false PASS"
fi

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
