local lib_zones = lib.zones
local core = Framework.core
local polyzone = {
    pos = vector4(0),
    isNear = false,
    mods = nil,
    free = false,
}

local function checkVehicleClass(classes)
    local currentClass = GetVehicleClass(cache.vehicle)
    for k,v in ipairs(classes) do
        if currentClass == v then
            return true
        end
    end
    return false
end
---comment
local function isAllowed(group, job)
    local name = job.name
    local grade = group[name]
    return grade and grade <= job.grade.name
end

---@param custom {locData: vector4, mods: table<string, boolean>, group: table<string, number>}
local showingNotification = false

local function onEnter(custom)
    local locData, mods, group, free, classes in custom
    if group and type(group) == 'table' then
        local playerData = core.getPlayerData()
        if not isAllowed(group, playerData.job) then return end
    end

    if classes and not checkVehicleClass(classes) then return end

    -- Show native GTA V notification instead of TextUI
    showingNotification = true
    CreateThread(function()
        while showingNotification do
            -- Only show notification if customs UI is not open
            local isUIOpen = _G.customsUIOpen or false
            if not isUIOpen then
                -- Native GTA V help text (top right corner)
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_TALK~ to open Customs")
                EndTextCommandDisplayHelp(0, false, true, -1)
            end
            Wait(0)
        end
    end)
    
    polyzone.pos = locData
    polyzone.mods = mods
    polyzone.free = free
    polyzone.isNear = true
end

local function onExit()
    showingNotification = false
    polyzone.pos = nil
    polyzone.isNear = false
end

CreateThread(function()
    local locations = require 'data.config'.locations
    for _, v in ipairs(locations) do
        local pos = v.pos
        local blip_data = v.blip

        lib_zones.box({
            coords = pos.xyz,
            size = vec3(8, 8, 6),
            rotation = pos.w,
            mods = v.mods,
            group = v.group,
            free = v.free,
            classes = v.classes,
            onEnter = onEnter,
            onExit = onExit,
            locData = vector4(pos.x, pos.y, pos.z, pos.w)
        })

        if blip_data then
            local sprite, scale, color, shortRange, label in blip_data
            local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
            SetBlipDisplay(blip, 4)
            SetBlipSprite(blip, sprite)
	    SetBlipScale(blip, scale)
            SetBlipColour(blip, color)
	    SetBlipAsShortRange(blip, shortRange or false)

            BeginTextCommandSetBlipName("STRING")
			AddTextComponentSubstringPlayerName(label)
			EndTextCommandSetBlipName(blip)
        end
    end
end)

return polyzone
