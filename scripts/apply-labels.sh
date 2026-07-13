#!/usr/bin/env bash
# Creates the baseline label set in a repo. Existing labels are updated in place
# (--force), other labels are left alone. Requires `repo` scope.
#
# Usage: scripts/apply-labels.sh <owner>/<repo>
set -euo pipefail

REPO="${1:?usage: $0 <owner>/<repo>}"

# label|color|description
LABELS=(
  "bug|d73a4a|Something is broken"
  "feature|a2eeef|New functionality or enhancement"
  "task|0e8a16|Scoped piece of work under a feature"
  "chore|fef2c0|Maintenance, deps, CI"
  "documentation|0075ca|Docs only"
  "tech-debt|d4c5f9|Cleanup or refactor work"
  "ci|ededed|Workflows and automation"
)

for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color desc <<<"$entry"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force
  echo "label: $name"
done

echo "Labels applied to $REPO"
