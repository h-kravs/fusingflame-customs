local Vehicle = {}
local createCam = require 'client.modules.camera'.createCam
local getModsNum = GetNumVehicleMods
local getModText = GetModTextLabel
local getModLabel = GetLabelText
local lib_table = lib.table
local table_deepcopy = lib_table.deepclone
local table_contain = lib_table.contains
local table_matches = lib_table.matches
local table_insert = table.insert
local store = require 'client.modules.store'

---@alias mods {label: string, id: number, selected?: boolean, applied?: boolean, price?: number}

---@param type number
---@param wheelData {id: number, price: number}
---@return mods[]

local function modCount(vehicle, id)
    if id == 24 then
        return GetVehicleLiveryCount(vehicle)
    end
    return getModsNum(vehicle, id)
end

local function isVehicleBlacklist(entity, blacklist)
    local modelName = GetEntityArchetypeName(entity)
    for _, v in ipairs(blacklist) do
        if modelName == v then
            return true
        end
    end
    return false
end

local function checkSelected(data, currentMod)
    local isSelected = false
    for _, v in ipairs(data) do
        if v.id == currentMod then
            v.selected = true
            v.applied = true
            isSelected = true
        end
    end
    if not isSelected then
        data[1].selected = true
        data[1].applied = true
    end
    return data
end

---comment
---@param modType string
---@return mods[]|nil
local function getPaintType(modType)
    local zone = require 'client.modules.polyzone'
    local colors = require 'data.colors'
    local colorType = store.modType

    if not table_contain(colors.paints, modType) then return false end

    local colorsData = colors.data[modType]
    local colorTypeData = colorsData and table_deepcopy(colorsData)
    if not colorTypeData then return end
    local colorPrimary, colorSecondary = GetVehicleColours(cache.vehicle)
    local currentPaint = colorType == 'Primary' and colorPrimary or colorSecondary
    if zone.free then
        for _,v in ipairs(colorTypeData) do
            v.price = 0
        end
    end
    table_insert(colorTypeData, 1, { label = 'Default', id = currentPaint, selected = true, applied = true })
    store.stored.currentMod = currentPaint
    return colorTypeData
end

function Vehicle.getMod(type, wheelData)
    local zone = require 'client.modules.polyzone'
    local stored = store.stored
    local mods = {}
    local isWheel = type == 23
    local mod = isWheel and wheelData or require 'data.decals'[type] or require 'data.horns'[type]
    local vehicle = cache.vehicle
    
    -- Check if mod exists
    if not mod then
        print('[WARNING] Mod type not found:', type)
        return {}
    end

    if not isWheel then
        local camera = mod.cam
        if camera then
            createCam(camera)
            if camera.door then
                SetVehicleDoorOpen(vehicle, camera.door, false, false)
                SetVehicleActiveForPedNavigation(vehicle, false)
            end
        end
    end

    local onClick = mod.onClick
    if onClick then
        local success, result = pcall(onClick, vehicle, stored)
        return success and result or {}
    end

    local id = 1
    local modType = isWheel and 23 or mod.id
    local modsNum = modCount(vehicle, modType) or getModsNum(vehicle, modType)
    local currentMod = GetVehicleMod(vehicle, modType)

    for i = 0, modsNum - 1 do
        local text = getModText(vehicle, modType, i)
        local label = getModLabel(text)
        local index = isWheel and 0 or currentMod
        local applied = i == index or nil
        local customLabel = mod.labels and mod.labels[i]
        
        mods[id] = {
            label = customLabel and customLabel.label or label,
            id = i,
            selected = applied,
            applied = not isWheel and applied,
            price = not zone.free and (customLabel and customLabel.price or math.floor((mod.price / modsNum * id) + 0.5)) or 0
        }
        id += 1
    end

    stored.currentMod = currentMod
    if wheelData then return mods end

    local applied = currentMod == -1 or nil
    table_insert(mods, 1, { label = 'Default', id = -1, selected = applied, applied = applied })
    return mods
end

----decals
---comment
---@return mods[]
function Vehicle.getVehicleDecals()
    print('🔍 [DEBUG] getVehicleDecals called')
    local decals = {}
    local count = 1
    local modType = store.modType
    local currentMenu = 'decals' -- Force to 'decals' since we're getting decals
    print('🔍 [DEBUG] modType:', modType, 'currentMenu:', currentMenu)
    
    local zone = require 'client.modules.polyzone'
    print('🔍 [DEBUG] polyzone loaded')

    local found = false
    local vehicle = cache.vehicle
    print('🔍 [DEBUG] vehicle:', vehicle)

    for mod, modData in pairs(require 'data.decals') do
        local blacklist, id, toggle, menuId, custom, canInteract in modData
        local canInteractMenu = true
        if canInteract then
            local success, resp = pcall(canInteract, vehicle)
            if not success or not resp then
                canInteractMenu = false
            end
        end

        if canInteractMenu and ((not blacklist or (not isVehicleBlacklist(vehicle, blacklist))) and menuId == currentMenu) then
            local add = false
            local appliedMod = mod == modType
            if appliedMod then found = true end
            
            local modCard = {
                id = mod,
                selected = appliedMod or nil,
                icon = modData.icon
            }

            if custom or modCount(vehicle, id) > 0 then
                add = true
            elseif toggle then
                modCard.id = id
                modCard.label = mod
                modCard.price = not zone.free and modData.price or 0
                modCard.toggle = true
                modCard.applied = IsToggleModOn(vehicle, id)
                add = true
            end
            if add then
                decals[count] = modCard
                count += 1
            end
        end
    end

    if decals[1] then
        decals[1].selected = not found and true or decals[1].selected
    end

    print('🔍 [DEBUG] getVehicleDecals returning', #decals, 'items')
    return decals
end

----wheels
---@return mods[]
function Vehicle.getVehicleWheels()
    local wheels = {}
    local vehicle = cache.vehicle
    local wheelsData = require 'data.wheels'
    local zone = require 'client.modules.polyzone'
    local data = GetVehicleClass(vehicle) == 8 and { Bike = { id = 6, price = not zone.free and 2000 or 0 } } or wheelsData

    local count = 1
    for mod, modData in pairs(data) do
        local blacklist, id, toggle, price in modData
        if (not blacklist or (not isVehicleBlacklist(vehicle, blacklist))) then
            price = not zone.free and price or 0
            if toggle then
                modData.applied = IsToggleModOn(vehicle, id)
                wheels[count] = modData
                if id == 20 then
                    store.stored.customTyres = modData.applied
                end
            else
                wheels[count] = { 
                    id = type(mod) == 'string' and mod or id,
                    icon = modData.icon
                }
            end
            count += 1
        end
    end

    return wheels
end

---comment
---@param type string
---@return mods[]
function Vehicle.getVehicleWheelType(type)
    local mod = require 'data.wheels'[type]
    local entity = cache.vehicle
    store.stored.currentWheelType = GetVehicleWheelType(entity)
    
    -- Store stance values BEFORE SetVehicleWheelType as it will reset them
    local stanceBackup = nil
    if store.stored.currentStance then
        stanceBackup = {}
        for stanceType, value in pairs(store.stored.currentStance) do
            stanceBackup[stanceType] = value
        end
    end
    
    SetVehicleWheelType(entity, mod.id)
    
    -- IMMEDIATE restoration after wheel type change
    if stanceBackup then
        for stanceType, value in pairs(stanceBackup) do
            Vehicle.applyStanceMod(entity, stanceType, value)
        end
    end
    
    -- Use exact same camera as L Door (no timeout to avoid inconsistency)
    createCam({ angle = vec2(178.62, 17.25), off = vec3(-2.900037, 0.000049, 0.300000) })
    
    return Vehicle.getMod(23, mod)
end

----colors

---@return mods[]
function Vehicle.getVehicleHorns()
    print('🔍 [DEBUG] getVehicleHorns called - using getMod for Horn')
    return Vehicle.getMod('Horn')
end

---@return mods[]
function Vehicle.getVehicleColors()
    local colorsData = {}
    local id = 1
    local colorFunctions = require 'data.colors'.functions
    for _, mod in ipairs(require 'client.modules.filter'.colorTypes) do
        local icon = colorFunctions[mod] and colorFunctions[mod].icon
        colorsData[id] = { 
            id = mod, 
            selected = id == 1 or nil,
            icon = icon
        }
        id += 1
    end
    return colorsData
end

---@return mods[]
function Vehicle.getPaintTypes()
    local paint = {}
    local id = 1
    for _, mod in ipairs(require 'data.colors'.paints) do
        paint[id] = { id = mod, selected = id == 1 or nil }
        id += 1
    end
    return paint
end

--modIndex

---@return mods[]
function Vehicle.getAllColors()
    local colorData = require 'data.colors'.data
    local mergedTable = {}
    local id = 1
    local zone = require 'client.modules.polyzone'

    for _, subTable in pairs(table_deepcopy({ colorData.Chrome, colorData.Matte, colorData.Metal, colorData.Metallic, colorData.Chameleon })) do
        for _, element in ipairs(subTable) do
            element.price = not zone.free and element.price or 0
            mergedTable[id] = element
            id += 1
        end
    end
    table_insert(mergedTable, 1, { label = 'Default', id = -1, selected = true })
    return mergedTable
end


---@return mods[]
function Vehicle.getNeons()
    local entity = cache.vehicle
    local currentMod = IsVehicleNeonLightEnabled
    local colorData = require 'data.colors'.data
    local data = table_deepcopy(colorData.Neons)

    for _, v in ipairs(data) do
        if type(v.id) == "number" and currentMod(entity, v.id) then
            v.applied = true
        end
    end
    return data
end

---@return mods[]
function Vehicle.getXenonColor()
    local colorData = require 'data.colors'.data
    return checkSelected(table_deepcopy(colorData.Xenon), GetVehicleXenonLightsColor(cache.vehicle))
end

---@return mods[]
function Vehicle.getTyreSmokes()
    local colorData = require 'data.colors'.data
    local currentMod = { GetVehicleTyreSmokeColor(cache.vehicle) }
    local data = table_deepcopy(colorData.TyreSmoke)

    for _, v in ipairs(data) do
        v.id = _
        if table_matches(v.rgb, currentMod) then
            v.selected = true
            v.applied = true
        end
    end
    return data
end

---@return mods[]
function Vehicle.getWindowsTint()
    local colorData = require 'data.colors'.data
    return checkSelected(table_deepcopy(colorData.WindowsTint), GetVehicleWindowTint(cache.vehicle))
end

---@param modType string
---@return mods[]|nil
function Vehicle.getVehicleColorTypes(modType)
    local isPaintType = getPaintType(modType) --get paint type such Metallic/Matte/Metal/Chrome/Chameleon
    if isPaintType then return isPaintType end

    local colors = require 'data.colors'
    local selector = colors.functions[modType]
    if not selector then return end
    if selector.cam then
        createCam(selector.cam)
    end
    return selector.onClick()
end

-- mod index application

---@alias applyColor {modIndex: number, colorType?: string}

---@param modIndex number
function Vehicle.applyExtraColor(vehicle, modIndex)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    pearlescentColor = store.modType == 'Pearlescent' and modIndex or pearlescentColor
    wheelColor = store.modType == 'Wheels' and modIndex or wheelColor
    SetVehicleExtraColours(vehicle, pearlescentColor, wheelColor)
end

---@param modIndex number
function Vehicle.applyTyreSmokeColor(vehicle, modIndex)
    local colorData = require 'data.colors'.data
    local color = colorData.TyreSmoke[modIndex]
    if not color then return end

    ToggleVehicleMod(vehicle, 20, true)
    SetVehicleTyreSmokeColor(vehicle, color.rgb[1], color.rgb[2], color.rgb[3])
end

---@param modIndex number
function Vehicle.applyXenonLightsColor(vehicle, modIndex)
    ToggleVehicleMod(vehicle, 22, true)
    SetVehicleXenonLightsColor(vehicle, modIndex)
end

---@param modIndex number
function Vehicle.applyVehicleColor(vehicle, modIndex)
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local primaryColor = store.modType == 'Primary' and modIndex or colorPrimary
    local secondaryColor = store.modType == 'Secondary' and modIndex or colorSecondary
    SetVehicleColours(vehicle, primaryColor, secondaryColor)
end

----performance
---@return mods[]
function Vehicle.getVehiclePerformance()
    -- print('Vehicle.getVehiclePerformance called') -- Debug log
    local performanceData = require 'data.performance'
    local performance = {}
    local count = 1
    
    for key, data in pairs(performanceData) do
        performance[count] = {
            id = key,
            label = key,
            icon = data.icon
        }
        count = count + 1
    end
    
    if performance[1] then
        performance[1].selected = true
    end
    -- print('Performance categories count:', #performance) -- Debug log
    return performance
end

---@param type string
---@return mods[]
function Vehicle.getPerformanceMod(type)
    local performanceData = require 'data.performance'
    local mod = performanceData[type]
    if not mod then return {} end
    
    local vehicle = cache.vehicle
    local camera = mod.cam
    if camera then
        createCam(camera)
    end
    
    -- Handle Engine Sound specially
    if type == 'Engine Sound' and mod.isEngineSound then
        local zone = require 'client.modules.polyzone'
        local mods = {}
        local currentEngineSound = Entity(vehicle).state['vehdata:sound'] or 'resetenginesound'
        local stored = store.stored
        
        -- print('🔊 Getting engine sounds - Current sound:', currentEngineSound)
        
        local selectedFound = false
        for soundName, soundHash in pairs(mod.sounds) do
            local applied = currentEngineSound == soundHash
            local selected = applied and not selectedFound
            local price = soundName == 'Default' and 0 or (not zone.free and mod.price or 0)
            
            table.insert(mods, {
                label = soundName,
                id = soundHash,
                selected = selected,
                applied = applied,
                price = price,
                isEngineSound = true
            })
            
            if applied then selectedFound = true end
            -- print('🎵 Sound option:', soundName, 'Hash:', soundHash, 'Applied:', applied, 'Selected:', selected)
        end
        
        -- If no current sound is found, default to "Default" (resetenginesound)
        if not selectedFound then
            for i, soundData in ipairs(mods) do
                if soundData.id == 'resetenginesound' then
                    mods[i].selected = true
                    mods[i].applied = true
                    currentEngineSound = 'resetenginesound'
                    break
                end
            end
        end
        
        stored.currentEngineSound = currentEngineSound
        -- print('🎯 Stored currentEngineSound:', stored.currentEngineSound)
        return mods
    end
    
    -- Handle Turbo specially (it's a toggle mod)
    if type == 'Turbo' then
        local zone = require 'client.modules.polyzone'
        return {
            {
                id = mod.id,
                label = 'Turbo',
                toggle = true,
                applied = IsToggleModOn(vehicle, mod.id),
                price = not zone.free and mod.price or 0
            }
        }
    end
    
    -- Handle other performance mods (they have levels -1, 0, 1, 2, 3)
    local mods = {}
    local zone = require 'client.modules.polyzone'
    local currentMod = GetVehicleMod(vehicle, mod.id)
    local stored = store.stored
    
    -- Level labels for performance upgrades
    local levels = {
        [-1] = 'Stock',
        [0] = 'Level 1',
        [1] = 'Level 2', 
        [2] = 'Level 3',
        [3] = 'Level 4'
    }
    
    -- Add performance levels
    for level = -1, 3 do
        local modsAvailable = GetNumVehicleMods(vehicle, mod.id)
        if level == -1 or level < modsAvailable then
            local applied = level == currentMod or nil
            local price = 0
            
            if not zone.free and level > -1 then
                price = mod.price + (level * (mod.levelPrice or 0))
            end
            
            table.insert(mods, {
                label = levels[level],
                id = level,
                selected = applied,
                applied = applied,
                price = price
            })
        end
    end
    
    stored.currentMod = currentMod
    return mods
end

-- Helper function to check if a stance modification can be applied
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

-- Get current stance values for a vehicle
local function getStanceValues(vehicle)
    local values = {}
    
    -- Height (suspension)
    values.height = GetVehicleSuspensionHeight(vehicle)
    
    -- Offset (track width)
    values.offsetFront = GetVehicleWheelXOffset(vehicle, 1)
    values.offsetRear = GetVehicleWheelXOffset(vehicle, 3)
    
    -- Camber
    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberFront') then
        values.camberFront = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberFront')
    else
        values.camberFront = nil
    end
    
    if canModifyStance(vehicle, 'CCarHandlingData', 'fCamberRear') then
        values.camberRear = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberRear')
    else
        values.camberRear = nil
    end
    
    -- Wheel size/width
    if GetVehicleMod(vehicle, 23) ~= -1 then
        -- Try to get values using native functions, fallback to handling or defaults
        local success, wheelSize = pcall(function() return GetVehicleWheelSize(vehicle) end)
        if success and wheelSize then
            values.wheelSize = wheelSize
        else
            -- Fallback: Use handling value or default
            local handlingSize = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fWheelScale')
            values.wheelSize = handlingSize > 0 and handlingSize or 1.0
        end
        
        local success2, wheelWidth = pcall(function() return GetVehicleWheelWidth(vehicle) end)
        if success2 and wheelWidth then
            values.wheelWidth = wheelWidth
        else
            -- Fallback: Use track width offset or default
            local offset = GetVehicleWheelXOffset(vehicle, 1)
            values.wheelWidth = 1.0 + (offset * 10) -- Convert offset back to width estimate
        end
    else
        values.wheelSize = nil
        values.wheelWidth = nil
    end
    
    return values
end

-- Persistent stance monitoring system
local stanceMonitorActive = false
local persistentStanceValues = {}

local function startStanceMonitor(vehicle)
    if stanceMonitorActive then return end
    stanceMonitorActive = true
    
    print('🔄 [STANCE MONITOR] Starting persistent stance monitoring')
    
    CreateThread(function()
        while stanceMonitorActive and DoesEntityExist(vehicle) do
            Wait(200) -- Check every 200ms
            
            if persistentStanceValues.wheelSize then
                local currentSize = GetVehicleWheelSize(vehicle)
                local expectedSize = persistentStanceValues.wheelSize
                
                if math.abs(currentSize - expectedSize) > 0.01 then
                    print('🚨 [STANCE MONITOR] Wheel size reset detected! Re-applying:', expectedSize)
                    SetVehicleWheelSize(vehicle, expectedSize)
                    -- Update collision
                    for i = 0, 3 do
                        local colliderSize = math.floor(expectedSize/2 * 100) / 100
                        SetVehicleWheelRimColliderSize(vehicle, i, colliderSize)
                        SetVehicleWheelTireColliderSize(vehicle, i, colliderSize)
                    end
                end
            end
            
            if persistentStanceValues.wheelWidth then
                local currentWidth = GetVehicleWheelWidth(vehicle)
                local expectedWidth = persistentStanceValues.wheelWidth
                
                if math.abs(currentWidth - expectedWidth) > 0.01 then
                    print('🚨 [STANCE MONITOR] Wheel width reset detected! Re-applying:', expectedWidth)
                    SetVehicleWheelWidth(vehicle, expectedWidth)
                end
            end
        end
        print('🔄 [STANCE MONITOR] Stopping stance monitoring')
    end)
end

local function stopStanceMonitor()
    stanceMonitorActive = false
    persistentStanceValues = {}
    print('🔄 [STANCE MONITOR] Stance monitoring stopped')
end

local function updatePersistentValue(stanceType, value)
    if stanceType == 'wheelSize' or stanceType == 'wheelWidth' then
        persistentStanceValues[stanceType] = value
        print('🔄 [STANCE MONITOR] Updated persistent value:', stanceType, '=', value)
    end
end

-- Apply stance modification
function Vehicle.applyStanceMod(vehicle, stanceType, value)
    print('🔧 [STANCE DEBUG] applyStanceMod called - type:', stanceType, 'value:', value, 'vehicle:', vehicle)
    if stanceType == 'height' then
        SetVehicleSuspensionHeight(vehicle, value)
    elseif stanceType == 'offsetFront' then
        SetVehicleWheelXOffset(vehicle, 0, -value)
        SetVehicleWheelXOffset(vehicle, 1, value)
    elseif stanceType == 'offsetRear' then
        SetVehicleWheelXOffset(vehicle, 2, -value)
        SetVehicleWheelXOffset(vehicle, 3, value)
    elseif stanceType == 'camberFront' then
        SetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberFront', value)
    elseif stanceType == 'camberRear' then
        SetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fCamberRear', value)
    elseif stanceType == 'wheelSize' then
        local currentWheelMod = GetVehicleMod(vehicle, 23)
        print('🔍 [WHEEL DEBUG] wheelSize - currentWheelMod:', currentWheelMod, 'value:', value)
        
        if currentWheelMod ~= -1 then
            -- Start persistent monitoring system
            startStanceMonitor(vehicle)
            updatePersistentValue('wheelSize', value)
            
            -- Try to use native function first, fallback to handling modification
            local success = pcall(function()
                SetVehicleWheelSize(vehicle, value)
                print('🔍 [WHEEL DEBUG] SetVehicleWheelSize called with value:', value)
                -- Update collision size with proper calculation
                for i = 0, 3 do
                    local colliderSize = math.floor(value/2 * 100) / 100
                    SetVehicleWheelRimColliderSize(vehicle, i, colliderSize)
                    SetVehicleWheelTireColliderSize(vehicle, i, colliderSize)
                end
            end)
            
            if not success then
                print('🔍 [WHEEL DEBUG] SetVehicleWheelSize FAILED, using fallback')
                -- Fallback: Use handling modification to simulate wheel size
                SetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fWheelScale', value)
            else
                print('🔍 [WHEEL DEBUG] SetVehicleWheelSize SUCCESS - Persistent monitoring active')
            end
        else
            print('🔍 [WHEEL DEBUG] Cannot set wheel size - no custom wheels (mod 23 = -1)')
        end
    elseif stanceType == 'wheelWidth' then
        local currentWheelMod = GetVehicleMod(vehicle, 23)
        print('🔍 [WHEEL DEBUG] wheelWidth - currentWheelMod:', currentWheelMod, 'value:', value)
        
        if currentWheelMod ~= -1 then
            -- Start persistent monitoring system
            startStanceMonitor(vehicle)
            updatePersistentValue('wheelWidth', value)
            
            -- Try to use native function first, fallback to handling modification
            local success = pcall(function()
                SetVehicleWheelWidth(vehicle, value)
                print('🔍 [WHEEL DEBUG] SetVehicleWheelWidth called with value:', value)
            end)
            
            if not success then
                print('🔍 [WHEEL DEBUG] SetVehicleWheelWidth FAILED, using fallback')
                -- Fallback: Use track width offset to simulate wheel width
                local offsetValue = (value - 1.0) * 0.1 -- Convert width to offset
                SetVehicleWheelXOffset(vehicle, 0, -offsetValue)
                SetVehicleWheelXOffset(vehicle, 1, offsetValue)
                SetVehicleWheelXOffset(vehicle, 2, -offsetValue)
                SetVehicleWheelXOffset(vehicle, 3, offsetValue)
            else
                print('🔍 [WHEEL DEBUG] SetVehicleWheelWidth SUCCESS - Persistent monitoring active')
            end
        else
            print('🔍 [WHEEL DEBUG] Cannot set wheel width - no custom wheels (mod 23 = -1)')
        end
    end
end

-- Get stance menu
function Vehicle.getVehicleStance()
    local vehicle = cache.vehicle
    local stanceData = require 'data.stance'
    local mods = {}
    
    for modType, data in pairs(stanceData) do
        table.insert(mods, {
            id = modType,
            label = data.label,
            icon = data.icon
        })
    end
    
    return mods
end

-- Get stance modifications for a specific type
function Vehicle.getStanceMod(type)
    local vehicle = cache.vehicle
    local stanceData = require 'data.stance'
    local mod = stanceData[type]
    
    if not mod then return {} end
    
    local currentValues = getStanceValues(vehicle)
    local currentValue = currentValues[mod.stanceType]
    
    -- Check if this modification can be applied
    local canModify = true
    if mod.stanceType == 'camberFront' or mod.stanceType == 'camberRear' then
        canModify = currentValue ~= nil
    elseif mod.stanceType == 'wheelSize' or mod.stanceType == 'wheelWidth' then
        canModify = GetVehicleMod(vehicle, 23) ~= -1
    end
    
    if not canModify then
        return {
            {
                id = 'unavailable',
                label = 'Not Available',
                selected = true,
                applied = true,
                price = 0,
                disabled = true
            }
        }
    end
    
    -- Store default values for reset (only once per session)
    if not store.stored.defaultStance then
        store.stored.defaultStance = getStanceValues(vehicle)
    end
    
    -- ALWAYS use current value as the base for calculations
    -- This makes the menu persistent and shows current state
    local baseValue = currentValue
    local originalDefaultValue = store.stored.defaultStance[mod.stanceType]
    
    print('🎛️ [STANCE DEBUG] Menu for', type, '- currentValue:', currentValue, 'baseValue:', baseValue, 'originalDefault:', originalDefaultValue)
    
    -- Create modification options
    local mods = {}
    local zone = require 'client.modules.polyzone'
    
    -- Add default/stock option (uses original default value)
    table.insert(mods, {
        id = 'default',
        label = 'Stock',
        value = originalDefaultValue,
        selected = math.abs(currentValue - originalDefaultValue) < 0.05,
        applied = math.abs(currentValue - originalDefaultValue) < 0.05,
        price = 0
    })
    
    -- Generate modification steps
    local steps = 10 -- Number of steps for adjustment
    local range = mod.range
    
    for i = 1, steps do
        local step = i / steps
        local modValue
        
        if mod.invert then
            -- For height, lower values mean lower suspension
            modValue = originalDefaultValue - (range * step)
        else
            -- For other mods, positive values increase the modification
            modValue = originalDefaultValue + (range * step)
        end
        
        local label = string.format("%d%%", math.floor(step * 100))
        local price = not zone.free and (1000 + (i * 500)) or 0
        
        table.insert(mods, {
            id = i,
            label = label,
            value = modValue,
            selected = math.abs(currentValue - modValue) < 0.05,
            applied = math.abs(currentValue - modValue) < 0.05,
            price = price,
            stanceType = mod.stanceType
        })
    end
    
    -- Also generate negative steps for some modifications
    if not mod.invert and (mod.stanceType == 'offsetFront' or mod.stanceType == 'offsetRear' or 
        mod.stanceType == 'camberFront' or mod.stanceType == 'camberRear') then
        
        for i = 1, steps do
            local step = i / steps
            local modValue = originalDefaultValue - (range * step)
            local label = string.format("-%d%%", math.floor(step * 100))
            local price = not zone.free and (1000 + (i * 500)) or 0
            
            table.insert(mods, {
                id = -i,
                label = label,
                value = modValue,
                selected = math.abs(currentValue - modValue) < 0.001,
                applied = math.abs(currentValue - modValue) < 0.001,
                price = price,
                stanceType = mod.stanceType
            })
        end
    end
    
    -- Sort mods by value
    table.sort(mods, function(a, b)
        return a.value < b.value
    end)
    
    -- Store current stance value and update persistent monitoring if active
    store.stored.currentStance = store.stored.currentStance or {}
    store.stored.currentStance[mod.stanceType] = currentValue
    
    -- Debug: Show which option is selected
    local selectedOption = nil
    for _, option in ipairs(mods) do
        if option.selected then
            selectedOption = option
            break
        end
    end
    
    if selectedOption then
        print('🎯 [STANCE DEBUG] Selected option for', type, '- label:', selectedOption.label, 'value:', selectedOption.value, 'currentValue:', currentValue)
    else
        print('⚠️ [STANCE DEBUG] No exact match found for', type, '- currentValue:', currentValue, 'finding closest option')
        -- Find the closest option and mark it as selected
        local closestOption = nil
        local smallestDiff = math.huge
        
        for i, option in ipairs(mods) do
            local diff = math.abs(currentValue - option.value)
            print('  Option', i, '- label:', option.label, 'value:', option.value, 'diff:', diff)
            if diff < smallestDiff then
                smallestDiff = diff
                closestOption = option
            end
        end
        
        if closestOption then
            closestOption.selected = true
            closestOption.applied = true
            print('🎯 [STANCE DEBUG] Selected closest option - label:', closestOption.label, 'value:', closestOption.value, 'diff:', smallestDiff)
        end
    end
    
    -- Set camera for this modification
    createCam(mod.camera.coords, mod.camera.rotation, mod.camera.fov)
    
    return mods
end

-- Public functions for stance monitoring
Vehicle.startStanceMonitor = startStanceMonitor
Vehicle.stopStanceMonitor = stopStanceMonitor
Vehicle.updatePersistentValue = updatePersistentValue

return Vehicle
