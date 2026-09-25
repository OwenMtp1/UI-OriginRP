local isOpen = false
local currentKind = nil

local function closeTablet()
    if not isOpen then return end
    isOpen = false
    currentKind = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openTablet(kind, data)
    currentKind = kind
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = data,
        subtitle = Config.Subtitles[kind],
        permissions = Config.Permissions,
    })
end

local function closestPlayer(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best, bestDistance = nil, maxDistance
    for _, player in ipairs(GetActivePlayers()) do
        local other = GetPlayerPed(player)
        if other ~= ped then
            local distance = #(coords - GetEntityCoords(other))
            if distance <= bestDistance then best, bestDistance = player, distance end
        end
    end
    return best
end

RegisterNetEvent('originrp_tablet:open', openTablet)
RegisterNetEvent('originrp_tablet:close', closeTablet)

RegisterNetEvent('originrp_tablet:update', function(kind, data)
    if isOpen and kind == currentKind then
        SendNUIMessage({ action = 'update', data = data })
    end
end)

RegisterNetEvent('originrp_tablet:notify', function(message, kind)
    SendNUIMessage({ action = 'toast', message = message, kind = kind })
end)

-- Ouverture depuis les menus F6 / F7
for kind, eventName in pairs(Config.OpenEvents) do
    AddEventHandler(eventName, function()
        TriggerServerEvent('originrp_tablet:request', kind)
    end)
end

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb('ok')
end)

RegisterNUICallback('action', function(data, cb)
    cb('ok')
    if not isOpen then return end
    local payload = type(data.payload) == 'table' and data.payload or {}

    if data.action == 'recruit' and payload.closest then
        local player = closestPlayer(Config.RecruitDistance)
        if not player then
            SendNUIMessage({ action = 'toast', message = "Personne n'est assez proche.", kind = 'error' })
            return
        end
        payload = { target = GetPlayerServerId(player) }
    end

    TriggerServerEvent('originrp_tablet:action', currentKind, data.action, payload)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)

exports('close', closeTablet)
exports('isOpen', function() return isOpen end)
