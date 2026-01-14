# Claude Code Instructions

## Commit Guidelines
- Never include "Generated with Claude Code" or similar attribution in commit messages
- Never add "Co-Authored-By: Claude" or any Claude/Anthropic attribution to commits
- Never mention Claude, AI, or Anthropic in code comments or documentation

## Custom Commands

### /build-dmg [version]
Build a signed and notarized DMG for distribution.

**Usage:**
- `/build-dmg` - Build with date-based version (YYYY.MM.DD)
- `/build-dmg 1.0.0` - Build with specific version

**Action:** Run `./scripts/build-release-dmg.sh [version]` from the project root.

**Prerequisites:**
- Developer ID Application certificate installed
- Notarization credentials stored as "notary" profile
- `brew install create-dmg fileicon`

**Output:** `release-build/Taptique-{version}.dmg`
