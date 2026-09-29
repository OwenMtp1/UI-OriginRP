--[[
    Ouvrir le salon (depuis le script de tatouage de la base) :

    exports.originrp_tatoueur:open({
        title = 'Tatoueur', subtitle = 'Blazing Tattoo · Vinewood',
        money = { cash = 305, bank = 4200 },
        -- zones = { ... }   -- optionnel, sinon Config.Zones
        tattoos = {          -- motifs par zone
            left_leg = {
                { id = 'tribal_star', label = 'Tribal Star',
                  collection = 'mpbiker_overlays', overlay = 'MP_MP_Biker_Tat_002_M' },
                -- price = 300 (optionnel, sinon prix de la zone)
            },
        },
        owned = { left_leg = { 'tribal_star' } },   -- motifs déjà possédés
    }, {
        onBuy = function(zoneId, tattoo, method) end,   -- tattoo = ligne de tattoos
        onClose = function() end,
    })

    L'aperçu est appliqué directement sur le personnage. En fermant, seuls les
    tatouages possédés restent :

        exports.originrp_tatoueur:purchaseResult(true, 'Tatouage réalisé !')
        exports.originrp_tatoueur:purchaseResult(false, 'Pas assez d\'argent.')
        exports.originrp_tatoueur:update({ money = { cash = 55, bank = 4200 } })

    Sans fonctions, les événements client '<ressource>:onBuy' et ':onClose'
    sont déclenchés. Le serveur doit revérifier le prix et l'argent, et
    sauvegarder les tatouages du joueur.
]]

local isOpen = false
local handlers = {}
local data = {}
local previewing = nil
local pending = nil
local RES = GetCurrentResourceName()

local function dispatch(name, ...)
    if handlers[name] then handlers[name](...) else TriggerEvent(('%s:%s'):format(RES, name), ...) end
end

local function findTattoo(zoneId, id)
    for _, t in ipairs((data.tattoos or {})[zoneId] or {}) do
        if t.id == id then return t end
    end
end

local function applyDecoration(ped, t)
    if t and t.collection and t.overlay then
        AddPedDecorationFromHashes(ped, joaat(t.collection), joaat(t.overlay))
    end
end

-- Tatouages possédés + aperçu éventuel
local function refresh()
    local ped = PlayerPedId()
    ClearPedDecorations(ped)
    for zoneId, ids in pairs(data.owned or {}) do
        for _, id in ipairs(ids) do applyDecoration(ped, findTattoo(zoneId, id)) end
    end
    if previewing then applyDecoration(ped, findTattoo(previewing.zone, previewing.id)) end
end

local function close(silent)
    if not isOpen then return end
    isOpen = false
    previewing, pending = nil, nil
    refresh()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if not silent then dispatch('onClose') end
end

local function open(d, h)
    data = d or {}
    data.zones = data.zones or Config.Zones
    data.owned = data.owned or {}
    handlers = h or {}
    previewing = nil
    isOpen = true
    SetNuiFocus(true, true)
    -- La NUI n'a besoin que des noms (pas des hashs)
    local tattoos = {}
    for zoneId, list in pairs(data.tattoos or {}) do
        tattoos[zoneId] = {}
        for i, t in ipairs(list) do tattoos[zoneId][i] = { id = t.id, label = t.label, price = t.price } end
    end
    SendNUIMessage({ action = 'open', data = {
        title = data.title, subtitle = data.subtitle, money = data.money,
        zones = data.zones, tattoos = tattoos, owned = data.owned,
    } })
end

RegisterNUICallback('preview', function(req, cb)
    cb('ok')
    if not isOpen then return end
    previewing = req.tattoo and { zone = req.zone, id = req.tattoo } or nil
    refresh()
end)

RegisterNUICallback('rotate', function(req, cb)
    cb('ok')
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + (tonumber(req.direction) or 1) * Config.RotateStep)
end)

RegisterNUICallback('buy', function(req, cb)
    cb('ok')
    local t = isOpen and findTattoo(req.zone, req.tattoo)
    if not t then return end
    pending = { zone = req.zone, id = t.id }
    dispatch('onBuy', req.zone, t, req.method == 'bank' and 'bank' or 'cash')
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    close()
end)

exports('purchaseResult', function(ok, message)
    if ok and pending then
        data.owned[pending.zone] = data.owned[pending.zone] or {}
        table.insert(data.owned[pending.zone], pending.id)
        SendNUIMessage({ action = 'update', data = { owned = data.owned } })
    end
    pending = nil
    if message then SendNUIMessage({ action = 'toast', message = message, kind = ok and 'success' or 'error' }) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == RES and isOpen then
        previewing = nil
        refresh()
        SetNuiFocus(false, false)
    end
end)

exports('open', open)
exports('close', function() close(true) end)
exports('update', function(d) SendNUIMessage({ action = 'update', data = d }) end)
exports('notify', function(message, kind) SendNUIMessage({ action = 'toast', message = message, kind = kind }) end)
exports('isOpen', function() return isOpen end)
