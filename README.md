# github-pm-templates

Reusable GitHub project management baseline: workflows, issue and PR templates,
and setup scripts, extracted from a working repo so any new or existing repo can
adopt the same conventions in minutes.

## What's included

### Workflows (`.github/workflows/`)

| Workflow | What it does |
| --- | --- |
| `pr-title.yml` | Validates the PR title as a Conventional Commit (the squash-merge subject). Title is passed via env, never interpolated, so a crafted title cannot inject shell. |
| `auto-author-assign.yml` | Assigns the PR author as assignee on open/reopen. |
| `pr-labels.yml` | Applies labels from changed paths using `actions/labeler` and `.github/labeler.yml`. |
| `markdownlint.yml` | Lints Markdown on PRs. Rules and scope live in `.markdownlint-cli2.jsonc` so CI and local runs match. |
| `secret-scan.yml` | TruffleHog scan on PRs and pushes to main. Fails on verified findings. |

All actions are SHA-pinned and `dependabot.yml` keeps the pins current.

### Templates

- `PULL_REQUEST_TEMPLATE.md`: What / Why / Relates to / Evidence, with optional
  Notes and env-checklist sections.
- `ISSUE_TEMPLATE/`: Bug, Feature, and Task forms, plus blank issues enabled.

### Scripts (`scripts/`)

- `apply-to-repo.sh <path>`: copies the payload into an existing checkout.
- `apply-labels.sh <owner>/<repo>`: creates the baseline label set.
- `apply-branch-protection.sh <owner>/<repo> [branch]`: PR required, 1 approval,
  linear history, conversation resolution, required status checks.

## How to use it

### New repo

Mark this repo as a template on GitHub (Settings, then "Template repository"),
then create new repos from it:

```sh
gh repo create <owner>/<name> --template <owner>/github-pm-templates --private --clone
```

### Existing repo

```sh
scripts/apply-to-repo.sh ../some-repo
```

Then follow the checklist the script prints.

### Post-setup checklist

1. Adapt `.github/labeler.yml` globs to the repo layout, and check every label
   it references exists (`scripts/apply-labels.sh` covers the baseline set).
2. Uncomment the matching package ecosystem in `.github/dependabot.yml`.
3. Run `scripts/apply-labels.sh <owner>/<repo>`.
4. Open a first PR so the checks report at least once, then run
   `scripts/apply-branch-protection.sh <owner>/<repo>`. Required check names in
   the script must match the workflow job names exactly.
5. If the org uses GitHub issue types, switch `ISSUE_TEMPLATE/task.yml` from
   `labels:` to `type: Task`.

## Design notes

- Conventional Commits are enforced on the PR title only. With squash merges,
  the title becomes the commit subject on main, so individual branch commits
  stay unconstrained.
- Required checks deliberately exclude `auto-author-assign` and `pr-labels`:
  they are automation, and a flake there should never block a merge.
- `pr-labels.yml` runs on `pull_request_target` so it can label PRs from forks;
  it checks out nothing, so untrusted code never executes with write perms.
- Branch protection lives in a script instead of clicking through settings, so
  it is reviewable, repeatable, and portable across orgs.
