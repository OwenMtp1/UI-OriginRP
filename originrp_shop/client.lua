local isOpen = false

-- Partie fixe envoyée à la tablette (catalogue, packs, textes)
local function catalog()
    local items = {}
    for i, item in ipairs(Config.Items) do
        items[i] = {
            id = item.id, category = item.category, label = item.label,
            description = item.description, price = item.price,
            image = item.image, tag = item.tag, featured = item.featured == true,
        }
    end
    return {
        title = Config.Title,
        subtitle = Config.Subtitle,
        currency = Config.Currency,
        buyUrl = Config.BuyUrl,
        packs = Config.OrinPacks,
        categories = Config.Categories,
        items = items,
    }
end

local function closeShop()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('originrp_shop:open', function(state)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', catalog = catalog(), state = state })
end)

RegisterNetEvent('originrp_shop:update', function(state)
    if isOpen then SendNUIMessage({ action = 'update', state = state }) end
end)

RegisterNetEvent('originrp_shop:notify', function(message, kind)
    SendNUIMessage({ action = 'toast', message = message, kind = kind })
end)

local function requestOpen()
    if not isOpen then TriggerServerEvent('originrp_shop:request') end
end

if Config.Command then
    RegisterCommand(Config.Command, requestOpen, false)
    if Config.Key then
        RegisterKeyMapping(Config.Command, 'Ouvrir la boutique', 'keyboard', Config.Key)
    end
end

RegisterNUICallback('close', function(_, cb)
    closeShop()
    cb('ok')
end)

RegisterNUICallback('buy', function(data, cb)
    cb('ok')
    if isOpen and type(data.id) == 'string' then
        TriggerServerEvent('originrp_shop:buy', data.id)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)

exports('open', requestOpen)
exports('close', closeShop)
