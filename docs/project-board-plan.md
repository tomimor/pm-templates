# Plan: project board integration

Goal: make this repo a complete bootstrap. Applying it to a repo should also
produce a wired-up GitHub Project, replicated from the canonical board.

## Canonical board

`https://github.com/users/tomimor/projects/9` ("PM Board Template", private).
Copied from Moonsong-Labs "Canton Vaults" (#15) on 2026-07-13 with zero items.

- Views: Backlog (table, `-status:Done is:issue`, grouped by Parent issue),
  Team (board, grouped by Milestone), Active PRs (table, `is:pr -status:Done`),
  Me (`assignee:@me`), Milestone (table, grouped by Milestone).
- Fields: Status (Design, Todo, In Progress, To Review, Done), Priority and
  Effort (single-select, no options yet).

Views have no create/update API, so this live project is the source of truth.
Edits to views happen there; `copyProjectV2` propagates them to new copies.

## Phase 1: capture the board

1. `docs/project-board.md`: snapshot of views, fields, and the manual
   built-in-workflow checklist (auto-add rule, "item closed -> Done"). This is
   the reviewable record of what the canonical board should look like.
2. `scripts/copy-project.sh <target-owner> [title]`: wraps `copyProjectV2` from
   the canonical board. Resolves source and target node IDs, runs the mutation,
   prints the new board URL. Requires a token with `project` scope that can
   read the source and write the target (user session or classic PAT;
   fine-grained PATs are single-owner).

## Phase 2: board automation workflow

1. `.github/workflows/pr-project-status.yml`: moves the PR's project item to
   "In Progress" when a PR is drafted and "To Review" on ready-for-review.
   Reads a fine-grained PAT from the `PROJECTS_TOKEN` repo secret, because the
   default `GITHUB_TOKEN` cannot write org or user projects.
2. Document `PROJECTS_TOKEN` creation (owner, Projects read/write permission,
   expiry) in the README. Keep the workflow out of required checks.

## Phase 3: wire it into the repo template

1. README "Project board" section: copy the board with the script, link the
   repo to the project, configure auto-add manually (`copyProjectV2` copies
   workflows except auto-add), create the `PROJECTS_TOKEN` secret.
2. Extend the post-setup checklist and the `apply-to-repo.sh` closing message
   with those steps.

## Phase 4: publish and maintain

1. Push this repo to GitHub and mark it as a template repository.
2. Board changes land in the canonical project first, then in
   `docs/project-board.md` in the same sitting, so doc and board stay in sync.

## Open decisions

- Priority and Effort options: define sets (e.g. P0/P1/P2, S/M/L) or drop the
  fields from the canonical board.
- Whether `pr-project-status.yml` should also move issues (e.g. linked issue to
  In Progress when its PR opens) or stay PR-only.
- Auto-add filter for new copies (e.g. `is:issue,pr` on the linked repo).
