# pm-templates

A GitHub template that gives a repo a project management baseline: PR checks,
issue and PR forms, labels, branch protection (paid plan for private repos),
and a project board with views and automation. Create a new repo from it, or apply it
to an existing one.

**Start at [AGENTS.md](AGENTS.md)**: the step-by-step setup runbook for people
and coding agents.

## The board

Board #9
([`users/tomimor/projects/9`](https://github.com/users/tomimor/projects/9),
private) is the GitHub Project that `scripts/copy-project.sh` copies to new
owners. It also tracks this repo's own roadmap, so it shows real work:
features as parent issues, tasks as sub-issues, milestones as releases.
Copies get the views and fields, never the issues or PRs.
[docs/project-board.md](docs/project-board.md) lists the views, fields, and
manual steps each copy needs.

## What's included

### Workflows (`.github/workflows/`)

| Workflow | What it does |
| --- | --- |
| `pr-title.yml` | Validates the PR title as a Conventional Commit. Title is passed via env, never interpolated, so a crafted title cannot inject shell. |
| `auto-author-assign.yml` | Assigns the PR author as assignee on open/reopen. |
| `pr-labels.yml` | Applies labels from changed paths using `actions/labeler` and `.github/labeler.yml`. |
| `markdownlint.yml` | Lints Markdown on PRs. Rules and scope live in `.markdownlint-cli2.jsonc` so CI and local runs match. |
| `secret-scan.yml` | TruffleHog scan on PRs and pushes to main. Fails on verified or unverifiable findings. |
| `pr-project-status.yml` | Moves the PR's board item (draft to "In Progress", ready to "To Review"). Inert until `PROJECT_URL` (repo variable) and `PROJECTS_TOKEN` (secret) are set. |

All actions are SHA-pinned, and `dependabot.yml` keeps the pins current.

### Templates

- `PULL_REQUEST_TEMPLATE.md`: What / Why / Relates to / Evidence, with optional
  Notes and env-checklist sections.
- `ISSUE_TEMPLATE/`: Bug, Feature, and Task forms, plus blank issues.

### Scripts (`scripts/`)

- `apply-to-repo.sh <path>`: copies `.github/`, `.markdownlint-cli2.jsonc`, and
  the label and branch-protection scripts into an existing checkout.
- `apply-labels.sh <owner>/<repo>`: creates the baseline label set.
- `apply-branch-protection.sh <owner>/<repo> [branch]`: PR required, 1 approval,
  linear history, conversation resolution, required status checks.
- `copy-project.sh <target-owner> [title]`: copies the board (views, fields) to
  an org or user.

## How to use it

```sh
# New repo
gh repo create <owner>/<name> --template tomimor/pm-templates --private --clone
# Existing repo, from a clone of this one
scripts/apply-to-repo.sh ../some-repo
```

Then follow [AGENTS.md](AGENTS.md) from step 2. The template must be readable
by whoever runs `gh repo create`. While it stays private, only the owner and invited
collaborators can use it, by either path.

## Design notes

- Conventional Commits are enforced on the PR title only, so branch commits stay
  unconstrained. The title becomes the subject on `main` only if squash is the
  sole merge method and its default title is the PR title; GitHub's default uses
  the commit title for single-commit PRs.
- Required checks deliberately exclude `auto-author-assign` and `pr-labels`:
  they are automation, and a flake there should never block a merge.
- `pr-labels.yml` runs on `pull_request_target` so it can label PRs from forks;
  it checks out nothing, so untrusted code never executes with write permissions.
- Branch protection lives in a script instead of clicking through settings, so
  it is reviewable, repeatable, and portable across orgs.
- Everything targets github.com; GHES is untested (the status workflow's URL
  parsing, for one, assumes github.com).

## Working on this repo

Work is tracked on board #9. Every change lands through a PR that closes
an issue there, and the merged `main` is the template.
