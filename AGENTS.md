# AGENTS.md

This repo is a reusable GitHub project management baseline. If you are an
agent asked to "set up PM automation like github-pm-templates" in a target
repo, follow the runbook below top to bottom. Every step is idempotent, so
re-running after a partial failure is safe.

## Inputs

Collect these before starting. Ask the user for anything missing.

- `TARGET`: target repo as `<owner>/<repo>` (may exist already or need creating)
- `BOARD_OWNER`: org or user that should own the project board (often the
  target repo's owner). Skip board steps if the user does not want a board.

## Preflight

```sh
gh auth status
gh auth refresh -s project        # only if `project` scope is missing
```

Stop and report if `gh` is unauthenticated or the user lacks admin on `TARGET`.

## Runbook

### 1. Get the payload into the target repo

New repo:

```sh
gh repo create TARGET --template tomimor/github-pm-templates --private --clone
```

Existing repo (from a clone of this template repo):

```sh
scripts/apply-to-repo.sh <path-to-target-checkout>
```

### 2. Adapt per-repo files

- `.github/labeler.yml`: replace the example globs with the target repo's
  layout. Every label referenced must exist (step 3 creates the baseline set).
- `.github/dependabot.yml`: uncomment the package ecosystem(s) matching the
  target's manifests.
- Delete `docs/project-board*.md` from the target if the user skipped the
  board; those files describe this template's board, not the target repo.

Commit these adaptations on a branch and open a PR (repos created from the
template start with the payload already on main; only the adaptations need a
PR).

### 3. Labels

```sh
scripts/apply-labels.sh TARGET
```

### 4. Branch protection

Run only after the first PR has made the checks report at least once,
otherwise GitHub rejects unknown contexts:

```sh
scripts/apply-branch-protection.sh TARGET
```

Check names in the script must match the workflow job names. If the user
removed a workflow, remove its check from the script's `CHECKS` list first.

### 5. Project board (optional)

```sh
scripts/copy-project.sh BOARD_OWNER "<board title>"
```

If it fails against an org, org projects are likely disabled; the script
prints the fix. Then things the API cannot do — hand these to the user:

- Enable the auto-add workflow on the new board (UI only; see
  `docs/project-board.md`).
- Link the target repo to the board (repo > Projects tab).

### 6. Board automation (optional, needs a human for the token)

`pr-project-status.yml` moves PR items between Status columns. It no-ops until
both of these exist, so it is safe to ship inert:

```sh
gh variable set PROJECT_URL --repo TARGET --body "<board url from step 5>"
gh secret set PROJECTS_TOKEN --repo TARGET   # value must come from the user
```

Never create or handle the PAT yourself: ask the user to create a
fine-grained PAT with Projects read/write on `BOARD_OWNER` and paste it into
the `gh secret set` prompt themselves.

## Verify

- `gh workflow list --repo TARGET` shows the five (or six) workflows.
- Open a test PR with title `chore: verify pm baseline`; confirm the PR title
  check passes, labels apply, and the author is auto-assigned.
- Retitle the PR to `Bad Title`; confirm the title check fails; retitle back.
- If the board is wired: confirm the PR appears on the board and moves to
  "To Review".

## Rules

- All workflow actions stay SHA-pinned. Never repin to a floating tag.
- Automation workflows (labels, assign, project status) never become required
  status checks.
- Do not copy this file (AGENTS.md) into target repos; it describes this
  template, not the targets.
