local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "MovementAlert"
local MovementAlert = ItruliaQoL:GetModule(moduleName)

function MovementAlert:GetDefaults()
    return {
        enabled = true,
        precision = 0,
        color = {r = 1, g = 1, b = 1, a = 1},
        updateInterval = 0.1,
        point = {point = "CENTER", x = 0, y = 50},
        
        showTimeSpiral = true,
        timeSpiralText = "Free Movement",
        timeSpiralColor = {r = 0.5333333611488342, g = 1, b = 0, a = 1},
        timeSpiralPlaySound = false,
        timeSpiralSound = nil,
        timeSpiralPlayTTS = false,
        timeSpiralTTS = "",
        timeSpiralTTSVolume = 50,

        font = {
            fontFamily = "Expressway",
            fontSize = 14,
            fontOutline = "OUTLINE",
            fontShadowColor = {r = 0, g = 0, b = 0, a = 1},
            fontShadowXOffset = 1,
            fontShadowYOffset = -1,
            frameStrata = ItruliaQoL.FrameStrataSettings.BACKGROUND,
            frameLevel = 1,
            justifyH = ItruliaQoL.JustifyHSettings.CENTER,
        }
    }
end