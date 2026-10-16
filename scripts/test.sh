#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .build
swiftc Sources/iMusic/Models/Lyrics.swift scripts/test-lrc.swift -o .build/lrc-smoke-test
.build/lrc-smoke-test
