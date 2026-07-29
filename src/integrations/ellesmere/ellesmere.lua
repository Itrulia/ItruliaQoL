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
-- A module that draws something also gets a live preview of its own frame pinned
-- above the page, in EllesmereUI's content header -- see EUIPreviewHeaderBuilder.
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
-- Never restyle a disabled module. The indicators' FontStrings are shown by
-- default and are only ever hidden from their OnEvent handler, which
-- RefreshConfig unwires while the module is off -- so they sit there visible but
-- empty. A single UpdateStyles fills the text in and it stays on screen for
-- good, which reads as the module having enabled itself even though db.enabled
-- is still false. EllesmereUI reaches this from every options row's apply() and
-- from ApplySavedPositions at login (which applies positions for every
-- registered element, hidden or not), so it only surfaces under EllesmereUI.
-- `== false` rather than `not`: a module without the field must still restyle.
function ItruliaQoL:ApplyModuleStyles(moduleName)
    local module = self:GetModule(moduleName, true)

    -- Ahead of the disabled guard: the preview is a separate instance that never
    -- touches the screen, so it keeps tracking the settings while the module is off.
    -- Seeing what a module will look like before switching it on is the point of it.
    if module then
        self:RefreshPreview(module)
    end

    if module and module.db and module.db.enabled == false then
        return
    end

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

-- Translates one of our row specs into BuildCogPopup's own vocabulary, which
-- names a few fields differently (dropdown/colorpicker/button, `action`,
-- `inputWidth`).
local function cogPopupRow(item)
    if item.type == "execute" then
        return { type = "button", label = item.label, action = item.func }
    end

    local vals = item.values
    local t = item.type

    if t == "select" then
        t = "dropdown"
    elseif t == "color" then
        t = "colorpicker"
    end

    return {
        type = t,
        label = item.label,
        tooltip = item.tooltip,
        hasAlpha = item.hasAlpha,
        min = item.min,
        max = item.max,
        step = item.step,
        values = vals,
        order = vals and (item.order or selectOrder(vals)) or nil,
        disabled = item.disabled,
        disabledTooltip = item.disabledTooltip,
        rawTooltip = item.rawTooltip,
        inputWidth = item.width,
        get = item.get,
        set = item.set,
    }
end

-- EllesmereUI's cog popup dims a disabled colour row's swatch but, unlike its
-- other row types, leaves the label at full alpha -- so a greyed-out colour still
-- reads as active next to the rows above it. Dim it ourselves, finding the label
-- by its text the way EllesmereUI's own BuildCursorAnchorRow does. `colorRows` is
-- the popup's colour rows that have a `disabled`.
local LABEL_ALPHA, LABEL_ALPHA_DISABLED = 0.6, 0.25

local function dimDisabledCogLabels(popup, colorRows)
    local EUI = ItruliaQoL.EUI

    for _, row in ipairs(colorRows) do
        if not row._cogLabel then
            local text = (EUI.L and EUI.L(row.label)) or row.label

            for i = 1, popup:GetNumRegions() do
                local reg = select(i, popup:GetRegions())

                if reg and reg.GetText and reg:GetText() == text then
                    row._cogLabel = reg
                    break
                end
            end
        end

        if row._cogLabel then
            row._cogLabel:SetAlpha(row.disabled() and LABEL_ALPHA_DISABLED or LABEL_ALPHA)
        end
    end
end

-- Inline cogwheel on a settings row: a small cog left of the row's control that
-- opens a popup with secondary settings, the way EllesmereUI keeps offsets and
-- other detail settings off the page instead of spending a full row on each.
-- `cog` is { title = "Popup Title", rows = { <row>, ... }, icon = <texture?> },
-- its rows using the same specs as the page itself.
local function attachEUICog(region, cog)
    local EUI = ItruliaQoL.EUI

    if not region or not cog or not cog.rows or #cog.rows == 0 then
        return
    end

    if not (EUI and EUI.BuildCogPopup) then
        return
    end

    local rows = {}
    local colorRows = {}

    for i, row in ipairs(cog.rows) do
        rows[i] = cogPopupRow(row)

        if row.type == "color" and row.disabled then
            colorRows[#colorRows + 1] = row
        end
    end

    local _, cogShow = EUI.BuildCogPopup({ title = cog.title, rows = rows })

    -- The popup is built on first open, so its labels can only be dimmed from
    -- there. Chain into its own refresh as well, so an edit inside the popup that
    -- flips a colour row's `disabled` keeps the label in step.
    local function show(anchorBtn)
        cogShow(anchorBtn)

        local popup = cogShow._popupFrame

        if not popup or #colorRows == 0 then
            return
        end

        if not popup.itruliaQoLDimHooked then
            popup.itruliaQoLDimHooked = true

            local refresh = popup._refresh
            popup._refresh = function(...)
                refresh(...)
                dimDisabledCogLabels(popup, colorRows)
            end
        end

        dimDisabledCogLabels(popup, colorRows)
    end

    -- Chain off `_lastInline` so several inline extras on one row stack leftwards,
    -- which is the convention EllesmereUI's own pages follow.
    local anchor = region._lastInline or region._control

    local btn = CreateFrame("Button", nil, region)
    btn:SetSize(26, 26)

    if anchor then
        btn:SetPoint("RIGHT", anchor, "LEFT", -8, 0)
    else
        btn:SetPoint("RIGHT", region, "RIGHT", -20, 0)
    end

    region._lastInline = btn
    btn:SetFrameLevel(region:GetFrameLevel() + 5)
    btn:SetAlpha(0.4)

    local tex = btn:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(cog.icon or EUI.COGS_ICON)

    btn:SetScript("OnEnter", function(self)
        self:SetAlpha(0.7)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetAlpha(0.4)
    end)
    btn:SetScript("OnClick", function(self)
        show(self)
    end)
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
--   { pair   = { <row>, <row> } }                             -- two controls, half width each
--   { type = "empty" }                                        -- a blank half in a pair
--   { type = "toggle",  label=, tooltip=, disabled=, get=, set= }
--   { type = "slider",  label=, min=, max=, step=, disabled=, get=, set= }
--   { type = "select",  label=, values=, order=, disabled=, get=, set= }
--   { type = "color",   label=, hasAlpha=, get=, set= }       -- get -> r,g,b,a ; set(r,g,b,a)
--   { type = "input",   label=, width=, disabled=, get=, set= }
--   { type = "execute", label=, disabled=, func= }
--   { type = "icons",   items = { { icon=, label=, tooltip=, onClick=, desaturated= }, ... } }
--
-- Any control row may also carry
--   cog = { title = "Popup Title", rows = { <row>, ... } }
-- to put secondary settings behind a cogwheel next to its control instead of on
-- rows of their own (see attachEUICog).
--
-- `disabled` is a function returning a bool. `disabledTooltip` explains why (a
-- requirement noun that EllesmereUI wraps into "This option requires X to be
-- enabled", or a full sentence of your own with `rawTooltip = true`). `get`/`set`
-- read/write the module db directly and call the module's own apply (e.g.
-- self:RefreshConfig()).
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

    -- Translate one row spec into a DualRow half config. EllesmereUI's DualRow takes
    -- a left and a right config, so the same translation serves a full-width row
    -- (left only) and a `pair` (both halves) -- see the `pair` branch below.
    -- Returns nil for the specs that are not controls (headers, spacers, grids).
    local function halfConfig(item)
        if not item then
            return nil
        end

        if item.text and not item.type then
            return { text = item.text }
        end

        -- A blank half, so an odd control still gets half the row rather than
        -- stretching its control across the full width.
        if item.type == "empty" then
            return { type = "spacer" }
        end

        if item.type == "toggle" then
            return {
                type = "toggle",
                text = item.label,
                tooltip = item.tooltip,
                disabled = item.disabled,
                disabledTooltip = item.disabledTooltip,
                rawTooltip = item.rawTooltip,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            }
        end

        if item.type == "slider" then
            -- EllesmereUI's slider does arithmetic on the value, so it must never
            -- be nil. Existing profiles can lack a field added after they were
            -- created (module defaults only seed brand-new profiles), so fall
            -- back to the slider min.
            local getV = item.get

            return {
                type = "slider",
                text = item.label,
                tooltip = item.tooltip,
                min = item.min,
                max = item.max,
                step = item.step,
                disabled = item.disabled,
                disabledTooltip = item.disabledTooltip,
                rawTooltip = item.rawTooltip,
                getValue = function()
                    local v = getV and getV()

                    if v == nil then
                        return item.min or 0
                    end

                    return v
                end,
                setValue = item.set,
            }
        end

        if item.type == "select" then
            local vals = item.values or {}

            return {
                type = "dropdown",
                text = item.label,
                tooltip = item.tooltip,
                values = vals,
                order = item.order or selectOrder(vals),
                disabled = item.disabled,
                disabledTooltip = item.disabledTooltip,
                rawTooltip = item.rawTooltip,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            }
        end

        if item.type == "color" then
            return {
                type = "colorpicker",
                text = item.label,
                hasAlpha = item.hasAlpha,
                getValue = item.get,
                setValue = item.set,
            }
        end

        if item.type == "input" then
            return {
                type = "input",
                text = item.label,
                tooltip = item.tooltip,
                inputWidth = item.width or 180,
                disabled = item.disabled,
                disabledTooltip = item.disabledTooltip,
                rawTooltip = item.rawTooltip,
                getValue = item.get,
                setValue = wrap(item.set, item.refresh),
            }
        end

        if item.type == "execute" then
            return {
                type = "button",
                text = item.label,
                disabled = item.disabled,
                disabledTooltip = item.disabledTooltip,
                rawTooltip = item.rawTooltip,
                onClick = wrap(item.func, item.refresh),
            }
        end

        return nil
    end

    local row

    for _, item in ipairs(rows) do
        if item.pair then
            -- Two controls sharing one row, each getting half the width.
            row, h = W:DualRow(parent, y, halfConfig(item.pair[1]), halfConfig(item.pair[2]))
            attachEUICog(row._leftRegion, item.pair[1] and item.pair[1].cog)
            attachEUICog(row._rightRegion, item.pair[2] and item.pair[2].cog)
            y = y - h
        elseif item.rows then
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
        elseif item.type == "icons" then
            _, h = self:RenderEUIIconGrid(parent, y, item.items or {})
            y = y - h
        else
            -- Anything else is a single control on its own full-width row.
            local cfg = halfConfig(item)

            if cfg then
                row, h = W:DualRow(parent, y, cfg)
                attachEUICog(row._leftRegion, item.cog)
                y = y - h
            end
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

-- Live preview of the module's own frame, in EllesmereUI's content header -- the
-- non-scrolling strip between the tab bar and the page, which is where EllesmereUI
-- puts its own previews (see the resource bars / action bars options).
--
-- A module page gets one by returning this builder from the registration's
-- `getHeaderBuilder`; EllesmereUI runs it on each cold page build and passes the
-- header frame and its width, expecting the used height back. Pages that return nil
-- get no header at all, so modules that draw nothing cost nothing.
--
-- Lifecycle, and why nothing here has to free anything: when the page is left,
-- EllesmereUI either stashes the header's children (page cached) or orphans them with
-- SetParent(nil) (page cleared). Either way `display` goes with it and the preview
-- inside it stops drawing. On the way back, a cached page fires onPageCacheRestore
-- (RestoreEUIPreview below) and a cleared one rebuilds cold through this builder.
local PREVIEW_HEADER_HEIGHT = 120

-- `pageName` is passed through to PreparePreview, so a module split across tabs can
-- preview the state each tab configures. Its display is remembered per page: a tabbed
-- module has one header per tab, each cached separately by EllesmereUI.
function ItruliaQoL:EUIPreviewHeaderBuilder(module, pageName)
    if not self:HasPreview(module) then
        return nil
    end

    return function(hdr, hdrW)
        -- Clipped so an oversized preview (a long alert text, a wide bar) stays in the
        -- header strip instead of drawing over the page below it.
        local display = CreateFrame("Frame", nil, hdr)
        display:SetSize(hdrW, PREVIEW_HEADER_HEIGHT)
        display:SetPoint("CENTER", hdr, "CENTER", 0, 0)
        display:SetClipsChildren(true)

        if not ItruliaQoL:ShowPreview(module, display, pageName) then
            return 0
        end

        module.euiPreviewDisplays = module.euiPreviewDisplays or {}
        module.euiPreviewDisplays[pageName or true] = display

        return PREVIEW_HEADER_HEIGHT
    end
end

-- The builder for one page of a sidebar entry, or nil when that page previews nothing.
function ItruliaQoL:EUIPageHeaderBuilder(entry, pageName)
    local module = entry.previewFor and entry.previewFor(pageName)

    return module and self:EUIPreviewHeaderBuilder(module, pageName) or nil
end

-- Re-attach after EllesmereUI restores a cached page: the header's frames come back
-- from its stash rather than through the builder, so the preview has to be re-hung
-- and redrawn against the settings as they stand now.
function ItruliaQoL:RestoreEUIPreview(module, pageName)
    local displays = module.euiPreviewDisplays
    local display = displays and displays[pageName or true]

    -- No parent means EllesmereUI orphaned this header instead of caching it; the page
    -- is about to be built cold, and the builder will make a fresh display.
    if display and display:GetParent() then
        self:ShowPreview(module, display, pageName)
    end
end

-- Prominent "still being built" banner, shown on the General page only (see
-- `betaNotice` in addEntry): it is about the integration as a whole, so a copy
-- above every module's settings would just be a row they scroll past. Returns
-- (frame, height) so it slots into the same `y = y - h` flow as everything else.
function ItruliaQoL:RenderEUIBetaNotice(parent, y)
    local EUI = self.EUI
    local PP = EUI.PanelPP or EUI.PP
    local pad = EUI.CONTENT_PAD or 0
    local fontPath = (EUI.GetFontPath and EUI.GetFontPath()) or STANDARD_TEXT_FONT

    local PAD_X, PAD_Y = 12, 10
    local availW = parent:GetWidth() - pad * 2

    local frame = CreateFrame("Frame", nil, parent)
    PP.Point(frame, "TOPLEFT", parent, "TOPLEFT", pad, y)
    PP.Size(frame, availW, 1) -- provisional; resized once the text has wrapped

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.85, 0.55, 0.1, 0.12)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 16, "OUTLINE")
    title:SetTextColor(1, 0.75, 0.2, 1)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD_X, -PAD_Y)
    title:SetText("BETA")

    local body = frame:CreateFontString(nil, "OVERLAY")
    body:SetFont(fontPath, 12, "")
    body:SetTextColor(1, 1, 1, 0.8)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    body:SetWidth(availW - PAD_X * 2)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    body:SetText("The EllesmereUI integration is still being built. The ElvUI and standalone config panels are the complete ones for now (although uglier).")

    -- Where to take a problem. Amber rather than the body's white, because this is
    -- the line that saves the EllesmereUI Discord a support request that is not
    -- theirs to answer.
    local support = frame:CreateFontString(nil, "OVERLAY")
    support:SetFont(fontPath, 12, "")
    support:SetTextColor(1, 0.85, 0.5, 0.9)
    support:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -8)
    support:SetWidth(availW - PAD_X * 2)
    support:SetJustifyH("LEFT")
    support:SetWordWrap(true)
    support:SetText("Itrulia QoL is an inofficial module and not part of EllesmereUI. Please do not ask about it in the EllesmereUI Discord -- message Itrulia on Discord directly instead.")

    -- Straight to the complete panel, styled like EllesmereUI's own "Unlock Mode"
    -- footer link: accent text that brightens on hover. The EllesmereUI panel is
    -- closed first -- AceConfigDialog would otherwise open behind it -- and the
    -- open is deferred a frame so it does not run inside the panel's own hide.
    local ar, ag, ab = EUI.GetAccentColor()

    local linkText = frame:CreateFontString(nil, "OVERLAY")
    linkText:SetFont(fontPath, 12, "")
    linkText:SetTextColor(ar, ag, ab, 0.9)
    linkText:SetPoint("TOPLEFT", support, "BOTTOMLEFT", 0, -8)
    linkText:SetText("Open the standalone config >")

    local link = CreateFrame("Button", nil, frame)
    link:SetPoint("TOPLEFT", linkText, "TOPLEFT", -2, 2)
    link:SetPoint("BOTTOMRIGHT", linkText, "BOTTOMRIGHT", 2, -2)
    link:SetFrameLevel(frame:GetFrameLevel() + 5)
    link:SetScript("OnEnter", function()
        linkText:SetTextColor(ar + (1 - ar) * 0.25, ag + (1 - ag) * 0.25, ab + (1 - ab) * 0.25, 1)
    end)
    link:SetScript("OnLeave", function()
        linkText:SetTextColor(ar, ag, ab, 0.9)
    end)
    link:SetScript("OnClick", function()
        C_Timer.After(0, function()
            ItruliaQoL.CD:Open(addonName)
        end)
    end)

    local height = PAD_Y + title:GetStringHeight() + 6 + body:GetStringHeight()
        + 8 + support:GetStringHeight() + 8 + linkText:GetStringHeight() + PAD_Y + 8
    PP.Size(frame, availW, height)
    PP.CreateBorder(frame, 0.95, 0.65, 0.15, 1, 1)

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

-- Statusbar texture dropdown data in EllesmereUI's native format: the label is
-- the texture NAME and each row previews the texture behind it (via the
-- dropdown's `_menuOpts.background` hook, the same way EllesmereUI's own bar
-- texture pickers do), instead of showing the raw file path. Keyed by LSM name,
-- so it stays compatible with the stored value and LSM:Fetch.
function ItruliaQoL:EUIStatusbarValues()
    local LSM = self.LSM
    local vals, order = {}, {}

    for name in pairs(LSM:HashTable("statusbar")) do
        vals[name] = name
        order[#order + 1] = name
    end

    table.sort(order)

    vals._menuOpts = {
        itemHeight = 28,
        background = function(key)
            return LSM:Fetch("statusbar", key)
        end,
    }

    return vals, order
end

-- A single EllesmereUI-native "Statusbar texture" dropdown row (name label +
-- per-texture preview). `row` is the usual select spec minus values/order:
--   { label?, tooltip?, disabled?, refresh?, get, set }
-- `get`/`set` read/write the LSM texture name.
function ItruliaQoL:EUIStatusbarRow(row)
    local vals, order = self:EUIStatusbarValues()

    return {
        type = "select",
        label = row.label or "Statusbar texture",
        tooltip = row.tooltip,
        values = vals,
        order = order,
        disabled = row.disabled,
        refresh = row.refresh,
        get = row.get,
        set = row.set,
    }
end

-- Sound dropdown data in EllesmereUI's native format: the label is the sound
-- NAME and each row gets a click-to-preview speaker icon (via the dropdown's
-- `_menuOpts.icon*` hooks, the same way EllesmereUI's own sound pickers do),
-- instead of showing the raw file path. Keyed by LSM sound name, so it stays
-- compatible with the stored value and LSM:Fetch.
function ItruliaQoL:EUISoundValues()
    local LSM = self.LSM
    local vals, order = {}, {}

    for name in pairs(LSM:HashTable("sound")) do
        vals[name] = name
        order[#order + 1] = name
    end

    table.sort(order)

    vals._menuOpts = {
        itemHeight = 26,
        maxTextWidthPct = 0.8,
        searchable = true,
        iconAtlas = function()
            return "common-icon-sound"
        end,
        iconPressedAtlas = function()
            return "common-icon-sound-pressed"
        end,
        iconOnClick = function(key)
            local path = LSM:Fetch("sound", key)

            if path then
                PlaySoundFile(path, "Master")
            end
        end,
        iconTooltip = function()
            return "Preview Sound"
        end,
    }

    return vals, order
end

-- A single EllesmereUI-native "Sound" dropdown row (name label + click-to-preview
-- speaker icon). Same `row` spec as EUIStatusbarRow; `get`/`set` read/write the
-- LSM sound name.
function ItruliaQoL:EUISoundRow(row)
    local vals, order = self:EUISoundValues()

    return {
        type = "select",
        label = row.label or "Sound",
        tooltip = row.tooltip,
        values = vals,
        order = order,
        disabled = row.disabled,
        refresh = row.refresh,
        get = row.get,
        set = row.set,
    }
end

-- Shared font-settings rows for the manual list, mirroring createFontOptions.
-- `apply` runs after each change (e.g. the module's RefreshConfig). `exclude` is
-- an optional set of row keys to skip:
--   size, font, outline, justify, shadowX, shadowY, shadowColor, strata, level
--
-- The block is the three dropdowns -- Font, Outline, Frame Strata -- two to a row,
-- with everything else on their cogwheels: size and justify on Font's, the shadow
-- settings on Outline's, the frame level on Frame Strata's, the way EllesmereUI
-- keeps a picker's detail settings next to it rather than below it. `exclude`
-- still keys every setting individually, and a cog row falls back to a row of its
-- own when its host is the one excluded.
--
-- `lead` is an optional list of rows to put in front of the dropdowns, joining the
-- same two-to-a-row flow rather than sitting above it -- for a module whose own
-- text settings (a colour, say) belong with the font ones.
function ItruliaQoL:EUIFontRows(f, apply, exclude, lead)
    exclude = exclude or {}

    -- A slug outline draws its own backdrop, so the shadow settings do nothing.
    -- They stay on the Outline cog, greyed out with that explanation, rather than
    -- the cog itself coming and going as the outline changes.
    local function slug()
        return f.fontOutline == "OUTLINESLUG"
    end

    local SLUG_TIP = "A slug outline draws its own backdrop, so a text shadow has no effect."

    local rows = {}
    local function add(key, row)
        if exclude[key] then
            return
        end

        rows[#rows + 1] = row
    end

    -- The cog spec for `specs` ({ key, row } pairs), dropping excluded rows and
    -- returning nil when nothing is left to put behind the cog.
    local function cogSpec(title, specs)
        local cogRows = {}

        for _, spec in ipairs(specs) do
            if not exclude[spec[1]] then
                cogRows[#cogRows + 1] = spec[2]
            end
        end

        if #cogRows == 0 then
            return nil
        end

        return { title = title, rows = cogRows }
    end

    local sizeRow = {
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
    }
    local justifyRow = {
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
    }
    local shadowXRow = {
        type = "slider",
        label = "Shadow X Offset",
        min = -5,
        max = 5,
        step = 1,
        disabled = slug,
        disabledTooltip = SLUG_TIP,
        rawTooltip = true,
        get = function()
            return f.fontShadowXOffset
        end,
        set = function(v)
            f.fontShadowXOffset = v
            apply()
        end,
    }
    local shadowYRow = {
        type = "slider",
        label = "Shadow Y Offset",
        min = -5,
        max = 5,
        step = 1,
        disabled = slug,
        disabledTooltip = SLUG_TIP,
        rawTooltip = true,
        get = function()
            return f.fontShadowYOffset
        end,
        set = function(v)
            f.fontShadowYOffset = v
            apply()
        end,
    }
    local shadowColorRow = {
        type = "color",
        label = "Shadow Color",
        hasAlpha = true,
        disabled = slug,
        disabledTooltip = SLUG_TIP,
        rawTooltip = true,
        get = function()
            local c = f.fontShadowColor
            return c.r, c.g, c.b, c.a
        end,
        set = function(r, g, b, a)
            f.fontShadowColor = { r = r, g = g, b = b, a = a }
            apply()
        end,
    }

    -- The dropdowns, paired up at the tail of this function; everything they host
    -- lives on their cogwheels. Any `lead` rows join the same flow, ahead of them.
    local pickers = {}

    for _, row in ipairs(lead or {}) do
        pickers[#pickers + 1] = row
    end

    -- Font: the family dropdown, with size and justify on its cogwheel.
    if exclude.font then
        add("size", sizeRow)
        add("justify", justifyRow)
    else
        local fontRow = self:EUIFontFamilyRow(f, apply)
        fontRow.cog = cogSpec("Font Settings", {
            { "size", sizeRow },
            { "justify", justifyRow },
        })

        pickers[#pickers + 1] = fontRow
    end

    -- Outline: the mode dropdown, with the shadow settings on its cogwheel.
    local shadowSpecs = {
        { "shadowX", shadowXRow },
        { "shadowY", shadowYRow },
        { "shadowColor", shadowColorRow },
    }

    if exclude.outline then
        for _, spec in ipairs(shadowSpecs) do
            add(spec[1], spec[2])
        end
    else
        local outlineRow = {
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
        }

        outlineRow.cog = cogSpec("Shadow Settings", shadowSpecs)

        pickers[#pickers + 1] = outlineRow
    end

    -- Frame Strata: the strata dropdown, with the level on its cogwheel.
    local levelRow = {
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
    }

    if exclude.strata then
        add("level", levelRow)
    else
        local strataRow = {
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
        }

        strataRow.cog = cogSpec("Frame Settings", { { "level", levelRow } })

        pickers[#pickers + 1] = strataRow
    end

    -- The pickers go first, two to a row, above whatever fell back to a row of its
    -- own. An odd one out keeps its half rather than stretching over the full row.
    local at = 1

    for i = 1, #pickers, 2 do
        local left, right = pickers[i], pickers[i + 1]

        table.insert(rows, at, { pair = { left, right or { type = "empty" } } })
        at = at + 1
    end

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

-- Sidebar layout
--
-- Every module gets its own row under an "Itrulia QoL" group header, matching
-- how EllesmereUI lists its own suite, so a module is one click away instead of
-- being buried on an arbitrary Indicators/Alerts/Utility page. Each row owns a
-- single page; the panel header already names the module, so pages don't need
-- distinct names beyond the two on the Profiles row.
local GROUP_KEY   = "itrulia"
local GROUP_LABEL = "Itrulia QoL"

local PAGE_GENERAL  = "General"
local PAGE_DISPLAY  = "Display"
local PAGE_SETTINGS = "Settings"
local PAGE_PROFILES = "Profiles"
local PAGE_IMPEXP   = "Import / Export"

-- The single tab of a module that doesn't declare EUIPages. A module that draws
-- something calls that tab "Display", matching the first tab of the modules that
-- do declare pages; one that only listens for events (FocusTargetMarker,
-- PreventRelease) has no display to name, so its tab stays "Settings".
-- PreparePreview is the same draws-something flag the preview header keys off.
local function defaultPage(module)
    return module.PreparePreview and PAGE_DISPLAY or PAGE_SETTINGS
end

-- Modules whose settings share one sidebar row instead of getting one each. Each
-- member becomes a tab on that row, and the row is emitted where its first member
-- would have appeared, so the surrounding order is untouched. The row needs its
-- own `description`: it is shown per row rather than per tab, so the members'
-- individual blurbs are not rendered anywhere.
local COMBINED_ROWS = {
    {
        key = "PetIndicators",
        display = "Pet Indicators",
        members = { "PetMissingIndicator", "PetPassiveIndicator" },
        description = "Missing/Passive pet text indicators.",
    },
}

local COMBINED_BY_MODULE = {}

for _, row in ipairs(COMBINED_ROWS) do
    for _, key in ipairs(row.members) do
        COMBINED_BY_MODULE[key] = row
    end
end

-- Top-level parentOptions.args keys that are not modules.
local RESERVED = {
    all = true, enable = true, description = true, profiles = true, importExport = true,
}

-- Addon-wide settings, from general/options.eui.lua.
function ItruliaQoL:BuildEUIGeneralPage(parent, yOffset)
    local W = self.EUI.Widgets
    local y = yOffset
    local _, h

    _, h = W:Spacer(parent, y, 8)
    y = y - h
    _, h = W:SectionHeader(parent, "GENERAL", y)
    y = y - h

    local spec = self.GetGeneralEUIOptions and self:GetGeneralEUIOptions()

    if spec and spec.rows then
        y = self:RenderEUIList(W, parent, y, spec.rows)
    end

    return math.abs(y)
end

-- One module's settings, from its own options.eui.lua. No section header for the
-- module name -- it is already the panel title and the selected sidebar row.
--
-- `descriptionInHeader` drops the leading plain-text row: every module's list
-- opens with one describing the module, and when that text is the panel header
-- instead (see descriptionFor in RegisterEUI) printing it again wastes the top of
-- the page. Combined rows pass it too, so their tabs stay clean -- but note that
-- config.description is per row rather than per page, so a combined row's header
-- carries one shared blurb and the members' individual ones are not shown.
--
-- `pageName` is forwarded to GetEUIOptions so a module big enough to want tabs can
-- return just that page's rows. Such a module lists its tabs in a static
-- `EUIPages` field, which is read at registration -- a plain table rather than a
-- call, so building the sidebar does not mean invoking every module at login.
-- Modules without EUIPages ignore the argument and keep their single page.
function ItruliaQoL:BuildEUIModulePage(module, parent, yOffset, descriptionInHeader, pageName)
    local W = self.EUI.Widgets
    local y = yOffset
    local _, h

    _, h = W:Spacer(parent, y, 8)
    y = y - h

    local spec = module.GetEUIOptions and module:GetEUIOptions(pageName)

    if not spec then
        _, h = W:DualRow(parent, y, { text = "This module has no EllesmereUI settings yet." })

        return math.abs(y - h)
    end

    local rows = spec.rows or {}
    local first = rows[1]

    if descriptionInHeader and first and first.text and not (first.type or first.rows or first.header) then
        local rest = {}

        for i = 2, #rows do
            rest[#rest + 1] = rows[i]
        end

        rows = rest
    end

    -- Modules whose only setting was the enable flag have nothing left to draw once
    -- that moved to the sidebar switch, so say so rather than showing a blank page.
    if #rows == 0 then
        _, h = W:DualRow(parent, y, { text = "Nothing to configure -- use the switch on the sidebar row to turn this on or off." })

        return math.abs(y - h)
    end

    y = self:RenderEUIList(W, parent, y, rows)

    return math.abs(y)
end

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
            group = GROUP_LABEL,
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
            -- Both gated on enabled for the reason described on
            -- ApplyModuleStyles: EllesmereUI calls applyPos for every registered
            -- element at login regardless of isHidden, and restyling a disabled
            -- module is what puts it on screen.
            clearPos = function()
                module.db.point = module:GetDefaults().point

                if module.db.enabled ~= false and frame.UpdateStyles then
                    frame:UpdateStyles()
                end
            end,
            applyPos = function()
                if module.db.enabled ~= false and frame.UpdateStyles then
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
-- `entries` is the ordered list of { key = , display = } rows to show under our
-- group header. Each key is a synthetic folder name (never a real addon folder),
-- so it must be marked alwaysLoaded: EllesmereUI otherwise greys the row and
-- offers a power toggle for an addon that does not exist.
function ItruliaQoL:InjectEUISidebar(entries)
    local EUI = self.EUI

    if not EUI then
        return
    end

    EUI._addonInfoByFolder = EUI._addonInfoByFolder or {}
    EUI._syncExempt = EUI._syncExempt or {}

    local members = {}

    for _, entry in ipairs(entries) do
        EUI._addonInfoByFolder[entry.key] = EUI._addonInfoByFolder[entry.key] or {
            folder = entry.key,
            display = entry.display,
            search_name = entry.display .. " Itrulia QoL Itrulia",
            alwaysLoaded = true,
        }

        EUI._syncExempt[entry.key] = true
        members[#members + 1] = entry.key
    end

    EUI.ADDON_GROUPS = EUI.ADDON_GROUPS or {}

    -- Member order is authoritative for the sidebar, so on a repeat call replace
    -- the list rather than bailing -- otherwise a changed module set keeps the
    -- stale rows.
    for _, group in ipairs(EUI.ADDON_GROUPS) do
        if group.key == GROUP_KEY then
            group.members = members

            return
        end
    end

    -- Appended, not prepended: we are a companion rather than part of the suite,
    -- and this group is long enough that putting it first would push EllesmereUI's
    -- own addons down the list.
    table.insert(EUI.ADDON_GROUPS, {
        key = GROUP_KEY,
        label = GROUP_LABEL,
        members = members,
    })
end

-- "(Inofficial Module)" beside our sidebar group header, so the group reads as a
-- companion addon rather than part of the EllesmereUI suite.
--
-- EllesmereUI's group rows carry only their own accent-coloured label, so the note
-- is a second FontString anchored to it, smaller and grey. The row is built once
-- per CreateMainFrame (kept in _sidebarGroupButtons, keyed by group), so attaching
-- once is enough -- guarded by _itruliaNote, since this runs on every panel open.
function ItruliaQoL:AttachEUISidebarGroupNote()
    local EUI = self.EUI
    local headers = EUI and EUI._sidebarGroupButtons
    local header = headers and headers[GROUP_KEY]

    if not header or header._itruliaNote or not header._label then
        return
    end

    local note = header:CreateFontString(nil, "OVERLAY")
    note:SetFont((EUI.GetFontPath and EUI.GetFontPath()) or STANDARD_TEXT_FONT, 11, "")
    note:SetTextColor(1, 1, 1, 0.35)
    note:SetText("(Inofficial Module)")
    note:SetPoint("LEFT", header._label, "RIGHT", 6, -1)

    header._itruliaNote = note
end

-- Per-module enable switch on the sidebar row itself, so a module can be turned on
-- or off without opening its page.
--
-- EllesmereUI has no API for this -- rows are built from _addonInfoByFolder and the
-- only right-edge controls it knows about are its own power / sync / download
-- icons -- so we attach ours to the row frame it exposes via _sidebarButtons. Three
-- things this has to work around:
--   * the row is a Button that selects the module on click, so ours sits several
--     frame levels above it to receive its own clicks;
--   * rows are created once per CreateMainFrame and only repositioned afterwards,
--     so attaching once per row is enough (guarded by row._itruliaEnable);
--   * EllesmereUI clamps the row label against btn._dlIcon, which exists (hidden)
--     on every row, so the right edge is already reserved and long display names
--     will not run under the switch.
--
-- A combined row switches every member at once: the switch reads as on when ANY of
-- them is on, and a click sets them all to the same state. The members still own
-- their own enabled flags, editable individually from their tabs.
function ItruliaQoL:AttachEUISidebarSwitches(entries)
    local EUI = self.EUI
    local rows = EUI._sidebarButtons

    if not rows then
        return
    end

    for _, entry in ipairs(entries) do
        local members = entry.members
        local row = members and members[1] and rows[entry.key]

        if row and not row._itruliaEnable then
            local btn = CreateFrame("Button", nil, row)

            -- Same icon, size and slot EllesmereUI uses for its own power toggle.
            btn:SetSize(13, 13)
            btn:SetPoint("RIGHT", row, "RIGHT", -18, 0)
            btn:SetFrameLevel(row:GetFrameLevel() + 5)

            local tex = btn:CreateTexture(nil, "OVERLAY")
            tex:SetAllPoints()
            tex:SetTexture(EUI.ICONS_PATH .. "power.png")

            -- On when ANY member is on, so a combined row reads as enabled even if
            -- only one of its modules is.
            local function anyOn()
                for _, member in ipairs(members) do
                    if member.module.db and member.module.db.enabled then
                        return true
                    end
                end

                return false
            end

            -- Icon alpha plus the row label: a module that is off greys its name, the
            -- way EllesmereUI dims an addon that is not installed. Its NAV_* colours
            -- are file-locals, so the alphas are copied from EllesmereUI.lua's
            -- "Sidebar nav states" block -- all 1,1,1 with alpha 1 (selected), 0.6
            -- (enabled), 0.11 (disabled), 0.86 (hover enabled), 0.39 (hover disabled).
            --
            -- We cannot simply set row._loaded = false and let EllesmereUI paint it:
            -- the row's OnClick is gated on _loaded, so the row would stop opening and
            -- there would be no way back in to re-enable the module.
            local function paint(hovered)
                local on = anyOn()

                tex:SetVertexColor(1, 1, 1, on and 1 or 0.5)

                local label = row._label

                if not label then
                    return
                end

                if not on then
                    label:SetTextColor(1, 1, 1, hovered and 0.39 or 0.11)
                elseif hovered then
                    label:SetTextColor(1, 1, 1, 0.86)
                elseif EUI.GetActiveModule and EUI:GetActiveModule() == entry.key then
                    label:SetTextColor(1, 1, 1, 1)
                else
                    label:SetTextColor(1, 1, 1, 0.6)
                end
            end

            row._itruliaRepaint = paint

            -- EllesmereUI's own hover scripts recolour the label from _loaded, which
            -- is always true for our rows, so wrap them and restore our state after.
            local rowEnter, rowLeave = row:GetScript("OnEnter"), row:GetScript("OnLeave")

            row:SetScript("OnEnter", function(self2, ...)
                if rowEnter then
                    rowEnter(self2, ...)
                end

                paint(true)
            end)

            row:SetScript("OnLeave", function(self2, ...)
                if rowLeave then
                    rowLeave(self2, ...)
                end

                paint(false)
            end)

            paint()

            -- Wrapped, not passed directly: OnShow hands the frame to its handler,
            -- which would arrive as a truthy `hovered`.
            btn:SetScript("OnShow", function()
                paint()
            end)

            btn:SetScript("OnClick", function()
                -- Every member follows the row: on when any was off, off otherwise.
                local enable = not anyOn()

                for _, member in ipairs(members) do
                    local db = member.module.db

                    if db then
                        db.enabled = enable

                        if member.module.RefreshConfig then
                            member.module:RefreshConfig()
                        end
                    end
                end

                paint()

                -- Keep the members' own Enable toggles in step if the page is open.
                if EUI.GetActiveModule and EUI:GetActiveModule() == entry.key and EUI.RefreshPage then
                    EUI:RefreshPage(true)
                end
            end)

            -- Hover previews the action, red to turn off and green to turn on,
            -- matching EllesmereUI's own power icon.
            btn:SetScript("OnEnter", function(self2)
                local on = anyOn()

                if on then
                    tex:SetVertexColor(0.824, 0.212, 0.212, 1)
                else
                    tex:SetVertexColor(0.212, 0.824, 0.325, 1)
                end

                if EUI.ShowWidgetTooltip then
                    EUI.ShowWidgetTooltip(self2,
                        (on and "Disable " or "Enable ") .. entry.display)
                end
            end)

            btn:SetScript("OnLeave", function()
                paint()

                if EUI.HideWidgetTooltip then
                    EUI.HideWidgetTooltip()
                end
            end)

            row._itruliaEnable = btn
        end
    end
end

-- Repaint every row we own. EllesmereUI recolours labels from its own state in
-- RefreshSidebarStates (on each panel open) and UpdateSidebarHighlight (on each
-- module switch), so the disabled grey has to be reapplied after both.
function ItruliaQoL:RefreshEUISidebarRows(entries)
    local rows = self.EUI._sidebarButtons

    if not rows then
        return
    end

    for _, entry in ipairs(entries) do
        local row = rows[entry.key]

        if row and row._itruliaRepaint then
            row._itruliaRepaint()
        end
    end
end

-- RegisterModule whitelists callers by their "AddOns/<folder>/" path via
-- debugstack. From a loadstring chunk the caller reads as "[string ...]", so the
-- guard falls through. (Same approach as NaowhUI_EUI.) Compiled once and reused
-- for every row; it reads the pending registration back out of a global.
local euiRegisterChunk = loadstring([[
    local r = _G.__ItruliaQoL_pendingReg
    if r and EllesmereUI and EllesmereUI.RegisterModule then
        EllesmereUI:RegisterModule(r.key, r.config)
    end
]], "ItruliaQoL-register")

-- Never assume registration worked. RegisterModule returns silently when the
-- caller isn't whitelisted, so a clean pcall proves nothing -- check the registry
-- itself (_modules is EllesmereUI's read-only alias). Without this a rejected
-- registration is indistinguishable from a working one until you notice the
-- sidebar row selects nothing.
function ItruliaQoL:RegisterEUIModule(key, config)
    local EUI = self.EUI
    local ok, err = false, nil

    _G.__ItruliaQoL_pendingReg = { key = key, config = config }

    if euiRegisterChunk then
        ok, err = pcall(euiRegisterChunk)
    end

    _G.__ItruliaQoL_pendingReg = nil

    if not ok then
        ok, err = pcall(EUI.RegisterModule, EUI, key, config)
    end

    if not (EUI._modules and EUI._modules[key]) then
        self:Print("|cffff0000EllesmereUI registration failed for|r", key,
            err or "caller rejected by EllesmereUI:RegisterModule")
    end
end

-- Build and register the EllesmereUI rows. Called from init.lua's
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

    -- One sidebar row per module, in the AceConfig tree's own order.
    local moduleKeys = {}

    for key, e in pairs(parentOptions.args) do
        if type(e) == "table" and e.type == "group" and not RESERVED[key] then
            moduleKeys[#moduleKeys + 1] = key
        end
    end

    table.sort(moduleKeys, function(a, b)
        local ea, eb = parentOptions.args[a], parentOptions.args[b]
        local oa, ob = ea.order or 100, eb.order or 100

        if oa == ob then
            return tostring(resolve(ea.name)) < tostring(resolve(eb.name))
        end

        return oa < ob
    end)

    local entries = {}

    -- Keys are namespaced so they can never collide with a real addon folder in
    -- EllesmereUI's roster. `build` takes (pageName, parent, y).
    -- `members` is the list of { key = , module = } this row fronts -- one entry for
    -- a normal module row, several for a combined one. It is what gives the row its
    -- enable switch (see AttachEUISidebarSwitches); rows without it (General,
    -- Profiles) get none.
    -- `previewFor` maps a page name to the module whose preview belongs in that page's
    -- content header -- one module for a normal row, the tab's own member for a
    -- combined one. Rows without it (General, Profiles) show no preview.
    local function addEntry(key, display, pages, build, description, members, previewFor)
        entries[#entries + 1] = {
            key = addonName .. "_" .. key,
            display = display,
            pages = pages,
            build = build,
            description = description,
            members = members,
            previewFor = previewFor,
            betaNotice = key == "General",
        }
    end

    -- Each module's own blurb, reused as the panel header description so it does
    -- not have to be repeated as the first row of the page. Read from the
    -- AceConfig tree rather than GetEUIOptions, which would mean calling into
    -- every module at login just to build the sidebar.
    local function descriptionFor(key)
        local grp = parentOptions.args[key]
        local desc = grp and grp.args and grp.args.description
        local text = desc and resolve(desc.name)

        if not text then
            return nil
        end

        -- The AceConfig strings pad themselves with trailing newlines for ElvUI's
        -- layout; the header does its own spacing.
        return (tostring(text):gsub("%s+$", ""))
    end

    addEntry("General", "General", { PAGE_GENERAL }, function(_, parent, y)
        return ItruliaQoL:BuildEUIGeneralPage(parent, y)
    end, "Quality-of-life indicators, alerts and helpers. Move things with EllesmereUI's unlock mode.")

    local function displayFor(key)
        local grp = parentOptions.args[key]

        return tostring(resolve(grp and grp.name) or key)
    end

    local emittedCombined = {}

    for _, key in ipairs(moduleKeys) do
        local combined = COMBINED_BY_MODULE[key]

        -- Skip modules with no hand-authored list -- they would get a sidebar row
        -- that opens an empty page. DungeonTeleports is the only one today.
        if combined then
            if not emittedCombined[combined.key] then
                emittedCombined[combined.key] = true

                local parts = {}

                for _, memberKey in ipairs(combined.members) do
                    local member = self:GetModule(memberKey, true)

                    if member and member.GetEUIOptions then
                        parts[#parts + 1] = {
                            key = memberKey,
                            module = member,
                            display = displayFor(memberKey),
                        }
                    end
                end

                if #parts > 0 then
                    -- One tab per member, labelled with its own name, so each keeps
                    -- a page to itself instead of sharing one long scroll.
                    local pages, moduleByPage = {}, {}

                    for _, part in ipairs(parts) do
                        pages[#pages + 1] = part.display
                        moduleByPage[part.display] = part.module
                    end

                    addEntry(combined.key, combined.display, pages,
                        function(pageName, parent, y)
                            local module = moduleByPage[pageName] or parts[1].module

                            return ItruliaQoL:BuildEUIModulePage(module, parent, y, true)
                        end, combined.description, parts, function(pageName)
                            return moduleByPage[pageName]
                        end)
                end
            end
        else
            local module = self:GetModule(key, true)

            if module and module.GetEUIOptions then
                -- Modules with nothing to turn off opt out of the row's enable
                -- switch by setting EUINoEnableSwitch; no members means no switch.
                local members

                if not module.EUINoEnableSwitch then
                    members = { { key = key, module = module } }
                end

                addEntry(key, displayFor(key), module.EUIPages or { defaultPage(module) },
                    function(pageName, parent, y)
                        return ItruliaQoL:BuildEUIModulePage(module, parent, y, true, pageName)
                    end, descriptionFor(key), members, function()
                        return module
                    end)
            end
        end
    end

    addEntry("Profiles", "Profiles", { PAGE_PROFILES, PAGE_IMPEXP }, function(pageName, parent, y)
        if pageName == PAGE_IMPEXP then
            return ItruliaQoL:BuildEUIImportExportPage(parent, y)
        end

        return ItruliaQoL:BuildEUIProfilesPage(parent, y)
    end)

    self:InjectEUISidebar(entries)

    -- Attach the row switches as soon as the panel opens rather than waiting for a
    -- page to be built. The rows only exist once CreateMainFrame has run, and that
    -- is reachable only from these three, each of which also runs
    -- RefreshSidebarStates before returning -- so a post-hook on them is the
    -- earliest point at which every row is present. Attaching is idempotent, so
    -- firing on every open (and on Toggle's close) costs nothing.
    if not self._euiSwitchHooked then
        self._euiSwitchHooked = true

        for _, name in ipairs({ "Show", "Toggle", "ShowModule" }) do
            if EUI[name] then
                hooksecurefunc(EUI, name, function()
                    ItruliaQoL:AttachEUISidebarGroupNote()
                    ItruliaQoL:AttachEUISidebarSwitches(entries)
                    ItruliaQoL:RefreshEUISidebarRows(entries)
                end)
            end
        end

        -- SelectModule recolours the outgoing and incoming labels itself.
        if EUI.SelectModule then
            hooksecurefunc(EUI, "SelectModule", function()
                ItruliaQoL:RefreshEUISidebarRows(entries)
            end)
        end
    end

    for _, entry in ipairs(entries) do
        local build = entry.build

        -- onReset wipes the whole profile, so it only belongs on the General row.
        -- EllesmereUI labels the footer button "Reset <row>", which on a module
        -- row would read as resetting that module alone.
        local onReset

        if entry.key == addonName .. "_General" then
            onReset = function()
                ItruliaQoL.db:ResetProfile()
                ItruliaQoL:RefreshModules()

                if EUI.RefreshPage then
                    EUI:RefreshPage()
                end
            end
        end

        self:RegisterEUIModule(entry.key, {
            title = GROUP_LABEL .. " - " .. entry.display,
            description = "|cffffbf33BETA:|r " .. (entry.description or ""),
            pages = entry.pages,
            buildPage = function(pageName, parent, yOffset)
                -- Filling the content header is the page's own job on a cold build;
                -- getHeaderBuilder below only hands the same builder back so
                -- EllesmereUI can re-run it after invalidating its header cache.
                --
                -- Not while prebuilding: EllesmereUI's global search runs buildPage
                -- against an off-screen wrapper to index it, and there is only ever
                -- one preview instance per module -- filling the header here would
                -- move it out of the page the player is actually looking at.
                local headerBuilder = not EUI._prebuilding
                    and ItruliaQoL:EUIPageHeaderBuilder(entry, pageName)

                if headerBuilder and EUI.SetContentHeader then
                    EUI:SetContentHeader(headerBuilder)
                end

                local y = yOffset

                if entry.betaNotice then
                    local _, noticeH = ItruliaQoL:RenderEUIBetaNotice(parent, y)
                    y = y - noticeH
                end

                return build(pageName, parent, y) or math.abs(y)
            end,
            getHeaderBuilder = function(pageName)
                return ItruliaQoL:EUIPageHeaderBuilder(entry, pageName)
            end,
            onPageCacheRestore = function(pageName)
                local module = entry.previewFor and entry.previewFor(pageName)

                if module then
                    ItruliaQoL:RestoreEUIPreview(module, pageName)
                end
            end,
            onReset = onReset,
        })
    end

    -- Test mode follows unlock mode (the EllesmereUI equivalent of hooking ElvUI's ToggleMovers).
    if EUI.RegisterUnlockModeListener then
        EUI:RegisterUnlockModeListener(addonName, function(active)
            ItruliaQoL:ToggleTestMode(active and true or false)
        end)
    end
end
