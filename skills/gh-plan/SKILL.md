---
name: gh-plan
description: Use when the user runs gh-plan or /gh-plan with an issue number, pastes a GitHub issue URL and wants a local plan, or asks to plan, make a local plan, or implement from an existing GitHub issue before writing code.
---

# gh-plan

Announce at start: "I'm using gh-plan to create a local plan from the GitHub issue."

**The goal is a local Cursor plan. Not code.** "Implement" here means creating the plan. Use Plan mode (hard stop).

Do not use GitHub MCP, REST clients, or a browser. Only `gh`.

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| GitHub CLI (`gh`), authenticated | the issue, comments, sub-issues, relations | `gh auth status` succeeds |
| A repo `gh` can resolve (or `--repo OWNER/REPO` from a URL) | the default branch, the tracking link | `gh repo view --json nameWithOwner,url,defaultBranchRef` succeeds |
| Plan mode | writing the plan without implementing | step 2 |

**Hard gate.** Run the checks before step 1. If any fails, stop, tell the user which requirement is missing and how to fix it. Do not continue, do not substitute another tool (GitHub MCP, REST clients, a browser), and do not implement in agent mode.

## Hard stop

Once the draft (or updated plan) and open questions are shown: **stop**. Do not write, change, or run any implementation.

**No exceptions:**

- Not "just the first task"
- Do not use writing-plans, executing-plans, or subagent-driven-development in this round
- Do not run gh-sync yet (that happens on Build)
- Do not create a branch, commit, PR, or any file other than the plan document itself

| Excuse | Reality |
| --- | --- |
| "The issue is clear enough to code" | Then the plan is short. It must still exist, in Plan mode. |
| "I'll put the code in the plan so it's ready" | The plan is decisions, PR split, and TDD steps — not finished code. |
| "Plan mode is optional, we're in agent mode" | Switch to Plan mode. Hard stop. |
| "I'll sync to GitHub right away" | gh-sync runs when the user says Build, not now. |

**Red flags:** code, tests, commits, "shall I start?", worktree, checking out a new branch, GitHub MCP.

When the user says **Build**, go ahead, implement, or "run it": leave this skill. Run `gh-sync` first, then implement.

## Procedure

```text
Task:
- [ ] Issue number
- [ ] Plan mode
- [ ] gh details
- [ ] Local plan
- [ ] Codebase (read)
- [ ] Plan draft + questions
- [ ] Hard stop (repeat on answers)
```

### 1. Issue number

From `gh-plan <issue_num>`, `/gh-plan`, `#N`, or an issue URL. Number missing: ask and stop.

### 2. Plan mode

If you are not already in Plan mode: `SwitchMode` with `target_mode_id: "plan"`. Explanation: local plan from a GitHub issue, hard stop, no implementation.

Tool missing: ask the user to switch manually. Do not implement in agent mode.

### 3. Fetch the issue with gh

The requirements above are already checked. URL with a different owner/repo: `--repo OWNER/REPO`. Otherwise the repo `gh` points at.

```bash
gh issue view N --json number,title,url,state,body,labels,assignees,milestone,comments,parent,subIssues,subIssuesSummary,blockedBy,blocking,closedByPullRequestsReferences
```

Read the **whole** body, comments, `parent`, `subIssues`, and related issues (`blockedBy` / `blocking`). Existing sub-issues are reused in the PR plan with `#N` — do not invent new PRs that duplicate them.

Closed issue: say so, and continue only if the user still wants a plan.

### 4. Check for an existing local plan

The GitHub issue is most likely linked to a plan that already exists locally. Search `~/.cursor/plans/` for it. If there is no earlier plan, go to the next step.

If there is an earlier plan, read it and judge whether it still applies. The codebase may have changed since it was written, and the plan may need updating.

### 5. Investigate, then write

Read the codebase against the issue. Answer what you can yourself. What remains becomes questions.

Write the **Cursor plan** (Plan mode / `~/.cursor/plans/*.plan.md`). Not `docs/superpowers/plans/`.

This order is not optional:

1. Generate a plan draft (with assumptions marked).
2. Ask open questions.
3. Hard stop.
4. When the user answers: update the plan, ask remaining questions, hard stop again.
5. Repeat until the questions are answered by the user or by your research.

New functionality: ask about an **env feature flag**. Do not add nice-to-haves.

### 6. Hard stop

Show the plan and the questions. Tell the user they can answer the questions, or say **Build** when the plan is approved. No implementation in the same turn.

## Plan content

YAML frontmatter: `name`, `overview`, `todos` (`pending`), `isProject: false`.

Right after the title:

```markdown
**Tracking:** [#N](url-from-gh).
```

Then, in this order:

1. **`## In brief`** — one short section for non-technical readers. What will happen, not how. Before the rest of the plan.
2. **`## Decisions`** — decisions and assumptions (mark the ones not yet locked).
3. Mermaid for non-obvious flows. **Dark theme:** first line of the diagram `%%{init: {'theme':'dark'}}%%`. Don't overdo it.
4. **`## PR plan`** (or `PR split` / `PR stack`) — small PRs, max ~500 lines each. Split into more PRs when needed. One item per PR (`### PR A`, …). If the issue has sub-issues: use them as PR items with their existing `#N`.
5. Each PR item: branch from the **default branch** (`defaultBranchRef`), TDD (red–green, not all tests first), documentation.
6. **`## PR description`** — detailed template, **without code examples**. At minimum: summary, branch, TDD, documentation, QA. This is a template, not the PR plan.
7. **`## Follow-up`** — out of scope / later. Do not duplicate PR sub-issues.
8. **`## QA`** — how to test what was actually built.

Todos: concrete deliverables, including TDD and documentation. No nice-to-haves.

Do not paste the superpowers header (`For agentic workers`).

In the plan, under constraints: "Before implementation: run the `gh-sync` skill."

Write the plan in the language of the issue and conversation. For a Norwegian plan, keep æ, ø, and å correct and use the Norwegian headings that `gh-sync` also recognises (`## Kort forklart`, `## Beslutninger`, `## PR-plan`, `## PR-beskrivelse`, `## Oppfølging`). Take URLs from `gh`; never hardcode a host.

## Common mistakes

- Starting to code because the issue looks small → still Plan mode and hard stop.
- Using the writing-plans file path and offering "Subagent-Driven vs Inline" → wrong ending. Hard stop, wait for Build.
- Skipping comments/sub-issues → incomplete spec.
- PR description with code blocks → cut the code, keep what/why/QA.

## Examples

See [examples.md](examples.md).
