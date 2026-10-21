# pm-templates

A ready-made GitHub project management setup. Drop it into any repo, new or
existing, and every repo works the same way.

## What you get

- **PR checks:** Conventional Commit titles, Markdown lint, secret scanning.
- **Automation:** PR authors assigned, labels applied from changed paths, PRs
  moved across the board once you add a token.
- **Issue forms** for bugs, features, and tasks, plus a short PR template.
- **A project board** with Backlog, Team, Active PRs, Me, and Milestone views.
- **Scripts** for labels, branch protection, and the board, one command each.

Every action is pinned to a commit SHA, and Dependabot keeps the pins current.

## Use it

```sh
# New repo
gh repo create <owner>/<name> --template tomimor/pm-templates --private --clone

# Existing repo, from a clone of this one
scripts/apply-to-repo.sh ../your-repo
```

Then follow [AGENTS.md](AGENTS.md) from step 2, or let a coding agent run most
of it.

## Design choices

- **Only PR titles are checked,** so branch commits stay free. If you
  squash-merge, set it to default to the PR title so `main` stays conventional.
- **Automation never blocks a merge.** Labeling, assignment, and board moves
  are not required checks.
- **Fork PRs are safe.** `pr-labels` runs on `pull_request_target` but checks
  out nothing, so fork code never runs with write access.

Built for github.com; GitHub Enterprise Server is untested.

## Roadmap

Planned work lives on [the project board](https://github.com/users/tomimor/projects/9),
the same board new repos copy.

## License

MIT-0: copy what you need, no attribution required.
