---
name: wow-addon-scaffold
description: >-
  Scaffold a new World of Warcraft Forever addon (Interface 16001) with a nested
  folder, TOC, Config feature flag, Core, Locale, .pkgmeta, .luarc.json, pure Lua
  tests, and a release flow built on a release script, a release tag and a
  CurseForge webhook (CurseForge only). Use for a new addon, a new module
  structure, or when the user asks to create or start a Forever addon.
---

# Wow addon scaffold (Forever)

Scaffolds a new World of Warcraft Forever addon with the same layout, scripts and tests every time. The release flow is: the maintainer runs the release script (`scripts/release.sh` or `scripts/release.ps1`), which tests, updates the changelog, creates and pushes the release tag. A CurseForge webhook on the GitHub repository reacts to that tag and CurseForge packages and uploads from it. The scripts never upload anything to CurseForge and hold no CurseForge token.

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| A place to create the addon (a clean directory or repo) | the scaffold itself | the target directory exists and does not already contain the addon |
| The addon name, confirmed by the user | folder, TOC, `Config`, `.pkgmeta`, scripts | the user has confirmed a lowercase name (see "Before you start") |
| `git` | the execute bit (`git update-index`), the release tag | `git --version` succeeds |
| bash (Git Bash on Windows) | `publish-local.sh`, `release.sh`, the vendored packager | `bash --version` succeeds |
| `lua` on PATH | the pure Lua tests, and the release script's changelog step (`update_changelog.lua`), which needs `lua` in a dry-run and a real release even with skip-tests. Only `publish-local --skip-tests` runs without `lua` | `lua -v` succeeds |
| **Conditional:** GitHub CLI (`gh`), authenticated | the GitHub Release step of the generated release script (first real release, not the scaffold) | `gh auth status` succeeds |
| **Conditional:** a real `zip` | the local dry-run zip and the zip attached to the GitHub Release (packager) | `zip --version` succeeds |

**Hard gate.** Check before starting. If a required item is missing, stop, tell the user which one and how to fix it, and do not work around it. For the conditional items, check them when the user wants to run a dry-run or a release of the scaffolded addon. The scaffold itself does not need them.

## Before you start

1. Confirm the addon name (lowercase folder, for example `myaddon`).
2. Use the layout under "Target structure" and the script contract in [`wow-addon-publish-release/reference.md`](../wow-addon-publish-release/reference.md). Create the new addon in a clean directory or repo.
3. Read the project's `GLOSSARY.md`, if there is one. When the addon introduces domain terms and one is resolved, update the glossary through the `domain-modeling` skill (see "Works with other skills").

Settle only what the repo cannot answer: addon name, scope, whether it has UI, options or data, which feature flags it needs, and the CurseForge project id (if the project exists). Use `grilling`: one frontier round, with a recommended answer for each question.

## Works with other skills

Integrations are optional. They never override this skill's own hard rules.

| When | Skill | How |
| --- | --- | --- |
| Before scaffolding: name, scope, UI/options/data, feature flags, CurseForge project id are open | `grilling` | Ask only what the repo cannot answer, as one frontier round (numbered questions, each with a recommended answer), then wait for the answers. |
| The addon introduces domain terms | `domain-modeling` | Read the project's `GLOSSARY.md`; when a term is resolved, update it through this skill instead of keeping the term only in code. |
| Splitting the addon into Core / UI / Data | `codebase-design` | Use its vocabulary: the WoW client API is the seam. Keep the logic as a deep module in pure Lua behind a small interface, with a real adapter in the client and a fake in the pure Lua tests. |
| The behaviour of a WoW API on Forever is unclear | `research` | Research it against primary sources (for example Blizzard UI source and the packager documentation) and keep the findings in the repo; do not guess. |
| A large addon with several features or open design questions | `wayfinder`, then `agent-plan-review` / `human-plan-review` | Map the decisions first with `wayfinder`; review the resulting plan with `plan-review` (report) or `human-plan-review` (quiz the developer) before scaffolding. |
| The work is tracked in a GitHub issue | `gh-plan`, then `gh-sync` | Plan it with `gh-plan` first (local plan, hard stop). Sync the plan to GitHub with `gh-sync` when the user says Build, before implementing. |

## Target structure

```text
<addon>/                      # VCS root of the project
  <addon>/                    # Copied to Interface\AddOns
    <addon>.toc
    Config.lua
    Locale/enUS.lua
    Core.lua
    UI/                       # as needed
  docs/
    RELEASE.md                # packager / dry-run / release tag / one-time webhook setup
  scripts/publish-local.sh    # REQUIRED (Git Bash is primary)
  scripts/publish-local.ps1   # PowerShell version
  scripts/release.sh          # REQUIRED: tests + changelog + release tag + BigWigs packager zip
  scripts/release.ps1         # PowerShell version
  scripts/release_meta.lua    # pure Lua: version, tag, zip name
  scripts/changelog_meta.lua  # pure Lua: commit subjects to Keep a Changelog
  scripts/update_changelog.lua  # command line entry that writes CHANGELOG.md
  scripts/forever-addons.path.example  # template for the gitignored scripts/forever-addons.path
  .release/release.sh         # vendored BigWigsMods/packager v2.7.0
  tests/
    test_release_meta.lua
    test_changelog_meta.lua   # plus the addon's own logic tests
  .pkgmeta
  .luarc.json
  README.md                   # REQUIRED: project docs
  docs/CURSEFORGE.md          # REQUIRED: CurseForge description (text under ---)
  LICENSE                     # REQUIRED: MIT, Copyright (c) <year> <author>
  reports/                    # gitignore: code reviews
  CHANGELOG.md                # REQUIRED: Keep a Changelog, at the repository root
```

The full file list with the purpose of each file is in section (a) of [`../wow-addon-publish-release/reference.md`](../wow-addon-publish-release/reference.md#a-files-of-a-scaffolded-addon).

`<author>` is the addon author's name. There is no `.release/.env` and no `.release/.env.example`: no token lives in the repository.

## TOC requirements

```text
## Interface: 16001
## Title: Display Name
## Notes: ...
## Author: ...
## Version: @project-version@
## DefaultState: enabled

Config.lua
Locale/enUS.lua
Core.lua
```

- Load order: **Config -> Locale -> (DB/Data) -> Core -> UI**.
- Do not add `## SavedVariables` as the only persistence (Forever does not load SavedVariables after a cold start).
- Add `## X-Curse-Project-ID` only when the CurseForge project exists.

## Config pattern

```lua
MyAddon = MyAddon or {}

MyAddon.Config = {
  ENABLED = true,  -- feature flag: false = no slash command/UI
  ADDON_NAME = "MyAddon",
  VERSION = "0.1.0",
  SLASH_COMMAND = "/myaddon",
}
```

Keep `VERSION = "x.y.z"` on its own line, as a table field. The release and publish-local scripts match a line that starts (after optional whitespace) with `VERSION = "..."`, so a one-line form such as `MyAddon.Config = { VERSION = "0.1.0" }` or `MyAddon.Config.VERSION = "0.1.0"` is not found and the scripts fail. (`release_meta.parse_version` is looser, but it is only used by the tests.)

Put new functionality behind its own flag in `Config` when that is natural.

## Core minimum

- `MyAddon = MyAddon or {}`
- Slash: `SLASH_MYADDON1 = Config.SLASH_COMMAND` + `SlashCmdList`
- Respect `Config.ENABLED`
- `PLAYER_LOGIN` (or equivalent) for init that needs units/API
- Chat via `DEFAULT_CHAT_FRAME:AddMessage` with a locale prefix

Optionally, with `codebase-design` (see "Works with other skills"): split Core (pure Lua logic), UI (frames) and Data, with the WoW client API as the seam.

## Locale

- Strings in `Locale/enUS.lua` (`MyAddon.L = { ... }`)
- `function MyAddon:T(key, ...) ... end` with `string.format` when needed
- Keys: `UPPER_SNAKE`

## Options (Settings -> AddOns)

- Follow the **canonical Blizzard Settings row style** in [`wow-addon-ui`](../wow-addon-ui/SKILL.md) (sections, rows, scroll, tooltips). The layout is described in that skill.
- `Settings.RegisterCanvasLayoutCategory` + `RegisterAddOnCategory`; `OnCommit` / `OnRefresh`.

## .pkgmeta

```yaml
package-as: <addon>

move-folders:
  <addon>/<addon>: <addon>

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

Also create the root `CHANGELOG.md` (Keep a Changelog header + `## [Unreleased]`). CurseForge reads `.pkgmeta` and the root `CHANGELOG.md` on the tagged commit, so both must be committed before the release tag. The release wrappers use `changelog_meta.lua`, `update_changelog.lua` and tests, as specified in [`reference.md`](../wow-addon-publish-release/reference.md).

## .luarc.json

- Runtime Lua 5.1
- Whitelist the WoW globals used in the project (`CreateFrame`, `DEFAULT_CHAT_FRAME`, ...) + the addon global

## Tests

- Pure Lua: `dofile` Config/logic without the client
- Runnable with `lua tests/...`
- Wire them into the scripts unless `-SkipTests`: the release scripts run every test file (including `test_release_meta.lua` and `test_changelog_meta.lua`), `publish-local` runs only the addon's own logic tests. Skipping the tests does not remove the need for `lua` in the release script (changelog step)
- Optionally, with `codebase-design`: put logic that touches the WoW client API behind a small interface; the real adapter lives in the client code and the tests use a fake.

## Feature flag

Ask whether new visible features should go behind a `Config` flag (default: yes).

## Publish and release scripts

- **Always** create both `.sh` and `.ps1` for publish-local **and** release (contract in [`reference.md`](../wow-addon-publish-release/reference.md)).
- `publish-local` must replace `@project-version@` in the *copied* TOC with `Config.VERSION`.
- The maintainer mainly uses Git Bash, so `.sh` is not optional.
- Vendor `.release/release.sh` from BigWigsMods/packager **v2.7.0**. It is used only for the local dry-run zip and the zip attached to the GitHub Release.
- `docs/RELEASE.md` covers the dry-run, the release tag, the `gh` GitHub Release and the one-time CurseForge setup below. It contains no tokens.
- On a **non**-dry-run, the release script must: run the tests; update `CHANGELOG.md` from git; commit it if it changed; create the annotated release tag `v{Config.VERSION}` on HEAD if it is missing (fail if the tag exists on another commit); push the tag to `origin`; then run `gh release create` with notes from the CHANGELOG section and the packager zip (or, if the release already exists, upload the zip to it with `--clobber`). The full contract (flags, step order, tag rules, helper modules and the cases their tests must cover) is in [`reference.md`](../wow-addon-publish-release/reference.md).
- The scripts do **not** upload anything to CurseForge and hold **no** CurseForge token. The pushed release tag is what the CurseForge webhook reacts to.
- The release script needs `lua` (always, for the changelog step, even with skip-tests), a real `zip` (for the packager zip) and `gh` (for the GitHub Release); `curl` and `jq` are not needed.
- Dry-run: tests + local zip, no commit, no tag, no push, no `gh`.
- Clear `GH_API_TOKEN` / `GITHUB_API_TOKEN` / `GITHUB_OAUTH` before the packager call (the wrappers own GitHub through `gh`).
- Execute bit: `git update-index --chmod=+x scripts/publish-local.sh scripts/release.sh`.
- Adapt the test file, the package-as name, the Config path for the release tag, and `.release/<addon>/<addon>.toc` in the wrappers.

### One-time CurseForge setup

Releases are CurseForge only. Do this once per addon:

1. Create the CurseForge project.
2. Set up the CurseForge GitHub webhook on the GitHub repository, tied to the CurseForge project's API key, by following CurseForge's own documentation. Do not guess URLs, menu paths or webhook URL formats; point to that documentation in `docs/RELEASE.md`.
3. After that, a release is just running the release script. The pushed release tag triggers the webhook, and CurseForge packages and uploads from the tagged commit.

The API key lives only in the webhook setup on GitHub and CurseForge. It must never be in the repository.

### Security checklist

- No tokens in git.
- Dry-run before the first real release.
- `Interface` stays 16001 in the packaged TOC.
- No CurseForge API key anywhere in the repository.

## After the scaffold

- Confirm `README.md` + `docs/CURSEFORGE.md` + MIT `LICENSE` (`<author>`) + `CHANGELOG.md`. The README must document the addon and the CurseForge description must be kept in `docs/CURSEFORGE.md`; the license must be MIT.
- Update the README that lists the addons, if there is one, with a link to the new GitHub repo.
- Offer UI -> skill [`wow-addon-ui`](../wow-addon-ui/SKILL.md)
- Macros/data -> skill [`wow-forever-macros`](../wow-forever-macros/SKILL.md)
- Publish -> skill [`wow-addon-publish-release`](../wow-addon-publish-release/SKILL.md)

Scripts, helper modules, tests, `.pkgmeta` and `.luarc.json` are specified in [`reference.md`](../wow-addon-publish-release/reference.md).

## Examples

See [examples.md](examples.md).
