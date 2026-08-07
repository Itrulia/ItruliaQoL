# Authoring EllesmereUI options (`options.eui.lua`)

When **EllesmereUI** is installed, ItruliaQoL surfaces its settings inside
EllesmereUI's own config window instead of the AceConfig dialog. EllesmereUI
replaced Ace3 with its own widget framework, so it cannot render an AceConfig
options table. Each module therefore ships a hand-authored settings list in
`options.eui.lua`, which `ellesmere.lua` renders with EllesmereUI's native
widgets.

- **`options.ace.lua`** — the AceConfig table. Used by ElvUI and the standalone
  Blizzard-options / `/itrulia` window.
- **`options.eui.lua`** — the manual list. Used only when EllesmereUI is present.

Both edit the **same** `module.db`, so the two stay in sync automatically.

`options.eui.lua` is **required** for a module to show up in EllesmereUI. There is
no auto-translation of the AceConfig table any more: a module without
`GetEUIOptions` is skipped entirely and gets no sidebar row, leaving its settings
reachable only from the ElvUI / standalone panels. `DungeonTeleports` is the one
module in that state today.

---

## File skeleton

```lua
local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM        -- only if you build a sound/media select yourself

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

function CombatTimer:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Combat Timer",   -- header shown for this module's section
        rows = {
            -- rows go here, top to bottom
        },
    }
end
```

Register the file in the module's `init.xml`, right after the ace options:

```xml
<Script file="options.ace.lua"/>
<Script file="options.eui.lua"/>
```

`GetEUIOptions()` returns `{ name = <string>, rows = { <row>, ... } }`. It is
called every time the page is (re)built, so read/write `module.db` **live**
inside the callbacks — never capture `local db = self.db` (that snapshot goes
stale on a profile switch).

It also receives one optional argument, the selected page name. That only matters
for modules that declare tabs — see **Tabs** below.

---

## Row types

Each entry in `rows` is one of the following tables.

### Layout / text

```lua
{ header = "Sound" }                 -- a section title
{ spacer = 12 }                      -- vertical gap of N px
{ text   = "Some help text." }       -- a plain, non-interactive line
{ header = "Font", rows = { ... } }  -- a titled sub-list (nested rows)
{ pair   = { <row>, <row> } }        -- two controls on one row, half width each
{ type   = "empty" }                 -- a blank half, only inside a `pair`
```

`pair` takes any two control rows (not just toggles) and puts them side by side:

```lua
{ pair = {
    { type = "toggle", label = "Auto accept role", get = ..., set = ... },
    { type = "toggle", label = "Announce key",     get = ..., set = ... },
} },
```

Each half gets half the row width, and EllesmereUI **truncates** labels rather than
wrapping them, so keep paired labels short and put the detail in `tooltip`.

Pair a control with `{ type = "empty" }` to give it half a row without a partner —
an odd control at the end of a paired block, say. Without it a lone control gets
the full row width, so its control sits at the far right and breaks the column the
rows above it line up on.

Three controls to a row (EllesmereUI's `TripleRow`) is not supported: a third of
the row cannot hold a label and a dropdown at usable widths.

### Controls

```lua
{ type = "toggle",  label=, tooltip=, disabled=, refresh=, rebuild=, get=, set= }
{ type = "slider",  label=, tooltip=, min=, max=, step=, disabled=, get=, set= }
{ type = "select",  label=, tooltip=, values=, order=, disabled=, refresh=, rebuild=, get=, set= }
{ type = "color",   label=, hasAlpha=, get=, set= }
{ type = "input",   label=, tooltip=, width=, disabled=, refresh=, rebuild=, get=, set= }
{ type = "execute", label=, disabled=, refresh=, rebuild=, func= }
{ type = "icons",   items = { <icon>, <icon>, ... } }   -- grid of icon buttons
```

Field reference:

| field      | meaning |
|------------|---------|
| `label`    | control label (left side of the row) |
| `tooltip`  | hover tooltip string |
| `disabled` | `function() return <bool> end` — greys out and locks the control |
| `disabledTooltip` | why it is greyed out: a requirement noun EllesmereUI wraps into "This option requires X to be enabled", or a full sentence with `rawTooltip = true` |
| `rawTooltip` | `true` to show `disabledTooltip` verbatim instead of wrapping it |
| `min/max/step` | slider range |
| `values`   | select options: `{ key = "Display", ... }` |
| `order`    | select display order: `{ "key1", "key2", ... }` (defaults to sorted-by-label) |
| `hasAlpha` | colour picker includes an opacity slider |
| `width`    | input box width in px (default 180) |
| `get`      | reader — see below |
| `set`/`func` | writer / button action — see below |
| `refresh`  | `true` to re-read the page's values after this edit — see below |
| `rebuild`  | `true` to rebuild the page after this edit, for edits that add or remove rows — see below |
| `cog`      | `{ title =, rows = { <row>, ... } }` — secondary settings behind a cogwheel — see below |

### `cog` — secondary settings behind a cogwheel

Any control row can carry a `cog`, which puts a small cogwheel left of its control
that opens a popup with further settings — how EllesmereUI keeps detail settings
(offsets, a font's size) off the page instead of spending a row on each:

```lua
{ type = "select", label = "Font", values = ..., order = ..., get = ..., set = ...,
  cog = {
      title = "Font Settings",
      rows = {
          { type = "slider", label = "Size", min = 1, max = 68, step = 1,
            get = function() return M.db.font.fontSize end,
            set = function(v) M.db.font.fontSize = v; apply() end },
      },
  } },
```

Cog rows are the same specs as page rows (`toggle`, `slider`, `select`, `color`,
`input`, `execute`) with the same `get`/`set` closures — only `icons` has no cog
equivalent. On a `pair`, each half can carry its own `cog`. Use it for settings
that are secondary to the row's own control; anything a user reaches for often
belongs on the page.

`icon` swaps the cogwheel for another texture, following what EllesmereUI's own
pages put on each kind of setting — a plain cog is only the default, not the rule:

| cog contents | `icon` |
|--------------|--------|
| a direction, or an X/Y offset | `ItruliaQoL.EUI.DIRECTIONS_ICON` (HealerManaIndicator's Growth) |
| a size or extent — padding, a text size | `ItruliaQoL.EUI.RESIZE_ICON` (RaidFrameManager's Padding) |
| anything else | omit it |

Guard the lookup with `ItruliaQoL.EUI and ...`, since the list is built whether or
not EllesmereUI is loaded:

```lua
cog = {
    title = "Padding",
    icon = ItruliaQoL.EUI and ItruliaQoL.EUI.RESIZE_ICON,
    rows = { ... },
},
```

A cog can also be gated as a whole, for settings that mean nothing while the row
they hang off is switched off — there is no point opening a popup whose every row
would be greyed out. Give it `disabled` (a function) and `disabledTooltip` (a full
sentence, shown verbatim), and the cogwheel dims, stops opening, and explains
itself on hover:

```lua
{ type = "toggle", label = "Only in a group", refresh = true, get = ..., set = ...,
  cog = {
      title = "Group Visibility",
      disabled = function() return not M.db.onlyInGroup end,
      disabledTooltip = "Only in a group has to be on before the bar can be limited to raids.",
      rows = { ... },
  } },
```

The gating row needs `refresh = true` for the cog to dim in the same edit.

### Icon grid (`icons`)

A grid of clickable spell-icon buttons (a 1px-bordered icon with a label
underneath, an accent hover border, and a hover tooltip), matching EllesmereUI's
own macro page. Use it when a plain list of `execute` buttons would be too heavy —
e.g. a set of one-click actions that read better as icons.

```lua
{ type = "icons", items = {
    {
        icon        = 194913,                       -- texture id/path, resolved by the caller
        label       = "Frostbane",                  -- shown under the icon (truncates; full name on hover)
        tooltip     = "What it does",               -- optional; hover tooltip body
        onClick     = function() ... end,           -- run when the icon is clicked
        desaturated = function() return <bool> end, -- optional; greys the icon when true
    },
    -- ...more icons...
} }
```

The grid lays icons left-to-right, wrapping to fit the panel width and centering
the last row. `icon` must already be a texture (resolve spell ids to textures via
`C_Spell.GetSpellTexture` before building the row). `desaturated` is re-evaluated
after each click, so state (e.g. "macro already exists") updates immediately.

### `get` / `set` signatures

`get`/`set` are plain closures (no AceConfig `info` argument):

```lua
-- toggle / slider / select / input
get = function() return CombatTimer.db.someValue end,
set = function(value) CombatTimer.db.someValue = value; apply() end,

-- color: get returns four numbers, set receives four numbers
get = function() local c = CombatTimer.db.color return c.r, c.g, c.b, c.a end,
set = function(r, g, b, a) CombatTimer.db.color = { r = r, g = g, b = b, a = a }; apply() end,

-- execute: no get; func is the button action
func = function() CombatTimer:DoTheThing() end,
```

---

## What `set` should call (apply rules)

After writing to `db`, call the right refresh so the change takes effect live.
Mirror what the AceConfig `set` did in `options.ace.lua`:

- **The `enable` toggle** → `Module:RefreshConfig()` (sets the feature up / tears
  it down):
  ```lua
  set = function(value)
      CombatTimer.db.enabled = value
      CombatTimer:RefreshConfig()
  end,
  ```
- **Appearance settings** (colour, text, size, font — anything the ace `set`
  applied via its `onChange`) → `apply()`:
  ```lua
  local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end
  ```
  `ApplyModuleStyles` calls the module's named frame `:UpdateStyles()`. This is
  the faithful, side-effect-free equivalent of the ace `onChange`.
- **Store-only settings** (behaviour flags, sound/TTS choices the ace `set` only
  stored) → nothing; just write `db`.

### Modules without `frame:UpdateStyles`

Some modules restyle in an `OnEvent`/`RefreshConfig` rather than a
`frame:UpdateStyles` (e.g. nameplate-font or macro-writing modules). There,
`ApplyModuleStyles` is a no-op, so route appearance changes through
`Module:RefreshConfig()` instead:

```lua
local function apply() FriendlyNameplates:RefreshConfig() end
```

---

## `refresh` — live-updating dependent controls

The AceConfig dialog re-renders after every change; EllesmereUI does not. When a
control **gates another** (its value drives another row's `disabled`), set
`refresh = true` on the *controlling* row so the page rebuilds and the dependent
control greys/ungreys immediately:

```lua
{ type = "toggle", label = "Play sound", refresh = true,
  get = function() return M.db.playSound end,
  set = function(v) M.db.playSound = v end },
ItruliaQoL:EUISoundRow({
  disabled = function() return not M.db.playSound end,   -- gated by the toggle above
  get = function() return M.db.sound end,
  set = function(v) M.db.sound = v end }),
```

`refresh` is honoured on `toggle`, `select`, `input`, and `execute`. Don't put it
on `slider`/`color` — those write continuously and rebuilding mid-drag breaks the
interaction.

It works the same on a row inside a `cog` popup, so a setting behind a cogwheel
can gate rows on the page it sits on.

### `rebuild` — when the row *set* changes

`refresh` re-reads the values of the widgets already on the page; it cannot make a
row appear or disappear. An edit that changes **which rows exist** — a user-editable
list, where adding an entry means adding its own Remove row (RaidFrameManager's pull
timers) — needs `rebuild = true` instead, which tears the page down and calls
`GetEUIOptions` again:

```lua
{ type = "execute", label = "Remove 10 s", rebuild = true,
  func = function() M:RemovePullTimer(10); apply() end },
```

Same set of row types as `refresh`, and the same caveat about sliders and colours.
Prefer `refresh` where it is enough: a rebuild reallocates every widget on the page.

---

## Shared helpers (`ellesmere.lua`)

- **`ItruliaQoL:EUIFontRows(fontObj, apply)`** → the full font block as a list of
  rows: Font, Outline and Frame Strata, two to a row, each with the rest on its
  cogwheel (Size and Justify, Shadow X/Y/Colour, Frame Level). Drop it into a
  `{ header = "Font", rows = ... }` group:
  ```lua
  { header = "Font", rows = ItruliaQoL:EUIFontRows(CombatTimer.db.font, apply) },
  ```
  A fourth argument, `lead`, is a list of rows to put in front of the dropdowns,
  joining the same two-to-a-row flow instead of sitting above it — for a module
  whose own text settings belong with the font ones (Death Alert leads with its
  colour, so the page is Color | Font, Outline | Frame Strata and needs no
  section header):
  ```lua
  rows = ItruliaQoL:EUIFontRows(DeathAlert.db.font, apply, nil, { colorRow }),
  ```
  `exclude` still keys every setting individually (`size`, `justify`, `shadowX`,
  …) even where it is no longer its own row, and a cog setting falls back to a
  full row if the row hosting its cog is the excluded one. A slug outline greys the
  shadow settings out with an explanation rather than removing them, so the
  cogwheel stays put as the outline changes.
- **`ItruliaQoL:EUIFontFamilyRow(fontObj, apply)`** → just the font-family
  dropdown row (font **name** label + a per-font preview, EllesmereUI-style). Use
  it when you want a reduced font block; add the size as its `cog` (see **`cog`**
  above) to match how the full block presents it:
  ```lua
  local fontRow = ItruliaQoL:EUIFontFamilyRow(M.db.font, apply)
  fontRow.cog = { title = "Font Settings", rows = {
      { type = "slider", label = "Size", min = 1, max = 68, step = 1,
        get = function() return M.db.font.fontSize end,
        set = function(v) M.db.font.fontSize = v; apply() end },
  } }

  -- ...
  { header = "Font", rows = { fontRow } },
  ```
- **`ItruliaQoL:EUIFontValues()`** → `(values, order)` for a font-family dropdown,
  if you need to build the select row by hand.
- **`ItruliaQoL:EUIStatusbarRow(row)`** → a statusbar-texture dropdown row: the
  texture **name** as the label and the texture itself drawn behind each menu row
  as a preview. `row` is the usual select spec minus `values`/`order`
  (`label?`, `tooltip?`, `disabled?`, `refresh?`, `get`, `set`); `label` defaults
  to `"Statusbar texture"`:
  ```lua
  ItruliaQoL:EUIStatusbarRow({
      get = function() return M.db.statusbarTexture end,
      set = function(v) M.db.statusbarTexture = v; apply() end,
  }),
  ```
- **`ItruliaQoL:EUISoundRow(row)`** → a sound dropdown row: the sound **name** as
  the label plus a click-to-preview speaker icon on each menu row, and a search
  box in the menu. Same `row` spec; `label` defaults to `"Sound"`.
- **`ItruliaQoL:EUIStatusbarValues()`** / **`ItruliaQoL:EUISoundValues()`** →
  `(values, order)` for those dropdowns, if you need to build the select row by
  hand (e.g. to add extra entries). The previews ride on `values._menuOpts`, so
  copy that field along if you shallow-copy the table.
- **`ItruliaQoL:ApplyModuleStyles(moduleName)`** → calls the module's named frame
  `:UpdateStyles()` and redraws the module's preview (see apply rules above, and
  **The preview** below).

Fonts, statusbar textures and sounds all come from LSM (the same media
EllesmereUI registers), and every helper keys its dropdown by the LSM **name** —
never the file path — so values stay compatible with what `db` stores and with
`LSM:Fetch`. Passing `LSM:HashTable(...)` straight into a `select` is the mistake
to avoid: that table is name → path, so the dropdown ends up labelling every row
with a raw file path.

---

## Where the module appears

Every module with an `options.eui.lua` gets **its own row** in EllesmereUI's
sidebar, under an "Itrulia QoL" group appended after EllesmereUI's own groups.
There are no shared category pages — the old `MODULE_PAGE` bucketing (Indicators /
Alerts / Utility) is gone, and nothing needs registering to place a new module: add
`options.eui.lua` and the row appears. Row order follows the module group's
AceConfig `order`, then name. Two rows are built in: **General**, and **Profiles**
(which holds the Profiles and Import / Export tabs).

### The panel header

The header text under the module title comes from the AceConfig `description` arg
in `options.ace.lua`, **not** from the eui list:

```lua
description = {
    type = "description",
    name = "Shows a timer counting up while you are in combat\n\n",
    width = "full",
    order = 1,
},
```

Because of that, do **not** open `rows` with a plain `{ text = ... }` describing the
module. `ellesmere.lua` strips a leading text-only row precisely because it would
repeat the header. Put per-control explanations in `tooltip` instead.

### The preview

A module that draws something on screen gets a **live preview of its own frame**
pinned above its settings, in EllesmereUI's content header — the non-scrolling
strip between the tab bar and the page, which is where EllesmereUI puts its own
previews. It restyles as you edit, so you can see a colour or font change without
closing the panel, and it works whether the module is switched on or off.

The preview is a *second instance* built by the module's own `GenerateFrame`, so it
styles itself through the same `UpdateStyles` as the live one — there is no
duplicated drawing code to keep in sync. It is built the first time its page is
opened and parked (hidden, out of the panel's frame tree) once you navigate away.

To opt in, add a `preview.lua` to the module's folder — registered in its `init.xml`
between `defaults.lua` and the options files — defining `Module:PreparePreview(frame)`.
`UpdateStyles` has already run when it is called; its job is
to put the instance into the state its `OnEvent` reaches when the feature actually
fires, since a freshly generated frame usually starts blank or hidden:

```lua
function StealthIndicator:PreparePreview(f)
    f.text:Show()
end
```

Modules whose display depends on live data fill in a sample instead, mirroring what
their `OnEvent` does under `ItruliaQoL.testMode`. Anything that changes the text has
to re-run `UpdateStyles` afterwards, because the frame sizes itself from it:

```lua
function CombatTimer:PreparePreview(f)
    f.text:SetText(f:FormatTime(83))
    f.text:Show()
    f:UpdateStyles()
end
```

A module split across tabs gets the selected page as a second argument, so each tab
can preview the text it configures. There is still only one preview instance —
switching tabs re-points it:

```lua
-- preview.lua
MovementAlert.pageDisplay = "Movement Alert"
MovementAlert.pageTimeSpiral = "Time Spiral"

function MovementAlert:PreparePreview(f, page)
    if page == self.pageTimeSpiral then
        -- ... the time spiral readout
    else
        -- ... the movement cooldown readout
    end

    f.text:Show()
    f:UpdateStyles()
end
```

The page names belong on the module in `preview.lua` — that is what switches on them —
rather than inlined as strings: `EUIPages` here, the AceConfig tab groups in
`options.ace.lua` and `PreparePreview` all have to agree, across three files.
`EUIPages` itself stays in `options.eui.lua`, built from those two names:

```lua
-- options.eui.lua
MovementAlert.EUIPages = { MovementAlert.pageDisplay, MovementAlert.pageTimeSpiral }
```

That is the whole contract. `PreparePreview` doubles as the opt-in flag: a module
that draws nothing — a pure event listener like `FocusTargetMarker` or
`PreventRelease` — simply omits it and gets no header, costing nothing. The same
function drives the AceConfig preview, so writing it once covers every host.

The AceConfig side needs its placement spelled out, having no content header to put it
in: add `ItruliaQoL:CreatePreviewOption(Module)` as the first entry of the module's
`args`. A tabbed module sets `childGroups = "tab"` on its group and puts one preview
option at the top of each tab's group, naming that tab —
`ItruliaQoL:CreatePreviewOption(MovementAlert, 0, nil, MovementAlert.pageTimeSpiral)`
— which is what feeds `PreparePreview` its `page` there.

Two things the preview deliberately overrides after `UpdateStyles`, handled centrally
in `src/preview.lua` so no module has to care:

- **Position and strata.** `UpdateStyles` anchors the frame at its saved point with
  the configured frame strata, which are meant for its real home on `UIParent`. Left
  alone, the saved point would push the preview out of the header and a `BACKGROUND`
  strata would hide it behind the panel.
- **Scale.** The config window can run at a different effective scale than
  `UIParent`, so the preview is scaled to compensate and a 28px font previews at the
  size it really draws.

### The enable switch

Each row carries a power icon on its right edge, styled like the one EllesmereUI
puts on its own addons. It toggles `db.enabled` and calls `RefreshConfig()`, so a
module can be switched on or off without opening its page. Nothing to author — it
appears automatically for every module row.

### Tabs (`EUIPages`)

A module with more settings than fit comfortably on one page can declare tabs in a
static `EUIPages` field. `ellesmere.lua` reads it at registration — a plain table
rather than a call, so building the sidebar never means invoking every module at
login — and passes the selected page back to `GetEUIOptions`:

```lua
DeathAlert.EUIPages = { "Display", "Sound Alert", "Filters" }

function DeathAlert:GetEUIOptions(pageName)
    if pageName == "Sound Alert" then
        return { name = "Death Alert", rows = { ... } }
    end

    if pageName == "Filters" then
        return { name = "Death Alert", rows = { ... } }
    end

    -- "Display", and the fallback for any caller that passes no page name
    return { name = "Death Alert", rows = { ... } }
end
```

Always return a valid list for the no-argument case — other hosts may call without
one. Tabs lay out in a single non-wrapping row, so keep the names short and the
count to roughly six or fewer.

A module that declares no `EUIPages` still gets one tab, named for it by
`ellesmere.lua`: **Display** for a module that draws something (it defines
`PreparePreview` — see **The preview**), **Settings** for a pure event listener
that has no display to name. Keep "Display" as the first page name when adding
`EUIPages` to a module that had none, so its tab does not appear to rename itself.

The content header sits *below* the tab bar, so each tab gets its own preview and
`PreparePreview` is told which tab is open — see **The preview** above.

### Combined rows (`COMBINED_ROWS`)

Two or more modules can share one sidebar row, each becoming a tab on it. This is
configured in `ellesmere.lua`, not in the modules:

```lua
local COMBINED_ROWS = {
    {
        key = "PetIndicators",
        display = "Pet Indicators",
        members = { "PetMissingIndicator", "PetPassiveIndicator" },
        description = "Missing/Passive pet text indicators.",
    },
}
```

The row is emitted where its first member would have appeared, so the surrounding
order is unchanged. Three things follow from it being one row:

- It needs its own `description`. The header is per row, not per tab, so the
  members' individual `description` args are never shown.
- Its enable switch sets **all** members at once, and reads as on when *any* member
  is on.
- `EUIPages` on a member is ignored — a combined row already spends its tabs on its
  members.
- The preview follows the selected tab, showing that member's own frame.

If two modules are grouped permanently, consider merging them into one real module
instead (as `AutoAcceptRole` + `GroupJoinedReminder` became `LFGImprovements`);
`COMBINED_ROWS` is for presentation only.

---

## Complete example

```lua
local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

function CombatTimer:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    -- No description row: that text lives in the AceConfig `description` arg and is
    -- rendered as the panel header (see "Where the module appears").
    return {
        name = "Combat Timer",
        rows = {
            {
                type = "toggle",
                label = "Enable",
                get = function() return CombatTimer.db.enabled end,
                set = function(value)
                    CombatTimer.db.enabled = value
                    CombatTimer:RefreshConfig()
                end,
            },
            {
                type = "select",
                label = "Time format",
                values = {
                    SECONDS = "180",
                    CLOCK   = "01:23",
                },
                get = function() return CombatTimer.db.timeFormat end,
                set = function(value) CombatTimer.db.timeFormat = value; apply() end,
            },
            {
                type = "color",
                label = "Color",
                hasAlpha = true,
                get = function()
                    local c = CombatTimer.db.color
                    return c.r, c.g, c.b, c.a
                end,
                set = function(r, g, b, a)
                    CombatTimer.db.color = { r = r, g = g, b = b, a = a }
                    apply()
                end,
            },
            {
                header = "Font",
                rows = ItruliaQoL:EUIFontRows(CombatTimer.db.font, apply),
            },
        },
    }
end
```
