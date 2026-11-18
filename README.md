# gauter-skills

Agent skills by Gaute Rønningen, shared for reuse by others. Some of the skills come from other people's MIT-licensed projects; see [Credits](#credits).

## Skills

**Planning**

| Skill | What it does |
| --- | --- |
| [`gh-plan`](skills/gh-plan/SKILL.md) | Turns a GitHub issue into a local plan, without writing any code. |
| [`gh-sync`](skills/gh-sync/SKILL.md) | Syncs the active plan to GitHub: tracking issue, PR sub-issues, follow-ups and blocked-by relations. |
| [`jira-planner`](skills/jira-planner/SKILL.md) | Writes a technical plan for a Jira issue as local markdown from templates, reviews it in a loop, and produces a short plan to paste into Jira. |
| [`plan-review`](skills/plan-review/SKILL.md) | Reviews a plan before development against a checklist and writes a markdown report. Changes nothing else. |
| [`wayfinder`](skills/wayfinder/SKILL.md) | Maps a large effort as decision tickets and resolves them one at a time until the way is clear. |
| [`grilling`](skills/grilling/SKILL.md) | Interviews you in rounds of questions, each with a recommended answer, until you share an understanding. |
| [`domain-modeling`](skills/domain-modeling/SKILL.md) | Builds and sharpens the domain model: `GLOSSARY.md` and ADRs. |
| [`research`](skills/research/SKILL.md) | Investigates a question against primary sources in a background agent and saves the findings as markdown. |
| [`codebase-design`](skills/codebase-design/SKILL.md) | Shared vocabulary for designing deep modules, seams and testable interfaces. |
| [`prototype`](skills/prototype/SKILL.md) | Builds a throwaway prototype (logic demo or UI variants) to answer a design question. |

**Review**

| Skill | What it does |
| --- | --- |
| [`human-code-review`](skills/human-code-review/SKILL.md) | Quizzes the developer on a diff to confirm they understand the change, and improves code that is hard to follow. |
| [`human-plan-review`](skills/human-plan-review/SKILL.md) | Quizzes the developer on a plan file to confirm they understand it, and improves plan text that is hard to follow. |

**Utilities**

| Skill | What it does |
| --- | --- |
| [`signature`](skills/signature/SKILL.md) | Builds the signature line that marks AI-generated text, for markdown, GitHub or Jira. |
| [`solve-conflicts`](skills/solve-conflicts/SKILL.md) | Resolves every git conflict by merging the intent of both sides. Never takes one side wholesale. |

[Diagrams of how the skills fit together](docs/skill-diagrams.md): which skill uses which, where each fits in the work, and the flow inside `jira-planner`, `wayfinder` and the human reviews.

`gh-plan` and `gh-sync` are meant to be used together: plan first, then sync when the plan is approved. `human-plan-review` fits between the two: review the plan before you say Build. `jira-planner` is the Jira-flavoured, template-only counterpart: it uses `wayfinder`, `grilling`, `domain-modeling`, `plan-review` and, when needed, `research`, `codebase-design` and `prototype`.

### gh-plan

Run it as `gh-plan 210`, `/gh-plan 210`, or paste an issue URL. The skill:

1. Switches to Plan mode and fetches the issue with `gh`, including its body, comments, sub-issues and blocking relations.
2. Looks for an existing plan in `~/.cursor/plans/` and checks whether it is still valid.
3. Reads the codebase, answers what it can, and writes a plan draft. The draft contains a plain-language summary, decisions and assumptions, a PR plan of small PRs (~500 lines each, using existing sub-issues), a PR description template, follow-ups and QA steps.
4. Asks the open questions and **stops**. It writes no code and creates no branches, commits or PRs.

Answer the questions to refine the plan, or say **Build** to leave the skill. On Build, run `gh-sync` before you implement.

Requires an authenticated [GitHub CLI](https://cli.github.com/).

### gh-sync

Treats the plan as the source of truth and mirrors it to GitHub issues using only the `gh` CLI:

- **Tracking issue**: reuses the issue linked in the plan, or one found by title search. If neither exists, it creates one.
- **PR sub-issues**: each item in the PR plan becomes a sub-issue of the tracking issue (`--parent`), as long as the plan is not done.
- **Follow-ups**: out-of-scope and later work becomes separate issues, blocked by the tracking issue.
- **Relations and bodies**: sets GitHub `blocked-by` / `blocking` relations, not just markdown. Rewrites issue bodies when the plan's decisions or scope have changed.
- **Write-back**: puts the issue links back into the plan.

Running it again is safe. It does not create duplicates, post comments or close issues. Plans can be in English or Norwegian. Requires `gh` 2.94+ for sub-issues.

### human-plan-review

Adapted from `human-code-review`, but for plan files instead of diffs. It is invoked explicitly (`disable-model-invocation`). The skill:

1. Finds the plan (named file, active plan, or a pick from the usual plan locations such as `~/.claude/plans/`, `~/.cursor/plans/` and `docs/plans/`) and the tracking issue it names, and checks the plan against the current codebase.
2. Flags overlapping plans and unresolved decisions, so you aren't quizzed on things the plan leaves open.
3. Asks 2–7 multiple-choice questions on scope, reasoning, failure modes, dependencies and predictions, with randomised answer positions.
4. Diagnoses wrong answers as a knowledge gap, an unclear plan, or an unclear question, and offers to rewrite unclear parts of the plan (only with your approval).
5. Scores at a 70% threshold. On a pass it writes a human understanding statement with the plan's file name and content hash, and offers to post it on the tracking issue.

It never writes code or runs `gh-sync`.

### jira-planner

Invoked explicitly (`disable-model-invocation`), with an issue key and the issue text pasted by you. The skill:

1. Builds a decision map and does a teach-back, so you and the agent agree before any plan text is written.
2. Writes a detailed local plan from `plan-template.md`, stress-tests it, then reviews it with `plan-review-template.md` and fixes it, repeating until nothing is blocking or "should fix before start" (at most 5 rounds).
3. Derives a short plan from `jira-plan-template.md` that you paste into the issue's Plan field.
4. Only if you ask: writes one subtask description per PR from `subtask-description-template.md`, which you paste into subtasks you create yourself.

It reads and writes local files under `reports/` only. It does not call Jira (no MCP, REST or browser) and runs no scripts. It writes no code.

### plan-review

Collects the plan (pasted text, a file, or a PR description) and the goal, loads the project's rules, maps the affected code, and goes through every section of a checklist: goal and scope, structure, domain, technical risks, testing, process, strengths and severity. It writes `reports/plan-review-<key-or-slug>-<date>.md` and a short chat summary. It never edits the plan or an issue tracker.

### signature

Prints the one signature line for AI-generated text (`🤖 Generated with AI by <user> with <model> in <editor>`) as markdown, GitHub text, or a Jira ADF fragment, with an optional `Source:` line and `language=en|no`. The user is always the logged-in `gh` user, so there is nothing to set up per person. The signature contains no email address, and the Jira fragment has no mention.

### wayfinder, grilling, domain-modeling, research, codebase-design, prototype

Building blocks for planning. `wayfinder` charts a large effort as a map of decision tickets. `grilling` and `domain-modeling` resolve those decisions and keep the glossary and ADRs up to date. `research` gathers facts from primary sources, `codebase-design` gives the vocabulary for module and seam design, and `prototype` answers a design question with throwaway code. Each has a short `SKILL.md`; read it for details.

### solve-conflicts

Triggers when git reports unmerged paths or conflict markers, during a merge, rebase, cherry-pick, revert or stash. The skill:

- Maps every conflicted file first, and states which side is "ours" and which is "theirs" (they swap during a rebase).
- Resolves each file by type. Lockfiles are regenerated with the package manager, never hand-merged. Generated files are rebuilt from source. Delete/modify conflicts are decided by searching for usages. Content conflicts get a three-way merge that keeps unique changes from both sides.
- Checks that no unmerged paths or markers remain, then continues the ongoing operation.

It never takes a side wholesale (`--ours`/`--theirs`, `-X ours`), skips commits, aborts without asking, pushes, or leaves markers behind.

## Requirements

The skills that call tools have a `Requirements` section with a hard gate: if a requirement is missing, the skill stops and says what to fix instead of working around it. The planning building blocks (`wayfinder`, `grilling`, `domain-modeling`, `research`, `codebase-design`, `prototype`) need no tools beyond the agent itself; `wayfinder` uses an issue tracker, or local markdown when none is given.

| Skill | Requires |
| --- | --- |
| `gh-plan` | `gh`, authenticated; a repo `gh` can resolve; Plan mode |
| `gh-sync` | `gh` 2.94+ (for `--parent`), authenticated, with triage access or higher; an active plan |
| `human-code-review` | `git`, `origin/main`, `gh` (authenticated), `jq`, bash with `$RANDOM`. `gh stack` is optional |
| `human-plan-review` | a plan file, `git` or `sha256sum`, bash with `$RANDOM`; `gh` (authenticated) when the plan names a tracking issue |
| `jira-planner` | an issue key and the issue text pasted by you; a writable `reports/` directory; the code checked out |
| `plan-review` | the plan text, a writable `reports/` directory, the code readable; `gh` (authenticated) if the plan is in a PR |
| `signature` | bash and `gh`, authenticated |
| `solve-conflicts` | `git` and something to resolve; the package manager if a lockfile conflicts |

## Install

With the [`skills`](https://www.skills.sh/) CLI:

```bash
npx skills add GauteR/gauter-skills
```

Or manually: copy `skills/<name>/` into your agent's skills directory (for example `.claude/skills/` or `.agents/skills/`).

## Language

The skills are written in English and reply in the language the developer uses.

## Contributing

Issues and pull requests are welcome. They are read on a best-effort basis, with no response time guaranteed.

## Credits

| Skills | From | Licence | Notes |
| --- | --- | --- | --- |
| `grilling`, `research`, `wayfinder`, `domain-modeling`, `codebase-design`, `prototype` | [mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock | MIT | Copied, with their supporting files. `domain-modeling`, `codebase-design` and `prototype` match the upstream text; `grilling`, `research`, `wayfinder` and `codebase-design/DESIGN-IT-TWICE.md` are earlier upstream versions, so check upstream for newer wording. |
| `human-code-review` | [NationalLibraryOfNorway/tibi-skills](https://github.com/NationalLibraryOfNorway/tibi-skills) by the National Library of Norway | MIT | Copied. |
| `human-plan-review` | `human-code-review` above | MIT | Adapted from it for plan files. |

The ideas behind `codebase-design` are credited inside the skill: the term *seam* comes from Michael Feathers, and *deep modules* and *Design It Twice* from John Ousterhout (*A Philosophy of Software Design*).

The other skills (`gh-plan`, `gh-sync`, `jira-planner`, `plan-review`, `signature`, `solve-conflicts`) were written by the repository author. `gh-plan` and `gh-sync` refer to the `superpowers` skills by name only; nothing is copied from them.

The copyright and permission notices that the MIT licence requires are in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Licence

[MIT](LICENSE). The skills listed under [Credits](#credits) remain under their original copyright; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
