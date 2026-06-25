#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

matches="$(
  {
    rg -n --glob 'dune' --glob 'dune-project' --glob '*.opam' \
      '\b(bonsai|bonsai\.driver|core|core_kernel|ppx_jane|ppx_bonsai)\b' .
    rg -n --glob '*.ml' --glob '*.mli' \
      '\bBonsai\b|\bCore\b|open! Core|open Core' .
  } \
    | rg -v '^\./scripts/check-no-bonsai-core-deps\.sh:' \
    | rg -v '^\./test/dune:' \
    | rg -v '^\./(dune-project|[^:]+\.opam):[0-9]+:.*(bonsai-native|github\.com/.*/bonsai-native|name bonsai_|name bonsai|public_name bonsai_)' \
    | rg -v '^\./[^:]+:[0-9]+:.*\bBonsai_[a-zA-Z0-9_]+\b' \
    || true
)"

if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches"
  exit 1
fi
