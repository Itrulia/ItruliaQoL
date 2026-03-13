local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CharacterIndicator"
local CharacterIndicator = ItruliaQoL:GetModule(moduleName)

function CharacterIndicator:GetDefaults()
    return {
        enabled = false,
        displayText = "+",
        color = {r = 0, g = 0.9568627450980393, b = 1, a = 1},
        updateInterval = 0.5,
        point = { point = "CENTER", x = 0, y = 0 },

        font = {
            fontFamily = "Expressway",
            fontSize = 28,
            fontOutline = "OUTLINE",
            fontShadowColor = {r = 0, g = 0, b = 0, a = 0},
            fontShadowXOffset = 1,
            fontShadowYOffset = -1,
            frameStrata = ItruliaQoL.FrameStrataSettings.BACKGROUND,
            frameLevel = 1,
            justifyH = ItruliaQoL.JustifyHSettings.CENTER,
        }
    }
end