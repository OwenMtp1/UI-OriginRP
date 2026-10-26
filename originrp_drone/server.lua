local inv = exports.ox_inventory
local Cases = {}        -- id → mallette posée
local Drones = {}       -- netId → id de mallette
local Jammers = {}      -- id → { coords, radius, expires, entity }
local nextId, nextJam = 0, 0

local function model(key) local m = Config.Models[key]; return Config.CustomProps and m.custom or m.fallback end
local function notify(src, msg, kind) ServerConfig.Notify(src, msg, kind) end

local function spawn(key, coords, heading, bag, value)
    local e = CreateObjectNoOffset(model(key), coords.x, coords.y, coords.z, true, true, false)
    local t = GetGameTimer() + 3000
    while not DoesEntityExist(e) and GetGameTimer() < t do Wait(0) end
    if not DoesEntityExist(e) then return nil end
    SetEntityHeading(e, heading or 0.0); FreezeEntityPosition(e, true)
    if bag then Entity(e).state:set(bag, value, true) end
    return e
end

local function delete(netId)
    local e = netId and NetworkGetEntityFromNetworkId(netId)
    if e and e ~= 0 and DoesEntityExist(e) then DeleteEntity(e) end
end

-- batterie après recharge dans la mallette
local function charged(meta)
    if not meta.storedAt then return meta.battery end
    local gain = (os.time() - meta.storedAt) / Config.Battery.chargeSeconds * 100
    return math.min(100, meta.battery + gain)
end

local function defaults(meta)
    meta = meta or {}
    meta.serial = meta.serial or ('OR-D2-%04d'):format(math.random(0, 9999))
    meta.battery = meta.battery or 100
    meta.health = meta.health or Config.Health.max
    if meta.hasDrone == nil then meta.hasDrone = true end
    return meta
end

local function canUse(src, case)
    if case.owner == ServerConfig.Identifier(src) or not Config.SharedJobs then return true end
    local job, grade = ServerConfig.GetJob(src)
    return job and Config.SharedJobs[job] and grade >= Config.SharedJobs[job]
end

local function near(src, coords, dist)
    return #(GetEntityCoords(GetPlayerPed(src)) - coords) <= (dist or 4.0)
end

local function caseCoords(case)
    local e = NetworkGetEntityFromNetworkId(case.netId)
    return (e ~= 0 and DoesEntityExist(e)) and GetEntityCoords(e) or case.coords
end

local function swapCase(case, key)
    local e = NetworkGetEntityFromNetworkId(case.netId)
    local h = (e ~= 0 and DoesEntityExist(e)) and GetEntityHeading(e) or case.heading
    delete(case.netId)
    local n = spawn(key, case.coords, h, 'orpCase', case.id)
    case.netId = n and NetworkGetNetworkIdFromEntity(n) or case.netId
end

-- ─── Poser la mallette (utilisation de l'item) ─────────────────────────────
lib.callback.register('originrp_drone:placeCase', function(src, slot, coords, heading)
    local item = inv:GetSlot(src, slot)
    if not item or item.name ~= Config.Items.case or not near(src, coords, 3.0) then return false end
    local meta = defaults(item.metadata)
    if not inv:RemoveItem(src, Config.Items.case, 1, nil, slot) then return false end
    meta.battery = charged(meta); meta.storedAt = os.time()
    nextId = nextId + 1
    local case = { id = nextId, owner = ServerConfig.Identifier(src), coords = coords, heading = heading, meta = meta }
    local e = spawn('case', coords, heading, 'orpCase', case.id)
    if not e then inv:AddItem(src, Config.Items.case, 1, meta); return false end
    case.netId = NetworkGetNetworkIdFromEntity(e)
    Cases[case.id] = case
    return true, case.id
end)

lib.callback.register('originrp_drone:caseInfo', function(src, id)
    local c = Cases[id]; if not c then return nil end
    return { hasDrone = c.meta.hasDrone, deployed = c.drone ~= nil, destroyed = c.drone and c.drone.destroyed or false,
        pilot = c.drone and c.drone.pilot or nil, battery = math.floor(c.drone and c.drone.battery or charged(c.meta)),
        health = c.drone and c.drone.health or c.meta.health, serial = c.meta.serial, mine = canUse(src, c) }
end)

-- ─── Déployer le drone ─────────────────────────────────────────────────────
lib.callback.register('originrp_drone:deploy', function(src, id)
    local c = Cases[id]
    if not c then return false end
    if not canUse(src, c) then return false, Config.Messages.notOwner end
    if not c.meta.hasDrone then return false, Config.Messages.noDrone end
    if c.drone then return false end
    local cc = caseCoords(c)
    if not near(src, cc) then return false end
    swapCase(c, 'caseOpen')
    local h = math.rad(c.heading)
    local o = Config.Deploy.droneOffset
    local pos = vector3(cc.x + o.x * math.cos(h) - o.y * math.sin(h), cc.y + o.x * math.sin(h) + o.y * math.cos(h), cc.z)
    local e = spawn('drone', pos, c.heading, 'orpDrone', id)
    if not e then return false end
    local battery = charged(c.meta)
    c.drone = { netId = NetworkGetNetworkIdFromEntity(e), battery = battery, health = c.meta.health, flying = false }
    c.meta.hasDrone = false; c.meta.storedAt = nil
    Drones[c.drone.netId] = id
    Entity(e).state:set('orpHp', c.drone.health, true)
    return true, c.drone.netId
end)

-- ─── Prendre / lâcher la radiocommande ─────────────────────────────────────
lib.callback.register('originrp_drone:takeController', function(src, id)
    local c = Cases[id]
    if not c or not c.drone or c.drone.destroyed then return false end
    if not canUse(src, c) then return false, Config.Messages.notOwner end
    if c.drone.pilot and c.drone.pilot ~= src and GetPlayerPing(c.drone.pilot) > 0 then return false end
    if not near(src, caseCoords(c)) then return false end
    c.drone.pilot = src
    return true, { netId = c.drone.netId, battery = c.drone.battery, health = c.drone.health, serial = c.meta.serial,
        home = caseCoords(c) }
end)

RegisterNetEvent('originrp_drone:release', function(id)
    local c = Cases[id]
    if c and c.drone and c.drone.pilot == source then c.drone.pilot = nil; c.drone.flying = false end
end)

RegisterNetEvent('originrp_drone:flying', function(id, flying)
    local c = Cases[id]
    if c and c.drone and c.drone.pilot == source then c.drone.flying = flying and true or false end
end)

-- ─── Ranger le drone (recharge) ────────────────────────────────────────────
lib.callback.register('originrp_drone:store', function(src, id)
    local c = Cases[id]
    if not c or not c.drone or c.drone.destroyed or c.drone.flying then return false end
    if not canUse(src, c) then return false, Config.Messages.notOwner end
    local e = NetworkGetEntityFromNetworkId(c.drone.netId)
    local cc = caseCoords(c)
    if e == 0 or not DoesEntityExist(e) or #(GetEntityCoords(e) - cc) > 4.0 then return false, Config.Messages.tooFar end
    if not near(src, cc) then return false end
    Drones[c.drone.netId] = nil
    DeleteEntity(e)
    c.meta.hasDrone = true; c.meta.battery = c.drone.battery; c.meta.health = c.drone.health; c.meta.storedAt = os.time()
    c.drone = nil
    swapCase(c, 'case')
    return true
end)

-- ─── Ramasser la mallette ──────────────────────────────────────────────────
lib.callback.register('originrp_drone:pickupCase', function(src, id)
    local c = Cases[id]
    if not c or c.drone then return false end
    if not canUse(src, c) or not near(src, caseCoords(c)) then return false end
    if not inv:CanCarryItem(src, Config.Items.case, 1) then return false end
    delete(c.netId); Cases[id] = nil
    inv:AddItem(src, Config.Items.case, 1, c.meta)
    return true
end)

-- ─── Installer un drone neuf dans une mallette vide ────────────────────────
lib.callback.register('originrp_drone:install', function(src, id)
    local c = Cases[id]
    if not c or c.drone or c.meta.hasDrone or not canUse(src, c) then return false end
    if not inv:RemoveItem(src, Config.Items.drone, 1) then return false end
    c.meta.hasDrone = true; c.meta.battery = 100; c.meta.health = Config.Health.max; c.meta.storedAt = os.time()
    c.meta.serial = ('OR-D2-%04d'):format(math.random(0, 9999))
    return true
end)

-- ─── Dégâts : chocs, balles, explosions ────────────────────────────────────
local hitRate = {}
local function destroy(id)
    local c = Cases[id]; if not c or not c.drone or c.drone.destroyed then return end
    c.drone.destroyed = true; c.drone.health = 0; c.meta.health = 0
    local e = NetworkGetEntityFromNetworkId(c.drone.netId)
    if e ~= 0 then Entity(e).state:set('orpHp', 0, true) end
    TriggerClientEvent('originrp_drone:destroyed', -1, c.drone.netId, id)
    local owner = c.drone.pilot
    if owner then notify(owner, Config.Messages.destroyed, 'error') end
    -- filet de sécurité si personne ne fait tomber le drone
    SetTimeout(15000, function()
        if c.drone and c.drone.destroyed and not c.drone.wreck then
            local ent = NetworkGetEntityFromNetworkId(c.drone.netId)
            if ent ~= 0 and DoesEntityExist(ent) then
                local p = GetEntityCoords(ent)
                TriggerEvent('originrp_drone:_wreck', id, vector3(p.x, p.y, p.z), GetEntityHeading(ent))
            end
        end
    end)
end

RegisterNetEvent('originrp_drone:hit', function(netId, kind, value, weapon)
    local src = source
    local id = Drones[netId]; local c = id and Cases[id]
    if not c or not c.drone or c.drone.destroyed then return end
    local now = GetGameTimer()
    hitRate[src] = hitRate[src] or { t = now, n = 0 }
    if now - hitRate[src].t > 1000 then hitRate[src] = { t = now, n = 0 } end
    hitRate[src].n = hitRate[src].n + 1
    if hitRate[src].n > 12 then return end
    local e = NetworkGetEntityFromNetworkId(netId)
    if e == 0 or not DoesEntityExist(e) then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(e)) > 200.0 then return end
    local dmg = 0
    if kind == 'collision' then
        if c.drone.pilot ~= src then return end
        dmg = math.min(Config.Health.collisionMax, math.max(0, (tonumber(value) or 0) - Config.Health.collisionMinSpeed) * Config.Health.collisionDamage)
    elseif kind == 'bullet' then
        dmg = Config.Health.weaponDamage[weapon] or Config.Health.bulletDamage
    elseif kind == 'explosion' then
        dmg = 999
    end
    if dmg <= 0 then return end
    c.drone.health = math.max(0, c.drone.health - dmg)
    Entity(e).state:set('orpHp', c.drone.health, true)
    if c.drone.pilot then TriggerClientEvent('originrp_drone:health', c.drone.pilot, c.drone.health, kind) end
    if c.drone.health <= 0 then destroy(id) end
end)

-- le pilote signale que le drone abattu a touché le sol → épave fumante
local function makeWreck(id, coords, heading)
    local c = Cases[id]; if not c or not c.drone or c.drone.wreck then return end
    c.drone.wreck = true
    Drones[c.drone.netId] = nil
    delete(c.drone.netId)
    local w = spawn('wreck', coords, heading, 'orpWreck', id)
    if w then
        SetTimeout(Config.Wreck.lifetime * 1000, function() if DoesEntityExist(w) then DeleteEntity(w) end end)
    end
    c.drone = nil
end
RegisterNetEvent('originrp_drone:wreck', function(id, coords, heading)
    local c = Cases[id]
    if not c or not c.drone or not c.drone.destroyed then return end
    if c.drone.pilot and c.drone.pilot ~= source then return end
    makeWreck(id, coords, heading)
end)
AddEventHandler('originrp_drone:_wreck', makeWreck)

lib.callback.register('originrp_drone:takeWreck', function(src, netId)
    local e = NetworkGetEntityFromNetworkId(netId)
    if e == 0 or not DoesEntityExist(e) or not Entity(e).state.orpWreck then return false end
    if not near(src, GetEntityCoords(e), 3.0) then return false end
    DeleteEntity(e)
    inv:AddItem(src, Config.Items.wreck, 1)
    return true
end)

-- ─── Batterie : 2 h de vol, décompte côté serveur ──────────────────────────
CreateThread(function()
    local step = 5
    while true do
        Wait(step * 1000)
        for id, c in pairs(Cases) do
            local d = c.drone
            if d and not d.destroyed and d.flying then
                local before = d.battery
                d.battery = math.max(0, d.battery - step / Config.Battery.flightSeconds * 100)
                if d.pilot then TriggerClientEvent('originrp_drone:battery', d.pilot, d.battery) end
                if before > Config.Battery.landAt and d.battery <= Config.Battery.landAt and d.pilot then
                    TriggerClientEvent('originrp_drone:batteryEmpty', d.pilot)
                    notify(d.pilot, Config.Messages.batteryEmpty, 'warning')
                end
            end
        end
    end
end)

-- ─── Brouilleurs GPS ───────────────────────────────────────────────────────
local function syncJammers()
    local list = {}
    for _, j in pairs(Jammers) do list[#list + 1] = { x = j.coords.x, y = j.coords.y, z = j.coords.z, r = j.radius } end
    GlobalState.orpJammers = list
end

local function addJammer(coords, radius, seconds, entity)
    nextJam = nextJam + 1
    local jid = nextJam
    Jammers[jid] = { coords = coords, radius = radius or Config.Jammer.radius, expires = os.time() + (seconds or Config.Jammer.duration), entity = entity }
    syncJammers()
    return jid
end
local function removeJammer(jid)
    local j = Jammers[jid]; if not j then return end
    if j.entity and DoesEntityExist(j.entity) then DeleteEntity(j.entity) end
    Jammers[jid] = nil; syncJammers()
end
exports('AddJammer', addJammer)
exports('RemoveJammer', removeJammer)

lib.callback.register('originrp_drone:placeJammer', function(src, coords, heading)
    if not near(src, coords, 3.0) then return false end
    if not inv:RemoveItem(src, Config.Items.jammer, 1) then return false end
    local e = spawn('jammer', coords, heading)
    local jid = addJammer(coords, Config.Jammer.radius, Config.Jammer.duration, e)
    if e then Entity(e).state:set('orpJammer', jid, true) end
    return true
end)

lib.callback.register('originrp_drone:pickupJammer', function(src, jid)
    local j = Jammers[jid]
    if not j or not Config.Jammer.pickup or not near(src, j.coords, 3.0) then return false end
    removeJammer(jid)
    inv:AddItem(src, Config.Items.jammer, 1)
    return true
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for jid, j in pairs(Jammers) do if now >= j.expires then removeJammer(jid) end end
    end
end)

-- ─── Nettoyage ─────────────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    for _, c in pairs(Cases) do
        if c.drone and c.drone.pilot == src then c.drone.pilot = nil; c.drone.flying = false end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, c in pairs(Cases) do delete(c.netId); if c.drone then delete(c.drone.netId) end end
    for jid in pairs(Jammers) do removeJammer(jid) end
end)
