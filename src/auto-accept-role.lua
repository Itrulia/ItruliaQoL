local addonName, ItruliaQoL = ...
local moduleName = "AutoAcceptRole"
local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E
local C = ItruliaQoL.C
local CD = ItruliaQoL.CD

local AutoAcceptRole = ItruliaQoL:NewModule(moduleName)

local defaults = {
    enabled = true,
};

function AutoAcceptRole:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.AutoAcceptRole = profile.AutoAcceptRole or defaults
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

    LFGListApplicationDialog.SignUpButton:SetScript("OnShow", function()
        if self.db.enabled then
            LFGListApplicationDialog.SignUpButton:Click()
        end;
    end)
end

local options = {
    type = "group",
    name = "Auto Role Accept",
    args = {
        description = {
            type = "description",
            name =  "Automatically accept the role call when signing up\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function() 
                return AutoAcceptRole.db.enabled
            end,
            set = function(_, value)
                AutoAcceptRole.db.enabled = value
                AutoAcceptRole:RefreshConfig()
            end,
        },
    }
}

function AutoAcceptRole:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end