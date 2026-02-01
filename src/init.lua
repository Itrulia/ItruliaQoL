local addonName, namespace = ...

ItruliaQoL = LibStub("AceAddon-3.0"):NewAddon(namespace, addonName, "AceConsole-3.0")
ItruliaQoL.C = LibStub("AceConfig-3.0")
ItruliaQoL.CD = LibStub("AceConfigDialog-3.0")
ItruliaQoL.LSM = LibStub("LibSharedMedia-3.0")
ItruliaQoL.LEM = LibStub("LibEQOLEditMode-1.0")
ItruliaQoL.SettingsLib = LibStub("LibEQOLSettingsMode-1.0")
ItruliaQoL.testMode = false
ItruliaQoL.E = ElvUI and unpack(ElvUI)
ItruliaQoL.Dump = DevTools_Dump

function ItruliaQoL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ItruliaQoLDB", {}, true)

    self.db.profile.all = self.db.profile.all or {
        font = {
            fontFamily = "Expressway",
            fontOutline = "OUTLINE",
            fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
            fontShadowXOffset = 1,
            fontShadowYOffset = -1,
        }
    }

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
    for _, module in self:IterateModules() do
        if module.RefreshConfig then
            module:RefreshConfig()
        end
    end
end

function ItruliaQoL:ApplyFontSettings()
    for _, module in self:IterateModules() do
        if module.ApplyFontSettings then
            module:ApplyFontSettings(self.db.profile.all.font)
        end
    end
end

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
            return ItruliaQoL.testMode
        end,
        set = function(_, value)
            ItruliaQoL:ToggleTestMode(value)
        end
    },
    all = {
        type = "group",
        name = "All",
        order = 1,
        args = {
            fontSettings = {
                type = "group",
                name = "Font",
                inline = true,
                args = {
                    font = {
                        order = 1,
                        type = "select",
                        dialogControl = "LSM30_Font",
                        name = "Font",
                        values = ItruliaQoL.LSM:HashTable("font"),
                        get = function()
                            return ItruliaQoL.db.profile.all.font.fontFamily
                        end,
                        set = function(_, value)
                            ItruliaQoL.db.profile.all.font.fontFamily = value
                        end
                    },
                    fontOutline = {
                        order = 2,
                        type = "select",
                        name = "Outline",
                        values = {
                            NONE = "None",
                            OUTLINE = "Outline",
                            THICKOUTLINE = "Thick Outline",
                            MONOCHROME = "Monochrome"
                        },
                        get = function()
                            return ItruliaQoL.db.profile.all.font.fontOutline
                        end,
                        set = function(_, value)
                            ItruliaQoL.db.profile.all.font.fontOutline = value ~= "NONE" and value or nil
                        end
                    },
                    spacer = {
                        type = "description",
                        name =  "",
                        width = "full",
                        order = 3,
                    },
                    fontShadowColor = {
                        order = 4,
                        type = "color",
                        name = "Shadow Color",
                        hasAlpha = true,
                        get = function()
                            local c = ItruliaQoL.db.profile.all.font.fontShadowColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            ItruliaQoL.db.profile.all.font.fontShadowColor = {
                                r = r,
                                g = g,
                                b = b,
                                a = a
                            }
                        end
                    },
                    fontShadowXOffset = {
                        order = 5,
                        type = "range",
                        name = "Shadow X Offset",
                        min = -5,
                        max = 5,
                        step = 1,
                        get = function()
                            return ItruliaQoL.db.profile.all.font.fontShadowXOffset
                        end,
                        set = function(_, value)
                            ItruliaQoL.db.profile.all.font.fontShadowXOffset = value
                        end
                    },
                    fontShadowYOffset = {
                        order = 5,
                        type = "range",
                        name = "Shadow Y Offset",
                        min = -5,
                        max = 5,
                        step = 1,
                        get = function()
                            return ItruliaQoL.db.profile.all.font.fontShadowYOffset
                        end,
                        set = function(_, value)
                            ItruliaQoL.db.profile.all.font.fontShadowYOffset = value
                        end
                    },
                    spacer2 = {
                        type = "description",
                        name =  "",
                        width = "full",
                    },
                    applyAll = {
                        type = "execute",
                        name = "Apply to all",
                        func = function()
                            ItruliaQoL:ApplyFontSettings()
                        end,
                    },
                }
            },
        }
    },
}

function ItruliaQoL:RegisterOptions()
    local AceDBOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	local parentOptions = {
        type = "group",
        name = "Itrulia QoL",
        childGroups = "tree",
        args = options
    }

	self.C:RegisterOptionsTable(addonName, parentOptions)
    self.CD:AddToBlizOptions(addonName, "Itrulia QoL")

    for _, module in self:IterateModules() do
        if module.RegisterOptions then
            module:RegisterOptions(parentOptions)
        end
    end

    parentOptions.args['Profiles'] = AceDBOptions;

    if (ItruliaQoL.E) then
        ItruliaQoL.E.Options.args[addonName] = parentOptions;
        ItruliaQoL.E.Options.args[addonName].order = 50;
        ItruliaQoL.E.Options.args[addonName].args.description.name = "You can move things around using the ElvUI movers. Test mode will automatically be turned on\n\n";
    end
end

function ItruliaQoL:ToggleTestMode(enabled)
    self.testMode = enabled

    for _, module in self:IterateModules() do
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