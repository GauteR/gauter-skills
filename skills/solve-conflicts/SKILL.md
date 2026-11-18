---
name: solve-conflicts
description: Use when git has unmerged paths, conflict markers (<<<<<<< ======= >>>>>>>), mergetool, MERGE_HEAD, REBASE_HEAD, CHERRY_PICK_HEAD, REVERT_HEAD, stash pop/apply conflicts, or the user asks to solve conflicts, fix merge conflicts, or resolve rebase conflicts.
disable-model-invocation: true
---

# solve-conflicts

Announce: "Using solve-conflicts."

**Core:** Resolve *all* conflicts by understanding the intent of both sides. The default is a three-way merge, never a whole file taken from one side.

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| `git`, inside a work tree | everything | `git rev-parse --is-inside-work-tree` prints `true` |
| Unmerged paths or an operation in progress | there is something to resolve | `git ls-files -u` prints paths, or `MERGE_HEAD` / `REBASE_HEAD` / `CHERRY_PICK_HEAD` / `REVERT_HEAD` exists |
| The project's package manager, **only if a lockfile conflicts** | regenerating the lockfile | the manager's `--version` succeeds |

**Hard gate.** Run the checks before mapping files. If any fails, stop and say which requirement is missing. With nothing to resolve, say so and change nothing. Do not hand-merge a lockfile because the package manager is missing.

## Map before you touch files

```
git status
git diff --name-only --diff-filter=U
git ls-files -u
```

Identify the operation: `MERGE_HEAD` / `REBASE_HEAD` / `CHERRY_PICK_HEAD` / `REVERT_HEAD`.

| Operation | ours (`:2`) | theirs (`:3`) |
| --- | --- | --- |
| merge, cherry-pick, revert, stash | HEAD (the branch you are on) | incoming |
| rebase | the branch you are rebasing *onto* | the commit being replayed |

List **all** conflicted files. Resolve all of them in the same round. Do not stop after the first.

```
git show :2:PATH   # ours
git show :3:PATH   # theirs
git show :1:PATH   # base (if it exists)
```

## Resolve per file

Classify, then resolve:

1. **Lockfile** (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `Cargo.lock`, `go.sum`, `poetry.lock`, `composer.lock`): resolve the manifest first (`package.json` etc.). Regenerate the lockfile with the package manager (`pnpm install`, `npm install`, …). **Do not hand-merge lockfiles** — not even "simple" stubs. If you cannot run install: stop and say so. Do not stage `node_modules/` or other install artefacts.
2. **Generated** (`dist/`, `*.min.*`, codegen): regenerate from source after the source is resolved.
3. **Binary / submodule**: pick one side based on intent. Never splice together.
4. **Deleted vs modified** (`deleted by us` / `deleted by them`): read both commits and search the tree for uses of the symbol. Keep the file if the other side added unique behaviour that exists nowhere else. Delete only when deletion is the functional intent (moved, replaced, deliberately removed) **and** the modification has no unique behaviour. "Nothing imports it right now" is not enough on its own.
5. **Both added** the same path: merge the content, do not overwrite.
6. **Content conflict**: three-way. Keep unique changes from both sides. Remove all markers. No "resolved" comments.

Content rules:

- Imports: union, no duplicates, the file's existing style
- Two new functions/keys: keep both
- Same function changed differently: merge the logic — not two copies one after the other
- Tests and i18n: union when they do not contradict; keep keys/translations from both
- Non-ASCII text (for example æ, ø, å): preserve it exactly

After each file: no `<<<<<<<` / `=======` / `>>>>>>>`. Then `git add PATH` (or `git rm PATH` for a deliberate deletion). Not `git add -A`.

## After all files

```
git diff --name-only --diff-filter=U
git diff --check
git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- .
```

Zero unmerged, zero markers. Continue the **ongoing** operation:

- merge: `git merge --continue` (or `git commit` only if git requires it for *this* merge)
- rebase: `git rebase --continue` (set the editor to non-interactive, e.g. `GIT_EDITOR=true`)
- cherry-pick / revert: `--continue`

New conflict in the next rebase commit? Loop from mapping. Do not stop with a half-finished rebase.

Do not create commits other than continuing the ongoing operation. Do not start a new merge/rebase. Do not push. No `--abort` unless the user asks for it.

## Forbidden

- `git checkout --ours/--theirs .` or `-X ours` / `-X theirs` on the whole tree
- `git rebase --skip` unless the commit is empty *and* its changes are already in HEAD
- Interactive mergetool, `git add -i`, `git rebase -i`
- Force push, skipping hooks, changing `git config`
- Leaving markers "for later"
- Dropping one side's unique functionality to get done
- Hand-merged lockfile

## Excuses

| Excuse | Reality |
| --- | --- |
| "Take theirs, it's newer / the user said hurry" | Newer ≠ correct. Merge the intent. Time pressure does not change this. |
| "I'll fix the lockfile by hand, it's small" | Regenerate. Hand-merging corrupts the lock. |
| "One file can wait" | Resolve all. A half merge is a broken tree. |
| "Skip this commit" | Skip throws away work. Resolve. |
| "Abort and start over" | Only if the user asks for it. |
| "Deleted by us, and nothing imports it" | Search for uses and read why the other side changed it. Then decide. |
| "On rebase, ours is the local commit" | Wrong. On rebase, ours is *upstream* and theirs is *the commit being replayed*. |

## Red flags

Whole-tree `--ours/--theirs`, `-X ours/theirs`, `rebase --skip`, `--abort` without asking, leftover markers, hand-merged lockfile, duplicated functions after a "merge", `git add -A`, stopping after the first conflicted file.

## Examples

See [examples.md](examples.md).
