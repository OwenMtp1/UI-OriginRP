local status = { health = 100, armor = 0, hunger = 100, thirst = 100 }
local lastSent = {}
local hidden = false

---------------------------------------------------------------------------
-- Position de la minimap (fractions de l'écran), selon la résolution,
-- le format d'écran et la zone de sécurité réglés par le joueur.
---------------------------------------------------------------------------
local function getMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local aspectRatio = GetAspectRatio(false)
    local resX, resY = GetActiveScreenResolution()
    local xScale, yScale = 1.0 / resX, 1.0 / resY
    local margin = math.abs(safezone - 1.0) * 10 / 20

    local width = xScale * (resX / (4 * aspectRatio))
    local height = yScale * (resY / 5.674)
    local left = xScale * (resX * margin)
    local bottom = 1.0 - yScale * (resY * margin)

    return { left = left, right = left + width, top = bottom - height, bottom = bottom }
end

---------------------------------------------------------------------------
-- Faim / soif selon le framework
---------------------------------------------------------------------------
local function detectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    return 'none'
end

local framework = detectFramework()

---------------------------------------------------------------------------
-- Identité du personnage (cadre au-dessus des jauges)
-- birthdate : 'JJ/MM/AAAA' ou 'AAAA-MM-JJ' (l'âge est calculé par la NUI),
-- ou age : nombre directement.
---------------------------------------------------------------------------
local identity = nil

local function setIdentity(data)
    if type(data) ~= 'table' then return end
    identity = {
        firstname = data.firstname or data.firstName,
        lastname = data.lastname or data.lastName,
        birthdate = data.birthdate or data.dateofbirth,
        age = tonumber(data.age),
    }
    SendNUIMessage({ action = 'identity', identity = identity })
end

if framework == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    local function fromPlayerData(data)
        if data and data.firstName then setIdentity(data) end
    end

    RegisterNetEvent('esx:playerLoaded', fromPlayerData)
    fromPlayerData(ESX.GetPlayerData())

    -- esx_status envoie toutes les valeurs à chaque tick
    AddEventHandler('esx_status:onTick', function(data)
        for _, s in ipairs(data) do
            if s.name == 'hunger' or s.name == 'thirst' then
                status[s.name] = (s.percent or (s.val or 0) / 10000)
            end
        end
    end)
elseif framework == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()

    local function fromPlayerData(data)
        local meta = data and data.metadata
        if meta then
            status.hunger = meta.hunger or status.hunger
            status.thirst = meta.thirst or status.thirst
        end
        local info = data and data.charinfo
        if info then setIdentity(info) end
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        fromPlayerData(QBCore.Functions.GetPlayerData())
    end)
    RegisterNetEvent('QBCore:Player:SetPlayerData', fromPlayerData)
    RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
        status.hunger, status.thirst = hunger, thirst
    end)
    fromPlayerData(QBCore.Functions.GetPlayerData())
end

---------------------------------------------------------------------------
-- Boucle d'envoi à la NUI (uniquement quand une valeur change)
---------------------------------------------------------------------------
local function clampPercent(value)
    value = tonumber(value) or 0
    return math.floor(math.max(0, math.min(100, value)) + 0.5)
end

local function send(data)
    SendNUIMessage(data)
end

RegisterNUICallback('ready', function(_, cb)
    lastSent = {}
    cb({
        gauges = Config.Gauges,
        scale = Config.Scale,
        gap = Config.Gap,
        lowThreshold = Config.LowThreshold,
        hideArmorWhenEmpty = Config.HideArmorWhenEmpty,
        showIdentity = Config.ShowIdentity,
        identity = identity,
    })
end)

CreateThread(function()
    local lastAnchor, lastVisible = nil, nil
    while true do
        local ped = PlayerPedId()
        local maxHealth = GetEntityMaxHealth(ped) - 100
        status.health = maxHealth > 0 and (GetEntityHealth(ped) - 100) / maxHealth * 100 or 0
        status.armor = GetPedArmour(ped)

        local values, changed = {}, false
        for name, value in pairs(status) do
            local v = clampPercent(value)
            values[name] = v
            if lastSent[name] ~= v then changed = true end
        end
        if changed then
            lastSent = values
            send({ action = 'status', values = values })
        end

        local visible = not hidden
            and not IsPauseMenuActive()
            and not IsScreenFadedOut()
            and not (Config.HideWithMinimap and IsRadarHidden())
        if visible ~= lastVisible then
            lastVisible = visible
            send({ action = 'visible', visible = visible })
        end

        local anchor = getMinimapAnchor()
        local key = ('%.4f:%.4f'):format(anchor.right, anchor.bottom)
        if key ~= lastAnchor then
            lastAnchor = key
            send({ action = 'anchor', anchor = anchor })
        end

        Wait(200)
    end
end)

if Config.ToggleCommand then
    RegisterCommand(Config.ToggleCommand, function()
        hidden = not hidden
    end, false)
end

-- Pour les scripts qui gèrent eux-mêmes la faim / soif (framework 'none')
exports('setStatus', function(name, value)
    if name == 'hunger' or name == 'thirst' then status[name] = value end
end)
-- Pour les bases sans ESX / QBCore :
-- exports.originrp_hud:setIdentity({ firstname = 'Liam', lastname = 'Coelho', birthdate = '14/03/1998' })
exports('setIdentity', setIdentity)
exports('setVisible', function(visible) hidden = not visible end)
