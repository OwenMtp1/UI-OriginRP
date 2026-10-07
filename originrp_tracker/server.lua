--[[
    Registre des traceurs (clé = numéro de série) :
    {
        serial, owner (identifiant), name (ou nil), active,
        state = 'pocket' | 'world',
        holder = serverId qui l'a en poche (state 'pocket'),
        netId = objet dans le monde (state 'world'),
    }
    owner / name / active sont sauvegardés (KVP), le reste est runtime.
]]

local KVP_KEY = 'originrp_tracker:registry'
local Trackers = {}
local Inbox = {}        -- identifiant -> { messages }
local PendingThrow = {} -- serial -> source qui vient de le lancer

-- ─── Persistance ───────────────────────────────────────────────────────────

local function save()
    local data = {}
    for serial, t in pairs(Trackers) do
        if t.owner then data[serial] = { owner = t.owner, name = t.name, active = t.active } end
    end
    SetResourceKvp(KVP_KEY, json.encode(data))
end

CreateThread(function()
    local raw = GetResourceKvpString(KVP_KEY)
    for serial, t in pairs(raw and json.decode(raw) or {}) do
        Trackers[serial] = { serial = serial, owner = t.owner, name = t.name, active = t.active, state = 'pocket' }
    end
end)

-- ─── Utilitaires ───────────────────────────────────────────────────────────

local function newSerial()
    local serial
    repeat serial = ('%04X'):format(math.random(0, 0xFFFF)) until not Trackers[serial]
    return serial
end

local function displayName(t)
    return t.name and Config.RenamedName:format(t.name) or Config.DefaultName:format(t.serial)
end

local function sourceOf(identifier)
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if ServerConfig.GetIdentifier(src) == identifier then return src end
    end
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Traceur GPS', description = message, type = kind or 'inform' })
end

-- Message envoyé dans l'outil de suivi du propriétaire (stocké s'il est hors ligne)
local function pushMessage(identifier, text)
    Inbox[identifier] = Inbox[identifier] or {}
    local msg = { text = text, time = os.time() }
    table.insert(Inbox[identifier], 1, msg)
    if #Inbox[identifier] > 20 then table.remove(Inbox[identifier]) end
    local src = sourceOf(identifier)
    if src then
        TriggerClientEvent('originrp_tracker:message', src, msg)
        notify(src, text, 'warning')
    end
end

local function trackerEntity(t)
    if t.state ~= 'world' or not t.netId then return end
    local ent = NetworkGetEntityFromNetworkId(t.netId)
    if ent ~= 0 and DoesEntityExist(ent) then return ent end
end

local function setEntityState(t)
    local ent = trackerEntity(t)
    if ent then Entity(ent).state:set('gpsTracker', { serial = t.serial, active = t.active == true }, true) end
end

local function getOrCreate(serial)
    Trackers[serial] = Trackers[serial] or { serial = serial, state = 'pocket' }
    return Trackers[serial]
end

-- Rattache les traceurs présents dans les poches du joueur (holder + numéro de série)
local function scanPockets(src)
    local result = {}
    for _, item in ipairs(ServerConfig.GetTrackerSlots(src)) do
        local meta = item.metadata
        if not meta.serial then
            meta.serial = newSerial()
            meta.description = ('N° de série : %s'):format(meta.serial)
            ServerConfig.SetMetadata(src, item.slot, meta)
        end
        local t = getOrCreate(meta.serial)
        t.state, t.holder, t.netId = 'pocket', src, nil
        result[#result + 1] = { slot = item.slot, tracker = t }
    end
    return result
end

-- ─── Données de la tablette ────────────────────────────────────────────────

local function tabletData(src)
    local me = ServerConfig.GetIdentifier(src)
    local pocket, mine = {}, {}

    for _, entry in ipairs(scanPockets(src)) do
        local t = entry.tracker
        if t.owner ~= me then
            pocket[#pocket + 1] = {
                slot = entry.slot,
                serial = t.serial,
                status = t.owner and (t.active and 'active' or 'foreign') or 'new',
            }
        end
    end

    for serial, t in pairs(Trackers) do
        if t.owner == me then
            mine[#mine + 1] = {
                serial = serial,
                name = t.name,
                label = displayName(t),
                active = t.active == true,
                location = t.state == 'world' and (trackerEntity(t) and 'world' or 'lost') or 'pocket',
            }
        end
    end
    table.sort(mine, function(a, b) return a.serial < b.serial end)

    return { mine = mine, pocket = pocket, messages = Inbox[me] or {} }
end

lib.callback.register('originrp_tracker:getData', function(src)
    return tabletData(src)
end)

-- Synchronisation d'un traceur présent dans la poche
lib.callback.register('originrp_tracker:sync', function(src, slot, force)
    local item = ServerConfig.GetSlot(src, slot)
    if not item or not item.metadata or not item.metadata.serial then
        return { ok = false, message = 'Traceur introuvable dans ta poche.' }
    end

    local me = ServerConfig.GetIdentifier(src)
    local t = getOrCreate(item.metadata.serial)
    if t.owner == me then return { ok = false, message = 'Ce traceur est déjà synchronisé.' } end

    if t.owner and t.active and not force then
        return { ok = false, needForce = true }
    end

    if t.owner then
        pushMessage(t.owner, ('Tracker %s a été déconnecté de force pour être synchronisé sur un autre appareil.')
            :format(t.name or ('#' .. t.serial)))
    end

    t.owner, t.name, t.active = me, nil, false
    t.state, t.holder = 'pocket', src
    save()
    return { ok = true, message = ('Traceur #%s synchronisé.'):format(t.serial), data = tabletData(src) }
end)

lib.callback.register('originrp_tracker:toggle', function(src, serial)
    local t = Trackers[serial]
    if not t or t.owner ~= ServerConfig.GetIdentifier(src) then return end
    t.active = not t.active
    setEntityState(t)
    save()
    return tabletData(src)
end)

lib.callback.register('originrp_tracker:rename', function(src, serial, name)
    local t = Trackers[serial]
    if not t or t.owner ~= ServerConfig.GetIdentifier(src) or type(name) ~= 'string' then return end
    name = name:gsub('[<>]', ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, Config.MaxNameLength)
    t.name = name ~= '' and name or nil
    save()
    return tabletData(src)
end)

lib.callback.register('originrp_tracker:forget', function(src, serial)
    local t = Trackers[serial]
    if not t or t.owner ~= ServerConfig.GetIdentifier(src) then return end
    t.owner, t.name, t.active = nil, nil, false
    setEntityState(t)
    save()
    return tabletData(src)
end)

-- ─── Lancer / poser / ramasser / détruire ──────────────────────────────────

lib.callback.register('originrp_tracker:throw', function(src, slot)
    local item = ServerConfig.GetSlot(src, slot)
    if not item then return end
    local meta = item.metadata or {}
    local serial = meta.serial or newSerial()
    if not ServerConfig.RemoveSlot(src, slot) then return end

    local t = getOrCreate(serial)
    t.state, t.holder = 'thrown', nil
    PendingThrow[serial] = src
    return serial
end)

RegisterNetEvent('originrp_tracker:placed', function(serial, netId)
    local src = source
    if PendingThrow[serial] ~= src then return end
    PendingThrow[serial] = nil

    local t = getOrCreate(serial)
    t.state, t.netId, t.holder = 'world', netId, nil
    setEntityState(t)
end)

lib.callback.register('originrp_tracker:pickup', function(src, netId)
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent == 0 or not DoesEntityExist(ent) then return false end

    local bag = Entity(ent).state.gpsTracker
    if not bag then return false end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - GetEntityCoords(ent)) > Config.PickupDistance + 1.5 then return false end

    local t = getOrCreate(bag.serial)
    local meta = { serial = t.serial, description = ('N° de série : %s'):format(t.serial) }
    if not ServerConfig.GiveTracker(src, meta) then
        notify(src, "Tu n'as plus de place sur toi.", 'error')
        return false
    end

    DeleteEntity(ent)
    t.state, t.netId, t.holder = 'pocket', nil, src
    return true
end)

RegisterNetEvent('originrp_tracker:shot', function(netId)
    local src = source
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent == 0 or not DoesEntityExist(ent) then return end
    local bag = Entity(ent).state.gpsTracker
    if not bag then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 150.0 then return end

    local coords = GetEntityCoords(ent)
    DeleteEntity(ent)
    local t = Trackers[bag.serial]
    if t then
        if t.owner then pushMessage(t.owner, ('%s a été détruit (signal perdu).'):format(displayName(t))) end
        Trackers[bag.serial] = nil
        save()
    end
    TriggerClientEvent('originrp_tracker:destroyedFx', -1, coords)
end)

-- ─── Points sur la carte ───────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        local perOwner = {}
        for serial, t in pairs(Trackers) do
            if t.owner and t.active then
                local coords
                local ent = trackerEntity(t)
                if ent then
                    coords = GetEntityCoords(ent)
                elseif t.state == 'pocket' and t.holder and GetPlayerPed(t.holder) ~= 0 then
                    coords = GetEntityCoords(GetPlayerPed(t.holder))
                end
                if coords then
                    perOwner[t.owner] = perOwner[t.owner] or {}
                    perOwner[t.owner][serial] = { x = coords.x, y = coords.y, z = coords.z, label = displayName(t) }
                end
            end
        end
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            TriggerClientEvent('originrp_tracker:blips', src, perOwner[ServerConfig.GetIdentifier(src)] or {})
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for _, t in pairs(Trackers) do
        if t.holder == src then t.holder = nil end
    end
end)
