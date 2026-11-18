# Examples

All values are synthetic: author Kari Nordmann, addon `myaddon`.

## First questions (grilling, one frontier round)

User: "Scaffold a new Forever addon called myaddon."

The repo cannot answer these, so ask them in one round, each with a recommended answer:

```text
Q1 - Addon name: Folder `myaddon`, display name "MyAddon", Lua global `MyAddon`. Confirm?
-> Yes, lowercase folder `myaddon`.

Q2 - Scope: What does the addon do in one sentence, and does it have a UI window, an Options panel, or data (macros, lists)?
-> A slash command only for now; add UI later with wow-addon-ui.

Q3 - Feature flags: Should new visible features go behind a Config flag?
-> Yes (default).

Q4 - CurseForge project id: Does the CurseForge project exist yet?
-> No. Leave out ## X-Curse-Project-ID until it does.

Q5 - Tests: Is lua on PATH, or should the tests be skipped?
-> Lua is on PATH; keep the tests. (The release script needs lua for the changelog step even if the tests are skipped.)
```

## Resulting tree

```text
myaddon/                      # VCS root
  myaddon/
    myaddon.toc
    Config.lua
    Locale/enUS.lua
    Core.lua
  docs/
    RELEASE.md
    CURSEFORGE.md
  scripts/
    publish-local.sh
    publish-local.ps1
    release.sh
    release.ps1
    release_meta.lua
    changelog_meta.lua
    update_changelog.lua
    forever-addons.path.example
  .release/
    release.sh                # vendored BigWigsMods/packager v2.7.0
  tests/
    test_release_meta.lua
    test_changelog_meta.lua   # plus the addon's own logic tests
  .pkgmeta
  .luarc.json
  README.md
  LICENSE                     # MIT, Copyright (c) 2026 Kari Nordmann
  CHANGELOG.md
  reports/                    # gitignored
```

There is no `.release/.env` and no `.release/.env.example`.

## Minimal myaddon.toc

```text
## Interface: 16001
## Title: MyAddon
## Notes: Example addon.
## Author: Kari Nordmann
## Version: @project-version@
## DefaultState: enabled

Config.lua
Locale/enUS.lua
Core.lua
```

## Minimal Config.lua

```lua
MyAddon = MyAddon or {}

MyAddon.Config = {
  ENABLED = true,  -- feature flag: false = no slash command/UI
  ADDON_NAME = "MyAddon",
  VERSION = "0.1.0",          -- on its own line: the scripts match it line-anchored
  SLASH_COMMAND = "/myaddon",
}
```

## After the scaffold

1. `git update-index --chmod=+x scripts/publish-local.sh scripts/release.sh`
2. Dry-run the release script: tests + local zip, no commit, no tag, no push, no `gh`.
3. One time: create the CurseForge project and set up the CurseForge webhook on the GitHub repository with the project's API key, following CurseForge's documentation.
4. Release: run `scripts/release.sh`. It tests, updates `CHANGELOG.md`, commits it if changed, creates and pushes the release tag `v0.1.0`, and creates the GitHub Release. The webhook reacts to the tag.
