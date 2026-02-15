local addonName, ItruliaQoL = ...
local moduleName = "PetPassiveIndicator"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local PetPassiveIndicator = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetText("**Pet passive!**")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")
frame.text:Hide()

function frame:IsPetPassive()
    -- Pet bar might be active while mounted
    if not UnitExists("pet") or not PetHasActionBar() or IsMounted() then 
        return false 
    end

    for slot = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, _, token, active = GetPetActionInfo(slot)

        if name == "PET_MODE_PASSIVE" and token and active then 
            return true 
        end
    end

    return false
end

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(PetPassiveIndicator.db.point.point, PetPassiveIndicator.db.point.x, PetPassiveIndicator.db.point.y)
        end

        self:SetFrameStrata(PetPassiveIndicator.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(PetPassiveIndicator.db.font.frameLevel or 1)
        self.text:SetText(PetPassiveIndicator.db.displayText)
        self.text:SetTextColor(PetPassiveIndicator.db.color.r, PetPassiveIndicator.db.color.g, PetPassiveIndicator.db.color.b, PetPassiveIndicator.db.color.a)
        self.text:SetFont(LSM:Fetch("font", PetPassiveIndicator.db.font.fontFamily), PetPassiveIndicator.db.font.fontSize, PetPassiveIndicator.db.font.fontOutline)
        self.text:SetShadowColor(PetPassiveIndicator.db.font.fontShadowColor.r, PetPassiveIndicator.db.font.fontShadowColor.g, PetPassiveIndicator.db.font.fontShadowColor.b, PetPassiveIndicator.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(PetPassiveIndicator.db.font.fontShadowXOffset, PetPassiveIndicator.db.font.fontShadowYOffset)
        
        self:SetSize(self.text:GetStringWidth(), self.text:GetStringHeight())
    end
end

local function OnEvent(self, event, ...)
    self:UpdateStyles()

    if ItruliaQoL.testMode then 
        self.text:Show()
        return
    end

    if self:IsPetPassive() then
        self.text:Show()
    else
        self.text:Hide()
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PET_BAR_UPDATE")
frame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

function PetPassiveIndicator:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PetPassiveIndicator = profile.PetPassiveIndicator or self:GetDefaults()
    self.db = profile.PetPassiveIndicator
end

function PetPassiveIndicator:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PetPassiveIndicator = profile.PetPassiveIndicator or self:GetDefaults()
    self.db = profile.PetPassiveIndicator

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PetPassiveIndicator:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    frame:UpdateStyles()
end

function PetPassiveIndicator:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil, nil, nil, nil, nil)
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function PetPassiveIndicator:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function PetPassiveIndicator:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end