---
name: wow-forever-macros
description: >-
  Authors and validates World of Warcraft Forever macros: one press = one GCD,
  the High off-GCD list, #showtooltip, conditionals, stance/form + ability =
  two presses, a class-keyed macro-template registry (Data files), and the
  {IF:race} race-conditional expansion. Use for macros, macro templates,
  Data/*.lua registry files, off-GCD questions, or changes to macro rules
  documentation.
---

# Forever macros

Rules for writing World of Warcraft Forever macros (the Forever client, not Classic Era) and for the registry data of a macro-template addon. The full rule set, the off-GCD classification with its evidence status, the registry data format, the race-conditional expansion and the CreateMacro checks are in [reference.md](reference.md).

## Requirements

| Requirement | Needed for | Check |
| --- | --- | --- |
| The intended main spell or action, named as in the English Forever client | every macro (rule 5: do not paste Classic-only names blindly) | the user or the project names the spell; do not guess a name from Classic habits |
| The Forever client (conditional: only to lift an Unverified status) | the in-game Forever check described under "Off-GCD" | the user can press the ability and watch for the GCD sweep. Without it the ability stays Unverified; this is not a stop |
| A macro-template addon with a class-keyed registry and `Data/*.lua` files (conditional: only when adding or editing registry entries) | `MyAddon.DB:Register(...)` entries and shared fragments | the addon has a registry module and a `Data/` folder; a new one can be made with `wow-addon-scaffold` |
| Addon code that creates macros with `CreateMacro` (conditional: only when writing or reviewing that code) | the "CreateMacro check" list | the code calls `CreateMacro` and `InCombatLockdown` |

**Hard gate.** Check before starting. If the main spell or action is unknown, or its English Forever name is unknown, stop, ask the user, and do not invent a name. For the conditional rows, check them only when that kind of work is requested. Lack of in-game verification is NOT a stop: write the macro, keep every ability outside the High list marked Unverified, and say so. Do not work around a missing requirement by copying Classic names or Classic off-GCD lists.

## Forever rules (always)

1. **One press = one GCD.** Only stack an extra `/cast` or `/use` when the first one is **off-GCD**.
2. **Stance/form + ability = two presses.** Do not assume the Classic one-press myths.
3. Prefer the **highest rank** name; Forever downranking is weaker than Classic habits suggest.
4. Use **`#showtooltip`** and the **`?` icon** (`INV_Misc_QuestionMark`) with `CreateMacro`.
5. Spell names are the **English Forever client** names (for example Bane of Agony, Victory Rush, Eureka!). Do not paste Classic-only names blindly.

## Off-GCD

**High** (safe to put in front of another cast): trinkets (`/use 13`, `/use 14`), Blood Fury, Berserking, Eureka!, Bloodrage, Presence of Mind, Inner Focus, Nature's Swiftness, Fel Domination, pet commands.

The **shared burst IF** also includes **Elune's Light** (Night Elf, +10% crit for damage and heals). Its GCD is **Unverified**: it is used because the crit window is relevant, not because its GCD is confirmed.

Everything else is **Unverified** until an in-game Forever check. Document the uncertainty; never present it as fact. Where the evidence behind each entry is described, see [reference.md](reference.md).

Pattern "free cooldown first":

```text
#showtooltip MAIN_SPELL
/use 13
/use 14
/cast Blood Fury
/cast MAIN_SPELL
```

## Common conditionals

```text
/cast [@mouseover,harm,nodead][] SPELL
/cast [@mouseover,help,nodead][help,nodead][@player] SPELL
/cast [@player] SPELL
/cast [@targettarget,harm,nodead][] SPELL
/cast [mod:shift] SECOND; FIRST
```

Helper commands: `/stopcasting`, `/startattack`, `/cancelaura`, `/targetenemy [noharm][dead]`.

## Macro registry data

The data format of a macro-template addon (for example one made with `wow-addon-scaffold`). The namespace `MyAddon` is a placeholder for the addon's own.

```lua
MyAddon.DB:Register("MAGE", {
  id = "mage_frostbolt",       -- unique within the class file
  name = "Frostbolt",          -- max 16 characters in practice
  icon = "Spell_Frost_FrostBolt02",
  body = "/cast Frostbolt",    -- max 255 characters
  category = "general",        -- general | pve | pvp
  note = "Author note",
})
```

Multiline bodies: a Lua long string `[[...]]` or `\n`.

### Race conditionals

```lua
body = [[
/cast Charge
{IF:DWARF=/cast Stoneform|GNOME=/cast Escape Artist|ORC=/cast Blood Fury}
]]
```

- Tokens are the `UnitRace` file values (`Scourge` = Undead).
- With no match, the whole `{IF:...}` block is removed.
- Shared fragments live in `Data/SHARED.lua` (for example a `withBurstPrefix` helper, a racial IF, trinkets).

## CreateMacro check

- [ ] Body at most 255 characters; name at most 16; name unique (add a suffix on collision)
- [ ] `InCombatLockdown` true: reject with an error message
- [ ] `#showtooltip` in place (an `EnsureShowTooltip`-style step)
- [ ] Icon `INV_Misc_QuestionMark` when the tooltip should drive the bar icon
- [ ] The preview text is the source when the macro is created from a UI

## Works with other skills

Integrations are optional. They never override this skill's own rules.

| When | Skill | How |
| --- | --- | --- |
| The facts about a spell or its off-GCD behaviour are missing | `research` | Gather documented facts from primary sources into a Markdown file. This can inform, but it does not lift an Unverified status: only the in-game Forever check does. |
| Class, spec, rotation or playstyle are unclear | `grilling` | Settle the intended class, spec, rotation and playstyle first, as one frontier round with a recommended answer per question, before writing macros. |
| Terms such as GCD, off-GCD, High, Unverified or burst IF need a shared meaning | `domain-modeling` | Record them in the project's `GLOSSARY.md` instead of leaving them only in comments. |
| A new macro-template addon is needed | `wow-addon-scaffold` | Scaffold the addon (layout, TOC, Config, Core, Locale, tests), then add the registry and `Data/` files described here. |
| The addon gets a create-macro window | `wow-addon-ui` | Build the window and Options page with it; the preview text is the source, and creation must respect combat lockdown (see the CreateMacro check). |
| Macro data changes are ready to ship | `wow-addon-publish-release` | Use it for the changelog, the release script and the release tag. |
| A diff of macro data is ready for merge | `human-code-review` | Run it on the diff before merge so the developer shows they understand the change. It is invoked by the user, not by the model, and it needs `git`, `gh` and `jq`. |

## Examples

See [examples.md](examples.md).
