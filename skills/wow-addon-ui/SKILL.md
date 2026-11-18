---
name: wow-addon-ui
description: >-
  Builds World of Warcraft Forever addon UI with BasicFrameTemplateWithInset,
  UISpecialFrames, a BackdropTemplate fallback, editable panels, and an Options
  page via Settings canvas in the Blizzard Settings style (sections, rows,
  scroll, tooltips). Use for a main window, an Options panel, CreateFrame, a
  slash toggle, or UI bugs in Forever addons.
---

# WoW addon UI (Forever)

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| An existing addon project with `Config`, `Locale` (`T()`) and `Core` (for example created with `wow-addon-scaffold`) | window wiring, `ToggleWindow`, `Config.ENABLED`, locale keys | the addon has `Config.lua`, a locale file and `Core.lua` |
| The Forever client | manual checks (`/reload`, Escape, combat, slash) | the addon loads in Forever without Lua errors |
| `Settings` canvas API on the client (conditional: only when building an Options page) | `Settings.RegisterCanvasLayoutCategory`, `Settings.RegisterAddOnCategory` | guarded with `pcall` and a canvas fallback, see "Avoid" |

**Hard gate.** Check before starting. If a required item is missing (no addon project with Config, Locale and Core, or no way to test in Forever), stop and tell the user what to fix. Do not work around it, for example by inventing a Config or hardcoding UI strings to get past a missing Locale.

## Works with other skills

These integrations are optional. They never override the hard rules in this skill.

| When | Skill | How |
| --- | --- | --- |
| Several layouts are plausible for the main window or the Options page | `prototype` (UI branch) | Build throwaway variants first. This is an adaptation: `prototype` is written for web routes, so here the variants are switched with a debug slash subcommand and removed before merge (see "Prototype layout variants"). |
| UX decisions: what the Options page contains, who may open the admin window | `grilling` | Ask the whole frontier in one round, with a recommended answer per question, before building. |
| Deciding where logic lives | `codebase-design` | Keep the UI thin: logic in pure Lua modules with a small interface that tests can call without the client; the UI only calls that interface (see "Keep the UI thin"). |
| Facts about UI templates and Settings APIs on Forever | `research` | Research primary sources instead of guessing. This backs the `pcall` / canvas-fallback rule. |
| UI wording, labels and section names | `domain-modeling` | Read the project's `GLOSSARY.md`, if there is one, and the locale keys so UI wording stays consistent. When a term changes, record it through `domain-modeling`. |
| After a substantial UI change, before merge | `human-code-review` | Run it on the diff so the developer understands the change before it merges. Optional: the developer starts it (it is not model-invoked) and it has its own requirements, so skip it if they are not met. |

## Main window

1. `CreateFrame("Frame", "AddonFrame", UIParent, "BasicFrameTemplateWithInset")`
2. Set `TitleText`, size, `SetMovable` + a drag region
3. Register in `UISpecialFrames` so Escape closes it
4. Closing: frame X / Escape. Avoid a redundant Close button unless the UX needs it
5. Show/hide with `Show`/`Hide` or a dedicated `ToggleWindow` from Core/slash

If the window shows UI for which a UX decision is open (who may open the admin window, what goes in it), settle it first with `grilling` (see "Works with other skills").

## Visual hierarchy (window)

- Contrast panels: `BackdropTemplate` when available; fall back to a solid texture
- Fonts: `GameFontNormal`, `GameFontHighlight`, `GameFontNormalLarge`, `GameFontNormalSmall`
- List + detail: scroll list -> preview/detail -> primary action

## Input and state

- Multiline preview: `EditBox` with `SetMultiLine(true)`
- The primary action must use **what the user sees** (the preview), not silently overwrite it with raw data
- Disable the action or show an error on `InCombatLockdown()` when the action is not secure-safe

### Keep the UI thin

Window and Options code should only draw, wire events and call into the addon. Put the decisions (what the preview text is, whether an action is allowed, what a setting's default is) in pure Lua modules with a small interface that tests can call without the client. The UI calls that interface and nothing deeper. This is also what makes "the primary action uses what the user sees" hold: the preview and the action read the same value from the same module. Use `codebase-design` for the vocabulary (module, interface, seam).

## Options -> AddOns (canonical style)

**Main style for all new and updated Forever addons:** a Blizzard Settings list (like typical Interface/AddOns pages), not a minimal "about" panel.

```lua
local category = Settings.RegisterCanvasLayoutCategory(panel, name)
Settings.RegisterAddOnCategory(category)
```

If it is unclear what the page should contain, ask the open UX questions in one `grilling` round first.

### Layout

1. Outer `panel` with `OnCommit` / `OnDefault` / `OnRefresh`
2. Inner `ScrollFrame` (`UIPanelScrollFrameTemplate`) + a `content` child for the whole page
3. Title (`GameFontNormalLarge`) + version (`GameFontHighlightSmall`; TOC metadata, strip `@...@`)
4. Short help blurb
5. **Sections** with `GameFontNormal` headings
6. **Rows** (status/settings):
   - Full width, light background (`SetColorTexture(1,1,1,0.04)`)
   - Label on the left (`GameFontHighlight`, roughly gold)
   - Value / control on the right (fixed X column)
7. Lists/tables (for example presence): column headers + inner scroll; optional zebra striping
8. Action buttons (`UIPanelButtonTemplate`) under the relevant sections
9. **Tooltips** on settings rows: `GameTooltip` OnEnter/OnLeave (title white, body text gold)

### Behaviour

- Metadata: `C_AddOns.GetAddOnMetadata` with a fallback to `GetAddOnMetadata`
- "Open" button (if relevant): close `SettingsPanel`, call `ToggleWindow` - respect access gates
- `Options:Open()` -> `Settings.OpenToCategory(category)` with a fallback to `category.ID` / the panel name
- Locale via `T()`; no hardcoded user strings
- Forever: do not rely on SavedVariables as the only persistence; document the cold start if Options writes SV

### Avoid

- Only an icon + long help text + one button, with no sections/rows
- Duplicating Settings controls in the main window (use a shortcut button to Options instead)
- Retail-only Settings APIs without `pcall` / a canvas fallback. When unsure whether an API or template exists on Forever, research the primary sources (`research`) instead of guessing, then guard the call
- Unicode in UI text (`→`, `—`, ...): Forever fonts often lack the glyphs - use ASCII (`->`, `-`)

## Prototype layout variants

When several layouts are plausible, build throwaway variants before committing. This is an adaptation of the `prototype` skill (UI branch), which is written for web routes with a URL search param and a floating bar. For an addon:

- Each variant is a separate function that builds the same window or page from the same data.
- A debug slash subcommand switches between them (for example `/addon proto A`, `/addon proto B`); register it only in the prototype.
- Variants must differ in structure (layout, hierarchy, primary affordance), not only in colour or copy.
- Wire variants to stubs, not real actions.
- Remove the variants, the subcommand and the switcher before merge. Keep only the winner, rewritten properly.

## Slash

- Register only when `Config.ENABLED`
- Same entry point as the Options "Open" button when there is an admin/main UI

## Checklist

- [ ] Escape closes the window (`UISpecialFrames`)
- [ ] `ENABLED = false` removes slash/UI after `/reload`
- [ ] Combat-blocked actions give a clear status/error
- [ ] Locale via `T()`, no hardcoded UI strings in Window/Options (wording consistent with the project's `GLOSSARY.md`, if there is one)
- [ ] Frame names unique and predictable (`AddonNameFrame`, ...)
- [ ] Options follows the Settings row style (scroll, sections, rows, tooltips where needed)
- [ ] Logic lives in pure Lua modules that tests can call without the client; the UI only calls their interface
- [ ] No prototype variants or debug subcommands left in the change
- [ ] After a substantial UI change: `human-code-review` considered before merge

## Examples

See [examples.md](examples.md).
