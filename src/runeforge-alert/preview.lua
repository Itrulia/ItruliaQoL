local addonName, ItruliaQoL = ...

local moduleName = "RuneforgeAlert"
local RuneforgeAlert = ItruliaQoL:GetModule(moduleName)

RuneforgeAlert.pageDisplay = "Display"
RuneforgeAlert.pageRuneforges = "Runeforges"

function RuneforgeAlert:PreparePreview(frame)
    frame.text:Show()
end
