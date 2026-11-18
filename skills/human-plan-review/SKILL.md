---
name: human-plan-review
description: Make sure the developer understands a plan before it is built or synced. Improve plans that are hard to understand. Quiz the developer on the actual plan file's scope, decisions, rationale, ordering, dependencies, and risks.
disable-model-invocation: true
---

# Human plan review

Results in pass or fail. It exists to confirm the developer responsible for a plan understands its scope, decisions, rationale, ordering, dependencies, and risks — not to test trivia, and not to punish. When a wrong answer traces back to a plan that is genuinely hard to follow, fix the plan; don't just fail the human. Re-derive every question from the actual current plan file — never reuse from a question bank, never ask about headings, todo ids or line numbers.

This skill reviews; it never implements. Do not write code, create branches, commits or PRs, or run `gh-sync` as part of a review. The only file you may change is the plan itself, and only with the developer's approval (step 9).

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| A readable plan file | the review itself | step 1 finds one |
| `git` or `sha256sum` | the content hash in the statement | `git --version` or `sha256sum --version` succeeds |
| bash with `$RANDOM` | random answer slot and option length | `bash -c 'echo $((1 + $RANDOM % 4))'` prints 1–4 |
| GitHub CLI (`gh`), authenticated, **only if the plan names a tracking issue** | issue text, relations, the comment in step 12 | `gh auth status` succeeds |

**Hard gate.** Run the checks before step 1; check `gh` as soon as step 1 shows that the plan names a tracking issue. If a requirement is missing, stop, tell the developer which one and how to fix it, and do not start or continue the review. Do not skip the issue, do not substitute another tool (GitHub MCP, REST clients, a browser), and do not choose the answer slot yourself.

## 1. Identify the target plan

The target is a plan file. Any markdown plan works, whichever tool wrote it (Claude Code plan mode, Cursor, `gh-plan`, or by hand).

1. If the developer named a file, use it.
2. Otherwise, if there is an active plan in the session (for example the plan file of the current plan mode), use it.
3. Otherwise list the most recently modified candidates and ask which one to review, newest as the suggestion. Look in the plan directories of the agents the developer uses (`~/.claude/plans/`, `~/.cursor/plans/`), in the repo (`docs/plans/`, `plans/`, `PLAN.md`, `*.plan.md`), and anywhere the developer points you to.

If no plan can be found, say so and stop.

## 2. Gather context

Read the **whole** plan, including frontmatter, todos, diagrams and any open questions. Then gather:

- the plan's identity: path, last-modified time, and a content hash for the statement in step 11 (`git hash-object <file>`, or `sha256sum <file>` if git is unavailable). Plans are normally not in git, so a commit SHA does not exist.
- the tracking issue, if the plan names one (for example a `**Tracking:** [#N](url)` line, as `gh-plan` writes it): title, body, comments, sub-issues and blocked-by relations (`gh issue view N --json number,title,url,state,body,comments,subIssues,blockedBy,blocking`). Use only `gh`. Treat the issue as supplementary evidence: every question must be traceable to the plan as written, not to what the issue says it should contain.
- the code, docs and tests the plan says it will touch. Check that the files, modules and interfaces the plan names still exist and behave as the plan assumes. Don't require anything to build.
- other local plans that cover the same issue or area (see "Overlapping plans" below)

If the plan or its issue is closed, done, or fully synced, say so; continue only if the developer still wants the review.

### Overlapping plans

The developer's mental model may follow a newer or parallel plan, not this one. Search the plan's own directory and the other plan locations from step 1 for other plans that name the same issue number or the same files and modules. Drop the plan under review. For each remaining plan, check which decisions or PR items it changes, replaces or supersedes.

Show them together with the plan summary:

> These plans also cover parts of this scope: <plan name> (<what it changes or supersedes>). I'll avoid questions about those parts unless you want them included.

### Unresolved items

List what the plan itself leaves open: unlocked decisions, assumptions marked as such, open questions, TODO/TBD markers. Show the list to the developer. These are not quiz material as if they were decided; ask about them only as "what is the status of this decision", and never count the plan's undecided choice as the correct answer to a question about the intended design. If the unresolved items cover the core of the plan, say so and offer to stop so they can be settled first.

Before generating questions, show the developer:

- Plan: file name and title
- Version: short content hash and last-modified time
- Tracking: issue number and state, if any
- Scope: number of PR items, decisions, todos, and plan lines (excluding frontmatter)
- Staleness: anything in the plan that no longer matches the codebase

## 3. Map comprehension-critical areas

Before writing questions, scan the plan for what the developer must understand:

- the goal, scope, and what is explicitly out of scope
- decisions and the reasoning behind them, including rejected alternatives
- the PR split: what each PR contains, ordering, and which PRs depend on which
- dependencies: other issues, plans, teams, services, data, feature flags, environments
- failure modes and risks: rollout, rollback, migration, data loss, security, concurrency, behaviour with the feature flag on and off
- test strategy (TDD steps), documentation, and QA: what each is meant to prove
- what breaks, or must be redone, if a decision is later changed or a PR is dropped

Separately, flag comprehensibility risks in the plan itself: ambiguous scope, vague todos, undefined terms, implicit ordering between PRs, PR items that are too large (over ~500 lines), decisions without a stated reason, contradictions between sections, a "In brief" section that doesn't match the details, missing rollback or flag handling, diagrams that disagree with the text. These are candidates for plan improvement, not for the quiz — a risk you flag here is a hint you're about to test the plan's clarity, not just the developer's memory.

Also flag plan **flaws**: steps that contradict the code, impossible orderings, assumptions the codebase disproves. Keep them for step 7.

## 4. Generate the questions

Count, measured over the plan's lines excluding frontmatter:

- Trivial plan (≤ 30 lines and a single PR item): 2. A trivial plan that touches security or authentication, data migration or deletion, database transactions or locks, concurrency, rollout behind a feature flag, or a business rule defined in `GLOSSARY.md` takes the count below instead.
- Otherwise: 3 for a small/simple plan, 5 by default, up to 7 for a complex one (many PR items, many dependencies, or high-risk areas).

Don't ask about parts that an overlapping plan replaces, unless the developer asked to include them. If you can't reach the question count without them, say "in this plan, before <plan name>" in the question body.

Mix across these five kinds, grounding every one in the actual plan — include at least one prediction or failure-mode question whenever the plan has meaningful behaviour of that kind:

1. **Scope** — what will and won't be done?
2. **Reasoning** — why was it decided this way, and what was rejected?
3. **Failure mode** — what happens when something goes wrong, or has to be rolled back?
4. **Dependency** — what must come first, what else does this touch, what is blocked?
5. **Prediction** — given a concrete scenario (a PR merged out of order, the flag off, a decision reversed, an input the plan didn't expect), what does the plan imply happens?

## 5. Generating the options to an answer

1. First, generate exactly one objectively correct option.
2. Then, generate 3 plausible distractors. These must have about the same number of words and characters, and the same level of detail, so that the length or level of detail does not give it away. Use `echo $(($RANDOM % 2))` to decide if the correct option should be longer (output is "1") or shorter (output is "0") than the distractors.
3. Then, randomize which letter (A–D) holds the correct answer for each question by running `echo $((1 + $RANDOM % 4))` in the shell (1=A, 2=B, 3=C, 4=D) and placing the correct answer in that slot — don't pick the slot yourself.
4. Then, assign the remaining letters (A–D) to the incorrect options.
5. Always include a fifth option (E) for "I don't know."

## 6. Before asking the questions

If the plan has a tracking issue, show a link to it.

Show this note once: "If you understand what the plan says but believe it is wrong (contradicts the code, impossible, or missing something essential), use (F) Flaw. A justification is optional."

## 7. Ask the questions

One question at a time. Record the answer; allow an explicit "I don't know" — it counts as incorrect but is a real signal of uncertainty, not noise to discard. Also allow an explicit "Flaw" — it counts as incorrect, but changes text in the summary.

Do not output educational insights (e.g. `★ Insight` blocks) while the quiz is running, from the first question until the score is shown. They can reveal the answer.

Each question should be formatted like so:

```
Question <CURRENT> of <TOTAL>

❓ **<question title>**: <question body, might be multiple paragraphs>

(A) <option A>
(B) <option B>
(C) <option C>
(D) <option D>
(E) I don't know
(F) Flaw (optional justification)
```

Each question is a three-turn exchange, finished before the next question is shown:

1. You ask the question; the user answers.
2. You say which option was chosen and whether it was correct, then ask for comprehension feedback in the same message (format below); the user answers.
3. You record the feedback and show the next question.

If the answer was "(F) Flaw", ask for a short justification if none was given, then check the claim against the plan and the code and assess whether this is likely a genuine flaw, using any justification as supporting evidence. Explain the reasoning to the user. Either way, count it as a wrong answer for scoring purposes — but if it is likely a genuine flaw, also record it as a confirmed flaw.

Comprehension feedback: take free text if offered, but don't demand it.

```
❓ **<ask for comprehension feedback for the previous question>**

(A) I understand it well
(B) Unsure
(C) Hard to understand from the plan
(D) The question itself was unclear
```

## 8. Diagnose weak understanding

Where answers are wrong or uncertainty clusters, decide whether the cause is (A) a knowledge gap, (B) an unclear or needlessly complex plan, or (C) an ambiguous question — possibly a mix. Don't default to (A). If (C), say so explicitly and don't treat that question as a reliable signal.

If a wrong answer matches what an overlapping plan says, classify it as (C), leave it out of the score, and score against the remaining questions.

## 9. Improve plan parts the questions exposed as hard to understand

When feedback or diagnosis points to (B): name the likely source of difficulty, explain it briefly, propose a clearer wording or structure, and offer to apply it to the plan file. Good targets: stating the reason next to each decision, making PR ordering and blocked-by relations explicit, splitting an oversized PR item, replacing vague todos with concrete deliverables, defining terms on first use, aligning "In brief" with the details, adding rollback and feature-flag behaviour, fixing a diagram that disagrees with the text. The bar is "easier to predict correctly," not "longer."

Only edit the plan with the developer's approval, and change only what was discussed. Keep the plan's language, frontmatter and heading names (`gh-sync` recognises them). Do not implement anything the plan describes. If you edit the plan, recompute the content hash and tell the developer; questions about passages you changed are no longer reliable signals.

## 10. Score

Pass threshold 70%, required-correct rounded up:

| questions | required |
| --------- | -------- |
| 1         | 1        |
| 2         | 2        |
| 3         | 2        |
| 4         | 3        |
| 5         | 4        |
| 6         | 5        |
| 7         | 5        |

Say: "<CORRECT> correct out of <TOTAL>."

## 11. Record the result

Only run this step if the score meets the pass threshold AND no confirmed flaws were found — a confirmed flaw always blocks the understanding statement, even on a passing score.

On a pass, output a human understanding statement. Fill in your name, the plan's file name, and the content hash of the plan as it is now (recomputed if it was edited in step 9), and the tracking issue if there is one.

Use the following format when the plan has a tracking issue:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ <your name> understands this plan: <issue url>
`<plan file name>` @ `<content hash>`
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

Use the following format if there is no tracking issue:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ <your name> understands this plan:
`<plan file name>` @ `<content hash>`
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

## 12. Sending a comment to the issue

If the plan has a tracking issue, offer to post the statement as a comment on it (`gh issue comment`). This is visible to others, so ask first and post only on a yes. Only post the human understanding statement, not the score or failure details. Never post the plan's contents.

If this repo has a signature skill (e.g. `.agents/skills/signature`) for marking AI-generated PR/ticket text, append its signature line to the posted comment.

Don't run `gh-sync` as part of this step. If the developer wants to sync or build, they say so afterwards.

## 13. Handle failure

If one or more confirmed flaws were found, DISAPPROVAL_TEXT is "Too many errors in the plan. Fix them and run human-plan-review again." — this always applies when a confirmed flaw exists, even if the score meets the pass threshold; a confirmed flaw blocks the understanding statement regardless of score. Otherwise, if the score does not meet the pass threshold, DISAPPROVAL_TEXT is "You have not demonstrated that you understand this plan."

No approval record. Show the score, name the weakest areas, surface the comprehension feedback gathered, and suggest reviewing and/or improving the flagged parts of the plan before trying again:

```text
<DISAPPROVAL_TEXT>

Result: <CORRECT>/<TOTAL>

Weakest areas:
- <AREA>
- <AREA>

Review these parts of the plan before trying again.
```

## Language

The text in this skill is English. Write questions, answers, statements and templates in the language the developer uses; if unclear, use English. Translate the templates and fixed phrases above (including the disapproval texts and the marker line of the understanding statement) into that language. Keep the `BEGIN`/`END HUMAN UNDERSTANDING STATEMENT` markers as they are. Never put real patron data or identifiers in questions; use synthetic values.

## Examples

See [examples.md](examples.md): fill-in templates for each step, example questions per kind, and a Norwegian set of the fixed phrases.
