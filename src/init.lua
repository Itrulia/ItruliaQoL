local addonName, namespace = ...

ItruliaQoL = LibStub("AceAddon-3.0"):NewAddon(namespace, addonName, "AceConsole-3.0")
ItruliaQoL.C = LibStub("AceConfig-3.0")
ItruliaQoL.CD = LibStub("AceConfigDialog-3.0")
ItruliaQoL.LSM = LibStub("LibSharedMedia-3.0")
ItruliaQoL.LEM = LibStub("LibEditMode")
ItruliaQoL.testMode = false
ItruliaQoL.E = ElvUI and unpack(ElvUI)
ItruliaQoL.EUI = _G.EllesmereUI

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
    self:WatchSharedMedia()
end

function ItruliaQoL:RefreshModules()
    for _, module in self:IterateModules() do
        if module.RefreshConfig then
            module:RefreshConfig()
        end
    end
end

function ItruliaQoL:RestyleModules()
    for _, module in self:IterateModules() do
        if not module.db or module.db.enabled then
            
            if module.Restyle then
                module:Restyle()
            elseif module.frame and module.frame.UpdateStyles then
                module.frame:UpdateStyles()
            end
        end
    end
end

function ItruliaQoL:WatchSharedMedia()
    local rerenderPending = false

    local mediaTypesToRerender = {
        font = true,
        statusbar = true,
        border = true,
        background = true,
    }

    local function batchRerender()
        if rerenderPending then
            return
        end

        rerenderPending = true

        C_Timer.After(0, function()
            rerenderPending = false
            self:RestyleModules()
        end)
    end

    self.LSM.RegisterCallback(self, "LibSharedMedia_Registered", function(_, mediatype)
        if mediaTypesToRerender[mediatype] then
            batchRerender()
        end
    end)

    self.LSM.RegisterCallback(self, "LibSharedMedia_SetGlobal", function(_, mediatype)
        if mediaTypesToRerender[mediatype] then
            batchRerender()
        end
    end)
end

function ItruliaQoL:ApplyFontSettings()
    for _, module in self:IterateModules() do
        if module.ApplyFontSettings then
            module:ApplyFontSettings(self.db.profile.all.font)
        end
    end
end

function ItruliaQoL:RegisterOptions()
    local options = self:GetGeneralOptions()

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

    local LibDualSpec = LibStub('LibDualSpec-1.0')
    LibDualSpec:EnhanceDatabase(self.db, addonName)
    LibDualSpec:EnhanceOptions(parentOptions.args['profiles'], self.db)

    if (ItruliaQoL.E) then
        ItruliaQoL.E.Options.args[addonName] = parentOptions;
        ItruliaQoL.E.Options.args[addonName].order = 50;
        ItruliaQoL.E.Options.args[addonName].args.description.name = "You can move things around using the ElvUI movers. Test mode will automatically be turned on\n\n";

        tinsert(ItruliaQoL.E.ConfigModeLayouts, "Itrulia")
        ItruliaQoL.E.ConfigModeLocalizedStrings["Itrulia"] = "Itrulia"
    elseif ItruliaQoL.EUI then
        ItruliaQoL:RegisterEUI(parentOptions)
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

local function finish(callback, ok, err)
  if callback then
    callback(ok, err)
  end

  return ok, err
end

function ItruliaQoL:ImportAsNewProfile(str, profileName, override, callback)
  if not profileName or profileName == "" then
    return finish(callback, false, "Invalid profile name")
  end

  if self.db.profiles[profileName] and not override then
    return finish(callback, false, "Profile already exists")
  end

  local ok, data = self:DecodeImportString(str)
  if not ok then
    return finish(callback, false, data)
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

  return finish(callback, true)
end

function ItruliaQoL:ImportIntoCurrentProfile(str, callback)
  local ok, dataOrErr = self:DecodeImportString(str)
  if not ok then
    return finish(callback, false, dataOrErr)
  end

  local profile = self.db.profile

  for k in pairs(profile) do
    profile[k] = nil
  end

  for k, v in pairs(dataOrErr) do
    profile[k] = v
  end

  self:RefreshModules()

  return finish(callback, true)
end

function ItruliaQoL:ToggleTestMode(enabled)
    self.testMode = enabled

    for _, module in self:IterateModules() do
        if module.ToggleTestMode then
            module:ToggleTestMode(enabled)
        end
    end
end


-- The three config hosts, each a { available, open } pair, so the automatic pick
-- and the explicit subcommands go through the same code.
local hosts = {
    elvui = {
        label = "ElvUI",
        available = function(self)
            return self.E and self.E.ToggleOptions and true or false
        end,
        open = function(self)
            self.E:ToggleOptions(addonName)
        end,
    },
    eui = {
        label = "EllesmereUI",
        available = function(self)
            return self.EUI and self.EUI.ShowModule and true or false
        end,
        open = function(self)
            -- Back to the row it was left on, General on the first open of the
            -- session (see integrations/ellesmere/ellesmere.lua's addEntry keys).
            -- EllesmereUI restores that row's own tab.
            local moduleKey = self:GetLastEUIModule() or (addonName .. "_General")

            self.EUI:ShowModule(moduleKey)

            -- Our group sits below EllesmereUI's own suite, so the row we just
            -- selected is off screen until the sidebar is scrolled to it.
            if self.ScrollEUISidebarToGroup then
                self:ScrollEUISidebarToGroup(moduleKey)
            end
        end,
    },
    standalone = {
        label = "standalone",
        available = function()
            return true
        end,
        open = function(self)
            self.CD:Open(addonName)
        end,
    },
}

local hostAliases = {
    elv = "elvui",
    elvui = "elvui",
    tukui = "elvui",
    eui = "eui",
    ellesmere = "eui",
    ellesmereui = "eui",
    standalone = "standalone",
    ace = "standalone",
    blizzard = "standalone",
}

local autoOrder = { "elvui", "eui", "standalone" }

function ItruliaQoL:OpenConfig(host)
    if host then
        local spec = hosts[host]

        if not spec.available(self) then
            self:Print("|cffff0000" .. spec.label .. " is not available.|r Opening the standalone config instead.")
            hosts.standalone.open(self)

            return
        end

        spec.open(self)

        return
    end

    for _, key in ipairs(autoOrder) do
        local spec = hosts[key]

        if spec.available(self) then
            spec.open(self)

            return
        end
    end
end

ItruliaQoL:RegisterChatCommand("itrulia", "MySlashProcessorFunc")
function ItruliaQoL:MySlashProcessorFunc(input)
    local arg = input and input:lower():match("^%s*(%S*)") or ""

    if arg == "" or arg == "config" or arg == "c" then
        self:OpenConfig()
    elseif hostAliases[arg] then
        self:OpenConfig(hostAliases[arg])
    elseif arg == "test" or arg == "t" then
        self:ToggleTestMode(not ItruliaQoL.testMode)
    else
        self:Print("AddOn commands:")
        self:Print("/itrulia")
        self:Print("/itrulia config")
        self:Print("/itrulia elvui")
        self:Print("/itrulia eui")
        self:Print("/itrulia standalone")
        self:Print("/itrulia help")
        self:Print("/itrulia test")
    end
end

if ItruliaQoL.E then
  hooksecurefunc(ItruliaQoL.E, "ToggleMovers", function(_, enabled)
      ItruliaQoL:ToggleTestMode(enabled)
  end)
elseif not ItruliaQoL.EUI then
    -- EllesmereUI drives test mode via RegisterUnlockModeListener (see ellesmere.lua).
    ItruliaQoL.LEM:RegisterCallback('enter', function()
	    ItruliaQoL:ToggleTestMode(true)
    end)

    ItruliaQoL.LEM:RegisterCallback('exit', function()
        ItruliaQoL:ToggleTestMode(false)
    end)
end

StaticPopupDialogs["ITRULIAQOL_CONFIRM_OVERWRITE"] = {
  text = "This will replace every setting in your current profile. Continue?",
  button1 = YES,
  button2 = NO,

  OnAccept = function(self)
    local ok, err = ItruliaQoL:ImportIntoCurrentProfile(self.data)

    if not ok then
      ItruliaQoL:Print("|cffff0000Import failed:|r", err)
    else
      ItruliaQoL:Print("|cff00ff00Profile imported.|r")
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
  end,

  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

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

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
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
