local Camera = {}
local cam
local mainCam
local shouldUpdate = false
local camDistance = 0.5
local angleY = 0.0
local angleZ = 0.0
local math_clamp = math.clamp
local math_cos = math.cos
local math_sin = math.sin
local targetCoords
local isTransitioning = false -- Add flag to prevent camera loops
local useCustomRotation = false -- Flag to track if camera uses SetCamRot vs PointCamAtCoord
local lastCamConfig = nil -- Track the last camera configuration to prevent redundant calls
local isUsingDefaultCamera = true -- Track if camera is in default position (no animation needed)

local function cos(degrees)
    return math_cos(degrees * math.pi / 180)
end

local function sin(degrees)
    return math_sin(degrees * math.pi / 180)
end

local function getOffCoords()
    return vec3(
        ((cos(angleZ) * cos(angleY)) + (cos(angleY) * cos(angleZ))) / 2 * camDistance,
        ((sin(angleZ) * cos(angleY)) + (cos(angleY) * sin(angleZ))) / 2 * camDistance,
        ((sin(angleY))) * camDistance
    )
end

local function SetCamPosition(mouseX, mouseY)
    if not targetCoords then return end
    local mouseX = mouseX or 0.0           --and mouseX * 5.0 or 0.0
    local mouseY = mouseY or 0.0           --and mouseY * 5.0 or 0.0

    -- print('🔧 [CAMERA] SetCamPosition called - mouseX:', mouseX, 'mouseY:', mouseY)
    -- print('🔧 [CAMERA] useCustomRotation flag:', useCustomRotation)
    
    -- Don't interfere with cameras that use SetCamRot for specific angles
    if useCustomRotation then
        -- print('⚠️ [CAMERA] Blocking SetCamPosition - camera uses custom rotation')
        return
    end
    
    -- print('🔧 [CAMERA] Before - angleY:', angleY, 'angleZ:', angleZ)
    
    angleZ = angleZ - mouseX               -- around Z axis (left / right)
    angleY = angleY + mouseY               -- up / down
    angleY = math_clamp(angleY, 0.0, 89.0) -- >=90 degrees will flip the camera, < 0 is underground

    -- print('🔧 [CAMERA] After - angleY:', angleY, 'angleZ:', angleZ)
    
    local offset = getOffCoords()
    local camPos = vec3(targetCoords.x + offset.x, targetCoords.y + offset.y, targetCoords.z + offset.z)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    -- print('🔧 [CAMERA] SetCamCoord called from SetCamPosition:', string.format('vec3(%.2f, %.2f, %.2f)', camPos.x, camPos.y, camPos.z))
    PointCamAtCoord(cam, targetCoords.x, targetCoords.y, targetCoords.z)
    -- print('🔧 [CAMERA] PointCamAtCoord called - safe for non-custom rotation cameras')
end

function Camera.handleNuiCamera(data)
    -- print('🔧 [CAMERA] handleNuiCamera called with data:', json.encode(data))
    local coord = data.coords

    if data.type == 'wheel' then
        local distance = camDistance + coord
        if distance < 0.1 then return end
        if distance > 7.0 then return end
        camDistance = distance
        SetCamPosition()
        -- print('🔧 [CAMERA] Called SetCamPosition() for wheel')
    else
        SetCamPosition(coord.x, coord.y)
        -- print('🔧 [CAMERA] Called SetCamPosition with coords:', coord.x, coord.y)
    end
end

function Camera.destroyCam()
    RenderScriptCams(false, true, 1000)
    DestroyCam(cam, false)
    DestroyCam(mainCam, false)
    cam = nil
    mainCam = nil
    isTransitioning = false -- Reset transitioning flag
    shouldUpdate = false -- Reset update flag
    lastCamConfig = nil -- Reset camera config tracking
    useCustomRotation = false -- Reset rotation flag
    isUsingDefaultCamera = true -- Reset to default state
end

function Camera.switchCam()
    -- print('🔄 [CAMERA] switchCam called - resetting to main camera')
    
    -- Prevent switching during transitions
    if isTransitioning then
        -- print('⚠️ [CAMERA] switchCam blocked - camera is transitioning')
        return
    end
    
    -- Reset camera configuration tracking
    lastCamConfig = nil
    useCustomRotation = false
    -- print('🔄 [CAMERA] Reset camera config tracking')
    
    -- Only animate if camera is not already in default position
    if cam and mainCam and not isUsingDefaultCamera then
        -- print('🔄 [CAMERA] Switching back to main camera from custom camera')
        isTransitioning = true
        SetCamActiveWithInterp(mainCam, cam, 500, true, true)
        
        -- Schedule cleanup after transition
        SetTimeout(600, function()
            isTransitioning = false
            isUsingDefaultCamera = true -- Mark as back to default
            -- print('🔄 [CAMERA] Switch to main camera completed')
        end)
    else
        -- print('🔄 [CAMERA] Camera already in default position - no animation needed')
        isUsingDefaultCamera = true -- Ensure flag is set
    end
end

function Camera.createMainCam()
    mainCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local vehicle = cache.vehicle
    local entityPos = GetEntityCoords(vehicle)
    local entityHeading = GetEntityHeading(vehicle)
    
    -- Convert heading to radians
    local headingRad = math.rad(entityHeading)
    
    -- Default camera position (relative to vehicle)
    local offsetX = -3.2
    local offsetY = 3.4
    
    -- Rotate offset based on vehicle heading
    local rotatedX = offsetX * math.cos(headingRad) - offsetY * math.sin(headingRad)
    local rotatedY = offsetX * math.sin(headingRad) + offsetY * math.cos(headingRad)

    RenderScriptCams(true, true, 1000)
    SetCamCoord(mainCam, entityPos.x + rotatedX, entityPos.y + rotatedY, entityPos.z + 2.1)
    PointCamAtEntity(mainCam, vehicle, 0.0, 0.0, 0.0, true)
    
    -- Mark that we're using the default camera
    isUsingDefaultCamera = true
end

---comment
---@param data {off: vector3, angle: vector2}
function Camera.createCam(data)
    -- local callStack = debug.traceback("", 2):match("([^\n]*)")
    -- print('🚨 [CAMERA-CALL] createCam() called from:', callStack)
    
    -- Prevent creating new camera while transitioning
    if isTransitioning then
        -- print('🚨 [CAMERA-BLOCK] createCam blocked - camera is transitioning')
        return
    end
    
    -- Check if this is the same camera configuration as last time
    local configKey = string.format("off:%s|angle:%s", 
        data.off and string.format("%.2f,%.2f,%.2f", data.off.x, data.off.y, data.off.z) or "nil",
        data.angle and string.format("%.2f,%.2f", data.angle.x, data.angle.y) or "nil"
    )
    
    if lastCamConfig == configKey then
        -- print('🚨 [CAMERA-DUP] DUPLICATE call detected and BLOCKED:', configKey)
        -- print('🚨 [CAMERA-DUP] Called from:', callStack)
        return
    end
    
    lastCamConfig = configKey
    -- print('🚨 [CAMERA-NEW] Processing NEW camera:', configKey)
    -- print('🚨 [CAMERA-NEW] Called from:', callStack)
    
    local vehicle = cache.vehicle
    local entityPos = GetEntityCoords(vehicle)
    local entityHeading = GetEntityHeading(vehicle)
    
    -- print('🚨 [CAMERA-DATA] Vehicle heading:', entityHeading)
    -- print('🚨 [CAMERA-DATA] Angle data:', data.angle and string.format('vec2(%.2f, %.2f)', data.angle.x, data.angle.y) or 'nil')
    -- print('🚨 [CAMERA-DATA] Offset data:', string.format('vec3(%.2f, %.2f, %.2f)', data.off.x, data.off.y, data.off.z))
    
    -- Reset global angle variables to prevent inheritance from previous cameras
    angleY = 0.0
    angleZ = 0.0
    useCustomRotation = false -- Reset rotation flag
    
    -- Initialize targetCoords for new cameras
    targetCoords = vec3(entityPos.x, entityPos.y, entityPos.z)
    
    -- Convert heading to radians
    local headingRad = math.rad(entityHeading)
    
    -- Rotate offset based on vehicle heading
    local offset = data.off
    local rotatedX = offset.x * math.cos(headingRad) - offset.y * math.sin(headingRad)
    local rotatedY = offset.x * math.sin(headingRad) + offset.y * math.cos(headingRad)
    
    -- Calculate camera position
    local camX = entityPos.x + rotatedX
    local camY = entityPos.y + rotatedY
    local camZ = entityPos.z + offset.z
    
    -- print('🚨 [CAMERA-POS] Final position:', string.format('vec3(%.2f, %.2f, %.2f)', camX, camY, camZ))
    
    -- Create or update camera
    local isNewCam = not cam
    if isNewCam then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        -- print('🚨 [CAMERA-CREATE] NEW camera created with handle:', cam)
    else
        -- print('🚨 [CAMERA-REUSE] Reusing existing camera:', cam)
    end
    
    -- Set camera position
    SetCamCoord(cam, camX, camY, camZ)
    
    -- Apply camera rotation/pointing
    if data.angle and (data.angle.x ~= 0 or data.angle.y ~= 0) then
        local rawAngleX = data.angle.x
        local rawAngleY = data.angle.y
        
        -- print('🚨 [CAMERA-DEBUG] rawAngleX exact value:', rawAngleX, 'type:', type(rawAngleX))
        -- print('🚨 [CAMERA-DEBUG] Is 178.62? Difference:', math.abs(rawAngleX - 178.62))
        
        useCustomRotation = true
        
        -- Front/Back cameras (0° angle) - direction based on Y offset
        if rawAngleX == 0.0 then
            local offsetY = data.off.y
            local lookDistance = 2.0
            
            if offsetY == 0 then
                -- Roof camera - point down at vehicle
                PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
                -- print('🚨 [CAMERA-ROT] Roof camera - PointCamAtEntity')
            else
                -- Front/back cameras - calculate target based on direction
                local directionMultiplier = offsetY < 0 and 1 or -1
                local angleRad = math.rad(entityHeading)
                local targetX = entityPos.x + (math.sin(angleRad) * lookDistance * directionMultiplier)
                local targetY = entityPos.y + (math.cos(angleRad) * lookDistance * directionMultiplier)
                local targetZ = entityPos.z + (rawAngleY * 0.02)
                
                PointCamAtCoord(cam, targetX, targetY, targetZ)
                -- print('🚨 [CAMERA-ROT] Front/Back camera - PointCamAtCoord, direction:', directionMultiplier)
            end
            
        -- Interior cameras (90° angle)
        elseif rawAngleX == 90.0 then
            SetCamRot(cam, rawAngleY, 0.0, rawAngleX, 2)
            -- print('🚨 [CAMERA-ROT] Interior camera - SetCamRot absolute')
            
        -- Skirt/L Door cameras (178.62°) - use tolerance for floating point comparison
        elseif math.abs(rawAngleX - 178.62) < 0.1 then
            PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
            -- print('🚨 [CAMERA-ROT] Skirt/L Door (178.62°) - PointCamAtEntity')
            
        -- All other cameras
        else
            local finalYaw = rawAngleX + entityHeading
            local finalPitch = rawAngleY
            
            -- Normalize angle
            while finalYaw >= 360.0 do finalYaw = finalYaw - 360.0 end
            while finalYaw < 0.0 do finalYaw = finalYaw + 360.0 end
            
            SetCamRot(cam, finalPitch, 0.0, finalYaw, 2)
            -- print('🚨 [CAMERA-ROT] Standard camera - SetCamRot, finalYaw:', finalYaw)
        end
        
    else
        -- No angle specified
        PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
        -- print('🚨 [CAMERA-ROT] Default - PointCamAtEntity')
    end
    
    -- Mark that we're now using a custom camera position
    isUsingDefaultCamera = false
    
    -- Activate the camera with smooth transition
    -- print('🚨 [CAMERA-ACTIVATE] Starting transition from main to specific camera')
    isTransitioning = true
    SetCamActiveWithInterp(cam, mainCam, 500, true, true)
    
    -- Schedule flag reset after transition completes
    SetTimeout(600, function()
        isTransitioning = false
        -- print('🚨 [CAMERA-ACTIVATE] Transition completed, isTransitioning reset')
    end)
    
    -- shouldUpdate = true -- Disabled with switchCam to prevent camera issues
end

-- to edit parts cams
--[[local function SetCamEdit(bonePos)
    local offsetEnabled = false
    local off = GetCamCoord(cam)
    local rot = GetCamRot(cam, 0)

    local offX, offY, offZ = off.x, off.y, off.z
    local rotX, rotY, rotZ = rot.x, rot.y, rot.z

    while cam do
        Wait(0)

        if IsControlJustPressed(0, 166) then --f5
            offsetEnabled = not offsetEnabled
            local string = offsetEnabled and 'enabled' or 'disabled'
            print('Offset = ' .. string)
        end
        if IsControlPressed(0, 172) then --up
            if offsetEnabled then
                offY -= 0.1
                offX -= 0.1
                SetCamCoord(cam, offX, offY, offZ)
            else
                --rotY += 0.5
                rotX -= 0.5
                SetCamRot(cam, rotX, rotY, rotZ, 0)
            end
        elseif IsControlPressed(0, 173) then -- down
            if offsetEnabled then
                offX += 0.1
                offY += 0.1
                SetCamCoord(cam, offX, offY, offZ)
            else
                --rotY -= 0.5
                rotX += 0.5
                SetCamRot(cam, rotX, rotY, rotZ, 0)
            end
        elseif IsControlPressed(0, 174) then -- left
            if offsetEnabled then
                offX += 0.1
                offY -= 0.1
                SetCamCoord(cam, offX, offY, offZ)
            end
        elseif IsControlPressed(0, 175) then -- right
            if offsetEnabled then
                offX -= 0.1
                offY += 0.1
                SetCamCoord(cam, offX, offY, offZ)
            end
        elseif IsControlPressed(0, 208) then -- page up
            if offsetEnabled then
                offZ += 0.1
                SetCamCoord(cam, offX, offY, offZ)
            else
                rotZ += 0.5
                SetCamRot(cam, rotX, rotY, rotZ, 0)
            end
        elseif IsControlPressed(0, 207) then -- page down
            if offsetEnabled then
                offZ -= 0.1
                SetCamCoord(cam, offX, offY, offZ)
            else
                rotZ -= 0.5
                SetCamRot(cam, rotX, rotY, rotZ, 0)
            end
        end


        if IsControlJustPressed(0, 170) then --f5
            print(vec3(rotX, rotY, rotZ), vec3(offX - bonePos.x, offY - bonePos.y , offZ - bonePos.z) )
        end
    end
end
]]
--RegisterCommand('editCam', function(f, args)
--    local Store = require 'config'
--    Camera.createMainCam()
--    Camera.createCam(Store.decals[args[1]].cam)
--    SetCamEdit(GetEntityCoords(cache.vehicle))
--end, false)

return Camera
