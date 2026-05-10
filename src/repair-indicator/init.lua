local addonName, ItruliaQoL = ...
local moduleName = "RepairIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local RepairIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("**Low Durability!**")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide()

function frame:RequiresRepair()
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

function frame:UpdateStyles()
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

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")

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
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function RepairIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function RepairIndicator:OnEnable()
    if self.db.enabled then 
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enabled
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function RepairIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function RepairIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end