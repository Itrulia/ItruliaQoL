local addonName, ItruliaQoL = ...

local moduleName = "Misc"
local Misc = ItruliaQoL:GetModule(moduleName)

function Misc:GetDefaults()
    return {
        enabled = true,
        auctionHouseFilters = {
            enabled = false,
        },
    }
end
