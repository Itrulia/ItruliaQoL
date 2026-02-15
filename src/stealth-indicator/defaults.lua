local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "StealthIndicator"
local StealthIndicator = ItruliaQoL:GetModule(moduleName)

function StealthIndicator:GetDefaults()
    return {
        enabled = false,
        displayText = "+Stealth",
        color = {r = 1, g = 1, b = 1, a = 1},
        point = {point = "CENTER", x = 0, y = 50},

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