local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "RaidConsumesAlert"
local RaidConsumesAlert = ItruliaQoL:GetModule(moduleName)

function RaidConsumesAlert:GetDefaults()
    return {
        enabled = false,
        color = {r = 1, g = 1, b = 1, a = 1},
        point = {point = "CENTER", x = 0, y = 100},

        feast = {
            enabled = true,
            displayText = "Eat feast",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },
        heartyFeast = {
            enabled = true,
            displayText = "Eat **hearty** feast",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },
        cauldron = {
            enabled = true,
            displayText = "Grab flask and potions",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },
        repairBot = {
            enabled = true,
            displayText = "Repair gear",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },
        soulwell = {
            enabled = true,
            displayText = "Grab healthstone",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },
        summonStone = {
            enabled = true,
            displayText = "Help summon",
            playSound = false,
            sound = nil,
            playTTS = false,
            tts = nil,
            ttsVolume = 50,
        },

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