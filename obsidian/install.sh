#!/bin/bash
set -euo pipefail

command -v node >/dev/null || { echo 'Node.js 22.6+ is required.' >&2; exit 1; }
brew install --cask obsidian
node --experimental-strip-types "$(dirname "${BASH_SOURCE[0]}")/setup.ts" "$@"
node --experimental-strip-types "$(dirname "${BASH_SOURCE[0]}")/link-codex.ts" "$@"
