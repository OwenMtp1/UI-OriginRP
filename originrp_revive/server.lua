local Active = {}   -- source du secouriste -> { target, started }
local Busy = {}     -- source (secouriste ou patient) -> true

local function totalDuration()
    local t = 0
    for _, ms in pairs(Config.Steps) do t = t + ms end
    return t
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Réanimation', description = message, type = kind or 'inform',
        icon = 'heart-pulse', position = Config.NotifyPosition,
    })
end

local function jobAllowed(src)
    if not Config.Jobs then return true end
    local name, grade = ServerConfig.GetJob(src)
    return name ~= nil and Config.Jobs[name] ~= nil and (grade or 0) >= Config.Jobs[name]
end

local function closeEnough(a, b, extra)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= Config.Distance + (extra or 0)
end

local function stop(src)
    local a = Active[src]
    Active[src] = nil
    Busy[src] = nil
    if a then Busy[a.target] = nil end
    return a
end

lib.callback.register('originrp_revive:start', function(src, target)
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return false end
    if Busy[src] or Busy[target] then return false, Config.Messages.busy end
    if not jobAllowed(src) then return false, Config.Messages.noJob end
    if not ServerConfig.HasKit(src) then return false, Config.Messages.noKit end
    if not closeEnough(src, target, 1.0) then return false, Config.Messages.tooFar end
    if not ServerConfig.IsDead(target) then return false, Config.Messages.notDead end

    Active[src] = { target = target, started = GetGameTimer() }
    Busy[src], Busy[target] = true, true
    TriggerClientEvent('originrp_revive:patientStart', target, src)
    return true
end)

-- Le secouriste annonce chaque étape : le patient joue l'animation correspondante
RegisterNetEvent('originrp_revive:step', function(step)
    local a = Active[source]
    if a and type(step) == 'string' then
        TriggerClientEvent('originrp_revive:patientStep', a.target, step)
    end
end)

RegisterNetEvent('originrp_revive:cancel', function()
    local a = stop(source)
    if a then TriggerClientEvent('originrp_revive:patientStop', a.target) end
end)

RegisterNetEvent('originrp_revive:finish', function()
    local src = source
    local a = Active[src]
    if not a then return end

    -- l'animation doit avoir réellement été jouée, et la personne toujours à côté
    if GetGameTimer() - a.started < totalDuration() - 800 or not closeEnough(src, a.target, 1.5) then
        stop(src)
        TriggerClientEvent('originrp_revive:patientStop', a.target)
        return notify(src, Config.Messages.cancelled, 'error')
    end
    if Config.ConsumeItem and not ServerConfig.RemoveKit(src) then
        stop(src)
        TriggerClientEvent('originrp_revive:patientStop', a.target)
        return notify(src, Config.Messages.noKit, 'error')
    end

    stop(src)
    ServerConfig.Revive(a.target)
    TriggerClientEvent('originrp_revive:patientStop', a.target, true)
    notify(src, Config.Messages.medicDone:format(ServerConfig.GetName(a.target)), 'success')
    notify(a.target, Config.Messages.patientDone:format(ServerConfig.GetName(src)), 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    local a = stop(src)
    if a then TriggerClientEvent('originrp_revive:patientStop', a.target) end
    for medic, b in pairs(Active) do
        if b.target == src then
            stop(medic)
            TriggerClientEvent('originrp_revive:medicCancel', medic)
        end
    end
end)
