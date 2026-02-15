local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "HealerManaIndicator"
local HealerManaIndicator = ItruliaQoL:GetModule(moduleName)

function HealerManaIndicator:GetDefaults()
    return {
        enabled = false,
        growUpwards = false,
        color = {r = 1, g = 1, b = 1, a = 1},
        point = {point = "CENTER", x = -100, y = 50},

        enableInRaids = false,
        enableInDungeons = true,

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