#!/usr/bin/env bash
# Copies the template payload into an existing repo checkout.
# Overwrites files that already exist, so review the diff before committing.
#
# Usage: scripts/apply-to-repo.sh <path-to-target-repo-checkout>
set -euo pipefail

TARGET="${1:?usage: $0 <path-to-target-repo-checkout>}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"

[ -d "$TARGET/.git" ] || { echo "error: $TARGET is not a git checkout" >&2; exit 1; }

mkdir -p "$TARGET/.github/workflows" "$TARGET/.github/ISSUE_TEMPLATE" "$TARGET/scripts"

cp "$SRC"/.github/workflows/*.yml "$TARGET/.github/workflows/"
cp "$SRC"/.github/ISSUE_TEMPLATE/*.yml "$TARGET/.github/ISSUE_TEMPLATE/"
cp "$SRC/.github/PULL_REQUEST_TEMPLATE.md" "$TARGET/.github/"
cp "$SRC/.github/dependabot.yml" "$TARGET/.github/"
cp "$SRC/.github/labeler.yml" "$TARGET/.github/"
cp "$SRC/.markdownlint-cli2.jsonc" "$TARGET/"
# Only the generic re-runnable scripts; the template-only ones stay here.
cp "$SRC/scripts/apply-labels.sh" "$SRC/scripts/apply-branch-protection.sh" "$TARGET/scripts/"

cat <<'EOF'
Payload copied. Manual follow-ups in the target repo:
  1. Adapt .github/labeler.yml globs to the repo layout.
  2. Uncomment the matching ecosystem in .github/dependabot.yml.
  3. Run scripts/apply-labels.sh <owner>/<repo>.
  4. Run scripts/apply-branch-protection.sh <owner>/<repo> once CI has run.
  5. Review the diff before committing.
EOF
