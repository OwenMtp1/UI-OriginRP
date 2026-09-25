local isOpen = false
local token = 0

local function closeCard()
    if not isOpen then return end
    isOpen = false
    SendNUIMessage({ action = 'close' })
end

local function openCard(data, duration)
    if type(data) ~= 'table' then return end
    token = token + 1
    local current = token

    SendNUIMessage({ action = 'open', data = data, position = Config.Position })

    duration = duration or Config.Duration
    if duration and duration > 0 then
        SetTimeout(duration, function()
            if token == current then closeCard() end
        end)
    end

    if isOpen then return end
    isOpen = true

    -- Retour arrière / Échap / clic droit pour ranger la carte
    CreateThread(function()
        while isOpen do
            DisableControlAction(0, 200, true) -- évite d'ouvrir le menu pause
            if IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
                closeCard()
            end
            Wait(0)
        end
    end)
end

local function notify(text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

local function closestPlayer(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local best, bestDistance = nil, maxDistance
    for _, player in ipairs(GetActivePlayers()) do
        local other = GetPlayerPed(player)
        if other ~= ped then
            local distance = #(coords - GetEntityCoords(other))
            if distance <= bestDistance then
                best, bestDistance = player, distance
            end
        end
    end
    return best
end

local function showToClosest()
    local player = closestPlayer(Config.ShowDistance)
    if not player then
        notify("Personne n'est assez proche.")
        return
    end
    TriggerServerEvent('originrp_idcard:show', GetPlayerServerId(player))
end

RegisterNetEvent('originrp_idcard:open', openCard)
RegisterNetEvent('originrp_idcard:close', closeCard)

if Config.CommandSelf then
    RegisterCommand(Config.CommandSelf, function()
        TriggerServerEvent('originrp_idcard:show')
    end, false)
end

if Config.CommandShow then
    RegisterCommand(Config.CommandShow, showToClosest, false)
end

exports('open', openCard)
exports('close', closeCard)
exports('showToClosest', showToClosest)
