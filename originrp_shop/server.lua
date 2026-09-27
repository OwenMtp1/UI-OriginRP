local itemsById = {}
for _, item in ipairs(Config.Items) do itemsById[item.id] = item end

local function notify(src, message, kind)
    TriggerClientEvent('originrp_shop:notify', src, message, kind)
end

local function playerState(src)
    local history = ServerConfig.GetHistory(src) or {}
    return {
        balance = tonumber(ServerConfig.GetBalance(src)) or 0,
        vip = ServerConfig.GetVip(src),
        history = history,
        purchases = #history,
    }
end

RegisterNetEvent('originrp_shop:request', function()
    local src = source
    TriggerClientEvent('originrp_shop:open', src, playerState(src))
end)

local busy = {}

RegisterNetEvent('originrp_shop:buy', function(itemId)
    local src = source
    local item = itemsById[itemId]
    if not item or busy[src] then return end
    busy[src] = true

    local price = tonumber(item.price) or 0
    local ok, reason = false, nil

    if (tonumber(ServerConfig.GetBalance(src)) or 0) < price then
        reason = ('Solde insuffisant (%d %s requis).'):format(price, Config.Currency.short)
    elseif not ServerConfig.RemoveBalance(src, price) then
        reason = 'Paiement refusé.'
    else
        ok, reason = ServerConfig.GiveItem(src, item)
        if ok then
            ServerConfig.AddHistory(src, item)
        else
            ServerConfig.AddBalance(src, price) -- remboursement
            reason = (reason or 'Livraison impossible.') .. ' Tu as été remboursé.'
        end
    end

    busy[src] = nil
    if ok then
        notify(src, ('%s acheté !'):format(item.label), 'success')
    else
        notify(src, reason, 'error')
    end
    TriggerClientEvent('originrp_shop:update', src, playerState(src))
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

-- Ouvrir la boutique depuis un autre script serveur
exports('open', function(src)
    TriggerClientEvent('originrp_shop:open', src, playerState(src))
end)
