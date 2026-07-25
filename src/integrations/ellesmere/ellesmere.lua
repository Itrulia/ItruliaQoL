local addonName, ItruliaQoL = ...

-- EllesmereUI integration.
--
-- Mirrors the ElvUI integration (see init.lua): when EllesmereUI is present we
-- surface the same settings inside its config window and register our movers
-- with its unlock mode.
--
-- EllesmereUI replaced Ace3 with its own widget framework, so we cannot hand it
-- an AceConfig options table the way we do for ElvUI. Each module hand-authors
-- its EllesmereUI settings as a list of rows in its own options.eui.lua
-- (Module:GetEUIOptions), which RenderEUIList turns into EllesmereUI widgets.
--
-- The registration technique (loadstring trampoline to pass EllesmereUI's
-- caller whitelist, plus manual sidebar injection) follows NaowhUI_EUI, the
-- reference third-party companion addon.

-- Resolve a value that may be a plain value or an AceConfig callback.
local function resolve(v, ...)
    if type(v) == "function" then
        return v(...)
    end

    return v
end

-- Live-restyle a module's named frame -- the faithful equivalent of the
-- AceConfig `onChange` (frame:UpdateStyles), without RefreshConfig's heavier
-- side effects (e.g. resetting the combat timer on a colour change). Manual
-- options.eui.lua lists use this for appearance changes; the enable toggle
-- still calls the module's RefreshConfig to set up / tear down.
function ItruliaQoL:ApplyModuleStyles(moduleName)
    local frame = _G[addonName .. moduleName]

    if frame and frame.UpdateStyles then
        frame:UpdateStyles()
    end
end

-- AceConfig selects sort by display text by default (no `sorting` given); mirror
-- that so dropdown order matches the other hosts.
local function selectOrder(values)
    local order = {}

    for k in pairs(values) do
        order[#order + 1] = k
    end

    table.sort(order, function(a, b)
        return tostring(values[a]) < tostring(values[b])
    end)

    return order
end

-- Manual settings list (options.eui.lua).
--
-- A module can hand-author its EllesmereUI settings by defining
-- Module:GetEUIOptions() in its own options.eui.lua, returning
--   { name = "Display Name", rows = { <row>, <row>, ... } }
-- Rows use clean get/set closures (no AceConfig `(info, value)` wrapper):
--
--   { header = "Section" }                                    -- section title
--   { spacer = 12 }                                           -- vertical gap
--   { text   = "Some help text" }                             -- plain label row
--   { rows   = { ... }, header = "optional" }                 -- nested sub-list
--   { type = "toggle",  label=, tooltip=, disabled=, get=, set= }
--   { type = "slider",  label=, min=, max=, step=, disabled=, get=, set= }
--   { type = "select",  label=, values=, order=, disabled=, get=, set= }
--   { type = "color",   label=, hasAlpha=, get=, set= }       -- get -> r,g,b,a ; set(r,g,b,a)
--   { type = "input",   label=, width=, disabled=, get=, set= }
--   { type = "execute", label=, disabled=, func= }
--   { type = "icons",   items = { { icon=, label=, tooltip=, onClick=, desaturated= }, ... } }
--
-- `disabled` is a function returning a bool. `get`/`set` read/write the module
-- db directly and call the module's own apply (e.g. self:RefreshConfig()).
function ItruliaQoL:RenderEUIList(W, parent, y, rows)
    local _, h

    -- `refresh = true` on a row re-renders the page after its edit, so controls
    -- it gates (their `disabled`/values depend on this one) update immediately.
    local function wrap(fn, refresh)
        if not refresh or not fn then
            return fn
        end

        return function(...)
            fn(...)

            local EUI = ItruliaQoL.EUI
            if EUI and EUI.RefreshPage then
                EUI:RefreshPage()
            end
        end
    end

    for _, item in ipairs(rows) do
        if item.rows then
            if item.header then
                _, h = W:SectionHeader(parent, item.header, y)
                y = y - h
            end

            y = self:RenderEUIList(W, parent, y, item.rows)
        elseif item.header then
            _, h = W:SectionHeader(parent, item.header, y)
            y = y - h
        elseif item.spacer then
            _, h = W:Spacer(parent, y, item.spacer)
            y = y - h
        elseif item.text then
            _, h = W:DualRow(parent, y, { text = item.text })
            y = y - h
        elseif item.type == "toggle" then
            _, h = W:DualRow(parent, y, {
                type = "toggle",
                text = item.label,
                tooltip = item.tooltip,
                disabled = item.disabled,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            })
            y = y - h
        elseif item.type == "slider" then
            -- EllesmereUI's slider does arithmetic on the value, so it must never
            -- be nil. Existing profiles can lack a field added after they were
            -- created (module defaults only seed brand-new profiles), so fall
            -- back to the slider min.
            local getV = item.get
            _, h = W:DualRow(parent, y, {
                type = "slider",
                text = item.label,
                tooltip = item.tooltip,
                min = item.min,
                max = item.max,
                step = item.step,
                disabled = item.disabled,
                getValue = function()
                    local v = getV and getV()

                    if v == nil then
                        return item.min or 0
                    end

                    return v
                end,
                setValue = item.set,
            })
            y = y - h
        elseif item.type == "select" then
            local vals = item.values or {}
            _, h = W:DualRow(parent, y, {
                type = "dropdown",
                text = item.label,
                tooltip = item.tooltip,
                values = vals,
                order = item.order or selectOrder(vals),
                disabled = item.disabled,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            })
            y = y - h
        elseif item.type == "color" then
            _, h = W:DualRow(parent, y, {
                type = "colorpicker",
                text = item.label,
                hasAlpha = item.hasAlpha,
                getValue = item.get,
                setValue = item.set,
            })
            y = y - h
        elseif item.type == "input" then
            _, h = W:DualRow(parent, y, {
                type = "input",
                text = item.label,
                tooltip = item.tooltip,
                inputWidth = item.width or 180,
                disabled = item.disabled,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            })
            y = y - h
        elseif item.type == "execute" then
            _, h = W:DualRow(parent, y, {
                type = "button",
                text = item.label,
                disabled = item.disabled,
                onClick = wrap(item.func, item.refresh),
            })
            y = y - h
        elseif item.type == "icons" then
            _, h = self:RenderEUIIconGrid(parent, y, item.items or {})
            y = y - h
        end
    end

    return y
end

-- Renders a grid of clickable spell-icon buttons (a 1px-bordered icon with a
-- label underneath and an accent hover border), matching EllesmereUI's own macro
-- page. Used by the "icons" row type. Each item:
--   { icon = <texture>, label = <string>, tooltip = <string?>,
--     onClick = function() ... end, desaturated = function() return <bool> end? }
-- Returns (frame, height) so it slots into RenderEUIList's `y = y - h` loop.
function ItruliaQoL:RenderEUIIconGrid(parent, y, items)
    local EUI = self.EUI
    local PP = EUI.PanelPP or EUI.PP
    local pad = EUI.CONTENT_PAD or 0
    local fontPath = (EUI.GetFontPath and EUI.GetFontPath()) or STANDARD_TEXT_FONT

    local ICON = 36
    local CELL_W = 84 -- horizontal stride per icon (icon + gap + label room)
    local ROW_H = 60  -- vertical stride per row (icon + label + gap)
    local TOP = 8

    local availW = parent:GetWidth() - pad * 2
    local perRow = math.max(1, math.floor(availW / CELL_W))
    local count = #items
    local rows = math.ceil(count / perRow)
    local height = TOP + rows * ROW_H

    local frame = CreateFrame("Frame", nil, parent)
    PP.Size(frame, availW, height)
    PP.Point(frame, "TOPLEFT", parent, "TOPLEFT", pad, y)

    for i, item in ipairs(items) do
        local idx = i - 1
        local row = math.floor(idx / perRow)
        local col = idx % perRow
        -- Centre the (possibly partial) last row within the available width.
        local inThisRow = math.min(perRow, count - row * perRow)
        local startX = (availW - inThisRow * CELL_W) / 2
        local cx = startX + col * CELL_W + CELL_W / 2
        local cy = -TOP - row * ROW_H

        local btn = CreateFrame("Button", nil, frame)
        PP.Size(btn, ICON, ICON)
        btn:SetPoint("TOP", frame, "TOPLEFT", cx, cy)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(item.icon)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local bdr = CreateFrame("Frame", nil, btn)
        bdr:SetAllPoints()
        bdr:SetFrameLevel(btn:GetFrameLevel() + 1)
        PP.CreateBorder(bdr, 0, 0, 0, 1, 1)

        local hoverBdr = CreateFrame("Frame", nil, btn)
        hoverBdr:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
        hoverBdr:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
        hoverBdr:SetFrameLevel(btn:GetFrameLevel() + 2)
        local ar, ag, ab = EUI.GetAccentColor()
        PP.CreateBorder(hoverBdr, ar, ag, ab, 1, 2)
        hoverBdr:Hide()

        local label = frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(fontPath, 12, "")
        label:SetTextColor(1, 1, 1, 0.9)
        label:SetPoint("TOP", btn, "BOTTOM", 0, -3)
        label:SetWidth(CELL_W - 10)
        label:SetWordWrap(false)
        label:SetJustifyH("CENTER")
        label:SetText((item.label or ""):gsub("\n", " "))

        local function refreshState()
            if item.desaturated then
                tex:SetDesaturated(item.desaturated() and true or false)
            end
        end
        refreshState()

        btn:SetScript("OnEnter", function(self2)
            hoverBdr:Show()
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(item.label or "", 1, 1, 1, 1, true)
            if item.tooltip then
                GameTooltip:AddLine(item.tooltip, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            hoverBdr:Hide()
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function()
            if item.onClick then
                item.onClick()
            end
            refreshState()
        end)
    end

    return frame, height
end

-- Font family dropdown data in EllesmereUI's native format: the label is the
-- font NAME and each item previews in its own font (values[name] = { text, font }),
-- instead of showing the raw file path. Keyed by LSM font name, so it stays
-- compatible with fontObject.fontFamily and LSM:Fetch.
function ItruliaQoL:EUIFontValues()
    local vals, order = {}, {}

    for name, path in pairs(self.LSM:HashTable("font")) do
        vals[name] = { text = name, font = path }
        order[#order + 1] = name
    end

    table.sort(order)

    return vals, order
end

-- A single EllesmereUI-native "Font" dropdown row (name label + per-font preview).
function ItruliaQoL:EUIFontFamilyRow(f, apply)
    local vals, order = self:EUIFontValues()

    return {
        type = "select",
        label = "Font",
        values = vals,
        order = order,
        get = function()
            return f.fontFamily
        end,
        set = function(v)
            f.fontFamily = v

            if apply then
                apply()
            end
        end,
    }
end

-- Shared font-settings rows for the manual list, mirroring createFontOptions.
-- `apply` runs after each change (e.g. the module's RefreshConfig). `exclude` is
-- an optional set of row keys to skip:
--   size, font, outline, justify, shadowX, shadowY, shadowColor, strata, level
function ItruliaQoL:EUIFontRows(f, apply, exclude)
    exclude = exclude or {}

    local rows = {}
    local function add(key, row)
        if not exclude[key] then
            rows[#rows + 1] = row
        end
    end

    add("size", {
        type = "slider",
        label = "Size",
        min = 1,
        max = 68,
        step = 1,
        get = function()
            return f.fontSize
        end,
        set = function(v)
            f.fontSize = v
            apply()
        end,
    })
    add("font", self:EUIFontFamilyRow(f, apply))
    add("outline", {
        type = "select",
        label = "Outline",
        values = self.OutlineSettings,
        get = function()
            return f.fontOutline or "NONE"
        end,
        set = function(v)
            f.fontOutline = (v ~= "NONE") and v or nil
            apply()
        end,
    })
    add("justify", {
        type = "select",
        label = "Justify",
        values = self.JustifyHSettings,
        get = function()
            return f.justifyH or "CENTER"
        end,
        set = function(v)
            f.justifyH = v
            apply()
        end,
    })
    add("shadowX", {
        type = "slider",
        label = "Shadow X Offset",
        min = -5,
        max = 5,
        step = 1,
        get = function()
            return f.fontShadowXOffset
        end,
        set = function(v)
            f.fontShadowXOffset = v
            apply()
        end,
    })
    add("shadowY", {
        type = "slider",
        label = "Shadow Y Offset",
        min = -5,
        max = 5,
        step = 1,
        get = function()
            return f.fontShadowYOffset
        end,
        set = function(v)
            f.fontShadowYOffset = v
            apply()
        end,
    })
    add("shadowColor", {
        type = "color",
        label = "Shadow Color",
        hasAlpha = true,
        get = function()
            local c = f.fontShadowColor
            return c.r, c.g, c.b, c.a
        end,
        set = function(r, g, b, a)
            f.fontShadowColor = { r = r, g = g, b = b, a = a }
            apply()
        end,
    })
    add("strata", {
        type = "select",
        label = "Frame Strata",
        values = self.FrameStrataSettings,
        get = function()
            return f.frameStrata or "BACKGROUND"
        end,
        set = function(v)
            f.frameStrata = v
            apply()
        end,
    })
    add("level", {
        type = "slider",
        label = "Frame Level",
        min = 1,
        max = 10,
        step = 1,
        get = function()
            return f.frameLevel or 1
        end,
        set = function(v)
            f.frameLevel = v
            apply()
        end,
    })

    return rows
end

-- Popups (profile names, confirmations, import/export strings)
local function popupEditBox(self)
    return self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
end

StaticPopupDialogs["ITRULIAQOL_EUI_INPUT"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 12000,
    editBoxWidth = 260,
    OnAccept = function(self)
        local d = self.data
        local eb = popupEditBox(self)

        if d and d.onAccept and eb then
            d.onAccept(eb:GetText())
        end
    end,
    OnShow = function(self)
        local d = self.data
        local eb = popupEditBox(self)

        if eb then
            eb:SetText((d and d.initial) or "")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        StaticPopup_OnClick(self:GetParent(), 1)
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ITRULIAQOL_EUI_CONFIRM"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local d = self.data

        if d and d.onAccept then
            d.onAccept()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function ShowInputPopup(prompt, initial, onAccept)
    StaticPopup_Show("ITRULIAQOL_EUI_INPUT", prompt, nil, { initial = initial, onAccept = onAccept })
end

local function ShowConfirmPopup(prompt, onAccept)
    StaticPopup_Show("ITRULIAQOL_EUI_CONFIRM", prompt, nil, { onAccept = onAccept })
end

-- Keep our popups above the EllesmereUI panel.
hooksecurefunc("StaticPopup_Show", function(which)
    if which and which:find("^ITRULIAQOL_EUI_") then
        local frame = StaticPopup_FindVisible(which)

        if frame then
            frame:SetFrameStrata("TOOLTIP")
            frame:SetFrameLevel(1000)
        end
    end
end)

-- Page layout
local PAGE_GENERAL    = "General"
local PAGE_INDICATORS = "Indicators"
local PAGE_ALERTS     = "Alerts"
local PAGE_UTILITY    = "Utility"
local PAGE_PROFILES   = "Profiles"
local PAGE_IMPEXP     = "Import / Export"

local PAGE_ORDER = {
    PAGE_GENERAL, PAGE_INDICATORS, PAGE_ALERTS, PAGE_UTILITY, PAGE_PROFILES, PAGE_IMPEXP,
}

-- Which page each module group lands on. Unknown modules default to Utility.
local MODULE_PAGE = {
    FocusInterruptIndicator = PAGE_INDICATORS,
    FocusTargetMarker       = PAGE_INDICATORS,
    MeleeIndicator          = PAGE_INDICATORS,
    NoTargetIndicator       = PAGE_INDICATORS,
    PetMissingIndicator     = PAGE_INDICATORS,
    PetPassiveIndicator     = PAGE_INDICATORS,
    StealthIndicator        = PAGE_INDICATORS,
    HealerManaIndicator     = PAGE_INDICATORS,
    CharacterIndicator      = PAGE_INDICATORS,

    DeathAlert          = PAGE_ALERTS,
    CombatAlert         = PAGE_ALERTS,
    PotionAlert         = PAGE_ALERTS,
    CombatTimer         = PAGE_ALERTS,
    MovementAlert       = PAGE_ALERTS,
    RepairIndicator     = PAGE_ALERTS,
    GroupJoinedReminder = PAGE_ALERTS,

    AutoAcceptRole   = PAGE_UTILITY,
    CursorCircle     = PAGE_UTILITY,
    FlyingBar        = PAGE_UTILITY,
    PreventRelease   = PAGE_UTILITY,
    DungeonTeleports = PAGE_UTILITY,
    MacroFactory     = PAGE_UTILITY,
}

-- Top-level parentOptions.args keys that are not modules.
local RESERVED = {
    all = true, enable = true, description = true, profiles = true, importExport = true,
}

-- Profiles page (built directly against AceDB rather than translated)
function ItruliaQoL:BuildEUIProfilesPage(parent, yOffset)
    local EUI = self.EUI
    local W = EUI.Widgets
    local db = self.db
    local y = yOffset
    local _, h

    local function names()
        return db:GetProfiles()
    end

    local function currentValues()
        local vals = {}

        for _, n in ipairs(names()) do
            vals[n] = n
        end

        return vals
    end

    local function otherValues()
        local vals, cur = {}, db:GetCurrentProfile()

        for _, n in ipairs(names()) do
            if n ~= cur then
                vals[n] = n
            end
        end

        return vals
    end

    local function sortedKeys(tbl)
        local o = {}

        for k in pairs(tbl) do
            o[#o + 1] = k
        end

        table.sort(o)

        return o
    end

    local function refresh()
        if EUI.RefreshPage then
            EUI:RefreshPage()
        end
    end

    _, h = W:Spacer(parent, y, 8)
    y = y - h
    _, h = W:SectionHeader(parent, "PROFILES", y)
    y = y - h

    do
        local cv = currentValues()
        _, h = W:DualRow(parent, y, {
            type = "dropdown",
            text = "Current Profile",
            values = cv,
            order = sortedKeys(cv),
            getValue = function()
                return db:GetCurrentProfile()
            end,
            setValue = function(v)
                db:SetProfile(v)
                refresh()
            end,
        })
        y = y - h
    end

    _, h = W:DualRow(parent, y, {
        type = "button",
        text = "New Profile",
        onClick = function()
            ShowInputPopup("Enter a name for the new profile:", "", function(name)
                name = name and name:match("^%s*(.-)%s*$") or ""

                if name ~= "" then
                    db:SetProfile(name)
                    refresh()
                end
            end)
        end,
    })
    y = y - h

    do
        local ov = otherValues()
        _, h = W:DualRow(parent, y,
            {
                type = "dropdown",
                text = "Copy From",
                values = ov,
                order = sortedKeys(ov),
                getValue = function()
                    return self._euiCopyFrom
                end,
                setValue = function(v)
                    self._euiCopyFrom = v
                end,
            },
            {
                type = "button",
                text = "Copy",
                onClick = function()
                    local from = self._euiCopyFrom

                    if from and from ~= db:GetCurrentProfile() then
                        db:CopyProfile(from)
                        self:RefreshModules()
                        refresh()
                    end
                end,
            }
        )
        y = y - h
    end

    do
        local ov = otherValues()
        _, h = W:DualRow(parent, y,
            {
                type = "dropdown",
                text = "Delete Profile",
                values = ov,
                order = sortedKeys(ov),
                getValue = function()
                    return self._euiDeleteSel
                end,
                setValue = function(v)
                    self._euiDeleteSel = v
                end,
            },
            {
                type = "button",
                text = "Delete",
                onClick = function()
                    local target = self._euiDeleteSel

                    if target and target ~= db:GetCurrentProfile() then
                        ShowConfirmPopup("Delete profile '" .. target .. "'? This cannot be undone.", function()
                            db:DeleteProfile(target)
                            self._euiDeleteSel = nil
                            refresh()
                        end)
                    end
                end,
            }
        )
        y = y - h
    end

    _, h = W:DualRow(parent, y, {
        type = "button",
        text = "Reset Current Profile",
        onClick = function()
            ShowConfirmPopup("Reset the current profile to defaults?", function()
                db:ResetProfile()
                self:RefreshModules()
                refresh()
            end)
        end,
    })
    y = y - h

    return math.abs(y)
end

-- Import / Export page
function ItruliaQoL:BuildEUIImportExportPage(parent, yOffset)
    local EUI = self.EUI
    local W = EUI.Widgets
    local y = yOffset
    local _, h

    _, h = W:Spacer(parent, y, 8)
    y = y - h
    _, h = W:SectionHeader(parent, "IMPORT / EXPORT", y)
    y = y - h

    _, h = W:DualRow(parent, y, { text = "Share your current profile, or paste a string to load one." })
    y = y - h

    _, h = W:WideButton(parent, "Export Current Profile", y, function()
        ShowInputPopup("Copy your profile export string:", ItruliaQoL:ExportCurrentProfile(), nil)
    end)
    y = y - h

    _, h = W:WideButton(parent, "Import (Overwrite Current Profile)", y, function()
        ShowInputPopup("Paste a string to OVERWRITE the current profile:", "", function(str)
            if not str or str == "" then
                return
            end

            local ok, err = ItruliaQoL:ImportIntoCurrentProfile(str)

            if ok then
                ItruliaQoL:Print("|cff00ff00Profile imported.|r")

                if EUI.RefreshPage then
                    EUI:RefreshPage()
                end
            else
                ItruliaQoL:Print("|cffff0000Import failed:|r", err)
            end
        end)
    end)
    y = y - h

    _, h = W:WideButton(parent, "Import as New Profile", y, function()
        ShowInputPopup("Paste a string to import as a new profile:", "", function(str)
            if not str or str == "" then
                return
            end

            ShowInputPopup("Enter a name for the new profile:", "", function(name)
                name = name and name:match("^%s*(.-)%s*$") or ""

                if name == "" then
                    return
                end

                local ok, err = ItruliaQoL:ImportAsNewProfile(str, name)

                if ok then
                    ItruliaQoL:Print("|cff00ff00Profile created:|r", name)

                    if EUI.RefreshPage then
                        EUI:RefreshPage()
                    end
                else
                    ItruliaQoL:Print("|cffff0000Import failed:|r", err)
                end
            end)
        end)
    end)
    y = y - h

    return math.abs(y)
end

function ItruliaQoL:CreateEUIMover(module, frame, moduleName)
    local EUI = self.EUI

    if not (EUI and EUI.RegisterUnlockElements and EUI.MakeUnlockElement) then
        return
    end

    EUI:RegisterUnlockElements({
        EUI.MakeUnlockElement({
            key = frame:GetName(),
            label = moduleName,
            group = "Itrulia",
            order = 1,
            isHidden = function()
                return not module.db.enabled
            end,
            getFrame = function()
                return frame
            end,
            getSize = function()
                return frame:GetWidth(), frame:GetHeight()
            end,
            -- EllesmereUI hands back CENTER/CENTER coords; store them the same
            -- shape the LibEditMode callback uses so UpdateStyles can reapply.
            savePos = function(_, point, relPoint, x, y)
                module.db.point = { point = point, relPoint = relPoint, x = x, y = y }
            end,
            -- Must return CENTER/CENTER for EllesmereUI to accept the stored pos.
            loadPos = function()
                local p = module.db.point

                if not p or not p.x then
                    return nil
                end

                return { point = p.point, relPoint = p.relPoint or p.point, x = p.x, y = p.y }
            end,
            clearPos = function()
                module.db.point = module:GetDefaults().point

                if frame.UpdateStyles then
                    frame:UpdateStyles()
                end
            end,
            applyPos = function()
                if frame.UpdateStyles then
                    frame:UpdateStyles()
                end
            end,
        }),
    }, addonName)
end

-- Registration
--
-- EllesmereUI's config sidebar is built from a hardcoded roster; add our entry
-- to the extension hooks it reads (mirrors NaowhUI_EUI). Safe to call once at
-- login: the sidebar is built lazily on first panel open.
function ItruliaQoL:InjectEUISidebar()
    local EUI = self.EUI

    if not EUI then
        return
    end

    EUI._addonInfoByFolder = EUI._addonInfoByFolder or {}
    EUI._addonInfoByFolder[addonName] = EUI._addonInfoByFolder[addonName] or {
        folder = addonName,
        display = "Itrulia QoL",
        search_name = "Itrulia QoL Itrulia",
        alwaysLoaded = true,
    }

    EUI._syncExempt = EUI._syncExempt or {}
    EUI._syncExempt[addonName] = true

    EUI.ADDON_GROUPS = EUI.ADDON_GROUPS or {}

    for _, group in ipairs(EUI.ADDON_GROUPS) do
        if group.key == "itrulia" then
            return
        end
    end

    table.insert(EUI.ADDON_GROUPS, 1, {
        key = "itrulia",
        label = "Itrulia",
        members = { addonName },
    })
end

-- Build and register the EllesmereUI category. Called from init.lua's
-- RegisterOptions with the fully-built AceConfig `parentOptions`.
function ItruliaQoL:RegisterEUI(parentOptions)
    local EUI = self.EUI

    -- Never gate on EUI.Widgets here. EllesmereUI_Widgets.lua wraps its whole
    -- body in a deferred init, so EUI.Widgets only exists once EnsureLoaded()
    -- has run -- and whether that happened before we get here is a PLAYER_LOGIN
    -- handler-order race (EllesmereUI registers its EnsureLoaded frame at file
    -- scope, we arrive via AceAddon's frame), so it flips whenever the installed
    -- addon set changes and silently skips the entire integration. Widgets is
    -- only read from buildPage, which runs on panel open, long after
    -- EnsureLoaded. NaowhUI_EUI guards on RegisterModule alone for this reason.
    if not (EUI and EUI.RegisterModule) then
        return
    end

    if self._euiRegistered then
        return
    end

    self._euiRegistered = true

    -- Bucket module groups onto pages.
    local perPage = {}

    for key, e in pairs(parentOptions.args) do
        if type(e) == "table" and e.type == "group" and not RESERVED[key] then
            local page = MODULE_PAGE[key] or PAGE_UTILITY
            perPage[page] = perPage[page] or {}
            table.insert(perPage[page], key)
        end
    end

    for _, list in pairs(perPage) do
        table.sort(list, function(a, b)
            local ea, eb = parentOptions.args[a], parentOptions.args[b]
            local oa, ob = ea.order or 100, eb.order or 100

            if oa == ob then
                return tostring(resolve(ea.name)) < tostring(resolve(eb.name))
            end

            return oa < ob
        end)
    end

    local function buildModulePage(page)
        return function(parent, yOffset)
            local W = EUI.Widgets
            local y = yOffset
            local _, h
            _, h = W:Spacer(parent, y, 8)
            y = y - h

            local list = perPage[page] or {}

            if #list == 0 then
                _, h = W:DualRow(parent, y, { text = "No settings on this page." })
                y = y - h
            end

            for _, key in ipairs(list) do
                local grp = parentOptions.args[key]
                local module = ItruliaQoL:GetModule(key, true)
                local spec = module and module.GetEUIOptions and module:GetEUIOptions()

                if spec then
                    -- Manual list (options.eui.lua).
                    _, h = W:SectionHeader(parent, spec.name or resolve(grp.name) or key, y)
                    y = y - h
                    y = ItruliaQoL:RenderEUIList(W, parent, y, spec.rows or {})
                end

                _, h = W:Spacer(parent, y, 12)
                y = y - h
            end

            return math.abs(y)
        end
    end

    local PAGES = {
        [PAGE_GENERAL] = function(parent, yOffset)
            local W = EUI.Widgets
            local y = yOffset
            local _, h
            _, h = W:Spacer(parent, y, 8)
            y = y - h
            _, h = W:SectionHeader(parent, "GENERAL", y)
            y = y - h

            -- Hand-authored, from general/options.eui.lua.
            local spec = ItruliaQoL.GetGeneralEUIOptions and ItruliaQoL:GetGeneralEUIOptions()

            if spec and spec.rows then
                y = ItruliaQoL:RenderEUIList(W, parent, y, spec.rows)
            end

            return math.abs(y)
        end,
        [PAGE_INDICATORS] = buildModulePage(PAGE_INDICATORS),
        [PAGE_ALERTS]     = buildModulePage(PAGE_ALERTS),
        [PAGE_UTILITY]    = buildModulePage(PAGE_UTILITY),
        [PAGE_PROFILES]   = function(parent, yOffset)
            return ItruliaQoL:BuildEUIProfilesPage(parent, yOffset)
        end,
        [PAGE_IMPEXP]     = function(parent, yOffset)
            return ItruliaQoL:BuildEUIImportExportPage(parent, yOffset)
        end,
    }

    self:InjectEUISidebar()

    local config = {
        title = "Itrulia QoL",
        description = "Quality-of-life indicators, alerts and helpers. Move things with EllesmereUI's unlock mode.",
        pages = PAGE_ORDER,
        buildPage = function(pageName, parent, yOffset)
            local fn = PAGES[pageName]

            return (fn and fn(parent, yOffset)) or math.abs(yOffset)
        end,
        onReset = function()
            ItruliaQoL.db:ResetProfile()
            ItruliaQoL:RefreshModules()

            if EUI.RefreshPage then
                EUI:RefreshPage()
            end
        end,
    }

    -- RegisterModule whitelists callers by their "AddOns/<folder>/" path via
    -- debugstack. From a loadstring chunk the caller reads as "[string ...]", so
    -- the guard falls through. (Same approach as NaowhUI_EUI.)
    _G.__ItruliaQoL_pendingReg = { key = addonName, config = config }

    local trampoline = loadstring([[
        local r = _G.__ItruliaQoL_pendingReg
        if r and EllesmereUI and EllesmereUI.RegisterModule then
            EllesmereUI:RegisterModule(r.key, r.config)
        end
    ]], "ItruliaQoL-register")
    local ok = trampoline and pcall(trampoline)
    _G.__ItruliaQoL_pendingReg = nil

    if not ok then
        pcall(function()
            EUI:RegisterModule(addonName, config)
        end)
    end

    -- Test mode follows unlock mode (the EllesmereUI equivalent of hooking ElvUI's ToggleMovers).
    if EUI.RegisterUnlockModeListener then
        EUI:RegisterUnlockModeListener(addonName, function(active)
            ItruliaQoL:ToggleTestMode(active and true or false)
        end)
    end
end
