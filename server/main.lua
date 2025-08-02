if not lib then return end

local config = require 'data.config'
local QBCore = exports['qb-core']:GetCoreObject()

-- Routing bucket management
local playerBuckets = {} -- Store which bucket each player is in
local availableBuckets = {} -- Pool of available buckets
local usedBuckets = {} -- Currently used buckets
local maxBuckets = 100 -- Maximum number of buckets to pre-create
local baseBucketId = 1000 -- Start bucket IDs from 1000 to avoid conflicts

-- Initialize available buckets
for i = 1, maxBuckets do
    availableBuckets[i] = baseBucketId + i
end

lib.callback.register('bl_customs:canAffordMod', function(source, amount)
    local moneyType = config.moneyType
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local money = Player.Functions.GetMoney(moneyType)
    if amount > money then return false end
    
    Player.Functions.RemoveMoney(moneyType, amount)
    
    -- Update UI money after purchase
    local newMoney = Player.Functions.GetMoney(moneyType)
    TriggerClientEvent('bl_customs:updatePlayerMoney', source, newMoney)
    
    return true
end)

lib.callback.register('bl_customs:getPlayerMoney', function(source)
    local moneyType = config.moneyType
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    return Player.Functions.GetMoney(moneyType)
end)

-- Listen for QBCore money changes and update UI
RegisterNetEvent('QBCore:Server:OnMoneyChange', function(source, moneytype, amount, action, reason)
    if moneytype == config.moneyType then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local newMoney = Player.Functions.GetMoney(moneytype)
            TriggerClientEvent('bl_customs:updatePlayerMoney', source, newMoney)
        end
    end
end)

-- Get an available bucket for a player
local function getAvailableBucket()
    if #availableBuckets > 0 then
        local bucket = table.remove(availableBuckets, 1)
        usedBuckets[bucket] = true
        return bucket
    end
    return nil -- No available buckets
end

-- Release a bucket back to the pool
local function releaseBucket(bucket)
    if usedBuckets[bucket] then
        usedBuckets[bucket] = nil
        table.insert(availableBuckets, bucket)
    end
end

-- Set player to a specific routing bucket
lib.callback.register('bl_customs:enterCustoms', function(source)
    local bucket = getAvailableBucket()
    if not bucket then
        return false -- No available buckets
    end
    
    -- Store the player's bucket
    playerBuckets[source] = bucket
    
    -- Set player and their vehicle to the bucket
    SetPlayerRoutingBucket(source, bucket)
    
    -- Get the player's vehicle
    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        SetEntityRoutingBucket(vehicle, bucket)
    end
    
    return true
end)

-- Reset player to normal world
lib.callback.register('bl_customs:exitCustoms', function(source)
    local bucket = playerBuckets[source]
    if bucket then
        -- Reset player to default bucket (0)
        SetPlayerRoutingBucket(source, 0)
        
        -- Get the player's vehicle and reset it too
        local ped = GetPlayerPed(source)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            SetEntityRoutingBucket(vehicle, 0)
        end
        
        -- Release the bucket
        releaseBucket(bucket)
        playerBuckets[source] = nil
    end
    
    return true
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function()
    local source = source
    local bucket = playerBuckets[source]
    if bucket then
        releaseBucket(bucket)
        playerBuckets[source] = nil
    end
end)