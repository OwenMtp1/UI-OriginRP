local props = {}   -- id -> objet
local blips = {}   -- id -> blip
local lastLocal = {}

local function radarList() return GlobalState.radarList or {} end
local function isDown(id) return (GlobalState.radarDown or {})[id] ~= nil end

-- ─── Props indestructibles ─────────────────────────────────────────────────

local function spawnProp(r)
    lib.requestModel(Config.Model)
    local obj = CreateObject(Config.Model, r.x, r.y, r.z, false, false, false)
    SetEntityHeading(obj, r.h)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetEntityProofs(obj, true, true, true, true, true, true, true, true)
    SetEntityCanBeDamaged(obj, false)
    SetDisableFragDamage(obj, true)
    return obj
end

local function clear(id)
    if props[id] and DoesEntityExist(props[id]) then DeleteEntity(props[id]) end
    props[id] = nil
end

local function refresh()
    local seen = {}
    for _, r in ipairs(radarList()) do
        seen[r.id] = true
        if isDown(r.id) then
            clear(r.id)
        elseif not props[r.id] or not DoesEntityExist(props[r.id]) then
            props[r.id] = spawnProp(r)
        end

        if Config.Blip.enabled and not blips[r.id] then
            local b = AddBlipForCoord(r.x, r.y, r.z)
            SetBlipSprite(b, Config.Blip.sprite)
            SetBlipColour(b, Config.Blip.color)
            SetBlipScale(b, Config.Blip.scale)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(('%s (%d km/h)'):format(Config.Blip.label, r.limit))
            EndTextCommandSetBlipName(b)
            blips[r.id] = b
        end
    end
    for id in pairs(props) do if not seen[id] then clear(id) end end
    for id, b in pairs(blips) do
        if not seen[id] then RemoveBlip(b) blips[id] = nil end
    end
end

AddStateBagChangeHandler('radarList', 'global', function() SetTimeout(0, refresh) end)
AddStateBagChangeHandler('radarDown', 'global', function() SetTimeout(0, refresh) end)
CreateThread(function() Wait(1000) refresh() end)

RegisterNetEvent('originrp_radar:destroyed', function(id)
    for _, r in ipairs(radarList()) do
        if r.id == id and #(GetEntityCoords(PlayerPedId()) - vector3(r.x, r.y, r.z)) < 150.0 then
            lib.requestNamedPtfxAsset('core')
            UseParticleFxAsset('core')
            StartParticleFxNonLoopedAtCoord('ent_sht_electrical_box', r.x, r.y, r.z + 3.0, 0.0, 0.0, 0.0, 2.0, false, false, false)
            UseParticleFxAsset('core')
            StartParticleFxNonLoopedAtCoord('exp_grd_bzgas_smoke', r.x, r.y, r.z + 1.0, 0.0, 0.0, 0.0, 1.5, false, false, false)
        end
    end
    clear(id)
end)

-- ─── Détection de vitesse ──────────────────────────────────────────────────

local function inCone(r, pos)
    local h = math.rad(r.h)
    local fx, fy = -math.sin(h), math.cos(h)
    local dx, dy = pos.x - r.x, pos.y - r.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.5 then return true end
    local cos = (fx * dx + fy * dy) / len
    return cos >= math.cos(math.rad(Config.DetectAngle / 2))
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and not Config.ExemptClasses[GetVehicleClass(veh)] then
            sleep = 100
            local pos = GetEntityCoords(veh)
            local speed = GetEntitySpeed(veh) * 3.6
            local now = GetGameTimer()

            for _, r in ipairs(radarList()) do
                if not isDown(r.id)
                    and speed > r.limit + Config.Tolerance
                    and #(pos - vector3(r.x, r.y, r.z)) <= Config.DetectRadius
                    and inCone(r, pos)
                    and (not lastLocal[r.id] or now - lastLocal[r.id] > Config.Cooldown * 1000) then
                    lastLocal[r.id] = now
                    TriggerServerEvent('originrp_radar:flash', r.id)
                end
            end
        end
        Wait(sleep)
    end
end)

-- ─── Flash + notification ──────────────────────────────────────────────────

RegisterNetEvent('originrp_radar:flashed', function(data)
    PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
    CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < 350 do
            local a = math.floor(255 * (1 - (GetGameTimer() - start) / 350))
            DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, a)
            Wait(0)
        end
    end)
    lib.notify({
        title = 'Radar automatique',
        description = Config.Message:format(data.amount) .. ('\n%d km/h (limite %d km/h) · %s'):format(data.speed, data.limit, data.plate or ''),
        type = 'error',
        icon = 'gauge-high',
        position = Config.NotifyPosition,
        duration = 8000,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(props) do clear(id) end
    for _, b in pairs(blips) do RemoveBlip(b) end
end)
