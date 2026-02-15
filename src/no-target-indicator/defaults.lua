local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "NoTargetIndicator"
local NoTargetIndicator = ItruliaQoL:GetModule(moduleName)

function NoTargetIndicator:GetDefaults()
    return {
        enabled = false,
        displayText = "No target",
        color = {r = 0.769, g = 0.118, b = 0.227, a = 1},
        point = {point = "CENTER", x = 0, y = 25},

        font = {
            fontFamily = "Expressway",
            fontSize = 14,
            fontOutline = "OUTLINE",
            fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
            fontShadowXOffset = 1,
            fontShadowYOffset = -1,
            frameStrata = ItruliaQoL.FrameStrataSettings.BACKGROUND,
            frameLevel = 1,
        }
    }
end