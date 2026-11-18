# Examples

All values are synthetic: author Kari Nordmann, addon `myaddon`. Every Lua block is an unverified sketch to adapt to your addon and to check on the Forever client. Besides the API names that the skill text names, the sketches use a few standard WoW calls (`tinsert`, `RegisterForDrag`, `StartMoving`, `SetScrollChild` and similar) that the skill does not name; verify them on Forever too.

## Main window

Unverified sketch, adapt before use.

```lua
-- Core.lua / UI/Window.lua (sketch)
local Window = {}

local frame

local function createFrame()
  frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(420, 320)
  frame:SetPoint("CENTER")
  frame.TitleText:SetText(T("WINDOW_TITLE")) -- locale key, no hardcoded string

  -- Movable with a drag region
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Escape closes the window
  tinsert(UISpecialFrames, "MyAddonFrame")

  frame:Hide()
end

function Window:ToggleWindow()
  if not frame then
    createFrame()
  end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

MyAddon.Window = Window
```

The slash command is registered only when `Config.ENABLED` and calls the same entry point as the Options "Open" button (`Window:ToggleWindow()`).

## Options page skeleton

Unverified sketch, adapt before use. Wrap the Settings calls in `pcall` and keep a canvas fallback.

```lua
-- UI/Options.lua (sketch)
local Options = {}

local panel = CreateFrame("Frame")
panel.name = "myaddon"

-- Outer panel callbacks
panel.OnCommit = function() end   -- apply pending values
panel.OnDefault = function() end  -- reset to defaults
panel.OnRefresh = function() end  -- re-read values into the controls

-- Scroll frame + content child for the whole page
local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 8, -8)
scroll:SetPoint("BOTTOMRIGHT", -28, 8)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(600, 400)
scroll:SetScrollChild(content)

-- Title and version (TOC metadata, strip @...@)
local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 8, -8)
title:SetText(T("OPTIONS_TITLE"))

local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = (getMeta("myaddon", "Version") or ""):gsub("@.-@", "")
local versionText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
versionText:SetPoint("LEFT", title, "RIGHT", 8, 0)
versionText:SetText(version)

-- A section header
local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
section:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
section:SetText(T("OPTIONS_SECTION_GENERAL"))

-- One settings row: label left, control right (fixed X column)
local row = CreateFrame("Frame", nil, content)
row:SetSize(560, 28)
row:SetPoint("TOPLEFT", section, "BOTTOMLEFT", 0, -8)
row:EnableMouse(true)
local bg = row:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(1, 1, 1, 0.04)

local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
label:SetPoint("LEFT", 8, 0)
label:SetText(T("OPTIONS_ROW_STATUS"))

local value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
value:SetPoint("LEFT", 320, 0)
value:SetText(T("STATUS_OK"))

-- Tooltip on the row (title white, body gold)
row:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(T("OPTIONS_ROW_STATUS"), 1, 1, 1)
  GameTooltip:AddLine(T("OPTIONS_ROW_STATUS_TIP"), 1, 0.82, 0, true)
  GameTooltip:Show()
end)
row:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Register in Settings, guarded
local category
local ok = pcall(function()
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
end)
-- if not ok: use the project's canvas fallback

function Options:Open()
  if ok and category then
    -- try the category, then category.ID, then the panel name
    if not pcall(Settings.OpenToCategory, category) then
      if not pcall(Settings.OpenToCategory, category.ID) then
        pcall(Settings.OpenToCategory, panel.name)
      end
    end
  end
end

MyAddon.Options = Options
```

## Prototype variants with a debug subcommand

Adaptation of the `prototype` skill, removed before merge.

```lua
-- Prototype only. Remove before merge.
local variants = {
  A = function() --[[ build layout A from the same data ]] end,
  B = function() --[[ build layout B from the same data ]] end,
}

-- Debug slash subcommand: /myaddon proto A
local function handleProto(arg)
  local build = variants[arg]
  if build then build() end
end
```

## Checklist, filled in

Change: new main window and Options page for `myaddon` by Kari Nordmann.

- [x] Escape closes the window (`UISpecialFrames`): checked after `/reload`
- [x] `ENABLED = false` removes slash/UI after `/reload`: checked
- [x] Combat-blocked actions give a clear status/error: "Not available in combat" shown while in combat
- [x] Locale via `T()`, no hardcoded UI strings in Window/Options; wording matches `GLOSSARY.md`
- [x] Frame names unique and predictable (`MyAddonFrame`)
- [x] Options follows the Settings row style (scroll, sections, rows, tooltips on the settings rows)
- [x] Logic lives in pure Lua modules; tests call them without the client
- [x] No prototype variants or debug subcommands left in the change
- [ ] `human-code-review` run on the diff: pending, before merge
