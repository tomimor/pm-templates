# AGENTS.md

This repo is a reusable GitHub project management baseline. If you are an
agent asked to "set up PM automation like github-pm-templates" in a target
repo, follow the runbook below top to bottom. After a partial failure, resume
at the failed step: steps 3, 5, and 7 are idempotent, but re-running step 1
overwrites step-2 adaptations (the script guards against this) and re-running
step 4 would create a duplicate board (the script aborts on a title match).

Two paths run through the runbook:

- **Template-created repos** (step 1, new-repo variant) contain every file of
  this repo, including files that describe the template itself. Step 6 removes
  those; do not skip it.
- **Existing repos** get the payload via `apply-to-repo.sh`, which never
  copies template metadata. Skip step 6's `git rm` and README stub, but still
  do its commit-and-PR part.

## Inputs

Collect these before starting. Ask the user for anything missing.

- `TARGET`: target repo as `<owner>/<repo>` (may exist already or need creating)
- `BOARD_OWNER`: org or user that should own the project board (often the
  target repo's owner). Skip steps 4 and 5 if the user does not want a board;
  step 6's cleanup is unconditional either way.

## Preflight

- `gh` (2.31 or newer) and `jq` must be installed.
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
gh repo create TARGET --template tomimor/github-pm-templates --private --clone
```

The clone lands in `./<repo>` under the current directory. Template generation
is asynchronous; if the clone comes up empty, wait a few seconds and re-clone.
If creation is refused (org policy, template visibility), create the repo
empty instead and use the existing-repo path below. If it fails with "Name
already exists", a previous attempt created it: `gh repo clone TARGET` and
continue; it still counts as template-created for step 6.

Existing repo (run from this template clone; it also copies the two reusable
scripts):

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
- If the target org has issue types enabled (org-level feature; never applies
  to user-owned repos), switch `.github/ISSUE_TEMPLATE/task.yml` from
  `labels: ["task"]` to `type: Task`.

### 3. Labels

```sh
scripts/apply-labels.sh TARGET
```

It overwrites color and description of same-named existing labels. On a repo
with curated labels, run `gh label list --repo TARGET` first and confirm with
the user.

### 4. Project board (optional)

Run from the template clone (`copy-project.sh` is never shipped to targets).
The default source board is private to its owner; other runners must override
`SOURCE_OWNER`/`SOURCE_NUMBER` to a board they can read, or rebuild the views
manually from `docs/project-board.md`:

```sh
scripts/copy-project.sh BOARD_OWNER "<board title>"
```

If it fails against an org, org projects are likely disabled; the script
prints the fix, but changing org settings needs the user's explicit OK first.
Then three things the API cannot do — hand these to the user:

- Enable the auto-add workflow on the new board (UI only; see
  `docs/project-board.md`).
- Verify the built-in "Item closed -> Done" workflow copied over; enable it
  if not.
- Link the target repo to the board (repo > Projects tab).

### 5. Board automation (optional, needs a human for the token)

`pr-project-status.yml` moves PR items between Status columns. It no-ops until
both of these exist, so it is safe to ship inert:

```sh
gh variable set PROJECT_URL --repo TARGET --body "<board url from step 4>"
gh secret set PROJECTS_TOKEN --repo TARGET   # value must come from the user
```

Never create or handle the PAT yourself: ask the user to create a
fine-grained PAT (Projects read/write on `BOARD_OWNER`, plus Pull requests
read on the target repo) and paste it into the `gh secret set` prompt
themselves.

### 6. Clean template metadata, commit, open the PR

Template-created repos only (apply-to-repo.sh never copies these):

```sh
git rm --ignore-unmatch AGENTS.md docs/project-board.md \
       scripts/apply-to-repo.sh scripts/copy-project.sh
```

Then replace `README.md` with a stub for the target project (a `# <repo>`
heading and one line is enough; markdownlint expects the file to exist).
Keep `scripts/apply-labels.sh` and `scripts/apply-branch-protection.sh`: they
are generic and useful for re-runs from the target.

Both paths: commit the step-2 (and step-6) changes and open a PR. This PR
doubles as the first run of the checks, which step 7 needs.

### 7. Branch protection

Wait until the PR's checks have reported, then prefer merging the PR before
running this (protection's 1-approval rule applies to open PRs immediately,
and a solo maintainer would need admin bypass to merge):

```sh
scripts/apply-branch-protection.sh TARGET
```

Check names in the script must match the workflow job names. If the user
removed a workflow, remove its check from the script's `CHECKS` list first.
Note: branch protection on private repos requires a paid plan; on a free plan
the API returns 403, report that to the user instead of retrying.

## Verify

On the step-6 PR (before or after merge):

- The PR title check passes and the author is auto-assigned.
- Retitle the PR to `Bad Title`; confirm the title check fails; retitle back.
- If the board is wired: the PR appears on the board and moves to "To Review".

Template-created repos only:

- `gh workflow list --repo TARGET` shows the six workflows (pr-title,
  pr-labels, auto-author-assign, markdownlint, secret-scan,
  pr-project-status).
- The target has no AGENTS.md and its README describes the target.

Existing repos: `gh workflow list` and the path-based labels only work after
the PR merges, because `pull_request_target` workflows run from the default
branch. Verify those two after merge, and never flag a pre-existing AGENTS.md
in the target as template metadata.

## Rules

- All workflow actions stay SHA-pinned. Never repin to a floating tag.
- Automation workflows (labels, assign, project status) never become required
  status checks.
- Step 6's cleanup list is authoritative. When adding a template-metadata file
  to this repo, add it to that list in the same change.
- After changing this repo, push main: the pushed state is the template.
