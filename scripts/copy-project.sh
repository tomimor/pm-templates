#!/usr/bin/env bash
# Copies the canonical project board (views + fields, no items) to a new owner.
# Views have no create API, so copyProjectV2 is the only way to replicate them.
#
# Usage: scripts/copy-project.sh <target-owner> [title]
#
# Requires: gh authenticated with `project` scope, read access to the source
# project, and project-create permission on the target owner. Fine-grained PATs
# are single-owner; use a user session or classic PAT for cross-org copies.
set -euo pipefail

TARGET_OWNER="${1:?usage: $0 <target-owner> [title]}"
TITLE="${2:-PM Board Template}"

# Canonical source. Override via env to copy from a different board.
SOURCE_OWNER="${SOURCE_OWNER:-tomimor}"
SOURCE_NUMBER="${SOURCE_NUMBER:-9}"

# External jq instead of gh --jq: on a GraphQL error gh prints the raw
# response body unfiltered, which would defeat the emptiness guards below.
# The `|| true` keeps set -e from killing the script before those guards run.
owner_project_id() {
  local owner="$1" number="$2"
  gh api graphql -f query='
    query($owner: String!, $number: Int!) {
      repositoryOwner(login: $owner) {
        ... on ProjectV2Owner { projectV2(number: $number) { id } }
      }
    }' -f owner="$owner" -F number="$number" 2>/dev/null \
    | jq -r '.data.repositoryOwner.projectV2.id // empty' 2>/dev/null || true
}

owner_node_id() {
  gh api graphql -f query='
    query($owner: String!) { repositoryOwner(login: $owner) { id } }' \
    -f owner="$1" 2>/dev/null \
    | jq -r '.data.repositoryOwner.id // empty' 2>/dev/null || true
}

SOURCE_ID="$(owner_project_id "$SOURCE_OWNER" "$SOURCE_NUMBER")"
[ -n "$SOURCE_ID" ] || { echo "error: source project $SOURCE_OWNER/#$SOURCE_NUMBER not found or not readable" >&2; exit 1; }

TARGET_ID="$(owner_node_id "$TARGET_OWNER")"
[ -n "$TARGET_ID" ] || { echo "error: owner $TARGET_OWNER not found" >&2; exit 1; }

# Copying is not idempotent (same-title duplicates are allowed), so abort if
# the target already has a board with this title.
EXISTING="$(gh api graphql -f query='
  query($owner: String!, $q: String!) {
    repositoryOwner(login: $owner) {
      ... on ProjectV2Owner { projectsV2(first: 5, query: $q) { nodes { title url } } }
    }
  }' -f owner="$TARGET_OWNER" -f q="$TITLE" 2>/dev/null \
  | jq -r --arg t "$TITLE" '.data.repositoryOwner.projectsV2.nodes[]? | select(.title == $t) | .url' 2>/dev/null || true)"
[ -z "$EXISTING" ] || { echo "error: $TARGET_OWNER already has a project titled '$TITLE': $EXISTING" >&2; echo "Pass a different title, or use the existing board." >&2; exit 1; }

if ! URL="$(gh api graphql -f query='
  mutation($project: ID!, $owner: ID!, $title: String!) {
    copyProjectV2(input: {projectId: $project, ownerId: $owner, title: $title, includeDraftIssues: false}) {
      projectV2 { number url }
    }
  }' -f project="$SOURCE_ID" -f owner="$TARGET_ID" -f title="$TITLE" \
  --jq '.data.copyProjectV2.projectV2.url')"; then
  echo "error: copy failed." >&2
  echo "If the target is an org, check that organization projects are enabled:" >&2
  echo "  gh api orgs/$TARGET_OWNER --jq .has_organization_projects" >&2
  echo "  gh api -X PATCH orgs/$TARGET_OWNER -F has_organization_projects=true" >&2
  exit 1
fi

echo "Board copied: $URL"
echo "Manual follow-ups (see docs/project-board.md): enable auto-add, verify"
echo "closed->Done workflow, link the repo to the project."
