# Project board

Board #9 (`https://github.com/users/tomimor/projects/9`, "PM Board Template",
private) is the source of truth. This file is its reviewable record: when the
board changes, update this file in the same PR.

The board also tracks this repo's roadmap. Copies never include its issues or
PRs, and the board's README and short description are written to stay true in a
copy.

Copy it with `scripts/copy-project.sh <target-owner>`, which wraps the
`copyProjectV2` GraphQL mutation to copy views, fields, and workflows in one
call.

## Views

| View | Layout | Filter | Group by | Sort by |
| --- | --- | --- | --- | --- |
| Backlog | Table | `-status:Done is:issue` | Parent issue | Status desc |
| Team | Board | `is:issue` | Milestone | Priority asc |
| Active PRs | Table | `is:pr -status:Done` | | Status desc, Updated desc |
| Me | Table | `assignee:@me` | | Status asc |
| Milestone | Table | `is:issue` | Milestone | |

## Custom fields

| Field | Type | Options |
| --- | --- | --- |
| Status | Single select | Design, Todo, In Progress, To Review, Done |
| Priority | Single select | Urgent, High, Medium, Low |
| Effort | Single select | High, Medium, Low |

## Manual steps after copying

`copyProjectV2` carries views, fields, and built-in workflows except auto-add.
On each new copy:

1. Link the repo, if AGENTS.md step 4 couldn't: repo > Projects tab > add the
   new project.
2. **Auto-add**: the project's `...` menu > Workflows > Auto-add to project. Enable it
   for the linked repo with filter `is:issue,pr`.
3. **Item closed -> Done**: verify the built-in workflow copied; enable if not.

## Org prerequisite

Copying into an org fails with a generic server error when organization
projects are disabled there. Check and fix (the fix needs an org owner's token
with the `admin:org` scope; ask the user first):

```sh
gh api orgs/<org> --jq .has_organization_projects
gh api -X PATCH orgs/<org> -F has_organization_projects=true
```
