#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  if [[ -n "${BONSAI_NATIVE_REPO_ROOT:-}" ]]; then
    printf '%s\n' "$BONSAI_NATIVE_REPO_ROOT"
  elif git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$git_root"
  else
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
  fi
)"
workflow="$repo_root/.github/workflows/ci.yml"
dune_project="$repo_root/dune-project"
bonsai_native_opam="$repo_root/bonsai_native.opam"

require_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq "$needle" "$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

reject_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq "$needle" "$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_contains \
  "$workflow" \
  "runs-on: macos-latest" \
  "CI must run on macOS because bonsai_apple builds stubs that include dispatch/dispatch.h."

reject_contains \
  "$workflow" \
  "runs-on: ubuntu-latest" \
  "CI must not run Apple stub builds on Ubuntu."

require_contains \
  "$workflow" \
  "brew install pkg-config ripgrep" \
  "CI must install macOS system dependencies used by build and repository tests."

require_contains \
  "$dune_project" \
  "melange" \
  "dune-project must declare melange for libraries built in Melange mode."

require_contains \
  "$bonsai_native_opam" \
  '"melange"' \
  "bonsai_native.opam must declare melange so fresh opam builds provide melc."
