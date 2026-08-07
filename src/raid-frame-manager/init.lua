local addonName, ItruliaQoL = ...
local moduleName = "RaidFrameManager"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local RaidFrameManager = ItruliaQoL:NewModule(moduleName)

RaidFrameManager.orientations = {
    HORIZONTAL = "Horizontal",
    VERTICAL = "Vertical",
}

local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

function RaidFrameManager:CanUse(spec)
    if spec.available and not spec.available() then
        return false
    end

    if not IsInGroup() then
        return true
    end

    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

function RaidFrameManager:GetUnusableReason(spec)
    if spec.available and not spec.available() then
        return "Not available right now."
    end

    return "Requires lead or assist."
end

function RaidFrameManager:InWantedGroup()
    if not self.db.onlyInGroup then
        return true
    end

    if self.db.onlyInRaid then
        return IsInRaid()
    end

    return IsInGroup()
end

RaidFrameManager.actionOrder = {"readyCheck", "rolePoll"}

RaidFrameManager.actions = {
    readyCheck = {
        name = "Ready Check",
        label = "Ready",
        tooltip = "Starts a ready check.",
        onClick = function()
            DoReadyCheck()
        end,
    },
    rolePoll = {
        name = "Role Check",
        label = "Roles",
        tooltip = "Starts a role poll.",
        available = function()
            return not HasLFGRestrictions() and not UnitInBattleground("player")
        end,
        onClick = function()
            InitiateRolePoll()
        end,
    },
}

function RaidFrameManager:StartPull(seconds)
    if ChatLocked() then
        ItruliaQoL:Print("|cffff0000Can't start a pull timer in combat.|r")

        return
    end

    C_PartyInfo.DoCountdown(seconds)
end

function RaidFrameManager:StopPull()
    if ChatLocked() then
        return
    end

    C_PartyInfo.DoCountdown(0)
end

function RaidFrameManager:GetPullTimers()
    self.db.pullTimers = self.db.pullTimers or {}

    return self.db.pullTimers
end

function RaidFrameManager:AddPullTimer(value)
    local seconds = tonumber(value)

    if not seconds then
        return false
    end

    seconds = math.floor(seconds + 0.5)

    if seconds < 0  then
        return false
    end

    local timers = self:GetPullTimers()

    for _, existing in ipairs(timers) do
        if existing == seconds then
            return false
        end
    end

    table.insert(timers, seconds)
    table.sort(timers)

    return true
end

function RaidFrameManager:RemovePullTimer(seconds)
    seconds = tonumber(seconds)

    if not seconds then
        return false
    end

    local timers = self:GetPullTimers()

    for index, existing in ipairs(timers) do
        if existing == seconds then
            table.remove(timers, index)

            return true
        end
    end

    return false
end

function RaidFrameManager:ResetPullTimers()
    self.db.pullTimers = self:GetDefaults().pullTimers
end

function RaidFrameManager:GetButtonSpecs()
    local specs = {}

    for _, key in ipairs(self.actionOrder) do
        if self.db.actions[key] then
            specs[#specs + 1] = self.actions[key]
        end
    end

    for _, seconds in ipairs(self:GetPullTimers()) do
        specs[#specs + 1] = {
            name = "Pull Timer",
            label = tostring(seconds),
            tooltip = ("Starts a %d second pull timer."):format(seconds),
            onClick = function()
                RaidFrameManager:StartPull(seconds)
            end,
        }
    end

    if self.db.cancelPull then
        specs[#specs + 1] = {
            name = "Cancel Pull",
            label = "Cancel",
            tooltip = "Cancels a running pull timer.",
            onClick = function()
                RaidFrameManager:StopPull()
            end,
        }
    end

    return specs
end

local function OnEvent(self)
    RaidFrameManager:ApplyBlizzardVisibility()

    self:UpdateVisibility()
    self:UpdatePermissions()
end

local function mouseoverAlpha(frame)
    local db = RaidFrameManager.db

    if frame:IsMouseOver() then
        return db.mouseoverAlpha or 1
    end

    return db.mouseoverFadeAlpha or 0
end

local function OnMouseoverUpdate(self, elapsed)
    self.mouseoverElapsed = (self.mouseoverElapsed or 0) + elapsed

    -- allows to move from 1 button to the other without it hiding and showing again
    if self.mouseoverElapsed < 0.1 then
        return
    end

    self.mouseoverElapsed = 0
    self:SetAlpha(mouseoverAlpha(self))
end

function RaidFrameManager:GenerateFrame(name, parent)
    local f = CreateFrame("Frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 0)
    f:SetSize(58, 20)
    f.buttons = {}
    f.shownCount = 0

    function f:AcquireButton(index)
        local existing = self.buttons[index]

        if existing then
            return existing
        end

        local btn = CreateFrame("Button", "$parent_Button" .. index, self)
        self.buttons[index] = btn

        btn.bg = ItruliaQoL:CreateBackground(btn)
        btn.border = ItruliaQoL:CreateBorder(btn)

        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER")
        btn.text:SetFont(LSM:Fetch("font", "Expressway"), 12, "OUTLINE")

        btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.highlight:SetAllPoints()
        btn.highlight:SetColorTexture(1, 1, 1, 0.12)

        local owner = self
        btn:SetScript("OnClick", function(button)
            if owner.isPreview or not button.usable or not button.spec then
                return
            end

            button.spec.onClick()
        end)

        btn:SetScript("OnEnter", function(button)
            local spec = button.spec

            if not spec or not RaidFrameManager.db.showTooltips then
                return
            end

            GameTooltip:SetOwner(button, "ANCHOR_TOP")
            GameTooltip:AddLine(spec.name)

            if spec.tooltip then
                GameTooltip:AddLine(spec.tooltip, 1, 1, 1, true)
            end

            if not button.usable then
                GameTooltip:AddLine(RaidFrameManager:GetUnusableReason(spec), 1, 0.2, 0.2, true)
            end

            GameTooltip:Show()
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return btn
    end

    function f:UpdateButtons()
        local db = RaidFrameManager.db
        local specs = RaidFrameManager:GetButtonSpecs()
        local horizontal = db.orientation ~= "VERTICAL"
        local spacing = db.spacing
        local paddingX, paddingY = db.paddingX, db.paddingY
        local font = db.font
        local justify = font.justifyH or "CENTER"

        -- The widest label sets the size for all of them: ragged buttons read as a
        -- broken bar, and a vertical one would have nothing to line up against.
        local textWidth, textHeight = 0, font.fontSize

        for index, spec in ipairs(specs) do
            local btn = self:AcquireButton(index)

            btn.spec = spec
            btn.bg:SetColor(db.buttonColor.r, db.buttonColor.g, db.buttonColor.b, db.buttonColor.a)

            btn.text:SetText(spec.label)
            btn.text:SetFont(LSM:Fetch("font", font.fontFamily), font.fontSize, font.fontOutline)
            btn.text:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b, db.textColor.a)
            btn.text:SetJustifyH(justify)
            btn.text:ClearAllPoints()

            if justify == "LEFT" then
                btn.text:SetPoint("LEFT", paddingX, 0)
            elseif justify == "RIGHT" then
                btn.text:SetPoint("RIGHT", -paddingX, 0)
            else
                btn.text:SetPoint("CENTER")
            end

            if font.fontOutline ~= "OUTLINESLUG" then
                btn.text:SetShadowColor(font.fontShadowColor.r, font.fontShadowColor.g, font.fontShadowColor.b, font.fontShadowColor.a)
                btn.text:SetShadowOffset(font.fontShadowXOffset, font.fontShadowYOffset)
            else
                btn.text:SetShadowColor(0, 0, 0, 0)
                btn.text:SetShadowOffset(0, 0)
            end

            textWidth = math.max(textWidth, btn.text:GetStringWidth())
            textHeight = math.max(textHeight, btn.text:GetStringHeight())
        end

        local width = math.ceil(textWidth) + paddingX * 2
        local height = math.ceil(textHeight) + paddingY * 2

        for index = 1, #specs do
            local btn = self.buttons[index]

            btn:SetSize(width, height)
            btn:ClearAllPoints()

            if index == 1 then
                btn:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            elseif horizontal then
                btn:SetPoint("TOPLEFT", self.buttons[index - 1], "TOPRIGHT", spacing, 0)
            else
                btn:SetPoint("TOPLEFT", self.buttons[index - 1], "BOTTOMLEFT", 0, -spacing)
            end

            btn:Show()
        end

        for index = #specs + 1, #self.buttons do
            self.buttons[index].spec = nil
            self.buttons[index]:Hide()
        end

        self.shownCount = #specs

        -- An empty bar still needs a size for the mover to be grabbable.
        local count = math.max(#specs, 1)

        if horizontal then
            self:SetSize(width * count + spacing * (count - 1), height)
        else
            self:SetSize(width, height * count + spacing * (count - 1))
        end
    end

    function f:UpdatePermissions()
        for index = 1, self.shownCount do
            local btn = self.buttons[index]
            local usable = self.isPreview or RaidFrameManager:CanUse(btn.spec)

            btn.usable = usable
            btn:SetAlpha(usable and 1 or 0.4)
        end
    end

    -- The preview is always fully opaque; hover fading there would just make the
    -- config page's own bar disappear while you configure it.
    function f:UpdateMouseover()
        if self.isPreview then
            return
        end

        if not RaidFrameManager.db.mouseover or not self:IsShown() then
            self:SetScript("OnUpdate", nil)
            self:SetAlpha(1)

            return
        end

        self.mouseoverElapsed = 0
        self:SetAlpha(mouseoverAlpha(self))
        self:SetScript("OnUpdate", OnMouseoverUpdate)
    end

    function f:UpdateVisibility()
        if self.isPreview then
            self:Show()

            return
        end

        local db = RaidFrameManager.db

        if not db.enabled then
            self:Hide()
            self:UpdateMouseover()

            return
        end

        local hiddenByCombat = PlayerIsInCombat() and not ItruliaQoL.testMode

        self:SetShown(not hiddenByCombat and (ItruliaQoL.testMode or RaidFrameManager:InWantedGroup()))
        self:UpdateMouseover()
    end

    function f:UpdateStyles()
        local db = RaidFrameManager.db

        if not E then
            self:ClearAllPoints()
            self:SetPoint(db.point.point, db.point.x, db.point.y)
        end

        self:SetFrameStrata(db.font.frameStrata or "MEDIUM")
        self:SetFrameLevel(db.font.frameLevel or 1)
        self:UpdateButtons()
        self:UpdatePermissions()
    end

    return f
end

-- Blizzard's manager goes under a hidden parent, which its own show logic cannot
-- undo. SetParent is blocked in combat, so PLAYER_REGEN_ENABLED re-asserts it.
local hiddenParent
local blizzardParent

function RaidFrameManager:ApplyBlizzardVisibility()
    local manager = CompactRaidFrameManager

    if not manager then
        return
    end

    if self.db.enabled then
        if not hiddenParent then
            hiddenParent = CreateFrame("Frame")
            hiddenParent:Hide()
        end

        blizzardParent = blizzardParent or manager:GetParent()

        if not InCombatLockdown() and manager:GetParent() ~= hiddenParent then
            manager:SetParent(hiddenParent)
        end
    elseif blizzardParent and manager:GetParent() == hiddenParent and not InCombatLockdown() then
        manager:SetParent(blizzardParent)

        -- Let Blizzard decide whether it belongs on screen right now; a plain
        -- Show() would put an empty manager up while solo.
        local updateShown = rawget(_G, "CompactRaidFrameManager_UpdateShown")

        if updateShown then
            updateShown()
        else
            manager:Show()
        end
    end
end

function RaidFrameManager:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_LEADER_CHANGED")

    if E then
        E:CreateMover(f, f:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    elseif ItruliaQoL.EUI then
        ItruliaQoL:CreateEUIMover(self, f, moduleName)
    else
        LEM:AddFrame(f, function(_, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end

    return f
end

function RaidFrameManager:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]
end

function RaidFrameManager:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile[moduleName] = profile[moduleName] or self:GetDefaults()
    self.db = profile[moduleName]

    self:ApplyBlizzardVisibility()

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:SetScript("OnEvent", OnEvent)
        f:UpdateStyles()
        f:UpdateVisibility()
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame:SetAlpha(1)
        self.frame:Hide()
    end
end

function RaidFrameManager:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH

    if self.frame then
        self.frame:UpdateStyles()
    end
end

function RaidFrameManager:OnEnable()
    self:RefreshConfig()
end

function RaidFrameManager:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    self.frame:UpdateVisibility()
end

function RaidFrameManager:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
            self.frame:UpdateVisibility()
        end

        ItruliaQoL:RefreshPreview(self)
    end)
end
