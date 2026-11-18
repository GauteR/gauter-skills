# Forever macros reference

Detail behind [SKILL.md](SKILL.md): the macro rules, the off-GCD classification with its evidence status, the registry data format, the race-conditional expansion and the CreateMacro checks. Game: World of Warcraft Forever (its own ruleset, not Classic Era); spell names are the English Forever client names.

## 1. Macro rules

1. One press = one GCD. A second `/cast` or `/use` is stacked only when the first is off-GCD.
2. Stance or form plus an ability is two presses on Forever. Classic "one-press stance swap" habits do not apply.
3. Prefer the highest rank name; downranking is less rewarding on Forever.
4. Use `#showtooltip` and the `INV_Misc_QuestionMark` icon so the action bar shows what the macro casts.
5. Forever renames and adds spells (examples: Bane of Agony, Victory Rush). Classic-only names must not be pasted blindly.

The intended pattern is racial plus trinkets plus main cooldown on one key, when the racial and trinkets are off-GCD.

## 2. Off-GCD classification and evidence status

Forever is its own ruleset. Classic Era and Retail off-GCD lists are weak hints, not truth. If Classic and Forever disagree, Forever wins.

Two statuses:

- **High**: explicitly described for Forever macros by Forever-specific guides, or a Forever spell page shows a GCD of 0 seconds.
- **Unverified**: plausible, or inherited from Classic, and not checked on Forever. Must not be stacked as a free press until checked.

Only High entries may be placed in front of another cast.

| Action | Status | Evidence |
| --- | --- | --- |
| Trinkets (`/use 13`, `/use 14`) | High | Forever macro guides: on-use trinkets do not use the GCD |
| Pet commands | High | Forever macro guides |
| Blood Fury (Orc) | High | Forever racial burst |
| Berserking (Troll) | High | Forever racial burst |
| Eureka! (Gnome) | High | Forever spell page: GCD 0 seconds |
| Presence of Mind (Mage) | High | Forever "free cooldown first" macro pattern |
| Nature's Swiftness (Druid, Shaman) | High | Forever "free cooldown first" macro pattern |
| Bloodrage (Warrior) | High | Forever "free cooldown first" macro pattern |
| Inner Focus (Priest) | High | Forever "free cooldown first" macro pattern |
| Fel Domination (Warlock) | High | Forever spell page: GCD 0 seconds |
| Elune's Light (Night Elf) | Unverified | in the shared burst IF for its +10% crit for damage and heals, not because its GCD is confirmed |
| Stoneform, Escape Artist, Will to Survive, Perception, Shadowmeld, Shatter Curse, War Stomp, Will of the Forsaken, Walk on Air, Skysight, Read Ley Line | Unverified | racial actives used only in utility or defensive IF blocks, never as free prefixes |
| Every other class or race ability not in the High rows above | Unverified | check in game before use |

Notes on specific entries:

- Rapid Regeneration (Troll) is a channel cancelled by any action, so it is left out of shared fragments (Unverified).
- Read Ley Line has a cast time, so it is not a free burst prefix.
- Totems may use a GCD and are not "free" (Unverified).
- Counterspell is instant but often still on the GCD (Unverified).
- New Forever trainer spells must not be assumed off-GCD without a tooltip check.

### How to lift Unverified (in-game Forever check)

Only an in-game Forever check, or a Forever spell page showing the GCD, moves an ability to High. Documentation from other sources can inform which abilities to test, but does not change the status.

1. Open the Forever spellbook (or the Forever spell page) and note the GCD.
2. Press the ability alone and watch the action bars for the GCD sweep.
3. Macro test: the candidate, then a known on-GCD spell, in one macro. Does the second fire on the same press?
4. Record: name, spell id, GCD, verified build, notes.

### Status of the classification

The High list is complete only for the abilities it names. A full class-by-class verified map is incomplete until abilities are checked systematically in game. Do not fill the gap by assumption.

## 3. Registry data format

A macro-template addon (for example one made with `wow-addon-scaffold`) keeps its templates in a class-keyed registry. `MyAddon` is a placeholder namespace.

```lua
MyAddon.DB:Register("WARRIOR", {
  id = "warrior_charge",           -- required, unique within the class key
  name = "Charge",                 -- default: id; max 16 characters in practice
  icon = "Ability_Warrior_Charge", -- default: INV_Misc_QuestionMark
  body = "/cast Charge",           -- default: empty; max 255 characters
  category = "general",            -- general | pve | pvp; anything else becomes general
  note = "Author note",            -- default: empty
})
```

- The first argument is the class file token (uppercase, for example `"MAGE"`). An empty key, or an entry without a string `id`, is ignored.
- `general` entries show under both the PvE and PvP filters; `pve` and `pvp` only under their own.
- Multiline bodies: a Lua long string `[[...]]` or `\n`.
- Keep the registry and its helpers free of client calls so they can be tested with plain Lua outside the game.

### Shared fragments

A file such as `Data/SHARED.lua` holds fragments reused across class files:

- a racial burst IF block (High abilities, plus Elune's Light with its Unverified GCD noted in a comment);
- a trinkets fragment, `/use 13` and `/use 14`;
- a `join` helper that drops empty parts and trims stray newlines;
- a burst-prefix helper, for example `withBurstPrefix(body)`, that returns trinkets, then the racial burst IF, then the body ("free cooldown first");
- a defensive-racials IF (GCD Unverified), split over two IF blocks so races with two actives can expand both.

Comments on a fragment should say which entries are High and which are Unverified.

## 4. Race-conditional expansion

Syntax: `{IF:TOKEN=value|TOKEN=value}`.

- Tokens are the uppercased file value of `UnitRace` (its second return value). Undead is `Scourge`. The tokens for the two Skyborne variants (`HIGHORDER`, `WINDSHAPER`) are Unverified: confirm with `/dump UnitRace("player")` on the Forever client.
- The branch whose token equals the player's token is substituted. Comparison trims whitespace and ignores case.
- With no match, the whole block becomes empty.
- Inside a branch, `\n` is a line break.
- After expansion, blank lines left by empty blocks are collapsed and leading and trailing newlines are trimmed.
- Expansion is idempotent for text without `{IF:` blocks, so text that is already expanded (for example edited preview text) passes through unchanged.
- Blocks cannot nest: a block runs from `{IF:` to the next `}` with no braces inside.

Optional refinement: when the final macro text is built for the player (on create and on sync), off-GCD `/cast` lines for a fixed list of prefix spells are dropped until the character knows the spell (`IsSpellKnown`). The list is the High abilities that are spells (Blood Fury, Berserking, Eureka!, Bloodrage, Presence of Mind, Inner Focus, Nature's Swiftness, Fel Domination) plus Elune's Light, which is on the list although its GCD is Unverified. Trinket lines stay. Without the client APIs (plain-Lua tests) every line is kept.

## 5. CreateMacro checks

1. Body length at most 255 characters (client cap); name at most 16. Count the body after expansion and after `#showtooltip` is added.
2. Name unique among existing macros. On collision, append a suffix (" 2", " 3", ...) and shorten the base so the total stays within 16.
3. `InCombatLockdown()` true: reject with a message and create nothing.
4. `#showtooltip` is present, built by one step that removes any existing `#showtooltip` line and prepends a fresh one:
   - a spell name from the first `/cast` or `/use` line that has one;
   - lines that are bare numbers (trinkets such as `/use 13`) and the prefix casts from the list above (the High spells plus Elune's Light) are skipped when choosing the spell, so the main cast drives the icon;
   - bare `#showtooltip` for `/castsequence`, for `;`-separated multi-spell lines and for `[mod:...]` lines, so a wrong primary icon is not shown.
5. Icon `INV_Misc_QuestionMark` when the tooltip should drive the bar icon.
6. Call `CreateMacro` through `pcall`. A nil result means the macro slots are full: report it.
7. When the macro is created from a UI, the preview text is the source: use it, not the raw registry body. Because expansion is idempotent, running it on preview text is safe.
8. If a macro is kept in sync with its template, the sync overwrites the body on purpose, is skipped in combat (retry after combat), drops its record when the macro was deleted or renamed, and is only offered when the preview was not hand-edited. Use a plain create for one-off edits.
