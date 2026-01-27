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
end

function ItruliaQoL:OnEnable()
	ItruliaQoL:GetModule('MeleeIndicator'):Enable()
	ItruliaQoL:GetModule('FocusInterruptIndicator'):Enable()
	ItruliaQoL:GetModule('PetMissingIndicator'):Enable()
	ItruliaQoL:GetModule('PetPassiveIndicator'):Enable()
	ItruliaQoL:GetModule('CDMSlash'):Enable()
end

function ItruliaQoL:OnEnable()
	self:RefreshModules()
	self:RegisterOptions()
end

function ItruliaQoL:RefreshModules()
    for name, module in self:IterateModules() do
        if module.RefreshConfig then
            module:RefreshConfig()
        end
    end
end

function ItruliaQoL:RegisterOptions()
    if (ItruliaQoL.E) then
      ItruliaQoL.E.Options.args[addonName] = {
			type = "group",
			name = "Itrulia QoL",
			order = 50, 
			args = {}
		}
    end

	local parentOptions = {
        type = "group",
        name = "Itrulia QoL",
        childGroups = "tab",
        args = {}
    }

	self.C:RegisterOptionsTable(addonName, parentOptions)
    self.CD:AddToBlizOptions(addonName, "Itrulia QoL")

    for name, module in self:IterateModules() do
        if module.RegisterOptions then
            module:RegisterOptions("Itrulia QoL")
        end
    end
end

ItruliaQoL:RegisterChatCommand("itrulia", "MySlashProcessorFunc")
function ItruliaQoL:MySlashProcessorFunc(input)
  if input == "test" then
    ItruliaQoL.testMode = not ItruliaQoL.testMode
  end

  if input == "help" then

  end

  if input == "config" then
    InterfaceOptionsFrame_OpenToCategory("ItruliaQoL")
  end
end

if ItruliaQoL.E then
  hooksecurefunc(ItruliaQoL.E, "ToggleMovers", function(_, enabled)
      ItruliaQoL.testMode = enabled
  end)
end