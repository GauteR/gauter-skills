---
name: plan-review
description: >
  Systematically review an implementation or product plan before development:
  goals alignment, structure, gaps, technical risks, strengths. Uses the
  project's own docs and rules. Writes a markdown report and changes nothing
  else.
  Trigger: review plan, plan review, "go through the plan", "is the plan
  ready?", gå gjennom planen, vurder plan.
  Not for interviewing (use grilling, plus domain-modeling when docs are wanted)
  or for checking that the developer understands the plan (use
  human-plan-review).
---

# Plan review

A thorough review of a plan **before** development. The result is a markdown report.

## When

- The user asks for a plan review, "go through the plan", or "is the plan ready?"
- An issue or PR has a plan that should be checked before implementation

**Do not use for:** interviewing or stress-testing the user's thinking (`grilling`, plus `domain-modeling` when docs are wanted), checking that the developer understands the plan (`human-plan-review`), code review, or QA after the code exists.

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| The plan text | the review itself | pasted in the conversation, a file the user named, or a PR description (see "Input") |
| Writable `reports/` directory | the report | `reports/` can be created |
| The code the plan concerns, readable | verifying what the plan claims | the relevant paths exist locally |
| GitHub CLI (`gh`), authenticated, **only if the plan is read from a PR** | the PR description | `gh auth status` succeeds |

**Hard gate.** If there is no plan text, stop and ask for it. If the plan lives in a PR and `gh` is missing or not logged in, stop and say so; do not fetch it by another route. If the code is not available, say so, mark every claim about code as unverified, and ask whether to continue.

## Hard rules

- **Never** edit the plan (in a PR or a file) unless the user explicitly asks.
- **Never** write to an issue tracker or a PR (no comments, no field updates). The only thing this skill writes is the report.
- **No shortcuts:** go through every section of [reference.md](reference.md).
- Load the project's own rules as the basis for the review: `AGENTS.md`, `CONTRIBUTING`, and any policy skill the project uses.
- Write the report in the language of the developer; English only in code, paths and technical terms.
- The report is **not committed** unless the user asks.

## Input (priority)

Collect the plan from every source available; note which one is primary:

1. **Pasted text** in the conversation
2. **A local file** the user pointed to
3. **A PR description** (technical plan): `gh pr view` for the current branch or a named PR
4. **Issue text** (summary, description, acceptance criteria) that the user pasted, as the statement of the goal

If there are several sources, review the **technical** plan (PR/file/paste) against the **goals** in the issue text. Flag discrepancies.

## Workflow

```
1. Collect plan + goals     → see Input
2. Load the rules           → the project's rules + docs (below)
3. Map the affected code    → modules, CONTEXT/ADR, existing patterns
4. Systematic check         → reference.md (all sections)
5. Write the report         → reports/plan-review-<key-or-slug>-<YYYY-MM-DD>.md
6. If anything is unclear   → recommend grilling (+ domain-modeling for docs)
```

### Documentation sources (read what is relevant)

| Source | When |
|--------|------|
| The project's policy skill (for example `governance`), if there is one | Always |
| `AGENTS.md`, `CONTRIBUTING`, editor rule files | Always |
| `README.md` and config examples of the affected modules | Affected modules |
| Module-specific instructions or skills | When they exist |
| `GLOSSARY.md`, `GLOSSARY-MAP.md`, `docs/adr/` | Domain and architecture |
| Related skills such as `codebase-design` | When the plan touches them |

Explore the codebase when the plan claims behaviour or structure: confirm or refute it with code.

### Systematic check

Follow **every** section of [reference.md](reference.md) in order. For each finding: severity, a concrete reason, and a suggestion. Do not skip "Strengths".

## Report

File: `reports/plan-review-<key-or-slug>-<YYYY-MM-DD>.md`

When `jira-planner` runs this skill in its review loop, it uses its own iteration-aware variant of the template (`jira-planner/plan-review-template.md`) and the file names it defines.

Template:

```markdown
# Plan review – <issue key or title>

## Short verdict

**[Ready | Ready with reservations | Not ready for development].** [1–3 sentences: what is needed before start.]

## Sources

- Primary plan: <PR #n | file | pasted text>
- Other: …
- Code verified: [paths]
- Rules: <project rules and other docs>

## Strengths

- …

## Errors and gaps

### Blocking

- …

### Should fix before start

- …

### Minor / clarifications

- …

## Goal vs plan

- Does the plan match the goals and acceptance criteria?
- Scope creep / missing scope?

## Structure

- Breakdown, order, dependencies, PR size (≤ 500 lines), feature flag

## Technical risks

- Security/GDPR, backwards compatibility, data, operations, testing, unknowns

## Recommended next steps

- [ ] Update the plan (who/where)
- [ ] Run `grilling` (+ `domain-modeling` when docs are wanted) for: <list of open questions>
- [ ] Or: ready for implementation
```

Also give a short summary in the chat (verdict, top 3 findings, path to the report).

## Related skills

| Task | Skill |
|------|-------|
| End to end: issue text → decision map → teach-back → draft → stress-test → review→fix → paste-ready plan | `jira-planner` |
| Grill open questions / stress-test a plan | `grilling` (+ `domain-modeling` for docs) |
| Check that the developer understands the plan | `human-plan-review` |
| Design of modules and seams | `codebase-design` |

## Examples

See [examples.md](examples.md).

## Language

The text in this skill is English. Write the report in the language of the developer; if unclear, use English. Keep the section names the user's tooling depends on as they are.
