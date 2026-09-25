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

-- docType : 'id' (défaut) ou 'license'
local function showToClosest(docType)
    local player = closestPlayer(Config.ShowDistance)
    if not player then
        notify("Personne n'est assez proche.")
        return
    end
    TriggerServerEvent('originrp_idcard:show', GetPlayerServerId(player), docType)
end

RegisterNetEvent('originrp_idcard:open', openCard)
RegisterNetEvent('originrp_idcard:close', closeCard)
RegisterNetEvent('originrp_idcard:notify', notify)

if Config.CommandSelf then
    RegisterCommand(Config.CommandSelf, function()
        TriggerServerEvent('originrp_idcard:show')
    end, false)
end

if Config.CommandShow then
    RegisterCommand(Config.CommandShow, function() showToClosest('id') end, false)
end

if Config.CommandLicenseSelf then
    RegisterCommand(Config.CommandLicenseSelf, function()
        TriggerServerEvent('originrp_idcard:show', nil, 'license')
    end, false)
end

if Config.CommandLicenseShow then
    RegisterCommand(Config.CommandLicenseShow, function() showToClosest('license') end, false)
end

exports('open', openCard)
exports('close', closeCard)
exports('showToClosest', showToClosest)
