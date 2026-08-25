local addonName, ItruliaQoL = ...

local moduleName = "SelfDispelAlert"
local SelfDispelAlert = ItruliaQoL:GetModule(moduleName)

function SelfDispelAlert:GetDefaults()
    return {
        enabled = false,
        displayText = "",
        showText = true,
        color = {r = 1, g = 1, b = 1, a = 1},
        showIcon = true,
        iconSize = 28,
        hideOnCooldown = true,
        disableInRaid = false,
        updateInterval = 0.1,
        point = {point = "CENTER", x = 0, y = -100},
        enabledSources = {},

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
