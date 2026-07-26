local addonName, ItruliaQoL = ...
local moduleName = "RepairIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local RepairIndicator = ItruliaQoL:NewModule(moduleName)

local function OnEvent(self, event, ...)
    if ItruliaQoL.testMode then
        self.text:Show()
        return
    end

    if not PlayerIsInCombat() and self:RequiresRepair() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

function RepairIndicator:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)
    f:SetPoint("CENTER", 0, 300)
    f:SetSize(28, 28)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
    f.text:SetText("**Low Durability!**")
    f.text:SetTextColor(1, 1, 1)
    f.text:SetJustifyH("CENTER")
    f.text:Hide()

    function f:RequiresRepair()
        for slot = 1, 18 do
            local current, maximum = GetInventoryItemDurability(slot)

            if current and maximum then
                if current == 0 or current / maximum < 0.2 then
                    return true
                end
            end
        end

        return false
    end

    function f:UpdateStyles()
        if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
            if not E then
                self:ClearAllPoints()
                self:SetPoint(RepairIndicator.db.point.point, RepairIndicator.db.point.x, RepairIndicator.db.point.y)
            end

            self:SetFrameStrata(RepairIndicator.db.font.frameStrata or "BACKGROUND")
            self:SetFrameLevel(RepairIndicator.db.font.frameLevel or 1)
            self.text:ClearAllPoints()
            self.text:SetPoint(RepairIndicator.db.font.justifyH or "CENTER")
            self.text:SetJustifyH(RepairIndicator.db.font.justifyH or "CENTER")
            self.text:SetText(RepairIndicator.db.displayText)
            self.text:SetTextColor(RepairIndicator.db.color.r, RepairIndicator.db.color.g, RepairIndicator.db.color.b, RepairIndicator.db.color.a)
            if RepairIndicator.db.font.fontOutline ~= "OUTLINESLUG" then
                self.text:SetShadowColor(RepairIndicator.db.font.fontShadowColor.r, RepairIndicator.db.font.fontShadowColor.g, RepairIndicator.db.font.fontShadowColor.b, RepairIndicator.db.font.fontShadowColor.a)
                self.text:SetShadowOffset(RepairIndicator.db.font.fontShadowXOffset, RepairIndicator.db.font.fontShadowYOffset)
            else
                self.text:SetShadowColor(0, 0, 0, 0)
                self.text:SetShadowOffset(0, 0)
            end
            self.text:SetFont(LSM:Fetch("font", RepairIndicator.db.font.fontFamily), RepairIndicator.db.font.fontSize, RepairIndicator.db.font.fontOutline)

            self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
        end
    end

    return f
end

function RepairIndicator:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    f:RegisterEvent("PLAYER_DEAD")
    f:RegisterEvent("PLAYER_ALIVE")

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

function RepairIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.RepairIndicator = profile.RepairIndicator or self:GetDefaults()
    self.db = profile.RepairIndicator
end

function RepairIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.RepairIndicator = profile.RepairIndicator or self:GetDefaults()
    self.db = profile.RepairIndicator

    if self.db.enabled then
        local f = self:EnsureFrame()

        f:UpdateStyles()
        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.frame.text:Hide()
    end
end

function RepairIndicator:ApplyFontSettings(font)
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

function RepairIndicator:OnEnable()
    self:RefreshConfig()
end

function RepairIndicator:ToggleTestMode()
    if not self.db.enabled or not self.frame then
        return
    end

    OnEvent(self.frame)
end

function RepairIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        if self.frame then
            self.frame:UpdateStyles()
        end
    end)
end
