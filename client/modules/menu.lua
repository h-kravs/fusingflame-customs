local poly = require 'client.modules.polyzone'
local camera = require 'client.modules.camera'
local vehicle = require 'client.modules.vehicle'
local getMod = vehicle.getMod
local lib_table = lib.table
local table_contain = lib_table.contains
local uiLoaded = false
_G.customsUIOpen = false -- Global variable to track UI state
local store = require 'client.modules.store'
local originalPos = nil -- Store original position to return player
local minimapDisabled = false -- Track minimap state

-- Fade effect functions
local function fadeOut(duration)
    DoScreenFadeOut(duration or 500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
end

local function fadeIn(duration)
    DoScreenFadeIn(duration or 500)
    while not IsScreenFadedIn() do
        Wait(0)
    end
end

-- Minimap control functions
local function disableMinimap()
    if not minimapDisabled then
        DisplayRadar(false)
        minimapDisabled = true
    end
end

local function enableMinimap()
    if minimapDisabled then
        DisplayRadar(true)
        minimapDisabled = false
    end
end


local function triggerSelector(prop, ...)
    local category = require 'client.modules.filter'.named[store.menu]
    local selector = category and category.selector
    if not selector or not selector[prop] then 
        return false 
    end
    
    return selector[prop](...)
end

---comment
---@param modIndex number
local function handleMod(modIndex)
    local modType = store.modType ~= 'none' and store.modType
    local storedData = store.stored

    triggerSelector('onModSwitch', modType or store.menu, modIndex)
    if not modType then return end

    local isWheel = store.menuType == 'wheels'
    local isPaint = store.menuType == 'paint'
    local isPerformance = store.menu == 'performance'
    local modData = isWheel and require 'data.wheels'[modType] or isPaint and require 'data.colors'.functions[modType] or isPerformance and require 'data.performance'[modType] or require 'data.decals'[modType]
    local vehicle = cache.vehicle

    local storedData = store.stored
    storedData.appliedMods = { modType = modType, mod = modIndex }
    
    -- For engine sounds, also store in currentEngineSound
    if isPerformance and modType == 'Engine Sound' then
        local performanceData = require 'data.performance'
        local modData = performanceData[modType]
        if modData and modData.isEngineSound then
            storedData.currentEngineSound = modIndex
        end
    end

    -- Special handling for paint color selection
    if isPaint and store.paintColorType then
        print('🎨 [DEBUG] Paint color preview - paintColorType:', store.paintColorType, 'colorId:', modIndex)
        
        -- Skip paint color handling for Window Tint and Neon Colors
        if modType == 'Window Tint' or modType == 'Neon Colors' then
            print('🎨 [DEBUG] Skipping paint color handling for:', modType)
            -- These have their own onSelect functions and should not be treated as paint colors
        else
            -- For paint colors, we need to check if we're at the final color selection level
            local colorsData = require 'data.colors'.data
            local isPaintData = colorsData[modType] -- Check if modType is Metallic, Matte, Chrome, etc.
            
            if isPaintData then
                print('🎨 [DEBUG] Applying paint preview for', store.paintColorType, 'with color ID:', modIndex)
                -- Store stance values BEFORE color application
                -- BUT only store values that have been actually applied (not preview values)
                local stanceBackup = nil
                if storedData.currentStance then
                    local appliedStance = storedData.appliedStance or {}
                    stanceBackup = {}
                    for stanceType, value in pairs(storedData.currentStance) do
                        -- Only backup values that match applied stance or defaults
                        local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
                        if appliedValue and math.abs((value or 0) - (appliedValue or 0)) < 0.01 then
                            stanceBackup[stanceType] = value
                        else
                            -- Use applied value instead of preview value
                            stanceBackup[stanceType] = appliedValue or (storedData.defaultStance and storedData.defaultStance[stanceType]) or 0
                            print('🚨 [DEBUG] Correcting unapplied stance value in paint -', stanceType, 'from:', value, 'to:', stanceBackup[stanceType])
                        end
                    end
                end
                
                -- Apply the color based on Primary/Secondary
                local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
                if store.paintColorType == 'Primary' then
                    SetVehicleColours(vehicle, modIndex, colorSecondary)
                    print('🎨 [DEBUG] Applied Primary color preview:', modIndex)
                elseif store.paintColorType == 'Secondary' then
                    SetVehicleColours(vehicle, colorPrimary, modIndex)
                    print('🎨 [DEBUG] Applied Secondary color preview:', modIndex)
                end
                
                -- IMMEDIATE restoration after color application
                if stanceBackup then
                    local vehicleModule = require 'client.modules.vehicle'
                    for stanceType, value in pairs(stanceBackup) do
                        vehicleModule.applyStanceMod(vehicle, stanceType, value)
                    end
                end
                
                return true
            end
        end
    end

    if not modData then return end

    local onSelect = modData.onSelect
    if onSelect then
        local storedData = store.stored
        -- Store stance values BEFORE onSelect as it may call vehicle natives that reset them
        -- BUT only store values that have been actually applied (not preview values)
        local stanceBackup = nil
        if storedData.currentStance then
            local appliedStance = storedData.appliedStance or {}
            stanceBackup = {}
            for stanceType, value in pairs(storedData.currentStance) do
                -- Only backup values that match applied stance or defaults
                local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
                if appliedValue and math.abs((value or 0) - (appliedValue or 0)) < 0.01 then
                    stanceBackup[stanceType] = value
                else
                    -- Use applied value instead of preview value
                    stanceBackup[stanceType] = appliedValue or (storedData.defaultStance and storedData.defaultStance[stanceType]) or 0
                    print('🚨 [DEBUG] Correcting unapplied stance value in onSelect -', stanceType, 'from:', value, 'to:', stanceBackup[stanceType])
                end
            end
        end
        
        local success, result = pcall(onSelect, vehicle, modIndex)
        
        -- IMMEDIATE restoration after onSelect
        if stanceBackup then
            local vehicleModule = require 'client.modules.vehicle'
            for stanceType, value in pairs(stanceBackup) do
                vehicleModule.applyStanceMod(vehicle, stanceType, value)
            end
        end
        
        return not success or not result
    end

    if not isPaint then
        if isPerformance then
            -- Handle performance mods
            if modData.isEngineSound then
                -- Handle engine sounds - use state bag for sync
                Entity(vehicle).state['vehdata:sound'] = modIndex
                ForceUseAudioGameObject(vehicle, modIndex)
            else
                -- Handle regular performance mods
                -- Store stance values AND wheel mod BEFORE SetVehicleMod as it will reset them
                -- BUT only store values that have been actually applied (not preview values)
                local stanceBackup = nil
                local wheelModBackup = nil
                if storedData.currentStance then
                    local appliedStance = storedData.appliedStance or {}
                    stanceBackup = {}
                    for stanceType, value in pairs(storedData.currentStance) do
                        -- Only backup values that match applied stance or defaults
                        local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
                        if appliedValue and math.abs((value or 0) - (appliedValue or 0)) < 0.01 then
                            stanceBackup[stanceType] = value
                        else
                            -- Use applied value instead of preview value
                            stanceBackup[stanceType] = appliedValue or (storedData.defaultStance and storedData.defaultStance[stanceType]) or 0
                            print('🚨 [DEBUG] Correcting unapplied stance value in performance -', stanceType, 'from:', value, 'to:', stanceBackup[stanceType])
                        end
                    end
                    wheelModBackup = GetVehicleMod(vehicle, 23)
                end
                
                SetVehicleMod(vehicle, modData.id, modIndex, false)
                
                -- Restore wheel mod if it was reset by SetVehicleMod
                if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                    SetVehicleMod(vehicle, 23, wheelModBackup, storedData.customTyres)
                end
                
                -- IMMEDIATE restoration after SetVehicleMod
                if stanceBackup then
                    local vehicleModule = require 'client.modules.vehicle'
                    for stanceType, value in pairs(stanceBackup) do
                        vehicleModule.applyStanceMod(vehicle, stanceType, value)
                    end
                end
                
                -- Update stats for performance previews
                SetTimeout(50, function()
                    updateVehicleStats()
                end)
            end
        else
            -- Handle other mods (wheels, decals, etc.)
            -- CRITICAL: Store stance values AND wheel mod BEFORE SetVehicleMod as it will reset them
            -- BUT only store values that have been actually applied (not preview values)
            local stanceBackup = nil
            local wheelModBackup = nil
            if storedData.currentStance then
                local appliedStance = storedData.appliedStance or {}
                stanceBackup = {}
                for stanceType, value in pairs(storedData.currentStance) do
                    -- Only backup values that match applied stance or defaults
                    local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
                    if appliedValue and math.abs((value or 0) - (appliedValue or 0)) < 0.01 then
                        stanceBackup[stanceType] = value
                    else
                        -- Use applied value instead of preview value
                        stanceBackup[stanceType] = appliedValue or (storedData.defaultStance and storedData.defaultStance[stanceType]) or 0
                        print('🚨 [DEBUG] Correcting unapplied stance value in handleMod -', stanceType, 'from:', value, 'to:', stanceBackup[stanceType])
                    end
                end
                
                -- Also backup the current wheel mod (mod 23) to restore if it gets reset
                wheelModBackup = GetVehicleMod(vehicle, 23)
                print('🚨 [WHEEL DEBUG] BEFORE SetVehicleMod - wheelMod:', wheelModBackup, 'modIndex:', modIndex, 'modType:', modData.id, 'isWheel:', isWheel)
            end
            
            SetVehicleMod(vehicle, isWheel and 23 or modData.id, modIndex, storedData.customTyres)
            
            -- Debug: Check wheel mod after SetVehicleMod
            if storedData.currentStance then
                local wheelModAfter = GetVehicleMod(vehicle, 23)
                print('🚨 [WHEEL DEBUG] AFTER SetVehicleMod - wheelMod:', wheelModAfter, 'changed from:', wheelModBackup, 'to:', wheelModAfter)
                
                -- If wheel mod was reset and we have stance modifications, restore it first
                if wheelModBackup and wheelModBackup ~= -1 and wheelModAfter == -1 and not isWheel then
                    print('🚨 [WHEEL DEBUG] Wheel mod was reset! Restoring wheel mod before stance')
                    SetVehicleMod(vehicle, 23, wheelModBackup, storedData.customTyres)
                    local restoredWheelMod = GetVehicleMod(vehicle, 23)
                    print('🚨 [WHEEL DEBUG] Restored wheel mod to:', restoredWheelMod)
                end
            end
            
            -- IMMEDIATE restoration after SetVehicleMod - this is the correct approach
            if stanceBackup then
                local vehicleModule = require 'client.modules.vehicle'
                -- Apply immediately - no delay needed, SetVehicleMod is synchronous
                for stanceType, value in pairs(stanceBackup) do
                    vehicleModule.applyStanceMod(vehicle, stanceType, value)
                end
            end
        end
    end
end

local function resetLastMod()
    local storedData = store.stored
    
    -- Skip reset entirely if we're dealing with stance modifications from a different menu
    -- This prevents stance from being reset when navigating between non-stance menus
    -- BUT also check that currentStance matches appliedStance to avoid re-applying preview values
    if store.menu ~= 'stance' and storedData.currentStance then
        -- Only skip if currentStance matches what was actually applied
        local appliedStance = storedData.appliedStance or {}
        local hasUnappliedChanges = false
        
        -- Check if any currentStance value differs from appliedStance
        for stanceType, currentValue in pairs(storedData.currentStance) do
            local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
            if math.abs((currentValue or 0) - (appliedValue or 0)) > 0.01 then
                hasUnappliedChanges = true
                break
            end
        end
        
        if not hasUnappliedChanges then
            -- Current stance matches applied stance, safe to skip reset
            return
        else
            print('🚨 [DEBUG] Detected unapplied stance changes - will reset to applied values')
        end
    end
    
    -- Check if appliedMods exists before accessing it
    if not storedData.boughtMods or (storedData.appliedMods and storedData.appliedMods.modType ~= storedData.boughtMods.modType) or (storedData.appliedMods and storedData.appliedMods.mod ~= storedData.boughtMods.mod) then
        if store.menuType == 'wheels' then
            -- Store stance values BEFORE SetVehicleWheelType as it will reset them
            -- BUT only store values that have been actually applied (not preview values)
            local stanceBackup = nil
            if storedData.currentStance then
                local appliedStance = storedData.appliedStance or {}
                stanceBackup = {}
                for stanceType, value in pairs(storedData.currentStance) do
                    -- Only backup values that match applied stance or defaults
                    local appliedValue = appliedStance[stanceType] or (storedData.defaultStance and storedData.defaultStance[stanceType])
                    if appliedValue and math.abs((value or 0) - (appliedValue or 0)) < 0.01 then
                        stanceBackup[stanceType] = value
                    else
                        -- Use applied value instead of preview value
                        stanceBackup[stanceType] = appliedValue or (storedData.defaultStance and storedData.defaultStance[stanceType]) or 0
                        print('🚨 [DEBUG] Correcting unapplied stance value -', stanceType, 'from:', value, 'to:', stanceBackup[stanceType])
                    end
                end
            end
            
            SetVehicleWheelType(cache.vehicle, storedData.currentWheelType)
            
            -- IMMEDIATE restoration after wheel type change
            if stanceBackup then
                local vehicleModule = require 'client.modules.vehicle'
                for stanceType, value in pairs(stanceBackup) do
                    vehicleModule.applyStanceMod(cache.vehicle, stanceType, value)
                end
            end
        end
        
        -- For engine sounds, use currentEngineSound instead of currentMod
        local isEngineSound = (store.menu == 'performance' and store.modType == 'Engine Sound')
        local modToReset = isEngineSound and storedData.currentEngineSound or storedData.currentMod
        
        -- For stance modifications, only reset to default values if currently in stance menu and specifically modifying stance
        if store.menu == 'stance' and store.modType and storedData.currentStance and storedData.defaultStance then
            local stanceData = require 'data.stance'
            local stanceMod = stanceData[store.modType]
            if stanceMod then
                local defaultValue = storedData.defaultStance[stanceMod.stanceType]
                if defaultValue then
                    local vehicle = require 'client.modules.vehicle'
                    vehicle.applyStanceMod(cache.vehicle, stanceMod.stanceType, defaultValue)
                end
            end
        elseif modToReset then
            handleMod(modToReset)
        end
        
        -- Update stats when resetting to previous mod (including performance mods)
        if store.menu == 'performance' then
            SetTimeout(50, function()
                updateVehicleStats()
            end)
        end
    end
end

local function resetMenuData()
    local entity = cache.vehicle
    SetVehicleDoorsLocked(entity, 1)
    FreezeEntityPosition(entity, false)
    
    -- Mark UI as closed (but keep uiLoaded as true since UI is still loaded)
    _G.customsUIOpen = false
    
    -- Always reset NUI focus when closing menu to restore game controls
    SetNuiFocus(false, false)
    
    -- If preview mode was active, make sure to reset it properly
    if store.preview then
        store.preview = false
    end
    
    camera.destroyCam()
    resetLastMod()
    
    -- Stop stance monitoring system when closing customs
    local vehicleModule = require 'client.modules.vehicle'
    vehicleModule.stopStanceMonitor()
    
    -- Re-enable minimap
    enableMinimap()

    store.menu = 'main'
    store.menuType = ''
    store.modType = 'none'
    store.stored = {}
    store.preview = false -- Double-check preview is false
    store.paintNavigationStack = nil -- Clear paint navigation stack
    store.paintColorType = nil -- Clear paint color type
    
    -- Teleport back to original position
    if originalPos then
        -- Fade out before teleporting
        fadeOut(500)
        
        -- Exit customs bucket
        lib.callback.await('bl_customs:exitCustoms', false)
        
        -- Teleport player and vehicle back
        local ped = PlayerPedId()
        SetEntityCoords(entity, originalPos.x, originalPos.y, originalPos.z)
        SetEntityHeading(entity, originalPos.w)
        SetEntityCoords(ped, originalPos.x, originalPos.y, originalPos.z)
        
        -- Small delay to ensure proper positioning
        SetTimeout(100, function()
            SetPedIntoVehicle(ped, entity, -1)
            -- Fade back in after teleport
            fadeIn(500)
        end)
        
        originalPos = nil
    end
end

-- Function to calculate vehicle stats based on modifications
local function calculateVehicleStats(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return {
            vehicleModel = "Unknown",
            speed = 0,
            acceleration = 0,
            braking = 0,
            handling = 0
        }
    end

    -- Get vehicle model name
    local modelHash = GetEntityModel(vehicle)
    local vehicleModel = GetDisplayNameFromVehicleModel(modelHash)
    
    -- Get base vehicle stats and normalize to 1.0-3.0 range (leaving room for mods)
    local speed = GetVehicleModelMaxSpeed(modelHash) / 50.0 -- Keep current scaling
    local acceleration = GetVehicleModelAcceleration(modelHash) * 3.0 -- Reduce scaling
    local braking = GetVehicleModelMaxBraking(modelHash) * 2.0 -- Much lower base to show improvement
    local handling = GetVehicleModelMaxTraction(modelHash) * 0.8 -- Reduce high values
    
    -- Ensure base values are in reasonable range (1.0-3.0)
    speed = math.max(1.0, math.min(speed, 3.0))
    acceleration = math.max(1.0, math.min(acceleration, 3.0))
    braking = math.max(1.0, math.min(braking, 3.0))
    handling = math.max(1.0, math.min(handling, 3.0))
    
    -- print('📊 Base stats - Speed:', speed, 'Acceleration:', acceleration, 'Braking:', braking, 'Handling:', handling)
    
    -- Apply modification bonuses
    -- Engine modification (11) affects speed and acceleration
    local engineMod = GetVehicleMod(vehicle, 11)
    if engineMod >= 0 then
        speed = speed + (engineMod + 1) * 0.3 -- Each level adds 0.3
        acceleration = acceleration + (engineMod + 1) * 0.25 -- Each level adds 0.25
    end
    
    -- Brakes modification (12) affects braking
    local brakesMod = GetVehicleMod(vehicle, 12)
    if brakesMod >= 0 then
        braking = braking + (brakesMod + 1) * 0.4 -- Each level adds 0.4
        -- print('🔧 Brakes mod level:', brakesMod, 'New braking value:', braking) -- Debug
    end
    
    -- Transmission modification (13) affects acceleration
    local transmissionMod = GetVehicleMod(vehicle, 13)
    if transmissionMod >= 0 then
        acceleration = acceleration + (transmissionMod + 1) * 0.2 -- Each level adds 0.2
    end
    
    -- Suspension modification (15) affects handling and braking
    local suspensionMod = GetVehicleMod(vehicle, 15)
    if suspensionMod >= 0 then
        handling = handling + (suspensionMod + 1) * 0.4 -- Each level adds 0.4 to handling
        braking = braking + (suspensionMod + 1) * 0.2 -- Each level adds 0.2 to braking (better stability)
        -- print('🔧 Suspension mod level:', suspensionMod, 'New handling:', handling, 'New braking:', braking) -- Debug
    end
    
    -- Debug all mod values
    -- print('🚗 All mods - Engine:', engineMod, 'Brakes:', brakesMod, 'Transmission:', transmissionMod, 'Suspension:', suspensionMod)
    
    -- Turbo modification (18) affects speed and acceleration
    if IsToggleModOn(vehicle, 18) then
        speed = speed + 0.5
        acceleration = acceleration + 0.4
    end
    
    -- Clamp values to max 5.0
    speed = math.min(speed, 5.0)
    acceleration = math.min(acceleration, 5.0)
    braking = math.min(braking, 5.0)
    handling = math.min(handling, 5.0)
    
    return {
        vehicleModel = vehicleModel,
        speed = math.max(speed, 0.1), -- Minimum 0.1
        acceleration = math.max(acceleration, 0.1),
        braking = math.max(braking, 0.1),
        handling = math.max(handling, 0.1)
    }
end

-- Function to update vehicle stats and send to UI
local function updateVehicleStats()
    if not uiLoaded then return end
    
    local vehicle = cache.vehicle
    if not vehicle then return end
    
    local stats = calculateVehicleStats(vehicle)
    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
    SendReactMessage('updateVehicleStats', stats)
end

local function filterMods()
    local categories = lib.load('client.modules.filter').filtered

    local polyMods = poly.mods
    if not poly.mods then
        return categories
    end

    local filter = {}
    for _, data in ipairs(categories) do

        if polyMods then
            local add = false
            for _, mod in ipairs(poly.mods) do
                if data.important or data.id == mod then
                    add = true
                end
            end
    
            if add then
                filter[#filter+1] = data
            end
        end
    end
    
    return filter
end

---comment
---@param show boolean
local function showMenu(show)
    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
    if not show then
        SendReactMessage('setVisible', false)
        resetMenuData()
        return
    end
    local entity = cache.vehicle
    if not poly.isNear or not entity then return end

    lib.waitFor(function()
        if uiLoaded then return true end
    end, 'Couldn\'t load UI, did you download release?', 5000)

    -- Store original position before teleporting
    local ped = PlayerPedId()
    originalPos = GetEntityCoords(entity)
    originalPos = vector4(originalPos.x, originalPos.y, originalPos.z, GetEntityHeading(entity))
    
    -- Fade out before teleporting
    fadeOut(500)
    
    -- Enter customs bucket
    local bucketSet = lib.callback.await('bl_customs:enterCustoms', false)
    if not bucketSet then
        lib.notify({ title = 'Customs', description = 'Customs shop is full, please wait', type = 'error' })
        originalPos = nil
        fadeIn(500) -- Fade back in if failed
        return
    end
    
    -- Get customization location from config
    local config = require 'data.config'
    local customLoc = config.customizationLocation
    
    -- Teleport vehicle and player to custom location
    SetEntityCoords(entity, customLoc.x, customLoc.y, customLoc.z)
    SetEntityHeading(entity, customLoc.w)
    SetEntityCoords(ped, customLoc.x, customLoc.y, customLoc.z)
    
    -- Small delay to ensure proper positioning
    SetTimeout(100, function()
        SetPedIntoVehicle(ped, entity, -1)
        -- Fade back in after teleport
        fadeIn(500)
    end)

    SendReactMessage('setZoneMods', filterMods())
    SendReactMessage('setVisible', true)
    _G.customsUIOpen = true -- Mark UI as open
    
    -- Disable minimap when UI opens
    disableMinimap()
    
    -- Send initial vehicle stats
    SetTimeout(200, function()
        updateVehicleStats()
    end)
    
    SetVehicleEngineOn(entity, true, true, false)
    SetVehicleModKit(entity, 0)
    FreezeEntityPosition(entity, true)
    SetVehicleDoorsLocked(entity, 4)
    camera.createMainCam()
    
    -- Start thread to disable vehicle controls while menu is open
    CreateThread(function()
        while _G.customsUIOpen do
            -- Disable radio controls (Q/E on keyboard, D-pad left on controller)
            DisableControlAction(0, 81, true)  -- Radio wheel (Q)
            DisableControlAction(0, 82, true)  -- Radio wheel (E)
            DisableControlAction(0, 83, true)  -- Radio Next
            DisableControlAction(0, 84, true)  -- Radio Previous
            DisableControlAction(0, 85, true)  -- Radio Skip
            
            -- Disable vehicle lights (H on keyboard, D-pad right on controller)
            DisableControlAction(0, 74, true)  -- Headlights
            
            -- Disable other vehicle controls that might interfere
            DisableControlAction(0, 75, true)  -- Exit vehicle
            DisableControlAction(0, 71, true)  -- Accelerate
            DisableControlAction(0, 72, true)  -- Brake/Reverse
            DisableControlAction(0, 86, true)  -- Horn
            DisableControlAction(0, 99, true)  -- Vehicle Select Next Weapon
            DisableControlAction(0, 100, true) -- Vehicle Select Previous Weapon
            DisableControlAction(0, 114, true) -- Vehicle Fly Throttle Up
            DisableControlAction(0, 115, true) -- Vehicle Fly Throttle Down
            DisableControlAction(0, 121, true) -- Vehicle Fly Roll Left
            DisableControlAction(0, 122, true) -- Vehicle Fly Roll Right
            
            Wait(0)
        end
    end)
end

---comment
---@param menu 'exit' | 'decals' | 'wheels' | 'paint' | 'preview'
---@return table|nil
local function handleMainMenus(menu)
    local category = require 'client.modules.filter'.named[menu]
    local selector = category and category.selector
    if not selector or not selector.onSelect then 
        -- print('❌ [DEBUG LUA] No selector found for menu:', menu)
        return {}
    end
    
    
    local result = selector.onSelect(category)
    
    -- Validate that all items have proper labels
    if result and type(result) == 'table' then
        for i, item in ipairs(result) do
            if not item.label and not item.id then
                -- print('⚠️  [DEBUG LUA] Item without label/id at index', i, 'in menu', menu)
                result[i].label = 'Unknown Item'
            elseif not item.label and item.id then
                result[i].label = tostring(item.id)
            end
        end
    end
    
    return result or {}
end

---comment
---@param data {type: string, isBack:boolean, clickedCard:string}
---@return table|nil
local function handleMenuClick(data)
    local cardType, clickedCard, isBack, menuType in data
    -- print('🔍 [DEBUG LUA] handleMenuClick called with data:', json.encode(data))
    
    if clickedCard == nil then 
        -- print('❌ [DEBUG LUA] clickedCard is nil, returning')
        return 
    end

    -- Only switch camera when going back from a specific camera view
    if isBack then
        -- print('🔄 [MENU] Back navigation detected - calling camera.switchCam()')
        camera.switchCam()
        resetLastMod()
    end
    
    -- IMPORTANT: Debug current state
    print('🔍 [DEBUG LUA] menuClick - isBack:', isBack, 'clickedCard:', clickedCard, 'store.menu:', store.menu, 'store.menuType:', store.menuType, 'store.modType:', store.modType)
    if store.paintNavigationStack then
        print('🔍 [DEBUG LUA] paintNavigationStack size:', #store.paintNavigationStack)
    end
    
    -- Special handling for backspace from main menu - HIGHEST PRIORITY
    if isBack and clickedCard == 'main' then
        print('🔙 [DEBUG LUA] Back navigation from main menu - closing customs')
        return false -- This will close the customs menu
    end
    
    -- Special handling for navigation to customization menu  
    if isBack and clickedCard == 'customization' then
        print('🔙 [DEBUG LUA] Back navigation to customization menu')
        store.menu = 'customization'
        store.menuType = 'main'
        store.modType = 'none'
        store.paintNavigationStack = nil -- Clear paint stack when leaving paint area
        return handleMainMenus('customization')
    end
    
    -- Special handling for when we're in customization and need to go back to main
    if isBack and store.menu == 'customization' then
        print('🔙 [DEBUG LUA] Back navigation from customization to main')
        store.menu = 'main'
        store.menuType = 'main'
        store.modType = 'none'
        store.paintNavigationStack = nil -- Clear any remaining paint stack
        store.paintColorType = nil -- Clear paint color type too
        -- Return the main menu (filtered categories) directly instead of calling handleMainMenus
        return filterMods()
    end
    
    -- Special handling for submenu back navigation (decals, horns, wheels)
    if isBack and (store.menu == 'decals' or store.menu == 'horns' or store.menu == 'wheels') then
        print('🔙 [DEBUG LUA] Back navigation from submenu:', store.menu, 'to customization')
        store.menu = 'customization'
        store.menuType = 'main'
        store.modType = 'none'
        return handleMainMenus('customization')
    end
    
    -- Special handling for paint back navigation (handle 4-level navigation)
    if isBack and store.menu == 'paint' and store.paintNavigationStack and #store.paintNavigationStack > 0 then
        print('🔙 [DEBUG LUA] Paint back navigation - store.modType:', store.modType, 'store.menuType:', store.menuType)
        
        -- Pop the last level from the stack and return that menu
        local previousLevel = table.remove(store.paintNavigationStack) -- Remove and return last element
        print('🔙 [DEBUG LUA] Going back to previous level:', json.encode(previousLevel))
        
        if previousLevel.type == 'customization' then
            -- Go back to customization menu and clear paint stack
            store.menu = 'customization'
            store.menuType = 'main'
            store.modType = 'none'
            store.paintNavigationStack = nil
            return handleMainMenus('customization')
        elseif previousLevel.type == 'paintTypes' then
            -- Go back to Primary/Secondary level
            local vehicle = require 'client.modules.vehicle'
            store.modType = previousLevel.modType or 'none'
            return vehicle.getVehicleColors()
        elseif previousLevel.type == 'colorTypes' then
            -- Go back to Metallic/Matte level  
            local vehicle = require 'client.modules.vehicle'
            store.modType = previousLevel.modType or 'Primary'
            return vehicle.getPaintTypes()
        end
    end
    
    if cardType == 'menu' then
        print('🔧 [DEBUG LUA] Processing menu type:', clickedCard)
        
        -- Special handling for direct actions (repair, preview)
        if clickedCard == 'repair' then
            print('🔧 [DEBUG LUA] Processing repair action directly')
            
            -- Execute repair directly without loading category
            local vehicle = cache.vehicle
            if not vehicle then
                print('❌ [DEBUG LUA] No vehicle found for repair')
                return false
            end
            
            -- Calculate repair price
            local engine, body = GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle)
            local bodyDamage = 100 - (body/10)
            local engineDamage = 100 - (engine/10)
            local price = ((bodyDamage * 50) + (engineDamage * 50))
            if price < 0 then price = 0 end
            price = math.floor(price)
            
            print('🔧 [DEBUG LUA] Repair price calculated:', price)
            
            if price == 0 then
                lib.notify({ title = 'Customs', description = 'Vehicle is fixed already', type = 'warning' })
                return false
            end
            
            -- Check if can afford
            local poly = require 'client.modules.polyzone'
            local canAfford = poly.free or lib.callback.await('bl_customs:canAffordMod', false, price)
            
            if canAfford then
                print('🔧 [DEBUG LUA] Starting repair process')
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleFixed(vehicle)
                
                local updateCard = require 'client.modules.utils'.updateCard
                updateCard('repair', {hide = true})
                
                lib.notify({ title = 'Customs', description = 'vehicle fixed!', type = 'success' })
                print('🔧 [DEBUG LUA] Repair process completed')
            else
                lib.notify({ title = 'Customs', description = 'You cannot afford this repair', type = 'error' })
            end
            
            -- Return false to indicate no menu navigation
            return false
        elseif clickedCard == 'preview' then
            print('🔧 [DEBUG LUA] Processing preview action directly')
            
            -- Execute preview toggle directly
            local camera = require 'client.modules.camera'
            store.preview = not store.preview
            local text = ''
            if store.preview then
                text = 'Preview Mode: On'
                SetNuiFocus(true, false)
                camera.destroyCam()
            else
                text = 'Preview Mode: Off'
                SetNuiFocus(true, true)
                camera.createMainCam()
            end

            lib.notify({ title = 'Customs', description = text, type = 'inform' })
            print('🔧 [DEBUG LUA] Preview toggled to:', store.preview)
            
            -- Return false to indicate no menu navigation
            return false
        end
        
        store.menu = clickedCard
        store.menuType = not isBack and (menuType or 'main') or store.menuType
        store.modType = 'none'
        
        -- Clear paint navigation stack when navigating to main menu
        if clickedCard == 'main' then
            store.paintNavigationStack = nil
            store.paintColorType = nil
            store.menu = 'main' -- Ensure menu is set to main
            store.menuType = 'main' -- Ensure menuType is set to main  
            store.modType = 'none' -- Ensure modType is reset
            print('🔧 [DEBUG LUA] Cleared all navigation state - navigating to main menu')
        end
        
        return handleMainMenus(clickedCard)
    elseif cardType == 'submenu' then
        print('🔧 [DEBUG LUA] Processing submenu type:', clickedCard)
        -- Don't update store.menu yet, we need it to remain 'customization' for triggerSelector
        store.menuType = not isBack and (menuType or clickedCard) or store.menuType
        store.modType = clickedCard
        
        -- Clear paintColorType when navigating to Window Tint or Neon Colors
        if clickedCard == 'Window Tint' or clickedCard == 'Neon Colors' then
            store.paintColorType = nil
            print('🎨 [DEBUG LUA] Cleared paintColorType for:', clickedCard)
        end
        -- For submenus, we need to trigger the childOnSelect of the parent (customization)
        -- Temporarily set store.menu to 'customization' to find the correct selector
        local originalMenu = store.menu
        store.menu = 'customization'
        print('🔍 [DEBUG LUA] About to call triggerSelector with store.menu forced to:', store.menu, '(was:', originalMenu, ')')
        local success, result = pcall(triggerSelector, 'childOnSelect', clickedCard)
        -- Restore original menu after the call
        store.menu = originalMenu
        print('🔧 [DEBUG LUA] Submenu triggerSelector result - success:', success, 'result type:', type(result))
        if not success then
            print('❌ [DEBUG LUA] triggerSelector error:', tostring(result))
        end
        if success and result then
            -- Now update store.menu after we got the result
            store.menu = clickedCard
            
            -- Initialize paint navigation stack when entering paint submenu
            if clickedCard == 'paint' then
                store.paintNavigationStack = {{type = 'customization', modType = 'none'}}
                print('🎨 [DEBUG LUA] Initialized paint navigation stack')
            end
            
            print('🔧 [DEBUG LUA] Submenu data returned:')
            if type(result) == 'table' then
                print('🔧 [DEBUG LUA] Number of items:', #result)
                for i = 1, math.min(3, #result) do
                    local item = result[i]
                    print(string.format('  Item %d: id=%s, label=%s', i, tostring(item.id), tostring(item.label or item.id)))
                end
            end
        end
        return success and result or nil
    elseif cardType == 'modType' then
        -- print('🔧 [DEBUG LUA] Processing modType:', clickedCard)
        local colorTypes = require 'client.modules.filter'.colorTypes
        store.modType = store.menuType == 'paint' and (table_contain(colorTypes, clickedCard) and clickedCard or store.modType) or clickedCard
        
        -- Clear paintColorType when selecting Window Tint or Neon Colors as modType
        if clickedCard == 'Window Tint' or clickedCard == 'Neon Colors' then
            store.paintColorType = nil
            print('🎨 [DEBUG LUA] Cleared paintColorType for modType:', clickedCard)
        end
        
        -- Special handling for items within submenus
        if store.menu == 'decals' then
            -- We're in decals submenu, handle decal items
            if clickedCard == 'Extras' and needRepair then
                lib.notify({ title = 'Customs', description = 'Please repair your car!', type = 'inform' })
                return nil
            end
            return getMod(clickedCard)
        elseif store.menu == 'horns' then
            -- We're in horns submenu, handle horn items
            return getMod(clickedCard)
        elseif store.menu == 'paint' then
            -- We're in paint submenu, use color functions
            print('🎨 [DEBUG LUA] Processing paint type:', clickedCard)
            local vehicle = require 'client.modules.vehicle'
            local colorFunctions = require 'data.colors'.functions
            local colorsData = require 'data.colors'.data
            
            -- Initialize navigation stack if it doesn't exist
            if not store.paintNavigationStack then
                store.paintNavigationStack = {}
            end
            
            -- Check if clickedCard is a paint type category (like Primary, Secondary)
            local func = colorFunctions[clickedCard]
            if func and func.onClick then
                -- Add current level to stack before navigating
                table.insert(store.paintNavigationStack, {type = 'paintTypes', modType = store.modType})
                print('🎨 [DEBUG LUA] Added paintTypes to stack, going to colorTypes')
                store.modType = clickedCard
                -- Store the paint color type (Primary or Secondary)
                if clickedCard == 'Primary' or clickedCard == 'Secondary' then
                    store.paintColorType = clickedCard
                    print('🎨 [DEBUG LUA] Set paintColorType to:', clickedCard)
                end
                return func.onClick()
            -- Check if clickedCard is a color type (like Metallic, Matte, Chrome)
            elseif colorsData[clickedCard] then
                -- Add current level to stack before navigating  
                table.insert(store.paintNavigationStack, {type = 'colorTypes', modType = store.modType})
                print('🎨 [DEBUG LUA] Added colorTypes to stack, going to specific colors')
                store.modType = clickedCard -- Update modType to track current level
                return colorsData[clickedCard]
            else
                print('❌ [DEBUG LUA] No function or data found for paint type:', clickedCard)
                return nil
            end
        elseif store.menu == 'wheels' then
            -- We're in wheels submenu, get specific wheel type
            print('🚗 [DEBUG LUA] Processing wheel type:', clickedCard)
            local vehicle = require 'client.modules.vehicle'
            
            -- Call getVehicleWheelType directly with the wheel type
            store.modType = clickedCard
            return vehicle.getVehicleWheelType(clickedCard)
        end
    end

    -- Special handling for back navigation when we're stuck
    if isBack and (clickedCard == 'Primary' or clickedCard == 'Secondary' or clickedCard == 'Dashboard' or clickedCard == 'Interior' or clickedCard == 'Wheels' or clickedCard == 'Pearlescent') then
        print('🔧 [DEBUG LUA] Detected back navigation from color type, going to customization')
        store.menu = 'customization'
        store.menuType = 'main'
        store.modType = 'none'
        store.paintNavigationStack = nil -- Clear any remaining paint stack
        return handleMainMenus('customization')
    end

    local success, result = pcall(triggerSelector, 'childOnSelect', clickedCard)
    print('🔧 [DEBUG LUA] triggerSelector result - success:', success, 'result type:', type(result))
    if result then
        print('🔧 [DEBUG LUA] Returning result with', #result, 'items')
    else
        print('🔧 [DEBUG LUA] No result to return')
    end
    return success and result or nil
end

---comment
---@param amount number
---@return boolean
local function removeMoney(amount)
    return poly.free or lib.callback.await('bl_customs:canAffordMod', false, amount)
end

local function buyMod(data)
    local storedData = store.stored
    local isPerformance = store.menu == 'performance'
    local modType = store.modType
    local isEngineSound = false
    
    -- print('🛒 BuyMod called - Performance:', isPerformance, 'ModType:', modType, 'Data:', json.encode(data))
    
    -- Check if it's an engine sound
    if isPerformance and modType == 'Engine Sound' then
        local performanceData = require 'data.performance'
        local modData = performanceData[modType]
        isEngineSound = modData and modData.isEngineSound
        -- print('🔊 Engine sound detected - ModData exists:', modData ~= nil, 'IsEngineSound:', isEngineSound)
    end

    -- For engine sounds, check current sound instead of mod
    local currentValue = isEngineSound and storedData.currentEngineSound or storedData.currentMod
    -- print('🔄 Current value:', currentValue, 'New mod:', data.mod)
    
    if currentValue == data.mod then
        lib.notify({ title = 'Customs', description = 'You have this mod already', type = 'warning' })
        -- print('❌ Already have this mod')
        return false
    end
    if not removeMoney(data.price) then
        lib.notify({ title = 'Customs', description = 'You\'re broke', type = 'warning' })
        -- print('💸 Not enough money')
        return false
    end
    storedData.boughtMods = { price = data.price, mod = data.mod, modType = store.modType }
    
    -- Update the appropriate current value
    if isEngineSound then
        storedData.currentEngineSound = data.mod
        -- print('🔊 Updated currentEngineSound to:', data.mod)
    else
        storedData.currentMod = data.mod
        -- print('🔧 Updated currentMod to:', data.mod)
    end

    -- print('🎯 Calling triggerSelector childOnBuy')
    -- For submenus, we need to temporarily set store.menu to 'customization' to find the correct childOnBuy
    local originalMenu = store.menu
    if store.menu == 'decals' or store.menu == 'horns' or store.menu == 'paint' or store.menu == 'wheels' then
        store.menu = 'customization'
        print('🔧 [DEBUG] Temporarily changed store.menu to customization for childOnBuy (was:', originalMenu, ')')
    end
    
    local success, result = pcall(triggerSelector, 'childOnBuy', data.mod)
    
    -- Restore original menu
    store.menu = originalMenu
    print('🔧 [DEBUG] triggerSelector childOnBuy result - Success:', success, 'Result:', result)
    
    -- Update vehicle stats if it's a performance modification
    if isPerformance then
        SetTimeout(100, function() -- Small delay to ensure mod is applied
            updateVehicleStats()
        end)
    end
    
    -- print('✅ BuyMod returning:', success and result or true)
    return success and result or true
end

---comment
---@param data {price: number, toggle:boolean, mod:number}
---@return boolean|nil
local function toggleMod(data)
    if not removeMoney(data.price) then
        lib.notify({ title = 'Customs', description = 'You\'re broke', type = 'warning' })
        return false
    end
    local mod, toggle in data
    local modType = store.modType
    local isPerformance = store.menu == 'performance'
    local modData = store.menuType == 'wheels' and require 'data.wheels'[modType] or store.menuType == 'paint' and require 'data.colors'.functions[modType] or isPerformance and require 'data.performance'[modType] or require 'data.decals'[modType]
    local vehicle = cache.vehicle

    if modData then
        local onToggle = modData.onToggle
        if onToggle then
            local success, result = pcall(onToggle, vehicle, mod, toggle)
            return not success or not result
        end
    end

    ToggleVehicleMod(vehicle, mod, toggle)

    -- Update vehicle stats if it's a performance toggle (like Turbo)
    if isPerformance then
        SetTimeout(100, function() -- Small delay to ensure mod is applied
            updateVehicleStats()
        end)
    end

    local success, result = pcall(triggerSelector, 'childOnToggle', mod, toggle)
    return not success or not result
end

RegisterNUICallback('hideFrame', function(_, cb)
    showMenu(false)
    cb({})
end)

RegisterNUICallback('setMenu', function(menu, cb)
    local menuData = handleMenuClick(menu)
    cb(menuData or false)
end)

RegisterNUICallback('applyMod', function(modIndex, cb)
    handleMod(modIndex)
    cb(true)
end)

RegisterNUICallback('buyMod', function(data, cb)
    cb(buyMod(data))
end)

RegisterNUICallback('customsLoaded', function(data, cb)
    uiLoaded = true
    cb(require 'client.modules.filter'.colorTypes)
end)

RegisterNUICallback('toggleMod', function(data, cb)
    cb(toggleMod(data))
end)

RegisterNUICallback("cameraHandle", function(data, cb)
    camera.handleNuiCamera(data)
    cb(1)
end)

RegisterNUICallback('getPlayerMoney', function(_, cb)
    local money = lib.callback.await('bl_customs:getPlayerMoney', false)
    cb(money or 0)
end)

RegisterNUICallback('getVehicleStats', function(_, cb)
    local vehicle = cache.vehicle
    local stats = calculateVehicleStats(vehicle)
    cb(stats)
end)

-- Stance menu callbacks
RegisterNUICallback('updateStanceValue', function(data, cb)
    local vehicle = cache.vehicle
    if not vehicle then cb(false) return end
    
    -- Store the stance value directly in currentStance
    store.stored.currentStance = store.stored.currentStance or {}
    store.stored.currentStance[data.type] = data.value
    
    local vehicleModule = require 'client.modules.vehicle'
    vehicleModule.applyStanceMod(vehicle, data.type, data.value)
    cb(true)
end)

RegisterNUICallback('applyStance', function(data, cb)
    -- Apply all stance values and save them
    local vehicle = cache.vehicle
    if not vehicle then cb(false) return end
    
    local price = data.price or 0
    print('💰 [DEBUG] Stance apply requested with price:', price)
    
    -- Check if player can afford the stance modifications
    local poly = require 'client.modules.polyzone'
    local canAfford = poly.free or lib.callback.await('bl_customs:canAffordMod', false, price)
    
    if not canAfford and price > 0 then
        print('❌ [DEBUG] Cannot afford stance modifications - price:', price)
        lib.notify({ title = 'Customs', description = 'You cannot afford these stance modifications', type = 'error' })
        cb(false)
        return
    end
    
    -- If price > 0, charge the player (handled by the callback system)
    if price > 0 then
        print('✅ [DEBUG] Player charged for stance modifications - price:', price)
        lib.notify({ title = 'Customs', description = 'Stance modifications applied for $' .. price, type = 'success' })
    else
        print('🆓 [DEBUG] No charge for stance modifications')
        lib.notify({ title = 'Customs', description = 'Stance modifications applied!', type = 'success' })
    end
    
    -- Mark as purchased and save current stance values as applied
    store.stored.stancePurchased = true
    
    -- Store the current stance values as the new "applied" state
    -- These will be used when user cancels stance menu to restore to purchased state
    local vehicleModule = require 'client.modules.vehicle'
    local currentStanceValues = {}
    
    -- Get actual current values from the vehicle
    currentStanceValues.height = GetVehicleSuspensionHeight(vehicle) or 0
    currentStanceValues.offsetFront = GetVehicleWheelXOffset(vehicle, 1) or 0
    currentStanceValues.offsetRear = GetVehicleWheelXOffset(vehicle, 3) or 0
    
    -- Helper function for camber
    local function canModifyStance(vehicle, class, field)
        local before = GetVehicleHandlingFloat(vehicle, class, field)
        SetVehicleHandlingFloat(vehicle, class, field, before + 0.01)
        if GetVehicleHandlingFloat(vehicle, class, field) == before then 
            SetVehicleHandlingFloat(vehicle, class, field, before)
            return false 
        end
        SetVehicleHandlingFloat(vehicle, class, field, before)
        return true
    end
    
    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberFront') then
        currentStanceValues.camberFront = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberFront') or 0
    end
    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberRear') then
        currentStanceValues.camberRear = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberRear') or 0
    end
    
    currentStanceValues.wheelSize = GetVehicleWheelSize(vehicle) or 1.0
    currentStanceValues.wheelWidth = GetVehicleWheelWidth(vehicle) or 1.0
    
    store.stored.appliedStance = currentStanceValues
    print('🔧 [DEBUG] Saved applied stance values - wheelSize:', currentStanceValues.wheelSize, 'wheelWidth:', currentStanceValues.wheelWidth)
    
    -- Simply close stance menu overlay - customization menu should still be there
    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
    SendReactMessage('closeStanceMenu', {})
    
    -- Restore NUI focus to customization menu
    SetNuiFocus(true, true)
    
    print('🔧 [DEBUG] Stance applied and overlay closed - customization menu should be visible')
    
    cb(true)
end)

RegisterNUICallback('cancelStance', function(_, cb)
    -- Reset ONLY non-applied (preview) changes, keep applied (purchased) changes
    local vehicle = cache.vehicle
    if not vehicle then cb(false) return end
    
    print('🔧 [DEBUG] Stance cancelled - resetting to last applied state')
    
    local vehicleModule = require 'client.modules.vehicle'
    local storedData = store.stored
    
    -- Get the last APPLIED stance values (purchased modifications)
    -- These are stored when the user actually buys modifications
    local lastAppliedStance = storedData.appliedStance or {}
    
    -- If we don't have applied stance data, use the original defaults
    if not lastAppliedStance or not next(lastAppliedStance) then
        -- No applied modifications, reset to original defaults
        local defaultStance = storedData.defaultStance
        if defaultStance then
            print('🔧 [DEBUG] No applied stance found - resetting to original defaults')
            vehicleModule.applyStanceMod(vehicle, 'height', defaultStance.height or 0)
            vehicleModule.applyStanceMod(vehicle, 'offsetFront', defaultStance.offsetFront or 0)
            vehicleModule.applyStanceMod(vehicle, 'offsetRear', defaultStance.offsetRear or 0)
            if defaultStance.camberFront then
                vehicleModule.applyStanceMod(vehicle, 'camberFront', defaultStance.camberFront)
            end
            if defaultStance.camberRear then
                vehicleModule.applyStanceMod(vehicle, 'camberRear', defaultStance.camberRear)
            end
            if defaultStance.wheelSize then
                vehicleModule.applyStanceMod(vehicle, 'wheelSize', defaultStance.wheelSize)
            end
            if defaultStance.wheelWidth then
                vehicleModule.applyStanceMod(vehicle, 'wheelWidth', defaultStance.wheelWidth)
            end
        end
    else
        -- Restore to last applied (purchased) state
        print('🔧 [DEBUG] Restoring to last applied stance values')
        for stanceType, value in pairs(lastAppliedStance) do
            vehicleModule.applyStanceMod(vehicle, stanceType, value)
            print('🔧 [DEBUG] Restored', stanceType, 'to applied value:', value)
        end
    end
    
    -- CRITICAL: Reset currentStance to match what was actually applied
    -- This prevents preview values from being re-applied when changing wheels
    if not lastAppliedStance or not next(lastAppliedStance) then
        -- No applied stance, reset to defaults
        storedData.currentStance = storedData.defaultStance and {} or nil
        if storedData.currentStance and storedData.defaultStance then
            for k, v in pairs(storedData.defaultStance) do
                storedData.currentStance[k] = v
            end
        end
        print('🔧 [DEBUG] Reset currentStance to default values')
    else
        -- Reset to last applied values
        storedData.currentStance = {}
        for k, v in pairs(lastAppliedStance) do
            storedData.currentStance[k] = v
        end
        print('🔧 [DEBUG] Reset currentStance to last applied values')
    end
    
    -- Close stance menu overlay
    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
    SendReactMessage('closeStanceMenu', {})
    
    -- Restore NUI focus to customization menu
    SetNuiFocus(true, true)
    
    print('🔧 [DEBUG] Stance overlay closed - customization menu should be visible')
    
    cb(true)
end)

-- Handle money updates from server
RegisterNetEvent('bl_customs:updatePlayerMoney', function(newMoney)
    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
    SendReactMessage('updatePlayerMoney', { money = newMoney })
end)

-- Handle engine sound synchronization (from enginesound-menu)
AddStateBagChangeHandler(
    "vehdata:sound",
    nil,
    function(bagName, _, value)
        local entity = GetEntityFromStateBagName(bagName)
        if entity == 0 then return end
        if not IsEntityAVehicle(entity) then return end
        ForceUseAudioGameObject(entity, value)
    end
)

return showMenu
