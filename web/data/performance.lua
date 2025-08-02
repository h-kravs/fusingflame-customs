return {
    Engine = {
        id = 11, -- EMS Upgrade
        price = 5000,
        levelPrice = 2500, -- Additional cost per level
        icon = 'engine.png'
    },
    Brakes = {
        id = 12, -- Brakes
        price = 3000,
        levelPrice = 1500,
        icon = 'brakes.png'
        -- No cam defined, will use default camera
    },
    Transmission = {
        id = 13, -- Transmission
        price = 4000,
        levelPrice = 2000,
        icon = 'transmission.png'
    },
    Suspension = {
        id = 15, -- Suspension
        price = 3500,
        levelPrice = 1750,
        icon = 'suspension.png',
        cam = { angle = vec2(178.62, 17.25), off = vec3(-2.900037, 0.000049, 0.300000) } -- Same as skirt
    },
    Armor = {
        id = 16, -- Armor
        price = 6000,
        levelPrice = 3000,
        icon = 'armour.png'
    },
    Turbo = {
        id = 18, -- Turbo (toggle mod)
        price = 10000,
        icon = 'turbo.png'
    },
    ["Engine Sound"] = {
        isEngineSound = true, -- Special flag for engine sounds
        price = 2000, -- Base price for engine sounds
        icon = 'exhaust.png',
        cam = { angle = vec2(0.0, 10.0), off = vec3(0.0, -3.5, 0.2) }, -- Same as exhaust
        sounds = {
            -- Import from enginesound-menu config - game sounds + add-ons
            ["Default"] = "resetenginesound",
            ["Adder"] = "adder", 
            ["Baller"] = "baller",
            ["Lazer"] = "lazer",
            ["T20"] = "t20",
            ["Zentorno"] = "zentorno",
            ["Bullet"] = "bullet",
            ["Blista3"] = "blista3",
            ["Cheetah"] = "cheetah",
            ["EntityXF"] = "entityxf",
            ["Infernus"] = "infernus",
            ["Monroe"] = "monroe",
            ["Stinger"] = "stinger",
            ["Vacca"] = "vacca",
            ["Voltic"] = "voltic",
            -- Custom sounds from testsounds
            ["Custom ST29"] = "st29b18cfnf"
        }
    }
}