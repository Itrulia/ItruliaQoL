local addonName, ItruliaQoL = ...
local LSM = ItruliaQoL.LSM

local moduleName = "MacroFactory"
local MacroFactory = ItruliaQoL:GetModule(moduleName)

-- 30% zoom in which crops away border baked into spell icons
local crop = (1 - 1 / 1.3) / 2
local iconCoords = { crop, 1 - crop, crop, 1 - crop }

function MacroFactory:GetOptions(onChange)
    local options = {
        order = 2,
        type = "group",
        name = "Macro Factory",
        args = {
            description = {
                type = "description",
                name = "Creates a set of handy macros. Click a button to create the macro; if one with that name already exists you'll be asked before it gets overwritten.\n\n",
                width = "full",
                order = 1,
            },
        }
    }

    local buttonOrder = 0

    local function addButton(container, macro)
        buttonOrder = buttonOrder + 1

        container["macro" .. buttonOrder] = {
            type = "execute",
            name = macro.name,
            desc = macro.desc,
            order = buttonOrder,
            dialogControl = "ItruliaMacroIcon",
            image = function()
                return MacroFactory:ResolveIcon(macro.icon)
            end,
            imageCoords = iconCoords,
            imageWidth = 36,
            imageHeight = 36,
            func = function()
                macro.create(MacroFactory)
            end,
        }
    end

    -- Build a button per registered macro, grouped by section and optional
    -- sub-section (e.g. a class group split into specs).
    for gi, group in ipairs(self:GetGroupedMacros()) do
        local groupArgs = {}
        options.args["group" .. gi] = {
            type = "group",
            name = group.name,
            inline = true,
            order = 10 + gi,
            args = groupArgs,
        }

        for _, macro in ipairs(group.macros) do
            addButton(groupArgs, macro)
        end

        for si, sub in ipairs(group.subgroups) do
            local subArgs = {}
            groupArgs["sub" .. si] = {
                type = "group",
                name = sub.name,
                inline = true,
                order = 100 + si,
                args = subArgs,
            }

            for _, macro in ipairs(sub.macros) do
                addButton(subArgs, macro)
            end
        end
    end

    return options
end
