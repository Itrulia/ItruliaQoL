local addonName, ItruliaQoL = ...

local moduleName = "SummonHelper"
local SummonHelper = ItruliaQoL:GetModule(moduleName)

function SummonHelper:GetDefaults()
    return {
        enabled = false,
        phrases = "123, summ",
        duration = 20,
        style = SummonHelper.stylePixel,
        spacing = 0,
        border = {
            thickness = 1,
            color = {r = 1, g = 1, b = 1, a = 1},
        },
        pixel = {
            lines = 6,
            thickness = 1,
            speed = 10,
            color = {r = 1, g = 1, b = 1, a = 1},
        },
        stoneReminder = true,
        messageText = "Summ Stone!",
        textColor = {r = 1, g = 1, b = 1, a = 1},
        point = {point = "CENTER", x = 0, y = 0},

        font = {
            fontFamily = "Expressway",
            fontSize = 40,
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
