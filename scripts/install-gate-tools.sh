#!/bin/bash
# install-gate-tools.sh — Installs the infra-quality/policy/security/cost gate
# CLI binaries directly on the HOST (not just inside .harness-sandbox/docker/
# Dockerfile.sandbox, which already had all of these for CI/sandboxed runs).
#
# Closes the gap where `skills/infra-quality-gates`, `skills/policy-gates`,
# `skills/security-gates`, `skills/cost-gates` scripts report SKIPPED locally
# (tool not installed) even though the exact same gates run for real in CI —
# see infra-platform .specs/project/DECISIONS.md D-2026-09-15-2/3.
#
# Versions/URLs/arch-naming quirks below are copied verbatim from
# docker/Dockerfile.sandbox (the canonical, already-verified-live source —
# do not edit versions here without updating both files, or they'll drift).
#
# Usage: ./install-gate-tools.sh
# Installs to ~/.local/bin (same convention already used on rastaFul dev
# machines for terraform/trivy/gitleaks/shellcheck/gh — no sudo required).
# Idempotent: skips any tool whose binary is already on PATH.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OS="linux"
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64) TARGETARCH="amd64" ;;
  aarch64|arm64) TARGETARCH="arm64" ;;
  *) echo "❌ Unsupported arch: $ARCH_RAW"; exit 1 ;;
esac

log()  { echo "[install-gate-tools] $*"; }
skip() { log "✅ $1 already installed ($(command -v "$1"))"; }

# ── tflint ───────────────────────────────────────────────────────────────
# Real bug found live 2026-09-15: terraform-linters/tflint removed
# install_linux.sh from its repo on 2026-09-12 (3 days before this was
# written) -- the old `curl .../install_linux.sh | bash` pattern now 404s.
# Switched to a direct release zip download, same pattern as every other
# tool in this script.
if command -v tflint &>/dev/null; then skip tflint; else
  log "📦 Installing tflint..."
  if curl -sSfLo "$TMP/tflint.zip" \
      "https://github.com/terraform-linters/tflint/releases/latest/download/tflint_${OS}_${TARGETARCH}.zip"; then
    unzip -q -o "$TMP/tflint.zip" -d "$BIN_DIR" tflint
    chmod +x "$BIN_DIR/tflint"
    log "✅ tflint installed"
  else
    log "⚠️  tflint download failed — skipping"
  fi
fi

# ── terraform-docs v0.24.0 ──────────────────────────────────────────────
if command -v terraform-docs &>/dev/null; then skip terraform-docs; else
  log "📦 Installing terraform-docs..."
  TERRAFORM_DOCS_VERSION=0.24.0
  if curl -sSfLo "$TMP/terraform-docs.tar.gz" \
      "https://terraform-docs.io/dl/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-${OS}-${TARGETARCH}.tar.gz"; then
    tar -xzf "$TMP/terraform-docs.tar.gz" -C "$TMP"
    mv "$TMP/terraform-docs" "$BIN_DIR/terraform-docs"
    chmod +x "$BIN_DIR/terraform-docs"
    log "✅ terraform-docs installed"
  else
    log "⚠️  terraform-docs download failed — skipping"
  fi
fi

# ── polaris v10.2.2 ──────────────────────────────────────────────────────
if command -v polaris &>/dev/null; then skip polaris; else
  log "📦 Installing polaris..."
  POLARIS_VERSION=10.2.2
  if curl -sSfLo "$TMP/polaris.tar.gz" \
      "https://github.com/FairwindsOps/polaris/releases/download/v${POLARIS_VERSION}/polaris_${POLARIS_VERSION}_${OS}_${TARGETARCH}.tar.gz"; then
    tar -xzf "$TMP/polaris.tar.gz" -C "$BIN_DIR" polaris
    chmod +x "$BIN_DIR/polaris"
    log "✅ polaris installed"
  else
    log "⚠️  polaris download failed — skipping"
  fi
fi

# ── pluto v5.24.3 ────────────────────────────────────────────────────────
if command -v pluto &>/dev/null; then skip pluto; else
  log "📦 Installing pluto..."
  PLUTO_VERSION=5.24.3
  if curl -sSfLo "$TMP/pluto.tar.gz" \
      "https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_${OS}_${TARGETARCH}.tar.gz"; then
    tar -xzf "$TMP/pluto.tar.gz" -C "$BIN_DIR" pluto
    chmod +x "$BIN_DIR/pluto"
    log "✅ pluto installed"
  else
    log "⚠️  pluto download failed — skipping"
  fi
fi

# ── kubeconform v0.8.0 ───────────────────────────────────────────────────
if command -v kubeconform &>/dev/null; then skip kubeconform; else
  log "📦 Installing kubeconform..."
  KUBECONFORM_VERSION=0.8.0
  if curl -sSfLo "$TMP/kubeconform.tar.gz" \
      "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-${OS}-${TARGETARCH}.tar.gz"; then
    tar -xzf "$TMP/kubeconform.tar.gz" -C "$BIN_DIR" kubeconform
    chmod +x "$BIN_DIR/kubeconform"
    log "✅ kubeconform installed"
  else
    log "⚠️  kubeconform download failed — skipping"
  fi
fi

# ── kube-linter v0.8.3 (amd64 asset has NO arch suffix, arm64 does) ────────
if command -v kube-linter &>/dev/null; then skip kube-linter; else
  log "📦 Installing kube-linter..."
  KUBE_LINTER_VERSION=0.8.3
  KL_FILE=$([ "$TARGETARCH" = "arm64" ] && echo "kube-linter-linux_arm64.tar.gz" || echo "kube-linter-linux.tar.gz")
  if curl -sSfLo "$TMP/kube-linter.tar.gz" \
      "https://github.com/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/${KL_FILE}"; then
    tar -xzf "$TMP/kube-linter.tar.gz" -C "$BIN_DIR" kube-linter
    chmod +x "$BIN_DIR/kube-linter"
    log "✅ kube-linter installed"
  else
    log "⚠️  kube-linter download failed — skipping"
  fi
fi

# ── conftest v0.69.0 (amd64 asset is "x86_64", arm64 is "arm64") ─────────
if command -v conftest &>/dev/null; then skip conftest; else
  log "📦 Installing conftest..."
  CONFTEST_VERSION=0.69.0
  CONFTEST_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x86_64")
  if curl -sSfL "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_${CONFTEST_ARCH}.tar.gz" \
      | tar -xz -C "$BIN_DIR" conftest; then
    chmod +x "$BIN_DIR/conftest"
    log "✅ conftest installed"
  else
    log "⚠️  conftest download failed — skipping"
  fi
fi

# ── osv-scanner v2.5.1 ───────────────────────────────────────────────────
if command -v osv-scanner &>/dev/null; then skip osv-scanner; else
  log "📦 Installing osv-scanner..."
  OSV_SCANNER_VERSION=2.5.1
  if curl -sSfLo "$BIN_DIR/osv-scanner" \
      "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_${OS}_${TARGETARCH}"; then
    chmod +x "$BIN_DIR/osv-scanner"
    log "✅ osv-scanner installed"
  else
    log "⚠️  osv-scanner download failed — skipping"
  fi
fi

# ── syft (official install script, installs to $BIN_DIR via -b) ─────────
if command -v syft &>/dev/null; then skip syft; else
  log "📦 Installing syft..."
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \
    | sh -s -- -b "$BIN_DIR" \
    && log "✅ syft installed" \
    || log "⚠️  syft install failed — skipping"
fi

# ── grype (official install script) ──────────────────────────────────────
if command -v grype &>/dev/null; then skip grype; else
  log "📦 Installing grype..."
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh \
    | sh -s -- -b "$BIN_DIR" \
    && log "✅ grype installed" \
    || log "⚠️  grype install failed — skipping"
fi

# ── infracost (official install script, needs INFRACOST_API_KEY at runtime
#    to actually price anything — not provisioned here, see cost-gates SKILL) ──
if command -v infracost &>/dev/null; then skip infracost; else
  log "📦 Installing infracost..."
  if curl -fsSL https://raw.githubusercontent.com/infracost/cli/main/scripts/install.sh -o "$TMP/infracost-install.sh"; then
    chmod +x "$TMP/infracost-install.sh"
    # Upstream script defaults to /usr/local/bin and may try sudo -- point it
    # at $BIN_DIR instead, same no-sudo convention as everything else here.
    if INSTALL_DIR="$BIN_DIR" sh "$TMP/infracost-install.sh" &>/dev/null && command -v infracost &>/dev/null; then
      log "✅ infracost installed"
    else
      log "⚠️  infracost install failed (may need INSTALL_DIR support upstream) — skipping"
    fi
  else
    log "⚠️  infracost installer download failed — skipping"
  fi
fi

# ── semgrep (pip, --user — no PEP668 on Ubuntu 20.04-class hosts; if a
#    newer host needs --break-system-packages, pass PIP_BREAK_SYSTEM_PACKAGES=1) ──
if command -v semgrep &>/dev/null; then skip semgrep; else
  log "📦 Installing semgrep (pip)..."
  PIP_FLAGS="--user"
  [ "${PIP_BREAK_SYSTEM_PACKAGES:-0}" = "1" ] && PIP_FLAGS="--user --break-system-packages"
  if pip3 install $PIP_FLAGS semgrep &>/dev/null; then
    log "✅ semgrep installed (ensure ~/.local/bin is on PATH)"
  else
    log "⚠️  semgrep pip install failed (needs Python >=3.9 in recent releases — this host: $(python3 --version 2>&1)) — skipping"
  fi
fi

log "Done. Re-run this script any time to pick up tools that were skipped (e.g. after a Python upgrade for semgrep)."
log "Verify: tflint --version; terraform-docs --version; polaris version; pluto version; kubeconform -v; kube-linter version; conftest --version; osv-scanner --version; syft version; grype version; infracost --version; semgrep --version"
