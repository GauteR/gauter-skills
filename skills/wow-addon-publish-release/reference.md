# Release and install script contract

This is the contract that the scripts of a scaffolded World of Warcraft Forever addon follow. It is self-contained: everything needed to write or check the scripts is here. `myaddon` stands for the lowercase addon name and is used as the package name everywhere.

Release flow in one paragraph: the maintainer runs the release script. A real release runs the tests, updates `CHANGELOG.md` from git, commits it if it changed, creates and pushes the annotated tag `v{Config.VERSION}`, builds the zip with the vendored packager and creates a GitHub Release with `gh`. The pushed tag triggers the CurseForge webhook (set up once on the GitHub repository, tied to the CurseForge project's API key), and CurseForge packages and uploads. The scripts upload nothing to CurseForge, hold no token, read no `.env` file and have no Wago support. They need neither `curl` nor `jq`. They do need `lua`: the changelog step runs `scripts/update_changelog.lua` in every release run, a dry-run included and also with skip-tests.

## (a) Files of a scaffolded addon

| File | Purpose |
| --- | --- |
| `myaddon/myaddon.toc` (inside the nested addon folder) | Addon manifest. `## Version: @project-version@` is replaced when packaging, and by `publish-local` in the copied TOC. `## Interface: 16001` stays. `## X-Curse-Project-ID` is added once the CurseForge project exists |
| `myaddon/Config.lua` | Holds `Config.VERSION`, the single source of truth for the version, plus feature flags. The release and publish-local scripts match a line-anchored pattern: a line that starts, after optional whitespace, with `VERSION = "1.2.3"`. Put `VERSION` on its own line as a table field. A one-line form such as `Config = { VERSION = "1.2.3" }` or `Config.VERSION = "1.2.3"` is not found, and the scripts fail. (`release_meta.parse_version` is looser, see section d, and is only used by the tests.) |
| `scripts/publish-local.sh`, `scripts/publish-local.ps1` | Copy the addon folder to the local Forever AddOns directory for in-game testing (section c) |
| `scripts/release.sh`, `scripts/release.ps1` | Test, update the changelog, tag, package and create the GitHub Release (section b) |
| `scripts/release_meta.lua` | Pure Lua: parse the version from Config text, version to tag, zip name (section d) |
| `scripts/changelog_meta.lua` | Pure Lua: conventional commit subjects to Keep a Changelog text (section d) |
| `scripts/update_changelog.lua` | Command line entry that writes `CHANGELOG.md` from commit subjects on stdin (section d) |
| `scripts/forever-addons.path.example` | Template for the local, gitignored `scripts/forever-addons.path` (section c). Its first line is a comment, then one line with the AddOns directory |
| `tests/test_release_meta.lua`, `tests/test_changelog_meta.lua`, plus the addon's own logic tests | Pure Lua tests, run with `lua tests/<file>`. The release scripts run every test file. `publish-local` runs only the addon's own logic tests, not the release-helper tests (`test_release_meta.lua`, `test_changelog_meta.lua`) |
| `.release/release.sh` | Vendored packager (section f). Output goes to `.release/` (keep that folder out of git) |
| `.pkgmeta`, `.luarc.json` | Packaging and editor configuration (section e) |
| `CHANGELOG.md` (repository root) | Keep a Changelog file. CurseForge reads it, and `.pkgmeta`, on the tagged commit |
| `docs/RELEASE.md`, `docs/CURSEFORGE.md` | Release instructions (no tokens) and the user-facing CurseForge description |
| `README.md`, `LICENSE` | Project documentation and the MIT licence |

## (b) Release script contract

Files: `scripts/release.sh` (bash) and `scripts/release.ps1` (PowerShell 5.1+). They behave the same, except for the differences listed under "Differences between the bash and PowerShell scripts" below. Both run from the repository root, whatever the current directory is. Constants at the top of each script: the package name, the relative path of `Config.lua` and the relative path of `CHANGELOG.md`.

### Flags

| Meaning | bash | PowerShell |
| --- | --- | --- |
| Dry-run: tests and a local zip only | `--dry-run` (also `-d`) | `-DryRun` |
| Skip the Lua tests | `--skip-tests` | `-SkipTests` |
| Extra packager arguments | any unrecognised argument, or everything after `--` | any remaining arguments (`ValueFromRemainingArguments`) |
| Help (bash) | `-h`, `--help` prints the usage comment | comment-based help |

Extra arguments are appended to the packager command line after the script's own packager flags.

### Primary-checkout check

The packager needs a `.git` directory. In a linked worktree `.git` is a file, so the script stops with an error saying to run the release from the primary checkout. It does this first, before anything else.

### Step order, dry-run

1. Check the primary checkout.
2. Run every test file unless skipped (each with `lua`; fail if `lua` is missing, saying to install Lua or skip the tests; any failing test aborts).
3. Resolve `Config.VERSION` (fail with a clear message if `Config.lua` or the version is missing). The match is line-anchored, see section a.
4. Check that `.release/release.sh` exists, otherwise fail and say to restore the pinned packager. This is the bash order; the PowerShell script checks later (see "Differences between the bash and PowerShell scripts").
5. Update `CHANGELOG.md` from git, without committing (see "Changelog step" below). This needs `lua` even when the tests are skipped.
6. Add `-d` to the packager arguments.
7. Clear the GitHub token variables.
8. If there is no real `zip`, add `-z` to the packager arguments (the packager then skips the zip and the script makes it in step 11).
9. Append extra arguments and run the packager: `bash .release/release.sh <args>`. The PowerShell script finds Git Bash (never the WSL launcher in the Windows system directory), converts the repository path to a Git Bash path and calls it with `bash -lc`.
10. Verify the packaged tree: `.release/myaddon/myaddon.toc` must exist, and `docs`, `tests` and `scripts` must not exist inside `.release/myaddon/`.
11. Only if the packager skipped the zip: read `## Version:` from the packaged TOC and create the zip (see "Zip naming" and "Zip creation").
12. Print the artifacts: every `.release/*.zip` with its size in KB.

No commit, no tag, no push, no `gh`.

### Step order, real release

1. Check the primary checkout.
2. Run the tests unless skipped.
3. Resolve `Config.VERSION`; the release tag is `v` plus that version.
4. Check that `.release/release.sh` exists (bash order; see "Differences between the bash and PowerShell scripts").
5. Update `CHANGELOG.md` from git and commit it if it changed. This needs `lua` even when the tests are skipped.
6. Ensure the annotated tag and push it (see "Tag rules").
7. Clear the GitHub token variables.
8. Zip tool check, extra arguments and the packager call as in dry-run steps 8 and 9 (no `-d`).
9. Verify the packaged tree, create the fallback zip if needed, as in dry-run steps 10 and 11.
10. Create the GitHub Release, or upload the zip to an existing one (see "GitHub Release").
11. Print the artifacts.

The tag is pushed before the packager runs, so the CurseForge webhook can already be working while the local zip is built. The script does not wait for it and does not check it.

Order that matters: the changelog commit comes before the tag, because CurseForge reads `CHANGELOG.md` and `.pkgmeta` on the tagged commit.

### Differences between the bash and PowerShell scripts

- Check for `.release/release.sh`. The bash script checks it early, before the changelog step. The PowerShell script updates the changelog first (and commits it in a real release), then looks up Git Bash, then checks that `.release/release.sh` exists, and only after that creates and pushes the tag. So in PowerShell a missing vendored packager is found after the changelog commit, but still before the tag.
- Zip tool. In `release.ps1` the decision to pass the packager `-z` flag comes from a `zip` check run inside Git Bash, while the check inside the PowerShell zip function runs in the PowerShell session. The two can disagree (for example `zip` exists in Git Bash but not in PowerShell). Python order also differs: `release.ps1` tries `python` then `python3`, the bash script tries `python3` then `python`.

### Changelog step

1. Find the previous version tag: the newest tag matching `v*` (sorted by version, newest first) that is not the tag being released.
2. Range: `<previous-tag>..HEAD`, or just `HEAD` when there is no previous tag.
3. Collect the commit subjects: `git log <range> --no-merges --pretty=format:%s`. In PowerShell write them to a temporary file as UTF-8 without BOM before piping them, so no byte order mark ends up in the subjects.
4. Run `lua scripts/update_changelog.lua <version> <UTC date YYYY-MM-DD> <path to CHANGELOG.md> --notes-out <temporary notes file>` with the subjects on stdin. Fail if `lua` is missing or the script fails. Remove the temporary subject file afterwards; the notes file is kept for the GitHub Release.
5. Only in a real release: `git add -- CHANGELOG.md`; if the staged diff of that file is empty print that it is unchanged, otherwise commit with `git commit --only -m "docs: update CHANGELOG for v<version>" -- CHANGELOG.md`. `--only` keeps other staged files out of this commit.

### Tag rules

- The tag is `v{Config.VERSION}` and annotated: `git tag -a v<version> -m v<version>`.
- If the tag does not exist, create it on HEAD.
- If it exists and points at HEAD, reuse it.
- If it exists and points at another commit, fail with an error that names both commits.
- Push it: `git push origin refs/tags/v<version>`. Failure to create or push is fatal.
- Dry-run never creates or pushes a tag. Without a tag the packager treats the build as an alpha.

### GitHub token clearing

Before the packager call, clear `GH_API_TOKEN`, `GITHUB_API_TOKEN` and `GITHUB_OAUTH` from the script's own environment (`unset` in bash, set to `$null` at process scope in PowerShell). The release script owns the GitHub Release through `gh`, so the packager must not find a token and make a duplicate GitHub upload of its own.

### Zip naming

The packager names the archive from the git tag, not from the bare version: `<package>-v<version>-forever.zip` in `.release/`. If the version already starts with `v` or `V`, no second `v` is added. When the script makes the zip itself (the fallback), it takes the version from the packaged TOC (`## Version:`; `unknown` if absent) and applies the same rule, so the name matches what the packager would have made. `release_meta.forever_zip_name` encodes this rule (section d).

### Zip creation (fallback only)

Normally the packager makes the zip. If there is no `zip` (checked in Git Bash for the PowerShell script; the zip function itself then checks in the PowerShell session, see "Differences between the bash and PowerShell scripts"), the script passes `-z` and creates a real zip of the packaged folder itself, with the addon folder as the single top-level directory:

1. `zip -r <zip> <addon folder>` if `zip` exists,
2. else Python with `shutil.make_archive` (bash: `python3`, then `python`; PowerShell: `python`, then `python3`),
3. else (PowerShell only) `Compress-Archive`,
4. else (bash) fail saying that `zip` or Python is needed.

Never use Windows `tar.exe -a`: it often writes a tar stream with a `.zip` name, and CurseForge rejects it ("Failed to verify archive"). Delete any existing zip with the same name first.

### GitHub Release

Real release only. Fail if `gh` is not on PATH (say to install it and run `gh auth login`) or if no zip is found.

1. Pick the zip: `.release/<package>-v<version>-forever.zip` if it exists, otherwise the first `.release/<package>-*.zip`.
2. Notes: `--notes-file <notes file from the changelog step>` when that file exists, otherwise `--generate-notes`.
3. If `gh release view v<version>` succeeds the release exists: `gh release upload v<version> <zip> --clobber` (the notes are left alone).
4. Otherwise: `gh release create v<version> --title v<version> <notes args> <zip>`.

## (c) publish-local contract

Files: `scripts/publish-local.sh` and `scripts/publish-local.ps1`. Purpose: copy the addon into the local Forever `Interface\AddOns` folder for testing.

### Flags

| Meaning | bash | PowerShell |
| --- | --- | --- |
| Destination AddOns directory | `--destination <path>` (also `-d`) | `-Destination <path>` |
| Skip the Lua tests | `--skip-tests` | `-SkipTests` |
| Show what would happen, write nothing | `--dry-run` (also `--what-if`) | `-WhatIf` |

An unknown argument is an error in bash.

### Resolving the destination

First match wins:

1. The flag.
2. An environment variable named after the addon, for example `MYADDON_FOREVER_ADDONS`.
3. `scripts/forever-addons.path`: a gitignored file created from the `.example`. Blank lines and lines starting with `#` are ignored; the first remaining line is the path.
4. A short list of typical Forever install locations, used only if one of them exists.

If nothing resolves, fail with a message that lists the three explicit options. In every case, if the path ends in the addon folder name, use its parent: the destination is always the AddOns directory, and the addon folder is appended. The resolved directory must exist, otherwise fail.

### Steps

1. Check that the addon source has its TOC (`<addon>/<addon>.toc`), otherwise fail.
2. Run the addon's own logic tests unless skipped (fail if `lua` is missing, saying to install Lua or skip the tests). It does not run the release-helper tests (`test_release_meta.lua`, `test_changelog_meta.lua`). Unlike the release scripts, `publish-local` needs no `lua` at all with skip-tests.
3. Resolve the destination; target is `<AddOns>/<addon>`.
4. Read `Config.VERSION` from `<addon>/Config.lua` with the same line-anchored match as the release script (a line starting, after optional whitespace, with `VERSION = "x.y.z"`); fail if it cannot be read.
5. With the dry-run flag: print what would be replaced and the TOC version, then stop.
6. Delete the target if it exists, create it, and copy the contents of the source addon folder into it (the contents, not an extra nesting level).
7. Check that the copied TOC exists.
8. In the COPIED TOC only, replace every `@project-version@` with `Config.VERSION` (the AddOn List then shows a real version). The source TOC is never modified. In PowerShell write the file as UTF-8 without BOM.
9. Tell the user to run `/reload` in game, or restart the client.

## (d) Pure Lua helper modules and their tests

All three modules are plain Lua 5.1 with no WoW API, so they run with a stock `lua`. Each module returns a table `M`. Tests set `package.path` from `arg[0]` so they run from any directory, count failures, print `PASS:` or `FAIL:` per assertion and `os.exit(1)` if anything failed.

### release_meta.lua

```lua
M.parse_version(config_text)               -- string -> string | nil
M.version_tag(version)                     -- string -> string | nil
M.forever_zip_name(package_name, version)  -- string, string -> string | nil
```

- `parse_version`: the first match of `VERSION%s*=%s*"([^"]+)"` anywhere in the text (looser than the scripts, which require `VERSION` at the start of a line; it is only used by the tests); `nil` if the argument is not a string or there is no match.
- `version_tag`: `"v" .. version`; `nil` if not a string or empty.
- `forever_zip_name`: `<package>-v<version>-forever.zip`; the `v` is added only if the version does not already start with `v` or `V`; `nil` if either argument is not a string or is empty.

Tests must cover:

- `parse_version('VERSION = "1.2.3",')` returns `"1.2.3"`.
- Text without a version returns `nil`.
- `version_tag("1.2.0")` returns `"v1.2.0"`; `version_tag("")` returns `nil`.
- `forever_zip_name("myaddon", "1.2.0")` returns `"myaddon-v1.2.0-forever.zip"`.
- The real `myaddon/Config.lua` has a non-empty version, and its tag and zip name follow the rules above.

### changelog_meta.lua

Category order, fixed: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

Conventional commit type to category (the type is matched case-insensitively):

| Category | Types |
| --- | --- |
| Added | `feat`, `feature` |
| Fixed | `fix`, `bugfix` |
| Removed | `remove`, `removed`, `revert` |
| Deprecated | `deprecate`, `deprecated` |
| Security | `security` |
| Changed | `docs`, `doc`, `chore`, `refactor`, `perf`, `style`, `test`, `build`, `ci`, `change`, `changed`, and anything unprefixed or unknown |

```lua
M.parse_subject_lines(text)                           -- string -> { string }
M.classify_subject(subject)                           -- string -> category | nil
M.strip_conventional_prefix(subject)                  -- string -> string
M.build_version_section(version, date, subjects)      -- -> string
M.merge_changelog(existing_text, version, date, subjects)  -- -> string
M.extract_version_notes(changelog_text, version)      -- -> string | nil
```

- `parse_subject_lines`: split on newlines, trim each line, drop empty lines.
- `classify_subject`: reads `type(scope):` or `type:` at the start; returns the category from the table, `"Changed"` for no or unknown type, `nil` for an empty or whitespace-only subject or a non-string.
- `strip_conventional_prefix`: removes the `type(scope):` or `type:` prefix and trims; a subject without a prefix is returned unchanged (trimmed).
- `build_version_section`: `## [<version>] - <date>`, then for each non-empty category in the fixed order a `### <Category>` heading and `- <subject without prefix>` bullets, with blank lines between. With no entries it writes `### Changed` and `- Maintenance release`.
- `merge_changelog`: the standard header ("Changelog", the Keep a Changelog and Semantic Versioning sentences) and `## [Unreleased]` are added if the text is empty or lacks them. If a section for the same version exists it is replaced in place (new date, new body). Otherwise the new section is inserted directly after `## [Unreleased]`, above older versions. Output ends with a single newline.
- `extract_version_notes`: the body of the version's section (without its heading), up to the next `## [` heading or the end, trimmed, plus a trailing newline; `nil` if the version is missing or the body is empty.

Tests must cover:

- Classification: `feat`, `feat(ui)`, `fix`, `fix(core)`, `remove`, `deprecate`, `security`, `docs`, `chore`, an unprefixed subject, an empty subject and a whitespace-only subject.
- Prefix stripping: with a scope, and an unprefixed subject kept as is.
- `build_version_section` with one feat, one fix and one docs subject: heading with version and date, the three category headings and their bullets.
- `merge_changelog` with `nil` existing text: header, `[Unreleased]`, version section and bullet.
- Replacing the same version: new date and body present, old entry gone.
- Inserting a newer version into a file that has an older one: after `[Unreleased]` and before the older version.
- `extract_version_notes`: contains the category heading and bullet; unknown version returns `nil`.
- `parse_subject_lines("feat: a\n\nfix: b\n")` gives two subjects in order.

### update_changelog.lua

Command line entry, not a library:

```text
git log <range> --no-merges --pretty=format:%s | lua scripts/update_changelog.lua <version> <YYYY-MM-DD> [CHANGELOG.md] [--notes-out <path>]
```

- Arguments 1 and 2 are required; if either is missing or empty print the usage to stderr and exit 1.
- The path defaults to `CHANGELOG.md`. Any other argument after the date is the changelog path; `--notes-out` takes the next argument as the notes path.
- It puts its own directory on `package.path` (taken from `arg[0]`) and requires `changelog_meta`, so it works from any working directory.
- It reads all of stdin, parses the subjects, reads the existing changelog if the file exists, merges, and writes the file.
- With `--notes-out` it writes the notes of that version, or `Release <version>` if the section cannot be found.
- It prints `Updated <path> for [<version>] - <date> (<n> commit subject(s))`.

It has no test file of its own; it is exercised through `changelog_meta` and by a dry-run.

## (e) .pkgmeta and .luarc.json essentials

### .pkgmeta

```yaml
package-as: myaddon

move-folders:
  myaddon/myaddon: myaddon

manual-changelog: CHANGELOG.md

ignore:
  - docs
  - tests
  - reports
  - scripts
  - README.md
  - .luarc.json
  - .github
  - CHANGELOG.md

enable-nolib-creation: no
```

- `package-as` equals the AddOns folder name.
- `move-folders` flattens the nested project layout (repository root, then the addon folder) into one flat addon folder.
- `manual-changelog` points at the root `CHANGELOG.md`, which is generated by `update_changelog.lua`. The file stays in `ignore` so it is not shipped inside the addon folder; the packager and CurseForge still read it from the checkout.
- `ignore` keeps docs, tests, reports, scripts and editor files out of the package. The release script fails if `docs`, `tests` or `scripts` end up in it.

### .luarc.json

- `runtime.version` is `Lua 5.1`; the builtin libraries are left at `default`.
- `diagnostics.globals` lists the addon global and every WoW global the addon uses, for example `CreateFrame`, `DEFAULT_CHAT_FRAME`, `UIParent`, `UISpecialFrames`, `tinsert`, `SlashCmdList`, `SLASH_MYADDON1`, `GameTooltip`, `Settings`, `C_AddOns`. Add each new global as it is used; do not disable the undefined-global diagnostic.
- `workspace.checkThirdParty` is `false`.
- `$schema` points at the Lua language server settings schema.

## (f) The vendored packager

`.release/release.sh` is BigWigsMods/packager v2.7.0 (https://github.com/BigWigsMods/packager), a third-party tool that is not part of this repository. GitHub detects no standard licence for it. Check its licence terms before vendoring it into an addon repository, and before redistributing the addon repository with it included. Pin the version, and do not change the vendored file by hand. When bumping the pin, read the packager's own documentation first.

The packager is used only for the local dry-run zip and for the zip attached to the GitHub Release. It reads `.pkgmeta`, replaces `@project-version@` and writes `.release/myaddon/` and the zip. It needs a primary checkout (a `.git` directory) and bash (Git Bash on Windows, never the WSL launcher).
