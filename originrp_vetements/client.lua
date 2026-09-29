--[[
    Ouvrir le magasin (depuis le script de magasin de la base) :

    exports.originrp_vetements:open({
        title = 'Vêtements', subtitle = 'Binco · Textile City',
        money = { cash = 305, bank = 4200 },
        -- categories = { ... }   -- optionnel, sinon Config.Categories
    }, {
        onBuy = function(purchase, method) end,
        -- purchase = { category, component | prop, drawable, texture, price }
        -- method   = 'cash' ou 'bank'
        onClose = function() end,
    })

    L'aperçu est appliqué directement sur le personnage. En fermant, la
    tenue d'origine est remise, sauf pour les achats confirmés :

        exports.originrp_vetements:purchaseResult(true, 'Haut acheté.')   -- garde le vêtement
        exports.originrp_vetements:purchaseResult(false, 'Pas assez d\'argent.')
        exports.originrp_vetements:update({ money = { cash = 185, bank = 4200 } })

    Sans fonctions, les événements client '<ressource>:onBuy' et ':onClose'
    sont déclenchés. La sauvegarde de la tenue (skin) reste au script de la base.
    Le serveur doit revérifier le prix et l'argent avant de valider.
]]

local isOpen = false
local handlers = {}
local categories = {}
local original = {}   -- tenue de référence (par id de catégorie)
local pending = nil   -- achat en attente de purchaseResult
local RES = GetCurrentResourceName()

local function dispatch(name, ...)
    if handlers[name] then handlers[name](...) else TriggerEvent(('%s:%s'):format(RES, name), ...) end
end

local function readSlot(ped, c)
    if c.prop then
        return { drawable = GetPedPropIndex(ped, c.prop), texture = GetPedPropTextureIndex(ped, c.prop) }
    end
    return { drawable = GetPedDrawableVariation(ped, c.component), texture = GetPedTextureVariation(ped, c.component) }
end

local function applySlot(ped, c, slot)
    if c.prop then
        if slot.drawable < 0 then ClearPedProp(ped, c.prop)
        else SetPedPropIndex(ped, c.prop, slot.drawable, slot.texture, true) end
    else
        SetPedComponentVariation(ped, c.component, slot.drawable, slot.texture, 0)
    end
end

local function restoreAll()
    local ped = PlayerPedId()
    for _, c in ipairs(categories) do
        if original[c.id] then applySlot(ped, c, original[c.id]) end
    end
end

local function categoryById(id)
    for _, c in ipairs(categories) do if c.id == id then return c end end
end

-- Liste des modèles et nombre de couleurs, lus sur le personnage
local function buildCategories(ped)
    local out = {}
    for i, c in ipairs(categories) do
        local count = c.prop and GetNumberOfPedPropDrawableVariations(ped, c.prop)
            or GetNumberOfPedDrawableVariations(ped, c.component)
        local items = {}
        for d = 0, count - 1 do
            local variants = c.prop and GetNumberOfPedPropTextureVariations(ped, c.prop, d)
                or GetNumberOfPedTextureVariations(ped, c.component, d)
            items[#items + 1] = { id = d, variants = math.max(1, variants), price = c.price }
        end
        out[i] = { id = c.id, label = c.label, icon = c.icon, price = c.price, items = items }
    end
    return out
end

local function close(silent)
    if not isOpen then return end
    isOpen = false
    pending = nil
    restoreAll()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if not silent then dispatch('onClose') end
end

local function open(data, h)
    data = data or {}
    handlers = h or {}
    categories = data.categories or Config.Categories
    local ped = PlayerPedId()
    original = {}
    for _, c in ipairs(categories) do original[c.id] = readSlot(ped, c) end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = {
        title = data.title, subtitle = data.subtitle, money = data.money,
        categories = buildCategories(ped),
    } })
end

RegisterNUICallback('preview', function(data, cb)
    cb('ok')
    if not isOpen then return end
    restoreAll()
    local c = data.category and categoryById(data.category)
    if c then
        applySlot(PlayerPedId(), c, { drawable = tonumber(data.drawable) or 0, texture = tonumber(data.variant) or 0 })
    end
end)

RegisterNUICallback('rotate', function(data, cb)
    cb('ok')
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + (tonumber(data.direction) or 1) * Config.RotateStep)
end)

RegisterNUICallback('buy', function(data, cb)
    cb('ok')
    local c = isOpen and categoryById(data.category)
    if not c then return end
    pending = { category = c.id, component = c.component, prop = c.prop,
        drawable = tonumber(data.drawable) or 0, texture = tonumber(data.variant) or 0, price = c.price }
    dispatch('onBuy', pending, data.method == 'bank' and 'bank' or 'cash')
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    close()
end)

-- Résultat de l'achat, appelé par le script de la base après vérification serveur
exports('purchaseResult', function(ok, message)
    if ok and pending then
        original[pending.category] = { drawable = pending.drawable, texture = pending.texture }
    end
    pending = nil
    if message then SendNUIMessage({ action = 'toast', message = message, kind = ok and 'success' or 'error' }) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == RES and isOpen then
        restoreAll()
        SetNuiFocus(false, false)
    end
end)

exports('open', open)
exports('close', function() close(true) end)
exports('update', function(data) SendNUIMessage({ action = 'update', data = data }) end)
exports('notify', function(message, kind) SendNUIMessage({ action = 'toast', message = message, kind = kind }) end)
exports('isOpen', function() return isOpen end)
