local function detectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    return 'custom'
end

local framework = detectFramework()
local ESX, QBCore

if framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function getIdentity(src)
    if framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return nil end
        return {
            lastname = xPlayer.get('lastName'),
            firstname = xPlayer.get('firstName'),
            sex = xPlayer.get('sex'),
            birthdate = xPlayer.get('dateofbirth'),
            height = xPlayer.get('height'),
            birthplace = Config.DefaultBirthplace,
        }
    elseif framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return nil end
        local info = player.PlayerData.charinfo or {}
        return {
            lastname = info.lastname,
            firstname = info.firstname,
            sex = info.gender == 1 and 'f' or 'm',
            birthdate = info.birthdate,
            birthplace = info.nationality or Config.DefaultBirthplace,
            number = player.PlayerData.citizenid,
        }
    end
    return Config.GetIdentity(src)
end

local lastUse = {}

-- targetId : joueur à qui montrer la carte (nil = soi-même)
RegisterNetEvent('originrp_idcard:show', function(targetId)
    local src = source
    local now = GetGameTimer()
    if lastUse[src] and now - lastUse[src] < 1500 then return end
    lastUse[src] = now

    local target = tonumber(targetId) or src
    if target ~= src then
        if not GetPlayerName(target) then return end
        local from = GetEntityCoords(GetPlayerPed(src))
        local to = GetEntityCoords(GetPlayerPed(target))
        if #(from - to) > Config.ShowDistance + 1.0 then return end
    end

    local identity = getIdentity(src)
    if not identity then return end

    TriggerClientEvent('originrp_idcard:open', target, identity)
    if target ~= src then
        TriggerClientEvent('originrp_idcard:open', src, identity)
    end
end)

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)

-- Pour afficher une carte depuis un autre script serveur (ex. item utilisable) :
-- exports.originrp_idcard:showCard(source, target)
exports('showCard', function(src, target)
    local identity = getIdentity(src)
    if identity then TriggerClientEvent('originrp_idcard:open', target or src, identity) end
end)
