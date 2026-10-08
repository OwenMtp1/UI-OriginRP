local Scenes = {}    -- id -> { id, owner, ownerName, title, template, x, y, z, netIds, expires }
local Cooldown = {}  -- identifiant -> os.time() de la dernière création
local lastId = 0

-- ─── Utilitaires ───────────────────────────────────────────────────────────

local function cleanTitle(s, fallback)
    if type(s) ~= 'string' then return fallback end
    s = s:gsub('[<>]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    s = s:sub(1, Config.MaxTitle)
    return s ~= '' and s or fallback
end

local function publish()
    local list = {}
    for _, s in pairs(Scenes) do
        list[#list + 1] = {
            id = s.id, title = s.title, template = s.template, owner = s.ownerName,
            x = s.x, y = s.y, z = s.z, expires = s.expires,
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    GlobalState.scenes = list
end

local function nearby(x, y, z, radius)
    local center = vector3(x, y, z)
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local ped = GetPlayerPed(src)
        if ped ~= 0 and #(GetEntityCoords(ped) - center) <= radius then list[#list + 1] = src end
    end
    return list
end

local function notifyNearby(x, y, z, message)
    for _, src in ipairs(nearby(x, y, z, Config.Radius)) do
        TriggerClientEvent('originrp_scene:notify', src, message)
    end
end

local function endScene(scene, notifyPlayers)
    for _, nid in ipairs(scene.netIds) do
        local ent = NetworkGetEntityFromNetworkId(nid)
        if ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    Scenes[scene.id] = nil
    if notifyPlayers then
        notifyNearby(scene.x, scene.y, scene.z, Config.Notify.ended:format(scene.title))
    end
    publish()
end

local function ownerScene(ident)
    for _, s in pairs(Scenes) do
        if s.owner == ident then return s end
    end
end

-- ─── Création ──────────────────────────────────────────────────────────────

lib.callback.register('originrp_scene:create', function(src, data)
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then return false, 'Données invalides.' end

    local tpl = Config.Templates[data.template]
    if not tpl then return false, 'Décor inconnu.' end
    if not ServerConfig.HasKit(src) then return false, 'Il te faut un kit de mise en scène.' end

    local ident = ServerConfig.GetIdentifier(src)
    if ownerScene(ident) then return false, 'Tu as déjà une scène active.' end

    local now = os.time()
    if Cooldown[ident] and now - Cooldown[ident] < Config.Cooldown then
        return false, ('Attends encore %d s avant une nouvelle scène.'):format(Config.Cooldown - (now - Cooldown[ident]))
    end

    local c = data.coords
    if type(c.x) ~= 'number' or type(c.y) ~= 'number' or type(c.z) ~= 'number' then
        return false, 'Position invalide.'
    end
    local center = vector3(c.x, c.y, c.z)
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - center) > Config.PlaceDistance + 3.0 then
        return false, 'La scène est trop loin de toi.'
    end

    local nids = data.netIds
    if type(nids) ~= 'table' or #nids == 0 or #nids > Config.MaxProps then
        return false, 'Décor invalide.'
    end
    local valid = {}
    for _, nid in ipairs(nids) do
        local ent = NetworkGetEntityFromNetworkId(nid)
        if ent == 0 or not DoesEntityExist(ent) then return false, 'Décor introuvable, réessaie.' end
        if #(GetEntityCoords(ent) - center) > Config.Spread + 3.0 then return false, 'Décor mal placé.' end
        valid[#valid + 1] = nid
    end

    local minutes = math.floor(math.min(math.max(tonumber(data.minutes) or Config.DefaultMinutes, 1), Config.MaxMinutes))
    local title = cleanTitle(data.title, tpl.label)
    local ownerName = ServerConfig.GetName(src)

    lastId = lastId + 1
    Scenes[lastId] = {
        id = lastId, owner = ident, ownerName = ownerName, title = title, template = data.template,
        x = c.x, y = c.y, z = c.z, netIds = valid, expires = now + minutes * 60,
    }
    Cooldown[ident] = now
    publish()

    notifyNearby(c.x, c.y, c.z, Config.Notify.created:format(title, ownerName))
    return true, 'Scène lancée.'
end)

-- ─── Fin de scène ──────────────────────────────────────────────────────────

lib.callback.register('originrp_scene:mine', function(src)
    local s = ownerScene(ServerConfig.GetIdentifier(src))
    return s and s.id or nil
end)

lib.callback.register('originrp_scene:end', function(src, id)
    local s = Scenes[tonumber(id)]
    if not s then return false, 'Scène introuvable.' end
    if s.owner ~= ServerConfig.GetIdentifier(src) and not ServerConfig.IsAdmin(src) then
        return false, 'Ce n\'est pas ta scène.'
    end
    endScene(s, true)
    return true, 'Scène terminée.'
end)

-- ─── Expiration automatique ────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(15000)
        local now = os.time()
        for _, s in pairs(Scenes) do
            if s.expires <= now then endScene(s, true) end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, s in pairs(Scenes) do endScene(s, false) end
end)

CreateThread(publish)
