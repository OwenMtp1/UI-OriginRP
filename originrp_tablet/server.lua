local ACTIONS = {
    recruit = true, promote = true, demote = true, kick = true,
    saveGrade = true, deleteGrade = true,
}

local function validKind(kind)
    return type(kind) == 'string' and Config.OpenEvents[kind] ~= nil
end

local function notify(src, message, kind)
    TriggerClientEvent('originrp_tablet:notify', src, message, kind)
end

RegisterNetEvent('originrp_tablet:request', function(kind)
    local src = source
    if not validKind(kind) then return end
    local data = ServerConfig.GetData(src, kind)
    if not data then
        notify(src, "Tu n'as pas accès à cette tablette.", 'error')
        return
    end
    TriggerClientEvent('originrp_tablet:open', src, kind, data)
end)

local lastAction = {}

RegisterNetEvent('originrp_tablet:action', function(kind, action, payload)
    local src = source
    if not validKind(kind) or not ACTIONS[action] or type(payload) ~= 'table' then return end

    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < 500 then return end
    lastAction[src] = now

    local ok, message = ServerConfig.OnAction(src, kind, action, payload)
    if message then notify(src, message, ok and 'success' or 'error') end

    local data = ServerConfig.GetData(src, kind)
    if data then
        TriggerClientEvent('originrp_tablet:update', src, kind, data)
    else
        TriggerClientEvent('originrp_tablet:close', src)
    end
end)

AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)

-- Ouvrir la tablette depuis un autre script serveur
exports('open', function(src, kind)
    local data = validKind(kind) and ServerConfig.GetData(src, kind)
    if data then TriggerClientEvent('originrp_tablet:open', src, kind, data) end
end)
