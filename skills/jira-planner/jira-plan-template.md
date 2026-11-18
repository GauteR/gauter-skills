# Paste-ready plan template (Jira)

Use this structure for:

- The paste-ready plan: `reports/plans/<KEY>-<nr>-jira.md` (the user pastes it into the Plan field on the parent issue)

This is **not** the detailed local plan. Details (PR slices, files, tests, deploy, decision map, …) are in `reports/plans/<KEY>-<nr>.md`, made from [plan-template.md](plan-template.md).

Rules:

- Short and pasteable: no local paths, no mermaid, no PR slices.
- The content must be **consistent** with the local plan (same goal, decisions, DoD).
- Derived in step 6 from the canonical local plan, not a copy of the whole detailed plan.
- Write in the language of the issue; code and paths in English.

```markdown
## Summary

[One short paragraph and/or a short bullet list for non-technical readers: what will be done, why, and what is not included.]

## Goal

[Concrete goal / desired outcome.]

## Decisions

[Settled decisions. A short bullet list.]

- …

## Definition of Done

- [ ] …
- [ ] …
```
