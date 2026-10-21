# AGENTS.md

This repo is a reusable GitHub project management baseline. If you are an
agent asked to "set up PM automation like pm-templates" in a target
repo, follow the runbook below top to bottom. After a partial failure, resume
at the failed step: steps 3, 5, and 7 are idempotent, but re-running step 1
overwrites step-2 adaptations (the script guards against this) and re-running
step 4 would create a duplicate board (the script aborts on a title match).

Two paths run through the runbook:

- **Template-created repos** (step 1, new-repo variant) contain every file of
  this repo, including files that describe the template itself. Step 6 removes
  those; do not skip it.
- **Existing repos** get the payload (`.github/`, `.markdownlint-cli2.jsonc`,
  and the two generic scripts) via `apply-to-repo.sh`, which never copies
  template metadata. Skip step 6's `git rm` and README stub, but still
  do its commit-and-PR part.

## Inputs

Collect these before starting. Ask the user for anything missing.

- `TARGET`: target repo as `<owner>/<repo>` (may exist already or need creating)
- `BOARD_OWNER`: org or user that should own the project board (often the
  target repo's owner). Skip steps 4 and 5 if the user does not want a board;
  step 6 still applies.
- `BOARD_TITLE`: the new board's title.

## Preflight

- `gh` (2.45 or newer) and `jq` must be installed.
- `gh auth status` must show a logged-in user whose token has the `project`
  scope. If the scope is missing, ask the user to run
  `gh auth refresh -s project` themselves (it is an interactive browser flow).
- For an existing `TARGET`, confirm admin:
  `gh api repos/TARGET --jq .permissions.admin` must print `true`.
- Run from a clone of this template repo, and confirm `git status -sb` shows
  no `ahead` commits: GitHub copies the *pushed* main, so unpushed work here
  silently produces stale targets.

## Runbook

### 1. Get the payload into the target repo

New repo:

```sh
gh repo create TARGET --template tomimor/pm-templates --private --clone
```

The clone lands in `./<repo>`. Template generation
is asynchronous; if the clone comes up empty, wait a few seconds and re-clone.
If creation is refused (org policy, template visibility), run
`gh repo create TARGET --private --add-readme --clone` instead (a PR needs an
existing `main`) and use the existing-repo path below. If the template command
fails with "Name already exists", run `gh repo clone TARGET`. If the clone has
`scripts/copy-project.sh`, treat it as template-created; otherwise use the
existing-repo path.

Existing repo (run from the template clone):

```sh
scripts/apply-to-repo.sh <path-to-target-checkout>
```

### 2. Adapt per-repo files

In the target checkout, on a branch (do not commit yet; step 6 finishes this
PR):

- `.github/labeler.yml`: replace the example globs with the target repo's
  layout. Every label referenced must exist (step 3 creates the baseline set).
- `.github/dependabot.yml`: uncomment the package ecosystem(s) matching the
  target's manifests.
- If the target is org-owned and
  `gh api orgs/<org>/issue-types --jq '.[].name'` lists `Task`, switch
  `.github/ISSUE_TEMPLATE/task.yml` from `labels: ["task"]` to `type: Task`.

### 3. Labels

```sh
scripts/apply-labels.sh TARGET
```

It overwrites color and description of same-named existing labels. On a repo
with curated labels, run `gh label list --repo TARGET` first and confirm with
the user.

### 4. Project board (optional)

Run from the template clone. The default source is board #9, private to its
owner; others must set env vars
`SOURCE_OWNER`/`SOURCE_NUMBER` to a board they can read, or rebuild the views
manually from `docs/project-board.md`:

```sh
scripts/copy-project.sh BOARD_OWNER "BOARD_TITLE"
```

If it fails against an org, org projects are likely disabled; the script
prints the fix, but changing org settings needs the user's explicit OK first.
If `BOARD_OWNER` also owns `TARGET`, link the board to the repo (the number is
the last segment of the URL the script prints). GitHub only links boards and
repos with the same owner; otherwise the user links it in the UI.

```sh
gh project link <board-number> --owner BOARD_OWNER --repo TARGET
```

Then hand the user the remaining steps under "Manual steps after copying" in
`docs/project-board.md`.

### 5. Board automation (optional, needs the user for the token)

`pr-project-status.yml` moves PR items between Status columns. It no-ops until
both of these exist:

```sh
gh variable set PROJECT_URL --repo TARGET --body "<board url from step 4>"
gh secret set PROJECTS_TOKEN --repo TARGET   # the user runs this line
```

Never create or handle the token yourself: the user creates it and runs the
`gh secret set` line in their own terminal. Org `BOARD_OWNER`: a fine-grained
PAT whose resource owner is that org, with Projects read/write and Pull
requests read on `TARGET` (same org); an org owner may have to approve it.
User `BOARD_OWNER`: a classic PAT with `project` and `repo` scopes, because
GitHub's docs say fine-grained PATs cannot access user-owned projects.

### 6. Clean template metadata, commit, open the PR

Template-created repos only:

```sh
git rm --ignore-unmatch AGENTS.md LICENSE docs/project-board.md \
       scripts/apply-to-repo.sh scripts/copy-project.sh
```

Then replace `README.md` with a stub for the target project (a `# <repo>`
heading and one line is enough). The two generic scripts stay for re-runs.

Both paths: commit the step-2 (and step-6) changes and open a PR titled
`chore: add PM automation`. This PR doubles as the first run of the checks,
which step 7 needs.

### 7. Branch protection

Once the PR's checks have reported and the PR checks under Verify pass, ask
the user to merge it before running this (protection's 1-approval rule applies
to open PRs immediately, and a solo maintainer would need admin bypass to
merge):

```sh
scripts/apply-branch-protection.sh TARGET
```

Check names in the script must match the workflow job names. If the user
removed a workflow, remove its check from the script's `CHECKS` list first.
Branch protection on private repos needs a paid plan. On a free plan the API
returns 403: report that to the user instead of retrying.

## Verify

On the step-6 PR, before step 7's merge:

- The PR title check passes and the author is auto-assigned.
- Retitle the PR to `Bad Title`; confirm the title check fails; retitle back.
- If step 5 was done: the PR appears on the board and moves to "To Review".

Template-created repos only:

- `gh workflow list --repo TARGET` shows the six workflows (PR Title, PR
  Labels, Auto Author Assign, Markdown Lint, Secret Scan, PR Project Status).
- The target has no AGENTS.md and its README describes the target.

Existing repos: `gh workflow list` and the path-based labels only work after
the PR merges, because `pull_request_target` workflows run from the default
branch. Verify those two after merge (labels on the next PR), and never
flag a pre-existing AGENTS.md in the target as template metadata.

## Rules

- All workflow actions stay SHA-pinned. Never repin to a floating tag.
- Automation workflows (labels, assign, project status) never become required
  status checks.
- Step 6's cleanup list is authoritative. When adding a template-metadata file
  to this repo, add it to that list in the same change.
- Changes to this repo land on `main` through a PR that closes an issue on
  board #9 (Dependabot PRs are exempt). The merged `main` is the template.
