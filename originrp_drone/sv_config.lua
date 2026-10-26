--[[
    Adaptateur serveur : job du joueur (ESX / QBCore / autre).
]]
ServerConfig = {}

local ESX, QBCore
CreateThread(function()
    if GetResourceState('es_extended') == 'started' then ESX = exports.es_extended:getSharedObject()
    elseif GetResourceState('qb-core') == 'started' then QBCore = exports['qb-core']:GetCoreObject() end
end)

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

-- Identifiant stable du joueur (propriétaire d'une mallette)
function ServerConfig.Identifier(src)
    return GetPlayerIdentifierByType(src, 'license') or tostring(src)
end

function ServerConfig.Notify(src, msg, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Drone OR-D2', description = msg, type = kind or 'inform', icon = 'helicopter', position = Config.NotifyPosition })
end
