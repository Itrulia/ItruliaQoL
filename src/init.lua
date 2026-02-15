local addonName, namespace = ...

ItruliaQoL = LibStub("AceAddon-3.0"):NewAddon(namespace, addonName, "AceConsole-3.0")
ItruliaQoL.C = LibStub("AceConfig-3.0")
ItruliaQoL.CD = LibStub("AceConfigDialog-3.0")
ItruliaQoL.LSM = LibStub("LibSharedMedia-3.0")
ItruliaQoL.LEM = LibStub("LibEditMode")
ItruliaQoL.testMode = false
ItruliaQoL.E = ElvUI and unpack(ElvUI)

local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

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

function ItruliaQoL:RegisterOptions()
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
                    args = ItruliaQoL:createFontOptions(ItruliaQoL.db.profile.all.font, function() end, {
                        frameStrata = ItruliaQoL.MergeDeep_Delete_Key,
                        frameLevel = ItruliaQoL.MergeDeep_Delete_Key,
                        applyAll = {
                            type = "execute",
                            name = "Apply to all",
                            func = function()
                                ItruliaQoL:ApplyFontSettings()
                            end,
                        },
                    })
                },
            }
        },
    }

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

    parentOptions.args['profiles'] = AceDBOptions;
    parentOptions.args['importExport'] = {
        order = 500,
        type = "group",
        name = "Import / Export",
        args = {
            export = {
                order = 1,
                type = "input",
                name = "Export Profile",
                multiline = true,
                width = "full",
                get = function()
                    return ItruliaQoL:ExportCurrentProfile()
                end,
            },
            spacer = {
                order = 2,
                type = "description",
                name =  "\n\n\n",
                width = "full",
            },
            importOverwrite = {
                type = "input",
                name = "Import (Overwrite Current Profile)",
                desc = "Replaces all settings in the current profile",
                multiline = true,
                width = "full",
                set = function(_, value)
                    StaticPopup_Show(
                        "ITRULIAQOL_CONFIRM_OVERWRITE",
                        nil,
                        nil,
                        value
                    )
                end,
            },
            importNew = {
                type = "input",
                name = "Import as New Profile",
                desc = "Creates a new profile from this string",
                multiline = true,
                width = "full",
                set = function(_, value)
                    StaticPopup_Show(
                        "ITRULIAQOL_IMPORT_NEW_PROFILE",
                        nil,
                        nil,
                        value
                    )
                end,
            },
        },
    }

    if (ItruliaQoL.E) then
        ItruliaQoL.E.Options.args[addonName] = parentOptions;
        ItruliaQoL.E.Options.args[addonName].order = 50;
        ItruliaQoL.E.Options.args[addonName].args.description.name = "You can move things around using the ElvUI movers. Test mode will automatically be turned on\n\n";
    end
end

function ItruliaQoL:ExportCurrentProfile()
  local profileName = self.db:GetCurrentProfile()
  local profileData = self.db.profiles[profileName]

  local serialized = AceSerializer:Serialize(profileData)
  local compressed = LibDeflate:CompressDeflate(serialized)
  local encoded = LibDeflate:EncodeForPrint(compressed)

  return addonName .. encoded
end

function ItruliaQoL:DecodeImportString(str)
  if type(str) ~= "string" or not str:find("^" .. addonName) then
    return false, "Missing or invalid prefix"
  end

  local payload = str:sub(#addonName + 1)

  local decoded = LibDeflate:DecodeForPrint(payload)
  if not decoded then
    return false, "Invalid encoded data"
  end

  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then
    return false, "Decompression failed"
  end

  local success, data = AceSerializer:Deserialize(decompressed)
  if not success or type(data) ~= "table" then
    return false, "Invalid serialized profile"
  end

  return true, data
end

function ItruliaQoL:ImportAsNewProfile(str, profileName, override)
  if not profileName or profileName == "" then
    return false, "Invalid profile name"
  end

  if self.db.profiles[profileName] and not override then
    return false, "Profile already exists"
  end

  local ok, data = self:DecodeImportString(str)
  if not ok then
    return false, data
  end

  self.db:SetProfile(profileName)

  local profile = self.db.profile
  for k in pairs(profile) do
    profile[k] = nil
  end

  for k, v in pairs(data) do
    profile[k] = v
  end

  self:RefreshModules()

  return true
end

function ItruliaQoL:ImportIntoCurrentProfile(str)
  local ok, dataOrErr = self:DecodeImportString(str)
  if not ok then
    return false, dataOrErr
  end

  local profile = self.db.profile

  for k in pairs(profile) do
    profile[k] = nil
  end

  for k, v in pairs(dataOrErr) do
    profile[k] = v
  end

  self:RefreshModules()

  return true
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
    if not input or input == "" or input == "config" or input == "c" then
        if self.E then
            self.E:ToggleOptions(addonName)
        else
            self.CD:Open(addonName)
        end
    elseif input == "test" or input == "t" then
        self:ToggleTestMode(not ItruliaQoL.testMode)
    else
        self:Print("AddOn commands:")
        self:Print("/itrulia")
        self:Print("/itrulia config")
        self:Print("/itrulia help")
        self:Print("/itrulia test")
    end
end

if ItruliaQoL.E then
  hooksecurefunc(ItruliaQoL.E, "ToggleMovers", function(_, enabled)
      ItruliaQoL:ToggleTestMode(enabled)
  end)
else 
    ItruliaQoL.LEM:RegisterCallback('enter', function()
	    ItruliaQoL:ToggleTestMode(true)
    end)

    ItruliaQoL.LEM:RegisterCallback('exit', function()
        ItruliaQoL:ToggleTestMode(false)
    end)
end

StaticPopupDialogs["ITRULIAQOL_IMPORT_NEW_PROFILE"] = {
  text = "Enter a name for the new profile:",
  button1 = ACCEPT,
  button2 = CANCEL,
  hasEditBox = true,
  maxLetters = 50,

  OnAccept = function(self)
    local profileName = self.EditBox:GetText()
    local str = self.data

    local ok, err = ItruliaQoL:ImportAsNewProfile(str, profileName)
    if not ok then
      ItruliaQoL:Print("|cffff0000Import failed:|r", err)
    else
      ItruliaQoL:Print("|cff00ff00Profile created:|r", profileName)
    end
  end,

  OnShow = function(self)
    self.EditBox:SetText("")
    self.EditBox:SetFocus()
  end,

  EditBoxOnEnterPressed = function(self)
    StaticPopup_OnClick(self:GetParent(), 1)
  end,

  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

hooksecurefunc("StaticPopup_Show", function(which)
  if which and which:find("^ITRULIAQOL_") then
    local frame = StaticPopup_FindVisible(which)
    
    if frame then
      frame:SetFrameStrata("TOOLTIP")
      frame:SetFrameLevel(1000)
    end
  end
end)