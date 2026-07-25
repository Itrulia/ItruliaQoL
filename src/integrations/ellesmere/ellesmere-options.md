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

Both edit the **same** `module.db`, so the two stay in sync automatically. If a
module has no `options.eui.lua`, `ellesmere.lua` falls back to auto-translating
its AceConfig table (a best-effort mirror), so an `options.eui.lua` is optional
but preferred.

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

---

## Row types

Each entry in `rows` is one of the following tables.

### Layout / text

```lua
{ header = "Sound" }                 -- a section title
{ spacer = 12 }                      -- vertical gap of N px
{ text   = "Some help text." }       -- a plain, non-interactive line
{ header = "Font", rows = { ... } }  -- a titled sub-list (nested rows)
```

### Controls

```lua
{ type = "toggle",  label=, tooltip=, disabled=, refresh=, get=, set= }
{ type = "slider",  label=, tooltip=, min=, max=, step=, disabled=, get=, set= }
{ type = "select",  label=, tooltip=, values=, order=, disabled=, refresh=, get=, set= }
{ type = "color",   label=, hasAlpha=, get=, set= }
{ type = "input",   label=, tooltip=, width=, disabled=, refresh=, get=, set= }
{ type = "execute", label=, disabled=, refresh=, func= }
{ type = "icons",   items = { <icon>, <icon>, ... } }   -- grid of icon buttons
```

Field reference:

| field      | meaning |
|------------|---------|
| `label`    | control label (left side of the row) |
| `tooltip`  | hover tooltip string |
| `disabled` | `function() return <bool> end` — greys out and locks the control |
| `min/max/step` | slider range |
| `values`   | select options: `{ key = "Display", ... }` |
| `order`    | select display order: `{ "key1", "key2", ... }` (defaults to sorted-by-label) |
| `hasAlpha` | colour picker includes an opacity slider |
| `width`    | input box width in px (default 180) |
| `get`      | reader — see below |
| `set`/`func` | writer / button action — see below |
| `refresh`  | `true` to re-render the page after this edit — see below |

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
{ type = "select", label = "Sound", values = LSM:HashTable("sound"),
  disabled = function() return not M.db.playSound end,   -- gated by the toggle above
  get = function() return M.db.sound end,
  set = function(v) M.db.sound = v end },
```

`refresh` is honoured on `toggle`, `select`, `input`, and `execute`. Don't put it
on `slider`/`color` — those write continuously and rebuilding mid-drag breaks the
interaction.

---

## Shared helpers (`ellesmere.lua`)

- **`ItruliaQoL:EUIFontRows(fontObj, apply)`** → the full font block as a list of
  rows (Size, Font, Outline, Justify, Shadow X/Y/Colour, Frame Strata, Frame
  Level). Drop it into a `{ header = "Font", rows = ... }` group:
  ```lua
  { header = "Font", rows = ItruliaQoL:EUIFontRows(CombatTimer.db.font, apply) },
  ```
- **`ItruliaQoL:EUIFontFamilyRow(fontObj, apply)`** → just the font-family
  dropdown row (font **name** label + a per-font preview, EllesmereUI-style). Use
  it when you want a reduced font block:
  ```lua
  { header = "Font", rows = {
      { type = "slider", label = "Size", min = 1, max = 68, step = 1,
        get = function() return M.db.font.fontSize end,
        set = function(v) M.db.font.fontSize = v; apply() end },
      ItruliaQoL:EUIFontFamilyRow(M.db.font, apply),
  } },
  ```
- **`ItruliaQoL:EUIFontValues()`** → `(values, order)` for a font-family dropdown,
  if you need to build the select row by hand.
- **`ItruliaQoL:ApplyModuleStyles(moduleName)`** → calls the module's named frame
  `:UpdateStyles()` (see apply rules above).

Font family/size use LSM (the same fonts EllesmereUI registers), so values stay
compatible with `db.font.fontFamily` and `LSM:Fetch`.

---

## Where the module appears (pages)

`ellesmere.lua` groups modules onto tabbed pages via the `MODULE_PAGE` map:
**General**, **Indicators**, **Alerts**, **Utility** (plus **Profiles** and
**Import / Export**, which are built-in). A module not listed in `MODULE_PAGE`
defaults to **Utility**. To place a new module, add it there:

```lua
local MODULE_PAGE = {
    ...
    MyNewModule = PAGE_INDICATORS,
}
```

Order within a page follows the module group's AceConfig `order`, then name.

---

## Complete example

```lua
local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CombatTimer"
local CombatTimer = ItruliaQoL:GetModule(moduleName)

function CombatTimer:GetEUIOptions()
    local function apply() ItruliaQoL:ApplyModuleStyles(moduleName) end

    return {
        name = "Combat Timer",
        rows = {
            { text = "Shows a timer counting up while you are in combat." },
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
