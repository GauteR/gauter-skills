---
name: wow-addon-publish-release
description: Local World of Warcraft Forever publish and BigWigs packager release for addons. Covers publish-local, the dry-run zip, CHANGELOG.md (Keep a Changelog) generated from git, annotated release tags, the CurseForge GitHub webhook that packages and uploads from the pushed tag, the gh GitHub Release with changelog notes, and the CurseForge TOC project ID. Use for install, publish-local, release, packager, CurseForge or GitHub Release.
---

# WoW addon publish & release (Forever)

"Forever" means World of Warcraft Forever. The release flow is: the maintainer runs the **release script** (`scripts/release.sh` or `scripts/release.ps1`). It runs the tests, updates `CHANGELOG.md`, creates the **release tag** `v{Config.VERSION}` and pushes it. The pushed tag is what the **CurseForge webhook** reacts to, so the scripts upload nothing to CurseForge and hold no CurseForge token.

Contract for the scripts, tests, `.pkgmeta` and `.luarc.json`: [reference.md](reference.md) (release and install script contract).

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| `bash` (on Windows: Git Bash, not the WSL `bash.exe` launcher) | the release script and the packager | `bash --version` succeeds, and it is Git Bash, not the WSL launcher |
| A primary checkout, not a linked worktree | the packager needs a `.git` directory | `git rev-parse --git-dir` prints `.git` |
| `lua` on PATH | the changelog step of the release script (always, also with `-SkipTests` / `--skip-tests`, in a dry-run and in a real release), and the tests. Only `publish-local` can run without `lua`, and only with skip-tests | `lua -v` succeeds |
| A real zip tool: `zip` in Git Bash, or the Python / `Compress-Archive` fallback | the dry-run zip and the zip attached to the GitHub Release | `zip -v` succeeds, or `python --version` / `Compress-Archive` is available. Not Windows `tar.exe -a` |
| `gh` on PATH and logged in (conditional: real release only, not dry-run) | the GitHub Release | `gh auth status` succeeds |
| The CurseForge GitHub webhook already set up on the GitHub repository (conditional: real release only; one-time setup) | CurseForge packaging and upload from the pushed tag | The script cannot check it. Ask the user to confirm it before the first real release |

**Hard gate.** Check before starting. If a required item is missing, stop and say what to fix. Do not work around it: no WSL launcher, no linked worktree, no tar-as-zip, no script-side upload to CurseForge, no tokens in the repository. A dry-run needs only the unconditional rows, which include `lua`: the release script fails without it, even with skip-tests, because the changelog step runs Lua. Only `publish-local --skip-tests` works without `lua`.

## One-time setup

1. Create the CurseForge project for the addon and write its description from `docs/CURSEFORGE.md` (see "CurseForge description").
2. Set up the CurseForge GitHub webhook on the GitHub repository, tied to the CurseForge project's API key, by following CurseForge's own documentation. Do not write webhook URLs or menu paths from memory; read the current documentation (see "Works with other skills").
3. Add `## X-Curse-Project-ID` to the TOC once the project exists.
4. From then on, releases happen by running the release script. The API key lives only in the webhook setup on GitHub and CurseForge and must never be in the repository.

## Local install (dev)

```powershell
.\scripts\publish-local.ps1
```

```bash
./scripts/publish-local.sh
```

- Copies the addon folder to the Forever `Interface\AddOns`
- Path override: `-Destination` / `--destination`, an environment variable, or `scripts/forever-addons.path` (from `scripts/forever-addons.path.example`)
- Replaces `@project-version@` in the copied TOC with `Config.VERSION` (AddOn List)
- Runs the addon's own logic tests unless `-SkipTests` / `--skip-tests` (needs `lua`; with skip-tests it does not)
- Then `/reload` in game

See [reference.md](reference.md#c-publish-local-contract) for the full contract.

## Release prerequisites

See "Requirements" for the checks. In addition:

- `lua` is required for every release run, dry-run included, even with `-SkipTests` / `--skip-tests`: the changelog step runs `scripts/update_changelog.lua`. Skipping the tests does not remove that need
- `Config.VERSION` must be on its own line in `Config.lua`, as `VERSION = "x.y.z"` (a line that starts, after optional whitespace, with `VERSION`). The scripts match line-anchored, so a one-line form such as `Config = { VERSION = "1.2.3" }` or `Config.VERSION = "1.2.3"` is not found (see [reference.md](reference.md#a-files-of-a-scaffolded-addon))
- Do **not** use Windows `tar.exe -a` as a zip: it often makes a tar with a `.zip` name, and CurseForge rejects it ("Failed to verify archive")
- The packager is vendored as `.release/release.sh` and pinned to BigWigsMods/packager v2.7.0 ([third-party tool](https://github.com/BigWigsMods/packager); check its licence terms before vendoring, see [reference.md](reference.md#f-the-vendored-packager)). It is used for the local dry-run zip and for the zip attached to the GitHub Release
- No tokens and no `.env` files: the release script holds no CurseForge token, and GitHub goes through `gh`. The CurseForge API key exists only in the webhook setup and **never in the repository**

## Versioning

1. Bump `Config.VERSION` before release
2. Update the root `CHANGELOG.md` (Keep a Changelog) from the commits since the previous `v*` tag via `scripts/changelog_meta.lua` / `update_changelog.lua` (conventional commits to Added/Fixed/Changed/...). Dry-run writes the file without committing; a real release commits it if it changed, **before** the tag (CurseForge reads the root `CHANGELOG.md` and `.pkgmeta` on the tagged commit)
3. In a real release (not dry-run): create the annotated **release tag** `v{Config.VERSION}` on HEAD if it is missing (fail if the tag already exists on another commit), then **push the tag** to `origin`. The push is what triggers the **CurseForge webhook**, which packages and uploads from the tag. Then `gh release create` with notes from the CHANGELOG section and the Forever zip (or `gh release upload --clobber` if the release exists). Manually: `git tag -a v1.1.0 -m "v1.1.0" && git push origin refs/tags/v1.1.0`
4. TOC: `## Version: @project-version@` is replaced when packaging
5. Without a tag (for example dry-run): the packager treats the build as alpha
6. The wrappers clear `GH_API_TOKEN` / `GITHUB_API_TOKEN` / `GITHUB_OAUTH` before the packager so it does not make a duplicate `upload_github`
7. `.pkgmeta`: `manual-changelog: CHANGELOG.md` (the file stays in `ignore`)
8. New addons get the release wrappers, the `changelog_meta` / `release_meta` / `update_changelog` helpers and their tests as specified in [reference.md](reference.md#d-pure-lua-helper-modules-and-their-tests)

Optional before a real release: run human-code-review on the release branch's own diff (see "Works with other skills").

## Commands

Dry-run (tests + local zip; no commit, no tag, no push, no gh; still needs `lua` for the changelog step):

```powershell
.\scripts\release.ps1 -DryRun
```

```bash
./scripts/release.sh --dry-run
```

Real release: the same without the dry-run flag. It runs the tests (unless skipped), updates `CHANGELOG.md` from git (needs `lua`, also with skip-tests), commits it if it changed, creates the annotated tag `v{Config.VERSION}` on HEAD, pushes that tag to `origin` (which triggers the CurseForge webhook) and creates the GitHub Release with the zip. It requires `gh` and the one-time setup above (the CurseForge webhook on the repository). The scripts do not upload to CurseForge.

Add `## X-Curse-Project-ID` to the TOC when the project exists.

## .pkgmeta check

- `package-as` matches the AddOns folder name
- `move-folders` flattens nested VCS to a flat addon
- `manual-changelog: CHANGELOG.md`
- `ignore`: docs, tests, reports, scripts, `CHANGELOG.md`, `.luarc.json`, ...

See [reference.md](reference.md#e-pkgmeta-and-luarcjson-essentials) for `.pkgmeta` and `.luarc.json`.

## CurseForge description

Every addon repo should have `docs/CURSEFORGE.md`. Write the user-facing description below a `---` line and paste that text into the CurseForge project when it is published.

## Works with other skills

Integrations are optional and never override this skill's own hard rules.

| When | Skill | How |
| --- | --- | --- |
| `CHANGELOG.md` conflicts between release branches | `solve-conflicts` | `CHANGELOG.md` is generated from git by `update_changelog.lua`, so rebuild it from source instead of hand-merging it. Let `solve-conflicts` handle the rest of the conflict set (it regenerates generated files from the resolved source and never takes a whole file from one side) |
| Before a real release | `human-code-review` | Optional. Run it on the release branch's own diff (it finds the base itself, from the stack or `origin/main`) so the person releasing understands what ships. It quizzes the developer on the actual diff and has its own requirements, see that skill |
| Bumping the pinned packager version, or when the CurseForge webhook or packaging behaviour changes | `research` | Research the primary sources first (the packager's own repository and CurseForge's documentation), then write the findings down, before changing the pin or the setup |
| Posting text about the release yourself (PR or issue comment) | `signature` | Sign the text. Do not add a signature to the GitHub Release notes: they come from `CHANGELOG.md` |

## Security

- [ ] No tokens in git
- [ ] Dry-run before the first real release
- [ ] Interface stays `16001` in the packaged TOC
- [ ] No CurseForge API key anywhere in the repository

## Examples

See [examples.md](examples.md).
