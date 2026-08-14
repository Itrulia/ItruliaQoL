local addonName, ItruliaQoL = ...

local moduleName = "KeystoneLister"
local KeystoneLister = ItruliaQoL:GetModule(moduleName)

KeystoneLister.pageDisplay = "Display"
KeystoneLister.pageListing = "Listing"

function KeystoneLister:PreparePreview(frame)
    frame:UpdateStyles()
    frame:Show()
end
