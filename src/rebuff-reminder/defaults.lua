local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "RebuffReminder"
local RebuffReminder = ItruliaQoL:GetModule(moduleName)

function RebuffReminder:GetDefaults()
    return {
        enabled = false,
        alertWhenIdle = false,
        displayText = "Rebuff",
        color = {r = 1, g = 1, b = 1, a = 1},
        point = {point = "CENTER", x = 0, y = 50},
        
        playSound = false,
        sound = nil,
        playTTS = false,
        tts = "",
        ttsVolume = 50,

        font = {
            fontFamily = "Expressway",
            fontSize = 28,
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