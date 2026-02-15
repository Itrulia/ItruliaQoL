local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "CursorCircle"
local CursorCircle = ItruliaQoL:GetModule(moduleName)

function CursorCircle:GetDefaults()
    return {
        enabled = false,
        displayTexture = [[Interface\AddOns\ItruliaQoL\media\textures\ItruliaCircleMedium.tga]],
        size = 28,
        color = {r = 0.769, g = 0.118, b = 0.227, a = 1},
    }
end