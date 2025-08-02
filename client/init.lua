if not lib then return end

local showMenu = require 'client.modules.menu'
CreateThread(function()
    lib.addKeybind({
        name = 'customs',
        description = 'press E to open customs',
        defaultKey = 'INPUT_TALK',
        onReleased = function(self)
            showMenu(true)
        end
    })
end)

-- Manual gamepad detection for D-pad right (control 46)
CreateThread(function()
    local polyzone = require 'client.modules.polyzone'
    
    while true do
        Wait(0)
        
        -- Only check if player is near customs area AND UI is not already open
        if polyzone.isNear then
            -- Check if customs UI is currently open using global variable
            local isUIOpen = _G.customsUIOpen or false
            
            -- Only detect D-pad right when UI is closed
            if not isUIOpen and IsControlJustPressed(0, 46) then
                showMenu(true)
            end
        else
            -- Reduce CPU usage when not near customs
            Wait(500)
        end
    end
end)

-- Command to open customs menu
RegisterCommand('customs', function(source, args, rawCommand)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Customs',
            description = 'You need to be in a vehicle to open customs',
            type = 'error'
        })
        return
    end
    
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({
            title = 'Customs',
            description = 'You need to be the driver to open customs',
            type = 'error'
        })
        return
    end
    
    showMenu(true)
end, false)

-- Alternative command (simpler)
RegisterCommand('custom', function()
    showMenu(true)
end, false)

-- Debug commands (commented out for production)
--[[
RegisterCommand('testcustoms', function()
    print('Test command works!')
    lib.notify({
        title = 'Test',
        description = 'Test command working!',
        type = 'success'
    })
end, false)
--]]

-- Add command suggestions
TriggerEvent('chat:addSuggestion', '/customs', 'Open vehicle customization menu')
TriggerEvent('chat:addSuggestion', '/custom', 'Open vehicle customization menu (alias)')