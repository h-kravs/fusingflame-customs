local vehicle = require 'client.modules.vehicle'
local applyVehicleColor, applyExtraColor, applyTyreSmokeColor, applyXenonLightsColor,--onSelects
getPaintTypes, getAllColors, getNeons, getXenonColor, getTyreSmokes, getWindowsTint in vehicle --onClicks

return {
    functions = {
        Primary = {
            onClick = getPaintTypes,
            onSelect = applyVehicleColor,
            icon = 'paint.png'
        },
        Secondary = {
            onClick = getPaintTypes,
            onSelect = applyVehicleColor,
            icon = 'paint.png'
        },
        Dashboard = {
            cam = { angle = vec2(90.0, 0.0), off = vec3(-0.6, 0.1, 0.5) },
            onClick = getAllColors,
            onSelect = SetVehicleDashboardColor,
            icon = 'dashboard.png'
        },
        Interior = {
            cam = { angle = vec2(90.0, 0.0), off = vec3(-0.6, 0.1, 0.5) },
            onClick = getAllColors,
            onSelect = SetVehicleInteriorColor,
            icon = 'interior.png'
        },
        Wheels = {
            cam = { angle = vec2(178.62, 17.25), off = vec3(-2.900037, 0.000049, 0.300000) },
            onClick = getAllColors,
            onSelect = applyExtraColor,
            icon = 'wheels.png'
        },
        Pearlescent = {
            onClick = getAllColors,
            onSelect = applyExtraColor,
            icon = 'paint.png'
        },
        Neon = {
            onToggle = function(entity, modIndex, toggle)
                -- Store stance values AND wheel mod BEFORE SetVehicleNeonLightEnabled as it will reset them
                local store = require 'client.modules.store'
                local stanceBackup = nil
                local wheelModBackup = nil
                if store.stored.currentStance then
                    stanceBackup = {}
                    for stanceType, value in pairs(store.stored.currentStance) do
                        stanceBackup[stanceType] = value
                    end
                    wheelModBackup = GetVehicleMod(entity, 23)
                end
                
                SetVehicleNeonLightEnabled(entity, modIndex, toggle)
                
                -- Restore wheel mod if it was reset
                if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(entity, 23) == -1 then
                    SetVehicleMod(entity, 23, wheelModBackup, store.stored.customTyres)
                end
                
                -- IMMEDIATE restoration after SetVehicleNeonLightEnabled
                if stanceBackup then
                    local vehicleModule = require 'client.modules.vehicle'
                    for stanceType, value in pairs(stanceBackup) do
                        vehicleModule.applyStanceMod(entity, stanceType, value)
                    end
                end
            end,
            onClick = getNeons,
            onSelect = SetVehicleNeonLightsColor_2,
            icon = 'neons.png'
        },
        ['Tyre Smoke'] = {
            onClick = getTyreSmokes,
            onSelect = applyTyreSmokeColor,
            icon = 'tire_smoke.png'
        },
        ['Xenon Lights'] = {
            onClick = getXenonColor,
            onSelect = applyXenonLightsColor,
            icon = 'headlights.png'
        },
        ['Window Tint'] = {
            onClick = getWindowsTint,
            onSelect = function(vehicle, index)
                -- Store stance values AND wheel mod BEFORE SetVehicleWindowTint as it will reset them
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
                
                SetVehicleWindowTint(vehicle, index)
                
                -- Restore wheel mod if it was reset
                if wheelModBackup and wheelModBackup ~= -1 and GetVehicleMod(vehicle, 23) == -1 then
                    SetVehicleMod(vehicle, 23, wheelModBackup, store.stored.customTyres)
                end
                
                -- IMMEDIATE restoration after SetVehicleWindowTint
                if stanceBackup then
                    local vehicleModule = require 'client.modules.vehicle'
                    for stanceType, value in pairs(stanceBackup) do
                        vehicleModule.applyStanceMod(vehicle, stanceType, value)
                    end
                end
            end,
            icon = 'windowtint.png'
        },
        ['Neon Colors'] = {
            onClick = getAllColors,
            onSelect = SetVehicleNeonLightsColor_2,
            icon = 'neons.png'
        }
    },
    paints = {
        'Metallic',
        'Matte',
        'Metal',
        'Chrome',
        'Chameleon'
    },
    data = {
        Neons = {
            { label = 'Left',   id = 0,            selected = true, price = 200,  toggle = true },
            { label = 'Right ', id = 1,            price = 200,     toggle = true },
            { label = 'Front ', id = 2,            price = 200,     toggle = true },
            { label = 'Back',   id = 3,            price = 200,     toggle = true },
        },
        WindowsTint = {
            { price = 200, label = "Default",    id = 0 },
            { price = 200, label = "Lightsmoke", id = 3 },
            { price = 200, label = "Darksmoke",  id = 2 },
            { price = 200, label = "Pure Black", id = 1 },
        },
        TyreSmoke = {
            { price = 200, label = "White",         rgb = { 222, 222, 255 } },
            { price = 200, label = "Blue ",         rgb = { 2, 21, 255 } },
            { price = 200, label = "Electric Blue", rgb = { 3, 83, 255 } },
            { price = 200, label = "Mint Green",    rgb = { 0, 255, 140 } },
            { price = 200, label = "Lime Green",    rgb = { 94, 255, 1 } },
            { price = 200, label = "Yellow",        rgb = { 255, 255, 0 } },
            { price = 200, label = "Golden Shower", rgb = { 255, 150, 0 } },
            { price = 200, label = "Orange",        rgb = { 255, 62, 0 } },
            { price = 200, label = "Red",           rgb = { 255, 1, 1 } },
            { price = 200, label = "Pony Pink",     rgb = { 255, 50, 100 } },
            { price = 200, label = "Hot Pink",      rgb = { 255, 5, 190 } },
            { price = 200, label = "Purple",        rgb = { 35, 1, 255 } },
            { price = 200, label = "Blacklight",    rgb = { 15, 3, 255 } },
        },
        Xenon = {
            { price = 200, label = "Default",       id = -1 },
            { price = 200, label = "White",         id = 0 },
            { price = 200, label = "Blue ",         id = 1 },
            { price = 200, label = "Electric Blue", id = 2 },
            { price = 200, label = "Mint Green",    id = 3 },
            { price = 200, label = "Lime Green",    id = 4 },
            { price = 200, label = "Yellow",        id = 5 },
            { price = 200, label = "Golden Shower", id = 6 },
            { price = 200, label = "Orange",        id = 7 },
            { price = 200, label = "Red",           id = 8 },
            { price = 200, label = "Pony Pink",     id = 9 },
            { price = 200, label = "Hot Pink",      id = 10 },
            { price = 200, label = "Purple",        id = 11 },
            { price = 200, label = "Blacklight",    id = 12 },
        },
        Chrome = {
            { price = 200, label = "Chrome", id = 120 },
        },
        Matte = {
            { price = 200, label = "Black",           id = 12 },
            { price = 200, label = "Gray",            id = 13 },
            { price = 200, label = "Light Gray",      id = 14 },
            { price = 200, label = "Ice White",       id = 131 },
            { price = 200, label = "Blue",            id = 83 },
            { price = 200, label = "Dark Blue",       id = 82 },
            { price = 200, label = "Midnight Blue",   id = 84 },
            { price = 200, label = "Midnight Purple", id = 149 },
            { price = 200, label = "Schafter Purple", id = 148 },
            { price = 200, label = "Red",             id = 39 },
            { price = 200, label = "Dark Red",        id = 40 },
            { price = 200, label = "Orange",          id = 41 },
            { price = 200, label = "Yellow",          id = 42 },
            { price = 200, label = "Lime Green",      id = 55 },
            { price = 200, label = "Green",           id = 128 },
            { price = 200, label = "Forest Green",    id = 151 },
            { price = 200, label = "Foliage Green",   id = 155 },
            { price = 200, label = "Olive Darb",      id = 152 },
            { price = 200, label = "Dark Earth",      id = 153 },
            { price = 200, label = "Desert Tan",      id = 154 }
        },
        Metal = {
            { price = 200, label = "Brushed Steel",       id = 117 },
            { price = 200, label = "Brushed Black Steel", id = 118 },
            { price = 200, label = "Brushed Aluminium",   id = 119 },
            { price = 200, label = "Pure Gold",           id = 158 },
            { price = 200, label = "Brushed Gold",        id = 159 }
        },
        Metallic = {
            { price = 200, label = "Black",            id = 0 },
            { price = 200, label = "Carbon Black",     id = 147 },
            { price = 200, label = "Graphite",         id = 1 },
            { price = 200, label = "Anhracite Black",  id = 11 },
            { price = 200, label = "Black Steel",      id = 11 },
            { price = 200, label = "Dark Steel",       id = 3 },
            { price = 200, label = "Silver",           id = 4 },
            { price = 200, label = "Bluish Silver",    id = 5 },
            { price = 200, label = "Rolled Steel",     id = 6 },
            { price = 200, label = "Shadow Silver",    id = 7 },
            { price = 200, label = "Stone Silver",     id = 8 },
            { price = 200, label = "Midnight Silver",  id = 9 },
            { price = 200, label = "Cast Iron Silver", id = 10 },
            { price = 200, label = "Red",              id = 27 },
            { price = 200, label = "Torino Red",       id = 28 },
            { price = 200, label = "Formula Red",      id = 29 },
            { price = 200, label = "Lava Red",         id = 150 },
            { price = 200, label = "Blaze Red",        id = 30 },
            { price = 200, label = "Grace Red",        id = 31 },
            { price = 200, label = "Garnet Red",       id = 32 },
            { price = 200, label = "Sunset Red",       id = 33 },
            { price = 200, label = "Cabernet Red",     id = 34 },
            { price = 200, label = "Wine Red",         id = 143 },
            { price = 200, label = "Candy Red",        id = 35 },
            { price = 200, label = "Hot Pink",         id = 135 },
            { price = 200, label = "Pfsiter Pink",     id = 137 },
            { price = 200, label = "Salmon Pink",      id = 136 },
            { price = 200, label = "Sunrise Orange",   id = 36 },
            { price = 200, label = "Orange",           id = 38 },
            { price = 200, label = "Bright Orange",    id = 138 },
            { price = 200, label = "Gold",             id = 99 },
            { price = 200, label = "Bronze",           id = 90 },
            { price = 200, label = "Yellow",           id = 88 },
            { price = 200, label = "Race Yellow",      id = 89 },
            { price = 200, label = "Dew Yellow",       id = 91 },
            { price = 200, label = "Dark Green",       id = 49 },
            { price = 200, label = "Racing Green",     id = 50 },
            { price = 200, label = "Sea Green",        id = 51 },
            { price = 200, label = "Olive Green",      id = 52 },
            { price = 200, label = "Bright Green",     id = 53 },
            { price = 200, label = "Gasoline Green",   id = 54 },
            { price = 200, label = "Lime Green",       id = 92 },
            { price = 200, label = "Midnight Blue",    id = 141 },
            { price = 200, label = "Galaxy Blue",      id = 61 },
            { price = 200, label = "Dark Blue",        id = 62 },
            { price = 200, label = "Saxon Blue",       id = 63 },
            { price = 200, label = "Blue",             id = 64 },
            { price = 200, label = "Mariner Blue",     id = 65 },
            { price = 200, label = "Harbor Blue",      id = 66 },
            { price = 200, label = "Diamond Blue",     id = 67 },
            { price = 200, label = "Surf Blue",        id = 68 },
            { price = 200, label = "Nautical Blue",    id = 69 },
            { price = 200, label = "Racing Blue",      id = 73 },
            { price = 200, label = "Ultra Blue",       id = 70 },
            { price = 200, label = "Light Blue",       id = 74 },
            { price = 200, label = "Chocolate Brown",  id = 96 },
            { price = 200, label = "Bison Brown",      id = 101 },
            { price = 200, label = "Creeen Brown",     id = 95 },
            { price = 200, label = "Feltzer Brown",    id = 94 },
            { price = 200, label = "Maple Brown",      id = 97 },
            { price = 200, label = "Beechwood Brown",  id = 103 },
            { price = 200, label = "Sienna Brown",     id = 104 },
            { price = 200, label = "Saddle Brown",     id = 98 },
            { price = 200, label = "Moss Brown",       id = 100 },
            { price = 200, label = "Woodbeech Brown",  id = 102 },
            { price = 200, label = "Straw Brown",      id = 99 },
            { price = 200, label = "Sandy Brown",      id = 105 },
            { price = 200, label = "Bleached Brown",   id = 106 },
            { price = 200, label = "Schafter Purple",  id = 71 },
            { price = 200, label = "Spinnaker Purple", id = 72 },
            { price = 200, label = "Midnight Purple",  id = 142 },
            { price = 200, label = "Bright Purple",    id = 145 },
            { price = 200, label = "Cream",            id = 107 },
            { price = 200, label = "Ice White",        id = 111 },
            { price = 200, label = "Frost White",      id = 112 }
        },
        Chameleon = {
            { price = 200, label = "Anodized Red Pearl",         id = 161 },
            { price = 200, label = "Anodized Wine Pearl",        id = 162 },
            { price = 200, label = "Anodized Purple Pearl",      id = 163 },
            { price = 200, label = "Anodized Blue Pearl",        id = 164 },
            { price = 200, label = "Anodized Green Pearl",       id = 165 },
            { price = 200, label = "Anodized Lime Pearl",        id = 166 },
            { price = 200, label = "Anodized Copper Pearl",      id = 167 },
            { price = 200, label = "Anodized Bronze Pearl",      id = 168 },
            { price = 200, label = "Anodized Champagne Pearl",   id = 169 },
            { price = 200, label = "Anodized Gold Pearl",        id = 170 },
            { price = 200, label = "Green/Blue Flip",            id = 171 },
            { price = 200, label = "Green/Red Flip",             id = 172 },
            { price = 200, label = "Green/Brown Flip",           id = 173 },
            { price = 200, label = "Green/Turquoise Flip",       id = 174 },
            { price = 200, label = "Green/Purple Flip",          id = 175 },
            { price = 200, label = "Teal/Purple Flip",           id = 176 },
            { price = 200, label = "Turquoise/Red Flip",         id = 177 },
            { price = 200, label = "Turquoise/Purple Flip",      id = 178 },
            { price = 200, label = "Cyan/Purple Flip",           id = 179 },
            { price = 200, label = "Blue/Pink Flip",             id = 180 },
            { price = 200, label = "Blue/Green Flip",            id = 181 },
            { price = 200, label = "Purple/Red Flip",            id = 182 },
            { price = 200, label = "Purple/Green Flip",          id = 183 },
            { price = 200, label = "Magenta/Green Flip",         id = 184 },
            { price = 200, label = "Magenta/Yellow Flip",        id = 185 },
            { price = 200, label = "Burgundy/Green Flip",        id = 186 },
            { price = 200, label = "Magenta/Cyan Flip",          id = 187 },
            { price = 200, label = "Copper/Purple Flip",         id = 188 },
            { price = 200, label = "Magenta/Orange Flip",        id = 189 },
            { price = 200, label = "Red/Orange Flip",            id = 190 },
            { price = 200, label = "Orange/Purple Flip",         id = 191 },
            { price = 200, label = "Orange/Blue Flip",           id = 192 },
            { price = 200, label = "White/Purple Flip",          id = 193 },
            { price = 200, label = "Red/Rainbow Flip",           id = 194 },
            { price = 200, label = "Blue/Rainbow Flip",          id = 195 },
            { price = 200, label = "Dark Green Pearl",           id = 196 },
            { price = 200, label = "Dark Teal Pearl",            id = 197 },
            { price = 200, label = "Dark Blue Pearl",            id = 198 },
            { price = 200, label = "Dark Purple Pearl",          id = 199 },
            { price = 200, label = "Oil Slick Pearl",            id = 200 },
            { price = 200, label = "Light Green Pearl",          id = 201 },
            { price = 200, label = "Light Blue Pearl",           id = 202 },
            { price = 200, label = "Light Purple Pearl",         id = 203 },
            { price = 200, label = "Light Pink Pearl",           id = 204 },
            { price = 200, label = "Off White Pearl",            id = 205 },
            { price = 200, label = "Cute Pink Pearl",            id = 206 },
            { price = 200, label = "Baby Yellow Pearl",          id = 207 },
            { price = 200, label = "Baby Green Pearl",           id = 208 },
            { price = 200, label = "Baby Blue Pearl",            id = 209 },
            { price = 200, label = "Cream Pearl",                id = 210 },
            { price = 200, label = "White Prismatic Pearl",       id = 211 },
            { price = 200, label = "Graphite Prismatic Pearl",    id = 212 },
            { price = 200, label = "Blue Prismatic Pearl",        id = 213 },
            { price = 200, label = "Purple Prismatic Pearl",      id = 214 },
            { price = 200, label = "Hot Pink Prismatic Pearl",    id = 215 },
            { price = 200, label = "Red Prismatic Pearl",         id = 216 },
            { price = 200, label = "Green Prismatic Pearl",       id = 217 },
            { price = 200, label = "Black Prismatic Pearl",       id = 218 },
            { price = 200, label = "Oil Spill Prismatic Pearl",   id = 219 },
            { price = 200, label = "Rainbow Prismatic Pearl",     id = 220 },
            { price = 200, label = "Black Holographic Pearl",     id = 221 },
            { price = 200, label = "White Holographic Pearl",     id = 222 },
            { price = 200, label = "YKTA Monochrome",             id = 223 },
            { price = 200, label = "YKTA Night & Day",            id = 224 },
            { price = 200, label = "YKTA The Verlierer",          id = 225 },
            { price = 200, label = "YKTA Sprunk Extreme",         id = 226 },
            { price = 200, label = "YKTA Vice City",              id = 227 },
            { price = 200, label = "YKTA Synthwave Night",        id = 228 },
            { price = 200, label = "YKTA Four Seasons",           id = 229 },
            { price = 200, label = "YKTA M9 Throwback",           id = 230 },
            { price = 200, label = "YKTA Bubblegum",              id = 231 },
            { price = 200, label = "YKTA Full Rainbow",           id = 232 },
            { price = 200, label = "YKTA Sunset",                 id = 233 },
            { price = 200, label = "YKTA The Seven",              id = 234 },
            { price = 200, label = "YKTA Kamen Rider",            id = 235 },
            { price = 200, label = "YKTA Chromatic",              id = 236 },
            { price = 200, label = "YKTA Christmas",              id = 237 },
            { price = 200, label = "YKTA Temperature",            id = 238 },
            { price = 200, label = "YKTA HSW Badge",              id = 239 },
            { price = 200, label = "YKTA Electro",                id = 240 },
            { price = 200, label = "YKTA Monika",                 id = 241 },
            { price = 200, label = "YKTA Fubuki",                 id = 242 },
        }
    }
}