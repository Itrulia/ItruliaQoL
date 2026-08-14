local addonName, ItruliaQoL = ...

local moduleName = "MovementAlert"
local MovementAlert = ItruliaQoL:GetModule(moduleName)

MovementAlert.pageDisplay = "Movement Alert"
MovementAlert.pageTimeSpiral = "Time Spiral"

function MovementAlert:PreparePreview(frame, page)
    frame:CacheMovementId()

    if page == self.pageTimeSpiral then
        frame.text:SetText(CreateColor(
            self.db.timeSpiralColor.r,
            self.db.timeSpiralColor.g,
            self.db.timeSpiralColor.b,
            self.db.timeSpiralColor.a
        ):WrapTextInColorCode(self.db.timeSpiralText .. "\n" .. string.format("%." .. self.db.precision .. "f", 7.4)))
    else
        frame.text:SetText("No " .. (frame.movementName or "movement ability") .. "\n" .. string.format("%." .. self.db.precision .. "f", 15.3))
    end

    frame.text:Show()
    frame:UpdateStyles()
end
