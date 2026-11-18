---
name: gh-sync
description: >-
  Syncs the active plan (Plan mode) to GitHub
  issues with the gh CLI: create or reuse a tracking issue, proposed-PR
  sub-issues, follow-up issues, and GitHub blocked-by / blocking / parent
  relations. Use in Plan mode, when this skill is invoked directly, or when the
  user asks to sync a plan to GitHub, create issues from a plan, create
  sub-issues, proposed PRs, a PR plan, follow-ups, issue relations, blocked-by,
  blocking, or to update existing issues with new decisions from the plan.
---

# Sync plans to GitHub

Announce at start: "I'm using gh-sync to sync the plan with GitHub."

Use GitHub CLI only. Do not use GitHub MCP, REST clients, or a browser.

The plan is the source of truth. New decisions, scope, and relations in the plan must land on the GitHub issues (tracking issue, PR sub-issues, and follow-ups) when generated content differs. Markdown in the issue body is not enough for blocking.

If the tracking issue does not exist, create it. Before the plan is done, create proposed PRs in the PR plan as sub-issues of the tracking issue. Create follow-up issues when they do not exist.

1. Read the active plan
2. Find or create tracking issue
3. PR sub-issues if plan is not done
4. Follow-up issues
5. Update bodies and GitHub relations
6. Write issue links back into the plan

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| GitHub CLI (`gh`), authenticated | everything | `gh auth status` succeeds |
| A repo `gh` can resolve | the tracking issue, sub-issues, follow-ups | `gh repo view --json nameWithOwner,url,defaultBranchRef` succeeds. Work against that repo; do not hardcode owner/name |
| Triage access or higher | editing issues and relations | `gh repo view --json viewerPermission` is `TRIAGE`, `WRITE`, `MAINTAIN` or `ADMIN` |
| gh 2.94+ with `--parent` | PR sub-issues | `gh issue create --help` shows `--parent` |
| An active plan | the source of truth | see "Which plan to use" |

**Hard gate.** Run the checks before step 1. If any fails, stop, tell the user which requirement is missing and how to fix it. Do not continue, do not substitute another tool (GitHub MCP, REST clients, a browser), and do not fall back to "Blocked by" for PR items when `--parent` is missing.

## Issue relations

**Required** after every create, every reuse of an existing issue, and every re-sync. Do not skip because the issue "already exists", because the body has "Blocked by", or because the user asked to sync quickly.

```bash
gh issue edit <issue-number> --add-blocked-by <blocking-number>
gh issue edit <issue-number> --add-blocking <blocked-number>
gh issue edit <issue-number> --remove-blocked-by <number>
gh issue edit <issue-number> --remove-blocking <number>
```

On create, pass `--blocked-by` / `--blocking` when the relation is already known. Otherwise `edit` immediately after create. PR sub-issues: never these flags — `--parent` only.

Read current relations before changing them:

```bash
gh issue view N --json number,title,url,state,body,blockedBy,blocking,parent
```

`blockedBy` and `blocking` are `{ "nodes": [...], "totalCount": N }`. Use `nodes[].number`. Idempotent: do not add a number already in `nodes`.

| Situation | Action |
| --- | --- |
| Follow-up vs tracking issue | Follow-up `--add-blocked-by TRACKING` (or `--blocked-by TRACKING` on create) |
| Plan says "Blocked by #N" | `--add-blocked-by N` |
| Plan says "blocks #N" | `--add-blocking N` |
| Plan had "Blocked by" / "Blocks" for this issue, and `#N` was removed | `--remove-blocked-by` / `--remove-blocking` for that number |
| PR sub-issue | `--parent` / `--add-sub-issue` only. Never blocked-by between PRs |
| "Related #N" with no blocking | Body only, not GitHub blocking |

Also put `## Blocked by` and `## Related` in the body when those links exist, so the issue is readable without the UI. Markdown does not replace `gh`.

Remove only numbers the plan itself controlled (listed under Blocked by / Blocks and now gone). Do not remove GitHub relations the plan never mentioned.

## Which plan to use

Read **the plan that is active now** — in Plan mode. That is the source. Do not fetch a plan from another agent workflow on your own.

Priority:

1. The plan in this conversation (the Plan mode document being written or shown).
2. The matching file under `~/.cursor/plans/*.plan.md`: match YAML `name`, first `#` title, or the open editor file. Do not pick "newest file" across all projects.
3. A file the user points to.

If the plan content only exists in the conversation: sync it, and write links back into the plan document. Update `.plan.md` when the file is known.

Do not use other plan directories unless the user explicitly points there.

Read the whole plan before syncing.

## Parse

Cursor plans have YAML frontmatter (`name`, `overview`, `todos`) and a markdown body. Extract:

| Field | Source |
| --- | --- |
| Title | YAML `name`, else first `#` |
| Goal | YAML `overview`, else `## Goal`, `## In brief`, `## Kort forklart` |
| Tracking | `**Tracking:**`, `Tracking: [#N]`, or `#N` near the top |
| Decisions | `## Decisions`, `## Beslutninger`, `Beslutninger (låst)`, "Decisions and assumptions" |
| Scope | YAML `todos` and sections for this delivery / PR |
| PR plan | `## PR plan`, `## PR-plan`, `PR stack`, `PR-stack`, `PR split`, `PRs` |
| Follow-up | `## Follow-up`, `## Oppfølging`, `## GitHub issues`, `## GitHub-saker` |
| Out of scope | "Not in this delivery", "Out of this PR", `## Out of scope`, `## Utenfor omfang`, "later" |
| Blocked by | `**Blocked by:**`, `## Blocked by`, `**Blokkert av:**`, "blocked by #N" |
| Blocks | `**Blocks:**`, `**Blokkerer:**`, "blocks #N" |
| Related | `**Related:**`, `**Relatert:**`, other `#N` links that are not tracking / PR / follow-up / blocking |

`## PR description` / `PR descriptions` / `## PR-beskrivelse` is a template, not the PR plan.

Write GitHub titles, bodies, and the user report in the same language as the plan. Keep existing plan headings when writing links back. Canonical English section names in the templates below; use the plan's equivalent headings when the plan is not English.

## Find or create the tracking issue

If the issue does not exist, create it.

1. Plan has `**Tracking:** #N` or `Tracking: #N` → `gh issue view N --json number,title,url,state,body,blockedBy,blocking,parent`
2. If view fails, or tracking is missing → search:

```bash
gh issue list --state all --limit 20 --search "in:title TITLE" --json number,title,url,state
```

1. Match: exact title, else a unique near-match. If several matches: ask the user. Then `gh issue view` with the JSON fields above.
2. No match: create. Include `--blocked-by` / `--blocking` when the plan has those relations.

```bash
gh issue create --title "TITLE" --body "$(cat <<'EOF'
BODY
EOF
)"
```

Tracking issue body:

```markdown
## Goal

[overview / Goal]

## Decisions

[from ## Decisions in the plan, if present]

## Related

- #N (short label)

## Scope

[todos and in-scope sections]

## Out of scope

[Follow-up candidates, no issue number yet]

## Blocked by

- #N (short label)
```

Omit empty sections. After create/reuse: run [Update body and relations](#update-body-and-relations).

## Update body and relations

Applies to the tracking issue, each PR sub-issue, and each follow-up. The plan is the source of truth.

"Do not overwrite the body" does **not** apply when generated content differs from the issue. The user does not need to ask for an update. "Sync quickly" and "the issue exists" are not exceptions. Do not comment on the issue instead of updating the body.

1. Generate the body from the plan for **this** issue (tracking = the whole delivery; PR = that PR item; follow-up = that follow-up item). Include new decisions, scope, and relation text.
2. Fetch `body`, `blockedBy`, `blocking` (and `parent` for sub-issues).
3. If trimmed generated body ≠ trimmed `body` → `gh issue edit N --body "$(cat <<'EOF' … EOF)"`.
4. Set GitHub relations from the table in [Issue relations](#issue-relations).

Do not change the title unless the user asks.

## Proposed PRs as sub-issues

Run this **after** the tracking issue exists, **before** follow-up issues.

**Create new PR sub-issues** only when the plan is not done: at least one YAML todo is `pending` or `in_progress`, **and** at least one PR item lacks `#N`.

**Do not create new ones** when every YAML todo is `completed`, **or** every PR item already has `#N`. Reuse already linked `#N` (`gh issue view` with body/relation fields). Then [Update body and relations](#update-body-and-relations) for each PR item (body from that item; never blocked-by between PRs).

**No PR section** (headings above) → skip this part. Do not invent PRs from todos.

PR items: children in the PR section such as `### PR A`, `## PR 1`, `**PR 1 — …**`. One item per unique identity (`PR A`, `PR 1`, …). Use the first match. Skip repeats under `PR description`.

For each item without `#N`:

1. Search `gh issue list --state all --search "in:title …"`
2. Match: reuse it; attach to the tracking issue if it is not already a sub-issue:

```bash
gh issue edit TRACKING --add-sub-issue N
```

1. No match → create as a sub-issue (`--parent` only, no `--blocked-by` / `--blocking`):

```bash
gh issue create --title "TITLE" --parent TRACKING --body "$(cat <<'EOF'
BODY
EOF
)"
```

Title: short, with the PR identity (for example `PR A: Shared JWT + config`), same language and style as existing issues.

Body:

```markdown
## Goal

[1–3 sentences from that PR item]

## Decisions

[decisions that apply to this PR item, if any]

## Scope

[bullets from that PR item]
```

Write the `#N` link into the **same** heading or `**PR …**` line in the PR plan, for example `### PR A — … ([#101](url))`. Not YAML todos. Not a mirror table.

After create/reuse: [Update body and relations](#update-body-and-relations).

## Follow-up issues

Also create follow-up issues if they do not exist. These are **not** sub-issues.

Candidates, in this order:

1. Every item under `## Follow-up` / `## Oppfølging` / `## GitHub issues` / `## GitHub-saker` that should be created
2. Items marked out of scope / later

**Do not create** when the item only points at an existing issue that already owns the work (for example "Member UI (#73)"). Do not create follow-ups for PR items that are already sub-issues.

**Create** when the item describes new work outside this plan, even if it is related to another issue.

For each candidate:

1. Item has `#N` → `gh issue view N` with body/relation fields (reuse; do not duplicate)
2. Else search the proposed title (`gh issue list --state all --search "in:title ..."`)
3. No match → create with `--blocked-by TRACKING` (not `--parent`)

```bash
gh issue create --title "TITLE" --blocked-by TRACKING --body "$(cat <<'EOF'
BODY
EOF
)"
```

Follow-up body (markdown **and** GitHub relation):

```markdown
## Goal

[What remains, 1–3 sentences]

## Decisions

[from the item / relevant decisions, if any]

## Related

- #N (short label)

## Blocked by

- #TRACKING (tracking issue title)

## Out of scope

- Work owned by the tracking issue or other issues
```

Include `## Related` when the item depends on another issue in addition to the tracking issue. If that dependency is blocking, also run `--add-blocked-by` / `--add-blocking`.

Title: short, concrete, same language and style as existing issues. Do not copy raw bullet text if it is cryptic.

After create/reuse: [Update body and relations](#update-body-and-relations). Existing follow-ups missing `blockedBy` toward the tracking issue must get `--add-blocked-by TRACKING`.

## Write back into the plan

After every issue is resolved, update **only** tracking, PR-plan links, and follow-ups. Keep YAML frontmatter. Do not rewrite decisions or other plan prose, and do not paste a foreign agent header unless it is already there.

Right after the title (or `## Goal` / `## In brief` / `## Kort forklart` if that section is at the top):

```markdown
**Tracking:** [#N](https://github.com/OWNER/REPO/issues/N).
```

PR plan: `#N` on each PR item as above. Do not touch other text in the section.

If the plan already has a follow-up / GitHub-issues section: fill in the real numbers there. Otherwise create `## Follow-up` (typically before QA), or `## Oppfølging` when the plan already uses Norwegian headings:

```markdown
## Follow-up

- [#A](https://github.com/OWNER/REPO/issues/A) short label
- [#B](https://github.com/OWNER/REPO/issues/B) short label
```

If `todos` has a GitHub-sync task: set `status: completed` when issues are created/linked.

Use URLs from `gh` (`url` field), not a hardcoded host. Preserve the plan's language, including letters such as æ, ø, and å.

## Idempotency

A new run must not create duplicates. Reuse already linked issues. Do not comment on issues. Do not close issues. Body / `gh issue edit --body` only when content differs. Relation flags only for numbers that are missing or should be removed.

## Report to the user

Short, in the conversation language:

- Plan (conversation / `~/.cursor/plans/…`)
- Tracking issue: existed / created + link
- PR sub-issues: existed / created / skipped (no PR section, todos completed, or already `#N`) + links
- Follow-up: existed / created / skipped (with reason) + links
- Body updated: which `#N` (or none)
- Relations: which `--add-blocked-by` / `--add-blocking` / remove ran (or none)
- What was written back into the plan

## Common mistakes

| Excuse | Rule |
| --- | --- |
| "Markdown Blocked by is enough" | GitHub relation via `gh` is required as well |
| "The issue exists, do not rewrite the body" | Update the body when generated content differs |
| "The user said sync quickly / don't waste time" | Relations and decision drift are part of the sync |
| "B waits on A, set blocked-by on the PR" | PR sub-issues: `--parent` only |
| "Leave a comment with the new decisions" | Update the body. Do not comment |

## Examples

See [examples.md](examples.md).
