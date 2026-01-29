local addonName, namespace = ...

ItruliaQoL = LibStub("AceAddon-3.0"):NewAddon(namespace, addonName, "AceConsole-3.0")
ItruliaQoL.C = LibStub("AceConfig-3.0")
ItruliaQoL.CD = LibStub("AceConfigDialog-3.0")
ItruliaQoL.LSM = LibStub("LibSharedMedia-3.0")
ItruliaQoL.LEM = LibStub("LibEQOLEditMode-1.0")
ItruliaQoL.SettingsLib = LibStub("LibEQOLSettingsMode-1.0")
ItruliaQoL.testMode = false
ItruliaQoL.E = ElvUI and unpack(ElvUI)

function ItruliaQoL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ItruliaQoLDB", {}, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshModules")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshModules")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshModules")
end

function ItruliaQoL:OnEnable()
	self:RegisterOptions()

    ItruliaQoL:GetModule('MeleeIndicator'):Enable()
	ItruliaQoL:GetModule('FocusInterruptIndicator'):Enable()
    ItruliaQoL:GetModule('FocusTargetMarker'):Enable()
	ItruliaQoL:GetModule('PetMissingIndicator'):Enable()
	ItruliaQoL:GetModule('PetPassiveIndicator'):Enable()
    ItruliaQoL:GetModule('DeathAlert'):Enable()
    ItruliaQoL:GetModule('MovementAlert'):Enable()
    ItruliaQoL:GetModule('DungeonTeleports'):Enable()
	ItruliaQoL:GetModule('CDMSlash'):Enable()
    ItruliaQoL:GetModule('AutoAcceptRole'):Enable()
end

function ItruliaQoL:RefreshModules()
    for name, module in self:IterateModules() do
        if module.RefreshConfig then
            module:RefreshConfig()
        end
    end
end

function ItruliaQoL:RegisterOptions()
    local AceDBOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    local options =  {
        description = {
            type = "description",
            name =  "You can move things around using the native Edit Mode. Test mode will automatically be turned on\n\n Note that it ignores the Edit Mode layouts \n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Test mode",
            get = function()
                return self.testMode
            end,
            set = function(_, value)
                self:ToggleTestMode(value)
            end
        },
    }
    

    if (ItruliaQoL.E) then
        ItruliaQoL.E.Options.args[addonName] = {
            type = "group",
            name = "Itrulia QoL",
            order = 50, 
            args = options
        }
        ItruliaQoL.E.Options.args[addonName].args.description.name = "You can move things around using the ElvUI movers. Test mode will automatically be turned on\n\n";
        ItruliaQoL.E.Options.args[addonName].args.profiles = AceDBOptions
    end

	local parentOptions = {
        type = "group",
        name = "Itrulia QoL",
        childGroups = "tab",
        args = options
    }

	self.C:RegisterOptionsTable(addonName, parentOptions)
    self.CD:AddToBlizOptions(addonName, "Itrulia QoL")

    for name, module in self:IterateModules() do
        if module.RegisterOptions then
            module:RegisterOptions("Itrulia QoL")
        end
    end

    self.C:RegisterOptionsTable(addonName.."Profiles", AceDBOptions)
    self.CD:AddToBlizOptions(addonName.."Profiles", "Profiles", "Itrulia QoL")
end

function ItruliaQoL:ToggleTestMode(enabled)
    self.testMode = enabled

    for name, module in self:IterateModules() do
        if module.ToggleTestMode then
            module:ToggleTestMode(enabled)
        end
    end
end

ItruliaQoL:RegisterChatCommand("itrulia", "MySlashProcessorFunc")
function ItruliaQoL:MySlashProcessorFunc(input)
    if not input or input == "" or input == "config" then
        if self.E then
            self.E:ToggleOptions(addonName)
        else
            self.CD:Open(addonName)
        end
    end

  if input == "test" then
    self:ToggleTestMode(not ItruliaQoL.testMode)
  end

  if input == "help" then

  end
end

if ItruliaQoL.E then
  hooksecurefunc(ItruliaQoL.E, "ToggleMovers", function(_, enabled)
      ItruliaQoL:ToggleTestMode(enabled)
  end)
else 
    EditModeManagerFrame:HookScript("OnShow", function()
        ItruliaQoL:ToggleTestMode(true)
    end)

    EditModeManagerFrame:HookScript("OnHide", function()
        ItruliaQoL:ToggleTestMode(false)
    end)
end