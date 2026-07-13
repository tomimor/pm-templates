# Project board

The canonical board is `https://github.com/users/tomimor/projects/9`
("PM Board Template", private). GitHub has no API to create or edit views, so
that live project is the source of truth. This file is its reviewable record:
when the board changes, update this file in the same sitting.

Replicate it with `scripts/copy-project.sh <target-owner>`, which wraps the
`copyProjectV2` GraphQL mutation (the only API path that carries views across).

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

1. **Auto-add**: project ... menu > Workflows > Auto-add to project. Enable it
   for the linked repo with filter `is:issue,pr`.
2. **Item closed -> Done**: verify the built-in workflow copied; enable if not.
3. Link the repo: repo > Projects tab > add the new project.

## Org prerequisite

Copying into an org fails with a generic server error when organization
projects are disabled there. Check and fix:

```sh
gh api orgs/<org> --jq .has_organization_projects
gh api -X PATCH orgs/<org> -F has_organization_projects=true
```
