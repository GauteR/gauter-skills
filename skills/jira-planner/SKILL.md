---
name: jira-planner
description: >
  Produces a technical plan for a Jira issue as local markdown, from templates:
  a decision map and teach-back before the draft, a stress-test of the draft,
  then an agent-plan-review → fix loop until no blocking or "should fix before start"
  findings remain, and finally a short paste-ready plan for the issue's Plan
  field. Optionally writes per-PR subtask descriptions, but only when the user
  explicitly asks. Never calls Jira: the user supplies the issue text and pastes
  the results. Use when the user asks for jira-planner, or "plan and review for
  PROJ-123". In an implementation turn, always run before implementation, then
  STOP (no code in the same turn). In plan mode, planning only.
disable-model-invocation: true
---

# Jira planner

End to end: issue text (from the user) → **decision map** → **grilling** / **teach-back** as needed → technical draft → **stress-test** → **iterative** plan review → fix plan (until nothing is blocking or "should fix before start") → **paste-ready markdown** for the Plan field. **Stop there**, unless the user explicitly asks for subtask descriptions.

This skill only reads files and writes local markdown from templates. It does not call Jira, the Atlassian MCP, a REST API, or a browser, and it runs no scripts. The user copies the results into Jira.

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| Issue key | every file name | the user gave one (`PROJ-123`, `proj-123`, or `123` when the project key is known) |
| Issue summary and description, pasted by the user | the source of the plan | the user pasted them, or named a file that contains them |
| Writable `reports/` directory in the working directory | all artefacts | `reports/plans/` can be created |
| The code the issue concerns, checked out | verifying claims in the plan | the relevant paths are readable |

**Hard gate.** Check before step 1. If the key or the issue text is missing, ask for it and stop. Do not guess the issue content, and do not try to fetch it from Jira by any other route (MCP, REST, browser). If the code is not available, say so, mark every claim about code as unverified, and ask whether to continue.

## Responsibility and boundary

- `jira-planner` owns the local plan orchestration and the paste-ready plan text. It writes subtask descriptions **only when the user explicitly asks**.
- Decision mapping (`wayfinder`), the interview engine (`grilling`), the CONTEXT/ADR step (`domain-modeling`), and the conditional `research`, `codebase-design` and `prototype` are separate skills that live next to this one in this repository. Use them when they are installed. If one is not, do the same work yourself: map the decisions, ask one question at a time with a recommended answer, and record the outcome in the plan.
- The plan review is a step in the loop. Use the `agent-plan-review` skill (its checklist is `reference.md`) and write the report with [plan-review-template.md](plan-review-template.md), the iteration-aware variant. Do it as a fresh pass over the plan on disk, not from memory of having written it.
- If the user only wants a review of an existing plan (no paste-ready plan), do just the review.

**All of steps 1–7 are mandatory.** Do not skip a step, merge steps without finishing the artefact, or replace them with a chat-only report. Step 2a may record a **skip** when the decision map shows that the path is already clear. Teach-back (2b) and stress-test (4) are still required. **Step 8 does not run** unless the user explicitly asks for subtask descriptions after the paste-ready plan.

## Input

- Issue key, normalised to `<KEY>-<nr>`.
- Issue summary and description, and any other fields the user pastes (components, acceptance criteria, existing plan).
- Optional: existing plan text or constraints.
- Optional: "no docs" → grilling only, no CONTEXT/ADR writing.
- Optional: "no decision map" → skip step 2a. Only when the user asks for it explicitly.

## Output (local)

| Artefact | Path |
| --- | --- |
| Decision map (local, optional) | `reports/plans/<KEY>-<nr>-wayfinder/map.md` |
| Decision tickets (local, optional) | `reports/plans/<KEY>-<nr>-wayfinder/issues/NN-<slug>.md` |
| Draft (first version, snapshot) | `reports/plans/<KEY>-<nr>-draft.md` |
| Detailed local plan (canonical, updated in the loop) | `reports/plans/<KEY>-<nr>.md` |
| Paste-ready plan (short, for the Jira Plan field) | `reports/plans/<KEY>-<nr>-jira.md` |
| Plan review, iteration 1 | `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD.md` |
| Plan review, iteration n ≥ 2 | `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD-i<n>.md` |
| Subtask descriptions (optional, on request) | `reports/plans/<KEY>-<nr>-subtasks.md` |

Templates:

| Template | Used for |
| --- | --- |
| [plan-template.md](plan-template.md) | the detailed local plan and its draft snapshot |
| [plan-review-template.md](plan-review-template.md) | each review iteration |
| [jira-plan-template.md](jira-plan-template.md) | the paste-ready plan |
| [subtask-description-template.md](subtask-description-template.md) | one subtask description per PR |

The user pastes `*-jira.md` into the Plan field themselves. Subtask descriptions are pasted into subtasks the user creates themselves.

## Workflow

**Plan mode:** run `jira-planner` as planning. Write the artefacts under `reports/plans/`. The implementation stop rule below does not apply.

**Implementation turn:**

1. If steps 1–7 are not done for the issue, finish `jira-planner` first (paste-ready plan and paste instructions).
2. **STOP the implementation.** Do not start code, a branch, TDD, or commits in the same turn.
3. The user pastes the plan and confirms; a new turn (or an explicit "implement") starts the coding.

**Standard end of `jira-planner`:** after step 7. The canonical plan is in `reports/plans/`.

**The order is fixed:** finish step *n* (including the file on disk where the step requires one) before step *n+1*. Always finish the stress-test (step 4) and the review → fix loop (step 5) before the paste-ready plan.

Copy and tick off:

```text
jira-planner:
- [ ] 1 Take the issue text from the user (no Jira calls)
- [ ] 2a Decision map (or a documented skip when the path is already clear)
- [ ] 2b Teach-back → user confirms shared understanding
- [ ] 3 Write the technical draft → reports/plans/<KEY>-<nr>.md (+ snapshot -draft.md)
- [ ] 4 Stress-test the draft → update the canonical plan
- [ ] 5 Iterate: plan review → fix plan until nothing blocking / "should fix before start" is open
- [ ] 6 Write the paste-ready plan (short; jira-plan-template) → reports/plans/<KEY>-<nr>-jira.md
- [ ] 7 Show the path and paste instructions → STOP here
- [ ] 8 Only if the user explicitly asks: subtask descriptions → reports/plans/<KEY>-<nr>-subtasks.md
```

Step 5 is **not** optional. Step 4 is finished **before** step 5.

### 1. Take the issue text

Use only what the user gave you: key, summary, description, and any pasted fields. Do not call Jira. Do not invent fields or acceptance criteria that were not provided; list what is missing and ask.

Also read the relevant code, `GLOSSARY.md` and ADRs before the decision map and grilling, and before the plan is written.

### 2a. Decision map

After the issue text and relevant code/CONTEXT: use the `wayfinder` skill if installed, for *this* issue. Otherwise do the same by hand.

**Tracker:** local markdown only, under `reports/plans/<KEY>-<nr>-wayfinder/`. Say so when you invoke `wayfinder`: it must use this local layout, not the repository's issue tracker, and it must not ask the user to set one up.

- Map: `map.md` with the headings Destination, Notes, Decisions so far, Not yet specified, Out of scope
- Tickets: `issues/NN-<slug>.md` with `Type:` / `Status:` / `Blocked by:`
- The notes on the map name the issue key, and `grilling` and `domain-modeling` when they were used

**Chart the map:**

1. Name the destination, anchored on the issue's goal.
2. Map the frontier breadth-first.
3. **If there is no fog** (the path to the destination is already clear and small enough for one session): document the skip in chat and later in the plan's decisions: "Decision map skipped: the path was already clear". Go to step 2b. Do not create an empty map for the sake of it.
4. Otherwise create the local map, tickets and blocking relations. Run research tickets before moving on.
5. Stop charting when the map is set. **Work through the map** in the same or following rounds until the frontier is empty or the destination is clear enough for a technical plan. At most **one** non-research ticket per session. The user can ask to continue tickets before the draft.

**Docs (default):** when domain terms or hard-to-reverse decisions come up, record them in CONTEXT/ADR (`domain-modeling`).

**"No docs":** no CONTEXT/ADR writing.

**"No decision map":** skip this step with one sentence; go to grilling directly (build a design tree for goal, scope, approach, risk, PR split), then 2b.

**Conditional** (only when the frontier needs it): `research`, `codebase-design`, `prototype`.

Facts = agent; decisions = user. Do **not** go to step 3 before step 2b is finished.

### 2b. Teach-back (mandatory before the draft)

Shared understanding before plan text:

1. A short summary: destination, settled decisions (from "Decisions so far"), scope / out of scope, risk.
2. Verification questions in `grilling` format: the question and a recommended answer.
3. This also applies after a skip in 2a.
4. **Exit:** the user confirms (or corrects). Only then step 3.

### 3. Technical draft

Write the **detailed local** plan `reports/plans/<KEY>-<nr>.md` from [plan-template.md](plan-template.md). Also take the snapshot `reports/plans/<KEY>-<nr>-draft.md`.

Do not write the paste-ready file here; that is step 6 ([jira-plan-template.md](jira-plan-template.md)).

**After step 3:** go straight to step 4.

### 4. Stress-test the draft (mandatory before plan review)

Run `grilling` (or the same interview by hand) against the detailed local plan `reports/plans/<KEY>-<nr>.md` (**not** `*-jira.md`):

- Focus: assumptions, gaps, misunderstandings, PR split, Definition of Done.
- Default: **no** new `domain-modeling` unless new domain terms or ADR needs show up.
- Update the canonical **local** plan after the rounds.
- Exit: the frontier of draft questions is empty **and** the user confirms. Then step 5.

### 5. Iterative plan review → fix plan

**Exit criterion:** the latest plan review has **no** open findings under **Blocking** or **Should fix before start**. The verdict is "Ready" or "Ready with reservations", where the reservations are only **Minor / clarifications**.

Set `n = 1`. Repeat:

1. **Plan review** of the detailed local plan `reports/plans/<KEY>-<nr>.md` (**not** `*-jira.md`), using [plan-review-template.md](plan-review-template.md).
   - `n = 1` → `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD.md`
   - `n ≥ 2` → `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD-i<n>.md`
   - Do not commit review files.
2. **Exit check:** nothing open under **Blocking** / **Should fix before start** → step 6.
3. **Fix the plan:** update the canonical **local** plan; keep the non-technical summary; mark the changes made because of the review; keep the PR plan. On "Not ready": close the gap, or run the decision map / grilling (and `domain-modeling` if needed) before the next iteration.
4. `n = n + 1`. If `n > 5`: stop, show the open findings, and ask the user. Do **not** go to step 6 with unresolved blocking / should-fix findings.
5. Back to point 1.

### 6. Paste-ready plan

Derive a **short** paste-ready file from the detailed local plan, not a full copy:

`reports/plans/<KEY>-<nr>-jira.md`

Template: [jira-plan-template.md](jira-plan-template.md). Only these sections:

- Summary
- Goal
- Decisions
- Definition of Done

The content must be consistent with `reports/plans/<KEY>-<nr>.md`. No local paths, no PR slices, no mermaid.

Subtask descriptions (step 8) are always written from the detailed local plan, never from the paste-ready file.

### 7. Show the paste instructions

Show the path to `reports/plans/<KEY>-<nr>-jira.md` (and to the canonical plan). Say explicitly that the user pastes it into the Plan field on `<KEY>-<nr>` themselves.

**Standard stop.** Do not go to step 8, do not suggest subtask descriptions, and do not ask "shall I write subtasks?", unless the user **explicitly** asks for them (for example "write subtask descriptions" or "make subtasks for the PRs").

**In an implementation turn:** after step 7, **stop the implementation** (no code in the same turn). Say briefly that the plan is ready to paste and that a new turn is needed for implementation. **In plan mode:** end the planning round as usual.

### 8. Subtask descriptions per PR (only on explicit request)

**Gates:** (1) the paste-ready file exists (steps 6–7 are done), (2) the user **explicitly** asked for subtask descriptions. Pasting the plan is not a request for subtasks. Without an explicit request, skip step 8.

1. Read the PR plan in `reports/plans/<KEY>-<nr>.md` (the table in [plan-template.md](plan-template.md), or the alternative numbered list).
2. 0 PR rows → say "found no PRs"; write nothing.
3. If the parent is itself a subtask, or an epic, say so and ask how the user wants to proceed; do not guess.
4. For each PR, write a **self-contained** description from [subtask-description-template.md](subtask-description-template.md) (Goal, Steps, Files, Tests, DoD) from the plan's PR slice: enough to start the work without reading the parent. Do not paste shared background. Do not write "see the parent plan" or point to the local plan file instead of slice content. No generic scope text that is identical on every PR.
5. Write all descriptions to `reports/plans/<KEY>-<nr>-subtasks.md`, one section per PR, in ascending PR number. Tell the user they create the subtasks and paste each section.
6. If the PR table has an issue column with keys already filled in, mention which PRs already have a subtask and write only the missing ones, unless the user asks for all.

## Expected PR format in the plan

See [plan-template.md](plan-template.md): the canonical table and an alternative numbered list.

## Expected behaviour (stress)

| ID | Situation | Expected |
| -- | --------- | -------- |
| S1 | Key or issue text missing | Hard gate: ask and stop; do not fetch from Jira |
| S2 | Step 7 done, no explicit subtask request | Stop; no list, no descriptions |
| S3 | User asks for subtask descriptions | Step 8; write the file; the user creates the subtasks |
| S4 | Parent is a subtask or an epic | Say so; ask how to proceed |
| S5 | 0 PR rows | "Found no PRs"; write nothing |
| S6 | Plan paste-ready, no subtask request | Paste-ready file only; no subtasks |
| S7 | Agent is about to call Jira, the Atlassian MCP or a REST API | Invalid; this skill writes local files only |
| S8 | Unreadable PR plan | Actionable error; ask for structure |
| S9 | Stops after one review with open blocking / should-fix findings | Invalid; continue the loop |
| S10 | Open blocking / should-fix findings after a review | Update the plan → new review; do not write the paste-ready file yet |
| S11 | Review "Ready" or only Minor | Exit the loop; write the short `<KEY>-<nr>-jira.md` |
| S12 | `n > 5` without exit | Stop; ask the user |
| S13 | Decision map: no fog | Document the skip in 2a; still do 2b teach-back |
| S14 | User says "no docs" | No CONTEXT/ADR writing |
| S15 | Before the draft | Teach-back and user confirmation |
| S16 | After the draft | Stress-test before plan review |
| S17 | Decision map under this skill | Local `reports/plans/<KEY>-<nr>-wayfinder/`; no Jira artefacts |
| S18 | User says "no decision map" | Skip the map; grilling + 2b |
| S19 | Implementation turn, `jira-planner` done (step 7) | STOP; no code in the same turn |
| S20 | Plan mode, `jira-planner` done | End planning; the implementation stop does not apply |

## Related skills (do not replace)

| Need | Skill |
| ---- | ----- |
| Decision map / frontier | `wayfinder` |
| Interview engine | `grilling` |
| CONTEXT / ADR | `domain-modeling` |
| Heavy fact finding | `research` |
| New modules / seams | `codebase-design` |
| Cannot be settled on paper | `prototype` |
| Code review of a diff or PR | `code-review` (not part of this skill) |
| Reviewing a plan on its own | `agent-plan-review` |
| Checking that the developer understands the plan | `human-plan-review` |
| Signing text that the agent wrote, before it is pasted into Jira or GitHub | `signature` |

This skill owns: decision map → teach-back → draft → stress-test → iterative plan review → fix → paste-ready plan; subtask descriptions **only on explicit request**. It is **not** a code review of a diff or PR.

## Stop rules

- **In an implementation turn:** run steps 1–7 before implementation; **stop the implementation** after the paste-ready plan, with no code in the same turn. **In plan mode:** the implementation stop does not apply.
- **No skipping steps 1–7** unless the user cancels the whole `jira-planner`. A skip in 2a requires a documented "path already clear" or "no decision map".
- **Step 8 only after an explicit request** for subtask descriptions. Never suggest or write them automatically after step 7.
- **No plan review (step 5) before the stress-test (step 4) is finished.**
- **No leaving the review → fix loop** while blocking / "should fix before start" findings are open.
- **No Jira access of any kind:** no MCP, REST, browser, comments, labels, transitions, or field updates. The user pastes.
- **No scripts.** Templates and local markdown only.
- No code changes or commits as part of this skill (also when it runs inside an implementation turn).
- No push or deploy.
- Review reports are not committed.
- No `code-review` / PR review as part of this skill.
- The decision map under this skill is **local files**, not Jira issues.

## Examples

See [examples.md](examples.md).

## Language

The text in this skill is English. Write the plans, reviews and replies in the language of the issue and the conversation; if unclear, use English. Keep code, file paths and the section names the user's tooling depends on as they are.
