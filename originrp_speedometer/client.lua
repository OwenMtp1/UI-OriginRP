local seatbelt = false
local forcedHidden = false
local lastVisible = nil

---------------------------------------------------------------------------
-- Essence selon le script installé
---------------------------------------------------------------------------
local function detectFuel()
    if Config.Fuel ~= 'auto' then return Config.Fuel end
    if GetResourceState('LegacyFuel') == 'started' then return 'legacy' end
    if GetResourceState('ps-fuel') == 'started' then return 'ps' end
    if GetResourceState('cdn-fuel') == 'started' then return 'cdn' end
    if GetResourceState('ox_fuel') == 'started' then return 'ox' end
    return 'native'
end

local fuelSource = detectFuel()

local function getFuel(vehicle)
    if fuelSource == 'legacy' then return exports['LegacyFuel']:GetFuel(vehicle) end
    if fuelSource == 'ps' then return exports['ps-fuel']:GetFuel(vehicle) end
    if fuelSource == 'cdn' then return exports['cdn-fuel']:GetFuel(vehicle) end
    if fuelSource == 'ox' then return Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle) end
    return GetVehicleFuelLevel(vehicle)
end

---------------------------------------------------------------------------
-- NUI
---------------------------------------------------------------------------
RegisterNUICallback('ready', function(_, cb)
    lastVisible = nil
    cb({
        unit = Config.Unit,
        maxSpeed = Config.MaxSpeed,
        scale = Config.Scale,
        bottom = Config.Bottom,
        lowFuel = Config.LowFuel,
        lowEngine = Config.LowEngine,
        seatbelt = Config.Seatbelt,
    })
end)

local function setVisible(visible)
    if visible == lastVisible then return end
    lastVisible = visible
    SendNUIMessage({ action = 'visible', visible = visible })
end

local function clamp(v, min, max) return math.max(min, math.min(max, v)) end

CreateThread(function()
    local factor = Config.Unit == 'mph' and 2.236936 or 3.6
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local show = vehicle ~= 0
            and not forcedHidden
            and not IsPauseMenuActive()
            and GetVehicleClass(vehicle) ~= 13
            and (not Config.DriverOnly or GetPedInVehicleSeat(vehicle, -1) == ped)

        setVisible(show)

        if show then
            local speed = GetEntitySpeed(vehicle) * factor
            local gear = GetVehicleCurrentGear(vehicle)
            local gearText
            if gear == 0 then gearText = 'R'
            elseif speed < 1.0 then gearText = 'N'
            else gearText = tostring(gear) end

            local _, lightsOn, highBeams = GetVehicleLightsState(vehicle)
            local lights = 0
            if highBeams == 1 or highBeams == true then lights = 2
            elseif lightsOn == 1 or lightsOn == true then lights = 1 end

            SendNUIMessage({
                action = 'update',
                speed = math.floor(speed + 0.5),
                rpm = GetIsVehicleEngineRunning(vehicle) and clamp(GetVehicleCurrentRpm(vehicle), 0.0, 1.0) or 0.0,
                gear = gearText,
                fuel = math.floor(clamp(getFuel(vehicle) or 0, 0, 100) + 0.5),
                engine = math.floor(clamp(GetVehicleEngineHealth(vehicle) / 10.0, 0, 100) + 0.5),
                lights = lights,
                seatbelt = seatbelt,
            })
            Wait(Config.Refresh)
        else
            Wait(400)
        end
    end
end)

---------------------------------------------------------------------------
-- Intégration
---------------------------------------------------------------------------
-- Ceinture : appeler depuis votre script de ceinture
exports('setSeatbelt', function(state) seatbelt = state and true or false end)
RegisterNetEvent('originrp_speedometer:seatbelt', function(state) seatbelt = state and true or false end)

-- Masquer le compteur (cinématique, menu…)
exports('setVisible', function(visible) forcedHidden = not visible end)
