local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "PetPassiveIndicator"
local PetPassiveIndicator = ItruliaQoL:GetModule(moduleName)

function PetPassiveIndicator:GetDefaults()
    return {
        enabled = true,
        displayText = "**Pet passive!**",
        color = {r = 1, g = 1, b = 1, a = 1},
        updateInterval = 0.5,
        point = {point = "CENTER", x = 0, y = 300},

        font = {
            fontFamily = "Expressway",
            fontSize = 28,
            fontOutline = "OUTLINE",
            fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
            fontShadowXOffset = 1,
            fontShadowYOffset = -1,
            frameStrata = ItruliaQoL.FrameStrataSettings.BACKGROUND,
            frameLevel = 1,
        }
    }
end