#!/usr/bin/env bash
# Applies branch protection to a repo's main branch.
# Idempotent, safe to re-run to change settings. Requires repo admin + `repo` scope.
#
# Usage: scripts/apply-branch-protection.sh <owner>/<repo> [branch]
#
# Note: PATCHing the .../protection/required_status_checks sub-resource can 404
# depending on token type. The full .../protection PUT below always works, so
# edit CHECKS here and re-run instead.
set -euo pipefail

REPO="${1:?usage: $0 <owner>/<repo> [branch]}"
BRANCH="${2:-main}"

# Required status checks. Names must match the workflow job names exactly.
# Set to '[]' to require none (e.g. before any CI exists in the repo).
CHECKS='["TruffleHog", "Validate Conventional Commit title", "markdownlint"]'

gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" \
  --input - <<JSON
{
  "required_status_checks": {
    "strict": false,
    "contexts": $CHECKS
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": true,
    "require_last_push_approval": false
  },
  "required_linear_history": true,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "restrictions": null
}
JSON

echo "Branch protection applied to $REPO@$BRANCH"
