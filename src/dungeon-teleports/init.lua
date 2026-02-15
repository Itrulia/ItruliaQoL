local addonName, ItruliaQoL = ...
local moduleName = "DungeonTeleports"

local DungeonTeleports = ItruliaQoL:NewModule(moduleName)

function DungeonTeleports:OnEnable()
    local frame = CreateFrame("frame", addonName .. moduleName)
    local teleportMap = {}

    -- TWW S3
    teleportMap[378] = 354465
    teleportMap[505] = 445414
    teleportMap[503] = 445417
    teleportMap[525] = 1216786
    teleportMap[542] = 1237215
    teleportMap[392] = 367416
    teleportMap[391] = 367416
    teleportMap[499] = 445444

    frame:RegisterEvent("ADDON_LOADED")

    local function onShow()
        for i = 1, select("#", ChallengesFrame:GetChildren()) do
            local childFrame = select(i, ChallengesFrame:GetChildren())
            local onEnterFunc = childFrame:GetScript("OnEnter")

            if childFrame.mapID ~= nil then
                local clickButton = CreateFrame("Button", nil, childFrame, "InsecureActionButtonTemplate")
                clickButton.vMapId = childFrame.mapID

                clickButton:SetAllPoints(childFrame)
                clickButton:SetAttribute("type", "spell")
                clickButton:SetAttribute("spell", teleportMap[childFrame.mapID]) 
                clickButton:RegisterForClicks("AnyDown")
                clickButton:HookScript("OnEnter", function()
                    onEnterFunc(childFrame)
                end)
            end
        end
    end

    local function onUpdate(self)
        for j = 1, select("#", self:GetChildren()) do
            local jFrame = select(j, self:GetChildren())

            if jFrame.mapID ~= nil then
                for k = 1, select("#", jFrame:GetChildren()) do
                    local kFrame = select(k, jFrame:GetChildren())

                    if kFrame.vMapId ~= jFrame.mapID then
                        kFrame:SetAttribute("spell", teleportMap[jFrame.mapID])
                        kFrame.vMapId = jFrame.mapID
                    end

                    break
                end
            end
        end
    end

    frame:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName == "Blizzard_ChallengesUI" then
            if not ChallengesFrame then
                return;
            end

            local prevFrameUpdate = ChallengesFrame.Update
            ChallengesFrame:HookScript("OnShow", onShow)
            ChallengesFrame.Update = function (self)
                onUpdate(self);
                prevFrameUpdate(ChallengesFrame)
            end
        end
    end)
end