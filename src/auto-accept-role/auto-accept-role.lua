local addonName, ItruliaQoL = ...
local moduleName = "AutoAcceptRole"

local AutoAcceptRole = ItruliaQoL:NewModule(moduleName)

function AutoAcceptRole:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.AutoAcceptRole = profile.AutoAcceptRole or AutoAcceptRole:GetDefaults()
    self.db = profile.AutoAcceptRole
end

function AutoAcceptRole:RefreshConfig()
    self:OnInitialize()
end

function AutoAcceptRole:OnEnable()
    LFDRoleCheckPopupAcceptButton:SetScript("OnShow", function()
        if self.db.enabled then
            LFDRoleCheckPopupAcceptButton:Click()
        end;
    end)
end

function AutoAcceptRole:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        
    end);
end