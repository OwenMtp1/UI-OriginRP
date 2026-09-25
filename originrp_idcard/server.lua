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

-- Catégories du permis : { car = true/false, bike = true/false, truck = true/false }
local function getLicenses(src)
    if framework == 'esx' then
        -- esx_license répond de façon asynchrone
        if GetResourceState('esx_license') ~= 'started' then return {} end
        local p = promise.new()
        TriggerEvent('esx_license:getLicenses', src, function(list) p:resolve(list or {}) end)
        SetTimeout(3000, function() if p.state == 0 then p:resolve({}) end end)
        local owned = {}
        for _, license in ipairs(Citizen.Await(p)) do owned[license.type] = true end
        local types = Config.EsxLicenseTypes
        return { car = owned[types.car] == true, bike = owned[types.bike] == true, truck = owned[types.truck] == true }
    elseif framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        local licences = player and player.PlayerData.metadata.licences or {}
        return { car = licences.driver == true, bike = licences.bike == true, truck = licences.truck == true }
    end
    return Config.GetLicenses(src) or {}
end

-- Document demandé : 'id' (carte d'identité) ou 'license' (permis de conduire)
local function buildDocument(src, docType)
    local data = getIdentity(src)
    if not data then return nil end
    data.type = docType
    if docType == 'license' then
        data.licenses = getLicenses(src)
        local l = data.licenses
        if Config.RequireLicense and not (l.car or l.bike or l.truck) then
            return nil, "Vous n'avez pas de permis de conduire."
        end
    end
    return data
end

local lastUse = {}

-- targetId : joueur à qui montrer la carte (nil = soi-même)
-- docType : 'id' (défaut) ou 'license'
RegisterNetEvent('originrp_idcard:show', function(targetId, docType)
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

    docType = docType == 'license' and 'license' or 'id'
    local document, reason = buildDocument(src, docType)
    if not document then
        if reason then TriggerClientEvent('originrp_idcard:notify', src, reason) end
        return
    end

    TriggerClientEvent('originrp_idcard:open', target, document)
    if target ~= src then
        TriggerClientEvent('originrp_idcard:open', src, document)
    end
end)

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)

-- Pour afficher une carte depuis un autre script serveur (ex. item utilisable) :
-- exports.originrp_idcard:showCard(source, target)      -- carte d'identité
-- exports.originrp_idcard:showLicense(source, target)   -- permis de conduire
local function showDocument(src, target, docType)
    local document, reason = buildDocument(src, docType)
    if document then
        TriggerClientEvent('originrp_idcard:open', target or src, document)
    elseif reason then
        TriggerClientEvent('originrp_idcard:notify', src, reason)
    end
end

exports('showCard', function(src, target) showDocument(src, target, 'id') end)
exports('showLicense', function(src, target) showDocument(src, target, 'license') end)
