# AGENTS.md

This repo is a reusable GitHub project management baseline. If you are an
agent asked to "set up PM automation like github-pm-templates" in a target
repo, follow the runbook below top to bottom. Every step is idempotent, so
re-running after a partial failure is safe.

Because GitHub templates copy every file, some files in this repo describe the
template itself and must be removed from targets. Step 6 is that cleanup; do
not skip it.

## Inputs

Collect these before starting. Ask the user for anything missing.

- `TARGET`: target repo as `<owner>/<repo>` (may exist already or need creating)
- `BOARD_OWNER`: org or user that should own the project board (often the
  target repo's owner). Skip steps 4, 5, and the board lines of step 6 if the
  user does not want a board.

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

Existing repo (run from a clone of this template repo; it also copies the two
reusable scripts):

```sh
scripts/apply-to-repo.sh <path-to-target-checkout>
```

### 2. Adapt per-repo files

In the target checkout, on a branch (do not commit yet; step 6 joins this PR):

- `.github/labeler.yml`: replace the example globs with the target repo's
  layout. Every label referenced must exist (step 3 creates the baseline set).
- `.github/dependabot.yml`: uncomment the package ecosystem(s) matching the
  target's manifests.

### 3. Labels

```sh
scripts/apply-labels.sh TARGET
```

### 4. Project board (optional)

```sh
scripts/copy-project.sh BOARD_OWNER "<board title>"
```

If it fails against an org, org projects are likely disabled; the script
prints the fix. Then things the API cannot do — hand these to the user:

- Enable the auto-add workflow on the new board (UI only; see
  `docs/project-board.md`).
- Link the target repo to the board (repo > Projects tab).

### 5. Board automation (optional, needs a human for the token)

`pr-project-status.yml` moves PR items between Status columns. It no-ops until
both of these exist, so it is safe to ship inert:

```sh
gh variable set PROJECT_URL --repo TARGET --body "<board url from step 4>"
gh secret set PROJECTS_TOKEN --repo TARGET   # value must come from the user
```

Never create or handle the PAT yourself: ask the user to create a
fine-grained PAT with Projects read/write on `BOARD_OWNER` and paste it into
the `gh secret set` prompt themselves.

### 6. Clean template metadata out of the target

Only for repos created via `--template` (apply-to-repo.sh never copies these).
In the target checkout, on the step-2 branch:

```sh
git rm AGENTS.md docs/project-board-plan.md docs/project-board.md \
       scripts/apply-to-repo.sh scripts/copy-project.sh
```

Then replace `README.md` with a stub for the target project (a `# <repo>`
heading and one line is enough; markdownlint expects the file to exist).
Keep `scripts/apply-labels.sh` and `scripts/apply-branch-protection.sh`: they
are generic and useful for re-runs from the target.

Commit steps 2 and 6 together and open a PR. This PR doubles as the first run
of the checks, which step 7 needs.

### 7. Branch protection

Run only after the step-6 PR has made the checks report at least once,
otherwise GitHub rejects unknown contexts:

```sh
scripts/apply-branch-protection.sh TARGET
```

Check names in the script must match the workflow job names. If the user
removed a workflow, remove its check from the script's `CHECKS` list first.

## Verify

- `gh workflow list --repo TARGET` shows the six workflows.
- On the step-6 PR: confirm the PR title check passes, labels apply, and the
  author is auto-assigned.
- Retitle the PR to `Bad Title`; confirm the title check fails; retitle back.
- Confirm the target has no AGENTS.md and its README describes the target.
- If the board is wired: confirm the PR appears on the board and moves to
  "To Review".

## Rules

- All workflow actions stay SHA-pinned. Never repin to a floating tag.
- Automation workflows (labels, assign, project status) never become required
  status checks.
- Step 6's cleanup list is authoritative. When adding a template-metadata file
  to this repo, add it to that list in the same change.
