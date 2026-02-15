local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "FocusInterruptIndicator"
local FocusInterruptIndicator = ItruliaQoL:GetModule(moduleName)

function FocusInterruptIndicator:GetDefaults()
    return {
        enabled = true,
        point = { point = "CENTER", x = 0, y = 150 },
        color = {r = 1, g = 1, b = 1, a = 1},
        displayText = "INTERRUPT",

        playSound = false,
        sound = "Kick",
        playTTS = false,
        TTS = "",
        TTSVolume = 50,

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