--[[
    Adaptateur serveur : inventaire, job, état « mort » et réanimation.
    Par défaut : ox_inventory + détection ESX / QBCore pour la réanimation.
]]
ServerConfig = {}

local inv = exports.ox_inventory
local ESX, QBCore
if GetResourceState('es_extended') == 'started' then
    ESX = exports.es_extended:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

function ServerConfig.GetName(src)
    return GetPlayerName(src) or 'Inconnu'
end

function ServerConfig.GetJob(src)
    if ESX then
        local x = ESX.GetPlayerFromId(src)
        if x then return x.job.name, x.job.grade end
    elseif QBCore then
        local p = QBCore.Functions.GetPlayer(src)
        if p then return p.PlayerData.job.name, p.PlayerData.job.grade.level end
    end
    return nil, 0
end

function ServerConfig.HasKit(src)
    return (inv:Search(src, 'count', Config.Item) or 0) > 0
end

function ServerConfig.RemoveKit(src)
    return inv:RemoveItem(src, Config.Item, 1)
end

-- La personne est-elle morte / à terre ?
function ServerConfig.IsDead(src)
    local state = Player(src).state
    if state.isDead or state.dead or state.isLaststand then return true end
    local ped = GetPlayerPed(src)
    return ped ~= 0 and GetEntityHealth(ped) <= 101
end

-- Réanimation selon ton système de mort
function ServerConfig.Revive(src)
    if ESX then
        TriggerClientEvent('esx_ambulancejob:revive', src)
    elseif QBCore then
        TriggerClientEvent('hospital:client:Revive', src)
    else
        TriggerClientEvent('originrp_revive:fallbackRevive', src)
    end
end
