-- Catalogue : base de données (sv_config.lua) si disponible, sinon config.lua
local function getItems() return ServerConfig.GetItems() or Config.Items end
local function getPacks() return ServerConfig.GetPacks() or Config.OrinPacks end

local function getSettings()
    local s = ServerConfig.GetSettings() or {}
    return {
        title = s.title or Config.Title,
        subtitle = s.subtitle or Config.Subtitle,
        buyUrl = s.buyUrl or Config.BuyUrl,
        open = s.open ~= false,
        currencyName = s.currencyName or Config.Currency.name,
        currencyShort = s.currencyShort or Config.Currency.short,
    }
end

local function findItem(id)
    for _, item in ipairs(getItems()) do
        if item.id == id then return item end
    end
end

-- Partie envoyée à la tablette (sans le champ data réservé au serveur)
local function catalog()
    local settings = getSettings()
    local items = {}
    for i, item in ipairs(getItems()) do
        items[i] = {
            id = item.id, category = item.category, label = item.label,
            description = item.description, price = item.price,
            image = item.image, tag = item.tag, featured = item.featured == true,
        }
    end
    return {
        title = settings.title,
        subtitle = settings.subtitle,
        currency = { name = settings.currencyName, short = settings.currencyShort },
        buyUrl = settings.buyUrl,
        packs = getPacks(),
        categories = Config.Categories,
        items = items,
    }
end

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

---------------------------------------------------------------------------
-- Boutique joueur
---------------------------------------------------------------------------

RegisterNetEvent('originrp_shop:request', function()
    local src = source
    if not getSettings().open then
        notify(src, 'La boutique est fermée pour le moment.', 'error')
        return
    end
    TriggerClientEvent('originrp_shop:open', src, catalog(), playerState(src))
end)

local busy = {}

RegisterNetEvent('originrp_shop:buy', function(itemId)
    local src = source
    local item = type(itemId) == 'string' and findItem(itemId)
    if not item or busy[src] or not getSettings().open then return end
    busy[src] = true

    local price = tonumber(item.price) or 0
    local ok, reason = false, nil

    if (tonumber(ServerConfig.GetBalance(src)) or 0) < price then
        reason = ('Solde insuffisant (%d %s requis).'):format(price, getSettings().currencyShort)
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

---------------------------------------------------------------------------
-- Gestion interne (admin)
---------------------------------------------------------------------------

local ADMIN_ACTIONS = {
    resetStats = true, saveSettings = true, saveItem = true, deleteItem = true,
    savePack = true, deletePack = true, adjustBalance = true,
    searchPlayers = true, selectPlayer = true,
}

local adminContext = {} -- [source] = { query = '', selected = id }

local function isAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

local function adminPayload(src)
    local data = ServerConfig.GetAdminData(src, adminContext[src] or {}) or {}
    data.settings = getSettings()
    data.categories = Config.Categories
    data.items = getItems()
    data.packs = getPacks()
    return data
end

RegisterNetEvent('originrp_shop:adminRequest', function()
    local src = source
    if not isAdmin(src) then return end
    adminContext[src] = { query = '' }
    TriggerClientEvent('originrp_shop:adminOpen', src, adminPayload(src))
end)

RegisterNetEvent('originrp_shop:adminAction', function(action, payload)
    local src = source
    if not isAdmin(src) or not ADMIN_ACTIONS[action] or type(payload) ~= 'table' then return end

    local context = adminContext[src] or {}
    adminContext[src] = context

    if action == 'searchPlayers' then
        context.query = tostring(payload.query or ''):sub(1, 64)
    elseif action == 'selectPlayer' then
        context.selected = payload.id
    else
        local ok, message = ServerConfig.OnAdminAction(src, action, payload)
        if message then notify(src, message, ok and 'success' or 'error') end
    end

    TriggerClientEvent('originrp_shop:adminUpdate', src, adminPayload(src))
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
    adminContext[source] = nil
end)

-- Ouvrir la boutique depuis un autre script serveur
exports('open', function(src)
    TriggerClientEvent('originrp_shop:open', src, catalog(), playerState(src))
end)
