local KVP_KEY = 'originrp_bracelet:wearers'
local Wearers = {}   -- identifiant -> true
local Pending = {}   -- source du poseur -> { target, started }

-- ─── Persistance ───────────────────────────────────────────────────────────

local function save()
    SetResourceKvp(KVP_KEY, json.encode(Wearers))
end

local function applyState(src)
    Player(src).state:set('bracelet', Wearers[ServerConfig.GetIdentifier(src)] == true, true)
end

CreateThread(function()
    local raw = GetResourceKvpString(KVP_KEY)
    Wearers = raw and json.decode(raw) or {}
    for _, id in ipairs(GetPlayers()) do applyState(tonumber(id)) end
end)

AddEventHandler('playerJoining', function()
    applyState(source)
end)

AddEventHandler('playerDropped', function()
    Pending[source] = nil
end)

-- ─── Utilitaires ───────────────────────────────────────────────────────────

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bracelet électronique',
        description = message,
        type = kind or 'inform',
        position = Config.NotifyPosition,
        icon = 'link',
    })
end

local function jobAllowed(src, jobs)
    if not jobs then return true end
    local name, grade = ServerConfig.GetJob(src)
    return name ~= nil and jobs[name] ~= nil and (grade or 0) >= jobs[name]
end

local function closeEnough(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= Config.TargetDistance + 1.5
end

local function hasBracelet(src)
    return Wearers[ServerConfig.GetIdentifier(src)] == true
end

local function setBracelet(src, value)
    Wearers[ServerConfig.GetIdentifier(src)] = value or nil
    save()
    applyState(src)
end

exports('HasBracelet', hasBracelet)
exports('SetBracelet', setBracelet)

-- ─── Pose ──────────────────────────────────────────────────────────────────

lib.callback.register('originrp_bracelet:start', function(src, target)
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return false end
    if not jobAllowed(src, Config.AllowedJobs) then return false, Config.Messages.noJob end
    if not ServerConfig.HasItem(src) then return false end
    if not closeEnough(src, target) then return false, Config.Messages.tooFar end
    if hasBracelet(target) then return false, Config.Messages.already end

    Pending[src] = { target = target, started = GetGameTimer() }
    TriggerClientEvent('originrp_bracelet:beingFitted', target, src, Config.Duration)
    return true
end)

RegisterNetEvent('originrp_bracelet:cancel', function()
    local src = source
    local p = Pending[src]
    Pending[src] = nil
    if p then TriggerClientEvent('originrp_bracelet:fitCancelled', p.target) end
end)

RegisterNetEvent('originrp_bracelet:finish', function()
    local src = source
    local p = Pending[src]
    Pending[src] = nil
    if not p then return end

    -- la pose doit avoir réellement duré ~3 s et la personne être toujours là
    if GetGameTimer() - p.started < Config.Duration - 400 then return end
    if not GetPlayerName(p.target) or not closeEnough(src, p.target) then
        notify(src, Config.Messages.tooFar, 'error')
        TriggerClientEvent('originrp_bracelet:fitCancelled', p.target)
        return
    end
    if hasBracelet(p.target) then return notify(src, Config.Messages.already, 'error') end
    if not ServerConfig.RemoveItem(src) then return end

    setBracelet(p.target, true)
    notify(src, Config.Messages.placed:format(ServerConfig.GetCharacterName(p.target)), 'success')
    notify(p.target, Config.Messages.received, 'warning')
end)

-- ─── Retrait (jobs autorisés) ──────────────────────────────────────────────

lib.callback.register('originrp_bracelet:remove', function(src, target)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false end
    if not jobAllowed(src, Config.RemoveJobs) then return false end
    if not closeEnough(src, target) or not hasBracelet(target) then return false end

    setBracelet(target, false)
    ServerConfig.GiveItem(src)
    notify(src, Config.Messages.removed:format(ServerConfig.GetCharacterName(target)), 'success')
    notify(target, Config.Messages.removedTarget, 'inform')
    return true
end)
