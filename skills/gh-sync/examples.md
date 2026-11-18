# Examples

## Plan mode with no tracking

Active `.plan.md` in the conversation:

```markdown
---
name: Report export
overview: Users can export reports as CSV; PDF export and scheduled exports come later.
todos:
  - id: github-followups
    content: Create GitHub issues for the delivery and out of scope
    status: pending
isProject: false
---

# Report export

## Goal

…

## Decisions

- **Not in this delivery:** export settings UI ([#73](https://github.com/OWNER/REPO/issues/73)), PDF export, scheduled exports.
```

Actions:

1. Use this plan (do not search other plan directories).
2. `gh issue list --state all --search "in:title Report export"` → no match
3. `gh issue create` for the tracking issue (body includes `## Decisions`)
4. Skip "Export settings UI (#73)" — that issue already owns the work
5. `gh issue create --title "…" --blocked-by 78` for PDF export and scheduled exports
6. Follow-up body has `## Blocked by` with `#78`. If create did not get `--blocked-by`: `gh issue edit 79 --add-blocked-by 78`

Write back into the same plan file:

```markdown
# Report export

**Tracking:** [#78](https://github.com/OWNER/REPO/issues/78).

## Follow-up

- [#79](https://github.com/OWNER/REPO/issues/79) PDF export
- [#80](https://github.com/OWNER/REPO/issues/80) scheduled exports
```

Set `github-followups` to `status: completed`. No PR sub-issues — the plan has no PR section.

## Before the plan is done, with a PR plan

Todos `pending`. Section `## PR stack` with `### PR A` and `### PR B` without `#N`. Tracking issue `#69` exists.

1. `gh issue create --help` shows `--parent`
2. `gh issue create --title "PR A: …" --parent 69` → `#101`
3. `gh issue create --title "PR B: …" --parent 69` → `#102`
4. No `--blocked-by` between A and B, even if B "waits on" A
5. No follow-up for PR A/B (they are sub-issues)
6. `gh issue view 69 --json body,blockedBy,blocking` — update tracking issue body only when it differs

Write back into the PR plan:

```markdown
### PR A — Export service + config ([#101](https://github.com/OWNER/REPO/issues/101))

### PR B — CSV download endpoint ([#102](https://github.com/OWNER/REPO/issues/102))
```

## Skip PR sub-issues

- Every YAML todo is `completed` → no new PR sub-issues, even if the PR plan lacks `#N`.
- Every PR item already has `#N` → `gh issue view`, no `create`. Still run the body/relation check per item.
- No `PR plan` / `PR stack` / `PRs` → skip. `## PR description` does not count.

## Plan already synced, unchanged

`**Tracking:** [#78](...)` and `## Follow-up` with numbers. `gh issue view` on each number (including `body`, `blockedBy`, `blocking`). Generated body matches. Relations match. No `gh issue create`. No `gh issue edit --body`. No file change.

## Re-sync with new decisions

Tracking `#78` exists. Follow-up `#79` exists. The plan has a new `## Decisions` section and `**Blocked by:** [#70](...)`.

1. `gh issue view 78 --json body,blockedBy,blocking`
2. Generated body differs → `gh issue edit 78 --body "$(cat <<'EOF' … EOF)"` (goal, decisions, scope, `## Blocked by` with `#70`)
3. `#70` missing from `blockedBy.nodes` → `gh issue edit 78 --add-blocked-by 70`
4. `gh issue view 79 --json body,blockedBy,blocking` — update body if the item changed; `--add-blocked-by 78` if the relation is missing
5. Plan file: do not rewrite decision prose. Only tracking / PR / follow-up links if they were missing

Do not comment on `#78`. Do not skip because the user said the issue already exists.

## Ambiguous title search

Search returns two issues with similar titles. Stop and ask which one is the tracking issue.
