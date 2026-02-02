local addonName, ItruliaQoL = ...
local moduleName = "GroupJoinedReminder"

local GroupJoinedReminder = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame.groupName = nil;

local function OnEvent(self, event, ...)
    if event == "GROUP_LEFT" then
        frame.groupName = nil;
    end

    if event == "LFG_LIST_JOINED_GROUP" then
        local _, groupName = ...
        frame.groupName = groupName
    end

    if event == "LFG_LIST_JOINED_GROUP" or event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        local created = ...
        if not created then
            return
        end

        local entryData = C_LFGList.GetActiveEntryInfo()
        if not entryData then
            return
        end

        local activityId = nil
        for _, id in ipairs(entryData.activityIDs) do
            activityId = id
            break;
        end

        if not activityId then
            return
        end

        local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
        if not activityInfo or (not activityInfo.isMythicPlusActivity and not activityInfo.isMythicActivity) then
            return
        end

        local fullName = activityInfo.fullName .. " " .. frame.groupName
        local dkColor = C_ClassColor.GetClassColor("DEATHKNIGHT");
        print(dkColor:WrapTextInColorCode("["..addonName.."]") .. " Joined: " .. fullName)
    end
end
    

frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("LFG_LIST_JOINED_GROUP")
frame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")

local defaults = {
    enabled = true,
};

function GroupJoinedReminder:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.GroupJoinedReminder = profile.GroupJoinedReminder or defaults
    self.db = profile.GroupJoinedReminder
end

function GroupJoinedReminder:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.GroupJoinedReminder = profile.GroupJoinedReminder or defaults
    self.db = profile.GroupJoinedReminder

    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
    end
end

function GroupJoinedReminder:OnEnable()
    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
    end
end

local options = {
    type = "group",
    name = "Group Joined Reminder",
    args = {
        description = {
            type = "description",
            name =  "Reminds you in the chat what mythic+ key you joined\n\n",
            width = "full",
            order = 1,
        },
        enable = {
            order = 2,
            type = "toggle",
            width = "full",
            name = "Enable",
            get = function() 
                return GroupJoinedReminder.db.enabled
            end,
            set = function(_, value)
                GroupJoinedReminder.db.enabled = value
                GroupJoinedReminder:RefreshConfig()
            end,
        },
    }
}

function GroupJoinedReminder:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = options;
end