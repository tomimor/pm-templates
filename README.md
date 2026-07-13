# github-pm-templates

Reusable GitHub project management baseline: workflows, issue and PR templates,
a replicable project board, and setup scripts, extracted from a working repo so
any new or existing repo can adopt the same conventions in minutes.

**Agents start at [AGENTS.md](AGENTS.md)**: it is the step-by-step runbook for
replicating this setup in a target repo.

## What's included

### Workflows (`.github/workflows/`)

| Workflow | What it does |
| --- | --- |
| `pr-title.yml` | Validates the PR title as a Conventional Commit (the squash-merge subject). Title is passed via env, never interpolated, so a crafted title cannot inject shell. |
| `auto-author-assign.yml` | Assigns the PR author as assignee on open/reopen. |
| `pr-labels.yml` | Applies labels from changed paths using `actions/labeler` and `.github/labeler.yml`. |
| `markdownlint.yml` | Lints Markdown on PRs. Rules and scope live in `.markdownlint-cli2.jsonc` so CI and local runs match. |
| `secret-scan.yml` | TruffleHog scan on PRs and pushes to main. Fails on verified findings. |
| `pr-project-status.yml` | Moves the PR's project-board item (draft to "In Progress", ready to "To Review"). Inert until `PROJECT_URL` (repo variable) and `PROJECTS_TOKEN` (secret) are set. |

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
- `copy-project.sh <target-owner> [title]`: replicates the canonical project
  board (views, fields) to an org or user via `copyProjectV2`.

### Project board

The board (views, Status field, workflows) lives as a live GitHub Project, at
`https://github.com/users/tomimor/projects/9`, because views have no
create/update API. `docs/project-board.md` is its reviewable snapshot and lists
the manual follow-ups (auto-add, repo link) each copy needs.

## How to use it

### New repo

This repo is marked as a template repository on GitHub; create new repos from
it:

```sh
gh repo create <owner>/<name> --template <owner>/github-pm-templates --private --clone
```

The template must be readable by whoever runs this. While it stays private and
personal, that means the owner only; for teammates, make it public, move it
into their org, or have them use the existing-repo path.

### Existing repo

```sh
scripts/apply-to-repo.sh ../some-repo
```

Then follow the checklist the script prints.

### Post-setup checklist

The full ordered version lives in [AGENTS.md](AGENTS.md); the short form:

1. Adapt `.github/labeler.yml` globs to the repo layout, and check every label
   it references exists (`scripts/apply-labels.sh` covers the baseline set).
2. Uncomment the matching package ecosystem in `.github/dependabot.yml`.
3. Run `scripts/apply-labels.sh <owner>/<repo>`.
4. Template-created repos only: remove the template metadata (AGENTS.md,
   `docs/project-board*.md`, `scripts/apply-to-repo.sh`,
   `scripts/copy-project.sh`) and replace this README with the target's own.
5. Open a first PR so the checks report at least once, then run
   `scripts/apply-branch-protection.sh <owner>/<repo>`. Required check names in
   the script must match the workflow job names exactly.
6. If the org uses GitHub issue types, switch `ISSUE_TEMPLATE/task.yml` from
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
- Everything targets github.com; GHES is untested (the status workflow's URL
  parsing, for one, assumes github.com).
