# Examples

Synthetic values: author Kari Nordmann, addon `myaddon`, version 1.1.0. The previous release tag is `v1.0.0`.

## Dry-run

Tests and a local zip. No commit, no tag, no push, no `gh`. `CHANGELOG.md` is written but not committed. `lua` must be on PATH, also with `-SkipTests` / `--skip-tests`, because the changelog step runs Lua.

```powershell
.\scripts\release.ps1 -DryRun
```

```bash
./scripts/release.sh --dry-run
```

## Real release

Prerequisites: `lua` on PATH (also with skip-tests), `gh` logged in, and the CurseForge webhook already set up on the GitHub repository (one-time). `Config.VERSION` is bumped to `1.1.0`.

```powershell
.\scripts\release.ps1
```

```bash
./scripts/release.sh
```

What happens, in order:

1. The tests run (`lua`, unless skipped). `lua` is still needed for step 2 when they are skipped.
2. `CHANGELOG.md` is updated from the commits since `v1.0.0`.
3. `CHANGELOG.md` is committed if it changed (before the tag, so the tagged commit carries it).
4. The annotated tag `v1.1.0` is created on HEAD. If `v1.1.0` already exists on another commit, the script fails.
5. The tag is pushed to `origin`. The pushed tag is what triggers the CurseForge webhook: CurseForge packages and uploads from the tag, reading `.pkgmeta` and the root `CHANGELOG.md` on the tagged commit. The scripts upload nothing to CurseForge and hold no CurseForge token.
6. `gh release create v1.1.0` makes the GitHub Release with the notes from the `1.1.0` section of `CHANGELOG.md` and the zip (`gh release upload --clobber` if the release exists).

## Sample CHANGELOG.md section

Built from conventional commits (Keep a Changelog format):

```markdown
## [1.1.0] - 2026-11-18

### Added

- Slash command `/myaddon reset` to restore the default window position

### Fixed

- Window no longer stays open after pressing Escape

### Changed

- Options panel now uses the shared locale table
```

Commits behind it:

```text
feat: add /myaddon reset slash command
fix: close window on Escape
refactor: use shared locale table in options
```

## Manual tag equivalent

If the tag must be made by hand (the pushed tag still triggers the CurseForge webhook):

```bash
git tag -a v1.1.0 -m "v1.1.0"
git push origin refs/tags/v1.1.0
```
