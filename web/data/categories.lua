local vehicle = require 'client.modules.vehicle'
local getVehicleDecals, getVehicleWheels, getVehicleColors, getMod, getVehicleWheelType, getVehicleColorTypes, getVehiclePerformance, getPerformanceMod, getVehicleHorns in vehicle
local updateCard = require 'client.modules.utils'.updateCard
local store = require 'client.modules.store'
local needRepair = false

return {
    {
        id = 'custom',
        label = 'Custom',
        icon = 'bug',
        hide = true,
        selector = {
            onOpen = function(data) -- this will trigger before the current menu renders (used in repair to update price depend on vehicle damage), data: self data
                data.icon = 'poo' --here we will update icon
            end,
            onSelect = function()
                return {
                    {id = 200, toggle = true, label = 'this is toggle', price = 100, selected = true},
                    {id = 2000, label = 'this is a mod', price = 100},
                    {id = 'menu1', label = 'this is a menu'}
                }
            end,
            childOnBuy = function(modType) -- trigger on mod buy, this will work if mod id is a number such '2000' 
                if modType == 2000 then -- here we listen to child item
                    print('setted mod')
                    return true -- return true to set check icon
                end
            end,
            childOnSelect = function(modType) -- trigger on mod select of the current menu, this will work if mod id is a string such 'menu1'
                if modType == 'menu1' then -- here we will create submenu for 'menu1', NOTE (currently we don't support menu inside submenu, you will get issue if you try to get back to previous)
                    return {
                        {id = 2000, label = 'this is a mod'},
                        {id = 2002, label = 'this is a mod2'},
                        {id = 2004, label = 'this is a mod3'},
                    }
                end
            end,
            childOnToggle = function(modType, toggle) -- this will trigger when clicking on mod that has toggle
                print(modType, toggle)
            end,
            onModSwitch = function(modType, modId) -- function(modType: parentMenu, modId: modId) | this will only work on mod and not toggle
                print(modType, modId)
            end
        },
    },
    {
        id = 'repair',
        important = true,
        label = 'Repair',
        icon = 'repair.png',
        price = 100,
        selected = true,
        selector = {
            onOpen = function(data) -- return self like (data.price, data.icon),  for ex here im calculating vehicle damage
                needRepair = false
                data.hide = false
                local vehicle = cache.vehicle
                local engine, body = GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle)
                local bodyDamage = 100 - (body/10)
                local engineDamage = 100 - (engine/10)
                local price = ((bodyDamage * 50) + (engineDamage * 50))
                if price < 0 then
                    price = 0
                end
                
                data.price = math.floor(price) -- we update the price to show on UI
                if data.price == 0 then
                    data.hide = true --if vehicle has no damage, we hide the menu
                else
                    needRepair = true
                end
            end,
            onSelect = function(data)
                print('🔧 [DEBUG] Repair onSelect called with data:', json.encode(data))
                local vehicle = cache.vehicle
                print('🔧 [DEBUG] Vehicle:', vehicle)
                local poly = require 'client.modules.polyzone'
                print('🔧 [DEBUG] Polyzone loaded, price:', data.price)
                
                if data.price == 0 then
                    print('🔧 [DEBUG] Price is 0, vehicle already fixed')
                    return lib.notify({ title = 'Customs', description = 'Vehicle is fixed already', type = 'warning' })
                end
                
                print('🔧 [DEBUG] Checking if can afford repair - poly.free:', poly.free, 'price:', data.price)
                local canAfford = poly.free or lib.callback.await('bl_customs:canAffordMod', false, data.price)
                print('🔧 [DEBUG] Can afford repair:', canAfford)
                
                if canAfford then
                    print('🔧 [DEBUG] Starting repair process')
                    SetVehicleBodyHealth(vehicle, 1000.0)
                    SetVehicleEngineHealth(vehicle, 1000.0)
                    SetVehicleFixed(vehicle)
                    print('🔧 [DEBUG] Vehicle repaired, hiding card')
                    updateCard('repair', {hide = true}) -- let hide the card after repairing
                    needRepair = false
                    lib.notify({ title = 'Customs', description = 'vehicle fixed!', type = 'success' })
                    data.price = 0 -- reset the price
                    print('🔧 [DEBUG] Repair process completed')
                else
                    print('🔧 [DEBUG] Cannot afford repair')
                    lib.notify({ title = 'Customs', description = 'You cannot afford this repair', type = 'error' })
                end
            end,
        },
    },
    {
        id = 'preview',
        important = true, -- An important menu can't be removed. If it's false, it can be removed if you didn't place it in the mods table in locations config
        label = 'Preview',
        icon = '9.png',
        selector = {
            onSelect = function()
                local camera = require 'client.modules.camera'
                local store = require 'client.modules.store'
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
            end
        }
    },
    {
        id = 'performance',
        important = true,
        label = 'Performance',
        icon = 'performance.png',
        selector = {
            onSelect = vehicle.getVehiclePerformance,
            childOnSelect = vehicle.getPerformanceMod,
            childOnBuy = function(modId)
                -- print('🎯 childOnBuy called for performance mod:', modId)
                local performanceData = require 'data.performance'
                local modType = store.modType
                local mod = performanceData[modType]
                
                -- For engine sounds, apply the sound
                if modType == 'Engine Sound' and mod and mod.isEngineSound then
                    local vehicle = cache.vehicle
                    -- print('🔊 Applying engine sound:', modId)
                    Entity(vehicle).state['vehdata:sound'] = modId
                    ForceUseAudioGameObject(vehicle, modId)
                    return true
                end
                
                -- For other performance mods, they're handled by the regular system
                return true
            end,
        },
    },
    {
        id = 'customization',
        important = true,
        label = 'Customization',
        icon = 'customization.png',
        selector = {
            onSelect = function()
                return {
                    {id = 'decals', label = 'Decals', icon = 'cosmetics.png'},
                    {id = 'horns', label = 'Horns', icon = 'horns.png'},
                    {id = 'paint', label = 'Paint', icon = 'paint.png', menuType = 'paint'},
                    {id = 'wheels', label = 'Wheels', icon = 'wheels.png', menuType = 'wheels'},
                    {id = 'stance', label = 'Stance', icon = 'performance.png'}
                }
            end,
            childOnSelect = function(submenuType)
                -- Handle submenu navigation (both forward and backward)
                local currentMenu = store.menu
                print('🔍 [DEBUG LUA] childOnSelect called with submenuType:', submenuType, 'currentMenu:', currentMenu)
                
                -- Always handle submenu requests regardless of current menu
                if submenuType == 'decals' then
                    local success, result = pcall(getVehicleDecals)
                    print('🔍 [DEBUG LUA] getVehicleDecals pcall - success:', success)
                    if success then
                        print('🔍 [DEBUG LUA] getVehicleDecals returned type:', type(result), 'length:', result and #result or 'nil')
                        return result
                    else
                        print('❌ [DEBUG LUA] getVehicleDecals failed with error:', tostring(result))
                        return {}
                    end
                elseif submenuType == 'horns' then
                    local result = getVehicleHorns()
                    print('🔍 [DEBUG LUA] getVehicleHorns returned type:', type(result), 'length:', result and #result or 'nil')
                    return result
                elseif submenuType == 'paint' then
                    local result = getVehicleColors()
                    print('🔍 [DEBUG LUA] getVehicleColors returned type:', type(result), 'length:', result and #result or 'nil')
                    return result
                elseif submenuType == 'wheels' then
                    local result = getVehicleWheels()
                    print('🔍 [DEBUG LUA] getVehicleWheels returned type:', type(result), 'length:', result and #result or 'nil')
                    return result
                elseif submenuType == 'stance' then
                    -- Open stance UI as overlay without changing menu
                    print('🔍 [DEBUG LUA] Opening stance UI overlay')
                    
                    -- Get current stance values
                    local vehicle = cache.vehicle
                    local currentValues = {}
                    local defaultValues = {}
                    
                    -- Get helper function to check if modification can be applied
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
                    
                    -- Get current stance values
                    -- BUT if we have unapplied stance changes, use the last applied values instead
                    local hasUnappliedChanges = false
                    if store.stored.currentStance and store.stored.appliedStance then
                        for stanceType, currentVal in pairs(store.stored.currentStance) do
                            local appliedVal = store.stored.appliedStance[stanceType] or (store.stored.defaultStance and store.stored.defaultStance[stanceType])
                            if appliedVal and math.abs((currentVal or 0) - (appliedVal or 0)) > 0.01 then
                                hasUnappliedChanges = true
                                print('🚨 [STANCE DEBUG] Detected unapplied change:', stanceType, 'current:', currentVal, 'applied:', appliedVal)
                                break
                            end
                        end
                    end
                    
                    if hasUnappliedChanges and store.stored.appliedStance then
                        -- Use last applied values instead of current vehicle values
                        print('🔧 [STANCE DEBUG] Using applied values instead of current vehicle values')
                        currentValues.height = store.stored.appliedStance.height or (store.stored.defaultStance and store.stored.defaultStance.height) or 0
                        currentValues.offsetFront = store.stored.appliedStance.offsetFront or (store.stored.defaultStance and store.stored.defaultStance.offsetFront) or 0
                        currentValues.offsetRear = store.stored.appliedStance.offsetRear or (store.stored.defaultStance and store.stored.defaultStance.offsetRear) or 0
                    else
                        -- Use actual current values from vehicle
                        currentValues.height = GetVehicleSuspensionHeight(vehicle) or 0
                        currentValues.offsetFront = GetVehicleWheelXOffset(vehicle, 1) or 0
                        currentValues.offsetRear = GetVehicleWheelXOffset(vehicle, 3) or 0
                    end
                    
                    -- Camber
                    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberFront') then
                        if hasUnappliedChanges and store.stored.appliedStance and store.stored.appliedStance.camberFront then
                            currentValues.camberFront = store.stored.appliedStance.camberFront
                        else
                            currentValues.camberFront = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberFront') or 0
                        end
                    else
                        currentValues.camberFront = nil
                    end
                    
                    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberRear') then
                        if hasUnappliedChanges and store.stored.appliedStance and store.stored.appliedStance.camberRear then
                            currentValues.camberRear = store.stored.appliedStance.camberRear
                        else
                            currentValues.camberRear = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberRear') or 0
                        end
                    else
                        currentValues.camberRear = nil
                    end
                    
                    -- Wheel size/width (always available)
                    if hasUnappliedChanges and store.stored.appliedStance then
                        currentValues.wheelSize = store.stored.appliedStance.wheelSize or (store.stored.defaultStance and store.stored.defaultStance.wheelSize) or 1.0
                        currentValues.wheelWidth = store.stored.appliedStance.wheelWidth or (store.stored.defaultStance and store.stored.defaultStance.wheelWidth) or 1.0
                    else
                        currentValues.wheelSize = GetVehicleWheelSize(vehicle) or 1.0
                        currentValues.wheelWidth = GetVehicleWheelWidth(vehicle) or 1.0
                    end
                    
                    -- Use stored default values if available, otherwise initialize with current
                    if store.stored.defaultStance then
                        -- Use previously stored defaults (preserves original vehicle state)
                        defaultValues = store.stored.defaultStance
                        print('🔧 [STANCE DEBUG] Using stored defaults - wheelSize:', defaultValues.wheelSize, 'wheelWidth:', defaultValues.wheelWidth)
                    else
                        -- First time opening stance - store current as defaults
                        defaultValues.height = currentValues.height
                        defaultValues.offsetFront = currentValues.offsetFront
                        defaultValues.offsetRear = currentValues.offsetRear
                        defaultValues.camberFront = currentValues.camberFront
                        defaultValues.camberRear = currentValues.camberRear
                        defaultValues.wheelSize = currentValues.wheelSize
                        defaultValues.wheelWidth = currentValues.wheelWidth
                        store.stored.defaultStance = defaultValues
                        print('🔧 [STANCE DEBUG] Initialized new defaults - wheelSize:', defaultValues.wheelSize, 'wheelWidth:', defaultValues.wheelWidth)
                    end
                    
                    print('🔧 [STANCE DEBUG] Current vs Default - wheelSize: current=', currentValues.wheelSize, 'default=', defaultValues.wheelSize, 'diff=', math.abs(currentValues.wheelSize - defaultValues.wheelSize))
                    print('🔧 [STANCE DEBUG] Current vs Default - wheelWidth: current=', currentValues.wheelWidth, 'default=', defaultValues.wheelWidth, 'diff=', math.abs(currentValues.wheelWidth - defaultValues.wheelWidth))
                    
                    -- Debug: Log what options are available for this vehicle
                    -- print('🎛️ [DEBUG LUA] Stance options for this vehicle:')
                    for key, value in pairs(currentValues) do
                        -- local status = value ~= nil and '✅ AVAILABLE' or '❌ NOT SUPPORTED'
                        -- print('  ' .. key .. ': ' .. status .. ' (value: ' .. tostring(value) .. ')')
                    end
                    
                    -- Send message to open stance UI as overlay
                    local stanceData = {
                        currentValues = currentValues,
                        defaultValues = defaultValues
                    }
                    
                    print('🎛️ [STANCE DEBUG] Sending to UI - currentValues.wheelSize:', currentValues.wheelSize, 'defaultValues.wheelSize:', defaultValues.wheelSize)
                    print('🎛️ [STANCE DEBUG] Sending to UI - currentValues.wheelWidth:', currentValues.wheelWidth, 'defaultValues.wheelWidth:', defaultValues.wheelWidth)
                    
                    local SendReactMessage = require 'client.modules.utils'.SendReactMessage
                    SendReactMessage('openStanceMenu', stanceData)
                    
                    -- Set NUI focus to the stance overlay for keyboard navigation
                    SetNuiFocus(true, true)
                    
                    -- Don't return any submenu data - stay in current customization menu
                    -- The stance UI will open as an overlay on top
                    -- print('🔍 [DEBUG LUA] Stance overlay opened, staying in customization menu')
                    return nil
                else
                    -- Unknown type
                    -- print('🔍 [DEBUG LUA] Unknown submenu type:', submenuType)
                    return nil
                end
            end,
            childOnBuy = function(modId)
                -- Handle purchases based on current submenu
                local currentMenu = store.menu
                local modType = store.modType -- This will be the actual submenu we're in
                
                print('🔧 [DEBUG] childOnBuy called - currentMenu:', currentMenu, 'modType:', modType, 'modId:', modId)
                
                -- Handle paint colors (Primary/Secondary)
                if currentMenu == 'paint' or store.paintColorType then
                    local vehicle = cache.vehicle
                    local paintType = store.paintColorType
                    print('🎨 [DEBUG] Applying paint color - paintColorType:', paintType, 'colorId:', modId)
                    
                    if paintType == 'Primary' or paintType == 'Secondary' then
                        -- Get current colors
                        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
                        print('🎨 [DEBUG] Current colors - Primary:', colorPrimary, 'Secondary:', colorSecondary)
                        
                        -- Store stance values AND wheel mod BEFORE SetVehicleColours as it will reset them
                        local stanceBackup = nil
                        local wheelModBackup = nil
                        if store.stored.currentStance then
                            stanceBackup = {}
                            for stanceType, value in pairs(store.stored.currentStance) do
                                stanceBackup[stanceType] = value
                            end
                            wheelModBackup = GetVehicleMod(vehicle, 23)
                        end
                        
                        -- Apply the color based on type
                        if paintType == 'Primary' then
                            SetVehicleColours(vehicle, modId, colorSecondary)
                            print('🎨 [DEBUG] Applied Primary color:', modId)
                        elseif paintType == 'Secondary' then
                            SetVehicleColours(vehicle, colorPrimary, modId)
                            print('🎨 [DEBUG] Applied Secondary color:', modId)
                        end
                        
                        -- Restore wheel mod if it was reset
                        if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                            SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
                        end
                        
                        -- IMMEDIATE restoration after SetVehicleColours
                        if stanceBackup then
                            local vehicleModule = require 'client.modules.vehicle'
                            for stanceType, value in pairs(stanceBackup) do
                                vehicleModule.applyStanceMod(vehicle, stanceType, value)
                            end
                        end
                        
                        -- Verify the color was applied
                        local newPrimary, newSecondary = GetVehicleColours(vehicle)
                        print('🎨 [DEBUG] New colors - Primary:', newPrimary, 'Secondary:', newSecondary)
                        
                        return true
                    end
                end
                
                if modType == 'horns' then
                    local vehicle = cache.vehicle
                    print('🔧 [DEBUG] Applying horn - vehicle:', vehicle, 'modId:', modId)
                    
                    -- Check current horn before applying
                    local currentHorn = GetVehicleMod(vehicle, 14)
                    print('🔧 [DEBUG] Current horn before:', currentHorn)
                    
                    -- Store stance values AND wheel mod BEFORE SetVehicleMod as it will reset them
                    local stanceBackup = nil
                    local wheelModBackup = nil
                    if store.stored.currentStance then
                        stanceBackup = {}
                        for stanceType, value in pairs(store.stored.currentStance) do
                            stanceBackup[stanceType] = value
                        end
                        wheelModBackup = GetVehicleMod(vehicle, 23)
                    end
                    
                    -- Apply the horn
                    SetVehicleMod(vehicle, 14, modId, false) -- 14 is the horn mod type
                    
                    -- Restore wheel mod if it was reset
                    if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                        SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
                    end
                    
                    -- IMMEDIATE restoration after SetVehicleMod
                    if stanceBackup then
                        local vehicleModule = require 'client.modules.vehicle'
                        for stanceType, value in pairs(stanceBackup) do
                            vehicleModule.applyStanceMod(vehicle, stanceType, value)
                        end
                    end
                    
                    -- Verify the horn was applied
                    local newHorn = GetVehicleMod(vehicle, 14)
                    print('🔧 [DEBUG] Horn after applying:', newHorn)
                    
                    if newHorn == modId then
                        print('🔧 [DEBUG] Horn applied successfully and verified')
                        
                        -- Try to test the horn briefly
                        SetTimeout(1000, function()
                            print('🔊 [DEBUG] Testing horn sound')
                            StartVehicleHorn(vehicle, 500, `HELDDOWN`, false)
                        end)
                    else
                        print('❌ [DEBUG] Horn application failed - expected:', modId, 'got:', newHorn)
                    end
                    
                    return true
                end
                
                
                -- For other types, use default system
                return true
            end,
        }
    },
}
