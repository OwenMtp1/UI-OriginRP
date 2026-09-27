local isOpen = false

local function closeShop()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('originrp_shop:open', function(catalog, state)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', catalog = catalog, state = state })
end)

-- Gestion interne (admin)
RegisterNetEvent('originrp_shop:adminOpen', function(data)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'adminOpen', data = data })
end)

RegisterNetEvent('originrp_shop:adminUpdate', function(data)
    if isOpen then SendNUIMessage({ action = 'adminUpdate', data = data }) end
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

if Config.AdminCommand then
    RegisterCommand(Config.AdminCommand, function()
        if not isOpen then TriggerServerEvent('originrp_shop:adminRequest') end
    end, false)
end

RegisterNUICallback('adminAction', function(data, cb)
    cb('ok')
    if isOpen and type(data.action) == 'string' then
        TriggerServerEvent('originrp_shop:adminAction', data.action, type(data.payload) == 'table' and data.payload or {})
    end
end)

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
