--[[
    Ouvrir l'armurerie (depuis le script d'armurerie de la base) :

    exports.originrp_armurerie:open({
        title = 'Armurerie', subtitle = 'Ammu-Nation · Pillbox Hill',
        money = { cash = 305, bank = 4200 },
        license = { required = true, owned = false, price = 5000, label = "Permis de port d'arme" },
        categories = {
            { id = 'melee',    label = 'Mêlée',       icon = 'knife' },
            { id = 'firearms', label = 'Armes à feu', icon = 'gun',  license = true },
            { id = 'ammo',     label = 'Munitions',   icon = 'ammo', license = true },
        },
        items = {
            { id = 'knife',    category = 'melee',    label = 'Couteau',  description = 'Lame de combat', price = 150 },
            { id = 'pistol',   category = 'firearms', label = 'Pistolet', description = '9 mm', price = 2500 },
            { id = 'ammo_9mm', category = 'ammo', label = 'Munitions 9 mm', description = 'Boîte de 12',
              price = 40, stackable = true, max = 10 },   -- stackable : choix de la quantité
        },
    }, {
        onBuy = function(itemId, quantity, method) end,   -- method : 'cash' ou 'bank'
        onBuyLicense = function(method) end,
        onClose = function() end,
    })

    Sans fonctions, les événements client '<ressource>:onBuy', ':onBuyLicense'
    et ':onClose' sont déclenchés avec les mêmes arguments.

    Après un achat, mettre à jour l'affichage :
        exports.originrp_armurerie:update({ money = { cash = 105, bank = 4200 } })
        exports.originrp_armurerie:update({ license = { required = true, owned = true } })
        exports.originrp_armurerie:notify('Pistolet acheté.', 'success')   -- ou 'error'

    IMPORTANT : le serveur doit relire le prix dans sa propre config et
    vérifier l'argent, le permis et la quantité avant de donner l'arme.
]]

local isOpen = false
local handlers = {}
local RES = GetCurrentResourceName()

local function dispatch(name, ...)
    if handlers[name] then
        handlers[name](...)
    else
        TriggerEvent(('%s:%s'):format(RES, name), ...)
    end
end

local function close(silent)
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if not silent then dispatch('onClose') end
end

local function open(data, h)
    if type(data) ~= 'table' then return end
    handlers = h or {}
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    close()
end)

RegisterNUICallback('buy', function(data, cb)
    cb('ok')
    if not isOpen or type(data.id) ~= 'string' then return end
    local quantity = math.max(1, math.floor(tonumber(data.quantity) or 1))
    dispatch('onBuy', data.id, quantity, data.method == 'bank' and 'bank' or 'cash')
end)

RegisterNUICallback('buyLicense', function(data, cb)
    cb('ok')
    if isOpen then dispatch('onBuyLicense', data.method == 'bank' and 'bank' or 'cash') end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == RES and isOpen then SetNuiFocus(false, false) end
end)

exports('open', open)
exports('close', function() close(true) end)
exports('update', function(data) SendNUIMessage({ action = 'update', data = data }) end)
exports('notify', function(message, kind) SendNUIMessage({ action = 'toast', message = message, kind = kind }) end)
exports('isOpen', function() return isOpen end)
