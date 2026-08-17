local addonName, ItruliaQoL = ...

local moduleName = "Misc"
local Misc = ItruliaQoL:GetModule(moduleName)

function Misc:GetDefaults()
    return {
        enabled = false,
        auctionHouseFilters = {
            enabled = false,
        },
    }
end
