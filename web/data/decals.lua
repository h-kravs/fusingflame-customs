return {
    Spoiler = {
        menuId = 'decals',
        id = 0,
        price = 2000,
        icon = 'spoiler.png',
        cam = { angle = vec2(0.0, 25.0), off = vec3(0.0, -6.0, 2.0) }, -- Behind vehicle, elevated
        --blacklist = {'sultan'}
    },
    Skirt = {
        menuId = 'decals',
        id = 3,
        price = 2000,
        icon = 'sideskirt.png',
        cam = { angle = vec2(178.62, 17.25), off = vec3(-2.900037, 0.000049, 0.300000) }, -- Using plate camera
    },
    Exhaust = {
        menuId = 'decals',
        id = 4,
        price = 2000,
        icon = 'exhaust.png',
        cam = { angle = vec2(0.0, 10.0), off = vec3(0.0, -3.5, 0.2) } -- Behind vehicle, closer
    },
    Chassis = {
        menuId = 'decals',
        id = 5,
        price = 2000,
        icon = 'body.png'
        -- No cam defined, will use default camera
    },
    Grill = {
        menuId = 'decals',
        id = 6,
        price = 2000,
        icon = 'grille.png',
        cam = { angle = vec2(0.0, 10.0), off = vec3(0.0, 4.5, 0.5) } -- Front view for grill
    },
    Bonnet = {
        menuId = 'decals',
        id = 7,
        price = 2000,
        icon = 'hood.png',
        cam = { angle = vec2(0.0, 35.0), off = vec3(0.0, 3.5, 3.0) } -- Above front for hood
    },
    Wing = {
        menuId = 'decals',
        id = 8,
        price = 2000,
        icon = 'fender.png',
        cam = { angle = vec2(0.0, 35.0), off = vec3(0.0, 3.5, 3.0) } -- Same as Bonnet - front hood view
    },
    Roof = {
        menuId = 'decals',
        id = 10,
        price = 2000,
        icon = 'roof.png',
        cam = { angle = vec2(0.0, 65.0), off = vec3(0.0, 0.0, 3.0) } -- Top view for roof, lower
    },
    Nitrous = {
        menuId = 'decals',
        id = 17,
        price = 2000,
        icon = 'misc.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Subwoofer = {
        menuId = 'decals',
        id = 19,
        price = 2000,
        icon = 'speakers.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Seats = {
        menuId = 'decals',
        id = 32,
        price = 2000,
        icon = 'seats.png',
        cam = { angle = vec2(90.0, 0.0), off = vec3(-0.6, 0.1, 0.5) } -- POV looking left towards dashboard
    },
    Steering = {
        menuId = 'decals',
        id = 33,
        price = 2000,
        icon = 'steeringwheel.png',
        cam = { angle = vec2(90.0, 0.0), off = vec3(-0.6, 0.1, 0.5) } -- POV looking left towards dashboard
    },
    Knob = {
        menuId = 'decals',
        id = 34,
        price = 2000,
        icon = 'dashboard.png',
        cam = { angle = vec2(90.0, 0.0), off = vec3(-0.6, 0.1, 0.5) } -- POV looking left towards dashboard
    },
    Plaque = {
        menuId = 'decals',
        id = 35,
        price = 2000,
        icon = 'misc.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Ice = {
        menuId = 'decals',
        id = 36,
        price = 2000,
        icon = 'misc.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Trunk = {
        menuId = 'decals',
        id = 37,
        price = 2000,
        icon = 'exterior.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Hydro = {
        menuId = 'decals',
        id = 38,
        price = 2000,
        icon = 'hydraulics.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    Lightbar = {
        menuId = 'decals',
        id = 49,
        price = 2000,
        icon = 'headlights.png',
        cam = { angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000) }
    },
    ['Enginebay 1'] = {
        menuId = 'decals',
        id = 39,
        price = 2000,
        icon = 'enginebay.png',
        cam = {
            door = 4,
            angle = vec2(127.125, 33.0),
            off = vec3(-2.400012, 0.000024, 1.000000)
        }
    },

    ['Engine Upgrades'] = {
        menuId = 'performance',
        id = 11,
        icon = 'engine.png',
        labels = {
            [0] = {label = 'Engine lvl 1', price = 200},
            [1] = {label = 'Engine lvl 2', price = 200},
            [2] = {label = 'Engine lvl 3', price = 200},
            [3] = {label = 'Engine lvl 4', price = 200},
            [4] = {label = 'Engine lvl 5', price = 200},
        }
    },
    ['Brakes Upgrades'] = {
        menuId = 'performance',
        id = 12,
        icon = 'brakes.png',
        -- No cam defined, will use default camera
        labels = {
            [0] = {label = 'Brakes lvl 1', price = 200},
            [1] = {label = 'Brakes lvl 2', price = 200},
            [2] = {label = 'Brakes lvl 3', price = 200},
            [3] = {label = 'Brakes lvl 4', price = 200},
            [4] = {label = 'Brakes lvl 5', price = 200},
        },
    },
    ['Armour Upgrades'] = {
        menuId = 'performance',
        id = 16,
        icon = 'armour.png',
        labels = {
            [0] = {label = 'Armour lvl 1', price = 200},
            [1] = {label = 'Armour lvl 2', price = 200},
            [2] = {label = 'Armour lvl 3', price = 200},
            [3] = {label = 'Armour lvl 4', price = 200},
            [4] = {label = 'Armour lvl 5', price = 200},
        },
    },

    ['Enginebay 2'] = {
        menuId = 'decals',
        id = 40,
        price = 2000,
        icon = 'enginebay.png',
        cam = {
            door = 4,
            angle = vec2(127.125, 33.0),
            off = vec3(-2.400012, 0.000024, 1.000000)
        }
    },
    ['Enginebay 3'] = {
        menuId = 'decals',
        id = 41,
        price = 2000,
        icon = 'enginebay.png',
        cam = {
            door = 4,
            angle = vec2(127.125, 33.0),
            off = vec3(-2.400012, 0.000024, 1.000000)
        }
    },
    ['Chassis 2'] = {
        menuId = 'decals',
        id = 42,
        price = 2000,
        icon = 'body.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-2.400012, 1.200024, 0.600000)
        }
    },
    ['Chassis 3'] = {
        menuId = 'decals',
        id = 43,
        price = 2000,
        icon = 'body.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-2.900012, -0.099976, 0.600000)
        }
    },
    ['Chassis 4'] = {
        menuId = 'decals',
        id = 44,
        price = 2000,
        icon = 'body.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-0.800012, 1.000024, 1.400000)
        }
    },
    ['Chassis 5'] = {
        menuId = 'decals',
        id = 45,
        price = 2000,
        icon = 'body.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-3.100024, 0.800024, 0.000000)
        }
    },
    ['L Door'] = {
        menuId = 'decals',
        id = 46,
        price = 2000,
        icon = 'exterior.png',
        cam = {
            angle = vec2(178.62, 17.25),
            off = vec3(-2.900037, 0.000049, 0.300000)
        }
    },
    ['R Door'] = {
        menuId = 'decals',
        id = 47,
        price = 2000,
        icon = 'exterior.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-3.200000, 3.400000, 2.100000)
        }
    },
    ['Livery Mod'] = {
        menuId = 'decals',
        id = 48,
        price = 2000,
        icon = 'paintjob.png'
        -- No cam defined, will use default camera
    },
    ['Front Bumper'] = {
        menuId = 'decals',
        id = 1,
        price = 2000,
        icon = 'frontbumper.png',
        cam = {
            angle = vec2(0.0, 10.0), -- Front view
            off = vec3(0.0, 5.5, 0.3)
        }
    },
    ['Rear Bumper'] = {
        menuId = 'decals',
        id = 2,
        price = 2000,
        icon = 'rearbumper.png',
        cam = {
            angle = vec2(0.0, 10.0), -- Lower angle for better view
            off = vec3(0.0, -5.5, 0.2) -- Further back and lower height
        }
    },
    ['Wing 2'] = {
        menuId = 'decals',
        id = 9,
        price = 2000,
        icon = 'fender.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(2.199975, 0.200000, 1.600000)
        }
    },
    ['Old Livery'] = {
        menuId = 'decals',
        id = 24,
        price = 2000,
        icon = 'wrap.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-3.200000, 3.400000, 2.100000)
        },
        onSelect = function(vehicle, index)
            -- Store stance values AND wheel mod BEFORE SetVehicleLivery as it will reset them
            local store = require 'client.modules.store'
            local stanceBackup = nil
            local wheelModBackup = nil
            if store.stored.currentStance then
                stanceBackup = {}
                for stanceType, value in pairs(store.stored.currentStance) do
                    stanceBackup[stanceType] = value
                end
                wheelModBackup = GetVehicleMod(vehicle, 23)
            end
            
            SetVehicleLivery(vehicle, index)
            
            -- Restore wheel mod if it was reset
            if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
            end
            
            -- IMMEDIATE restoration after SetVehicleLivery
            if stanceBackup then
                local vehicleModule = require 'client.modules.vehicle'
                for stanceType, value in pairs(stanceBackup) do
                    vehicleModule.applyStanceMod(vehicle, stanceType, value)
                end
            end
        end,
    },
    ['Plate holder'] = {
        menuId = 'decals',
        id = 25,
        price = 2000,
        icon = 'numberplate.png',
        cam = {
            angle = vec2(127.125, 33.0),
            off = vec3(-3.100024, 0.800024, 0.000000)
        }
    },
    ['Plate vanity'] = {
        menuId = 'decals',
        id = 26,
        price = 2000,
        icon = 'numberplate.png',
        cam = {
            angle = vec2(0.0, 15.0),
            off = vec3(0.0, 5.0, 0.5)
        }
    },
    ['Interior 1'] = {
        menuId = 'decals',
        id = 27,
        price = 2000,
        icon = 'interior.png',
        cam = {
            angle = vec2(90.0, 0.0),
            off = vec3(-0.6, 0.1, 0.5)
        }
    },
    ['Interior 2'] = {
        menuId = 'decals',
        id = 28,
        price = 2000,
        icon = 'interiormods.png',
        cam = {
            angle = vec2(90.0, 0.0),
            off = vec3(-0.6, 0.1, 0.5)
        }
    },
    ['Interior 3'] = {
        menuId = 'decals',
        id = 29,
        price = 2000,
        icon = 'interiormods.png',
        cam = {
            angle = vec2(90.0, 0.0),
            off = vec3(-0.6, 0.1, 0.5)
        }
    },
    ['Interior 4'] = {
        menuId = 'decals',
        id = 30,
        price = 2000,
        icon = 'interiormods.png',
        cam = {
            angle = vec2(90.0, 0.0),
            off = vec3(-0.6, 0.1, 0.5)
        }
    },
    ['Interior 5'] = {
        menuId = 'decals',
        id = 31,
        price = 2000,
        icon = 'interiormods.png',
        cam = {
            angle = vec2(90.0, 0.0),
            off = vec3(-0.6, 0.1, 0.5)
        }
    },
    ['Plate Index'] = {
        menuId = 'decals',
        id = 51,
        icon = 'numberplate.png',
        cam = {
            angle = vec2(0.0, 15.0),
            off = vec3(0.0, 5.0, 0.5)
        },
        onSelect = function(vehicle, index)
            -- Store stance values AND wheel mod BEFORE SetVehicleNumberPlateTextIndex as it will reset them
            local store = require 'client.modules.store'
            local stanceBackup = nil
            local wheelModBackup = nil
            if store.stored.currentStance then
                stanceBackup = {}
                for stanceType, value in pairs(store.stored.currentStance) do
                    stanceBackup[stanceType] = value
                end
                wheelModBackup = GetVehicleMod(vehicle, 23)
            end
            
            SetVehicleNumberPlateTextIndex(vehicle, index)
            
            -- Restore wheel mod if it was reset
            if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
            end
            
            -- IMMEDIATE restoration after SetVehicleNumberPlateTextIndex
            if stanceBackup then
                local vehicleModule = require 'client.modules.vehicle'
                for stanceType, value in pairs(stanceBackup) do
                    vehicleModule.applyStanceMod(vehicle, stanceType, value)
                end
            end
        end,
        onClick = function(vehicle, stored)
            local mods = {
                { label = 'Blue/White',   id = 0, price = 200 },
                { label = 'Yellow/black', id = 1, price = 200 },
                { label = 'Yellow/Blue',  id = 2, price = 200 },
                { label = 'Blue/White2',  id = 3, price = 200 },
                { label = 'Blue/White3',  id = 4, price = 200 },
                { label = 'Yankton',      id = 5, price = 200 },
            }

            if GetGameBuildNumber() > 2944 then
                mods[#mods + 1] = { label = 'eCola', id = 6, price = 200 }
                mods[#mods + 1] = { label = 'Las Venturas', id = 7, price = 200 }
                mods[#mods + 1] = { label = 'Liberty City', id = 8, price = 200 }
                mods[#mods + 1] = { label = 'LS Car Meet', id = 9, price = 200 }
                mods[#mods + 1] = { label = 'Panic', id = 10, price = 200 }
                mods[#mods + 1] = { label = 'Pounders', id = 11, price = 200 }
                mods[#mods + 1] = { label = 'Sprunk', id = 12, price = 200 }
            end
            
            local currentMod = GetVehicleNumberPlateTextIndex(vehicle)
            stored.currentMod = currentMod
            for _, v in ipairs(mods) do
                if v.id == currentMod then
                    v.selected = true
                    v.applied = true
                    break
                end
            end
            return mods
        end,
    },
    Extras = {
        menuId = 'decals',
        custom = true,
        icon = 'exterior.png',
        onToggle = function(vehicle, index, toggle)
            -- Store stance values AND wheel mod BEFORE SetVehicleExtra as it will reset them
            local store = require 'client.modules.store'
            local stanceBackup = nil
            local wheelModBackup = nil
            if store.stored.currentStance then
                stanceBackup = {}
                for stanceType, value in pairs(store.stored.currentStance) do
                    stanceBackup[stanceType] = value
                end
                wheelModBackup = GetVehicleMod(vehicle, 23)
            end
            
            SetVehicleExtra(vehicle, index, not toggle)
            
            -- Restore wheel mod if it was reset
            if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
            end
            
            -- IMMEDIATE restoration after SetVehicleExtra
            if stanceBackup then
                local vehicleModule = require 'client.modules.vehicle'
                for stanceType, value in pairs(stanceBackup) do
                    vehicleModule.applyStanceMod(vehicle, stanceType, value)
                end
            end
        end,
        canInteract = function(vehicle)
            for extra = 0, 20 do
                if DoesExtraExist(vehicle, extra) then
                    return true
                end
            end
        end,
        onClick = function(vehicle)
            local mods = {}
            local count = 0
            for extra = 0, 20 do
                if DoesExtraExist(vehicle, extra) then
                    count += 1
                    mods[count] = {
                        label = ('Extra %s'):format(extra),
                        id = extra,
                        price = 200,
                        applied = IsVehicleExtraTurnedOn(vehicle, extra),
                        toggle = true
                    }
                end
            end
            return mods
        end,
    },
    ['Gearbox'] = {
        menuId = 'performance',
        id = 13,
        icon = 'transmission.png',
        labels = {
            [0] = {label = 'Gearbox lvl 1', price = 0},
            [1] = {label = 'Gearbox lvl 2', price = 0},
            [2] = {label = 'Gearbox lvl 3', price = 0},
            [3] = {label = 'Gearbox lvl 4', price = 0},
        },
    },
    ['Suspension'] = {
        menuId = 'performance',
        id = 15,
        icon = 'suspension.png',
        cam = { angle = vec2(178.62, 17.25), off = vec3(-2.900037, 0.000049, 0.300000) }, -- Same as skirt
        labels = {
            [0] = {label = 'Suspension lvl 1', price = 0},
            [1] = {label = 'Suspension lvl 2', price = 0},
            [2] = {label = 'Suspension lvl 3', price = 0},
            [3] = {label = 'Suspension lvl 4', price = 0},
        },
    },
    --Tyre_smoke =              {id = 20, price = 2000, cam = {angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000)}},
    --Hydraulics =              {id = 21, price = 2000, cam = {angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000)}},
    --Xenon_lights =            {id = 22, price = 2000, cam = {angle = vec2(127.125, 33.0), off = vec3(-3.200000, 3.400000, 2.100000)}},

}
