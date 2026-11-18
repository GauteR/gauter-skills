# Examples

All values are synthetic. Only spells and constructs named in [SKILL.md](SKILL.md) are used.

## Free cooldown first

The main spell is the last line. Every stacked line before it is from the High list (trinkets, Presence of Mind), so the press still costs one GCD.

```text
#showtooltip Frostbolt
/use 13
/use 14
/cast Presence of Mind
/cast Frostbolt
```

An ability outside the High list is not stacked. If a user asks to put an Unverified spell in front, keep it out of the macro, or add it and state in a note that its GCD is Unverified until a Forever check.

## A registry entry

```lua
MyAddon.DB:Register("MAGE", {
  id = "mage_frostbolt_burst",
  name = "Frostbolt Burst",     -- 15 characters, within the 16 limit
  icon = "Spell_Frost_FrostBolt02",
  body = "/use 13\n/use 14\n/cast Presence of Mind\n/cast Frostbolt",
  category = "pve",
  note = "Free cooldown first. Presence of Mind and trinkets are High.",
})
```

## A race-conditional body

A shared helper in `Data/SHARED.lua` can hold the racial burst IF, and a body can use it. The raw body:

```lua
body = [[
/use 13
/use 14
{IF:ORC=/cast Blood Fury|TROLL=/cast Berserking|GNOME=/cast Eureka!|NIGHTELF=/cast Elune's Light}
/cast MAIN_SPELL
]]
```

Expanded for an Orc (`UnitRace` file value `Orc`):

```text
/use 13
/use 14
/cast Blood Fury
/cast MAIN_SPELL
```

Expanded for a Human (no matching token), the whole `{IF:...}` block is removed:

```text
/use 13
/use 14
/cast MAIN_SPELL
```

Elune's Light is in the burst IF but its GCD is Unverified. If the Night Elf branch is kept, say so in the entry's `note`.

## A mouseover cast

Cast on the mouseover enemy if there is one, otherwise on the current target:

```text
#showtooltip MAIN_SPELL
/cast [@mouseover,harm,nodead][] MAIN_SPELL
```

A friendly variant that falls back to the target, then to yourself:

```text
#showtooltip MAIN_SPELL
/cast [@mouseover,help,nodead][help,nodead][@player] MAIN_SPELL
```

## A filled-in CreateMacro checklist

For the "Frostbolt Burst" entry above, created by a character that is not in combat:

- [x] Body at most 255 characters (77 with `#showtooltip`); name 15 of 16; no existing macro named "Frostbolt Burst", so no suffix
- [x] `InCombatLockdown` false at the time of creation (if true: reject with an error message, create nothing)
- [x] `#showtooltip Frostbolt` added at the top; the trinket lines and the Presence of Mind line are skipped when picking the tooltip spell, so Frostbolt drives the icon
- [x] Icon `INV_Misc_QuestionMark`, so the bar icon follows the tooltip
- [x] The text in the preview is the text passed to `CreateMacro`, not the raw registry body
