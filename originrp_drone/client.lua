-- Mallette, déploiement, radiocommande, épave, brouilleurs, dégâts par balles
local function model(key) local m = Config.Models[key]; return (Config.CustomProps and IsModelInCdimage(m.custom)) and m.custom or m.fallback end
local function notify(msg, kind) lib.notify({ title = 'Drone OR-D2', description = msg, type = kind or 'inform', icon = 'helicopter', position = Config.NotifyPosition }) end
local function anim(a, flag, dur) lib.requestAnimDict(a[1]); TaskPlayAnim(PlayerPedId(), a[1], a[2], 3.0, -3.0, dur or -1, flag or 0, 0.0, false, false, false) end
Drone = { notify = notify, model = model, anim = anim }

local function holdProp(key, bone, off, rot)
    local m = model(key); lib.requestModel(m, 3000)
    local ped = PlayerPedId()
    local o = CreateObject(m, GetEntityCoords(ped), false, false, false)
    AttachEntityToEntity(o, ped, GetPedBoneIndex(ped, bone), off.x, off.y, off.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(m)
    return o
end
Drone.holdProp = holdProp

local function progress(label, ms, a)
    return lib.progressBar({ duration = ms, label = label, useWhileDead = false, canCancel = true,
        disable = { move = true, car = true, combat = true }, anim = a and { dict = a[1], clip = a[2], flag = 1 } or nil })
end

-- ─── Item : poser la mallette ──────────────────────────────────────────────
exports('useCase', function(data, slot)
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.65, 0.0)
    local ok, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    pos = vector3(pos.x, pos.y, ok and z or pos.z - 1.0)
    local hand = holdProp('case', 57005, vector3(0.12, 0.0, -0.02), vector3(0.0, 280.0, 53.0))
    local done = progress('Pose de la mallette…', 1600, Config.Anims.place)
    DeleteEntity(hand); ClearPedTasks(ped)
    if not done then return end
    lib.callback.await('originrp_drone:placeCase', false, slot.slot or slot, pos, GetEntityHeading(ped) + 180.0)
end)

-- ─── Options ALT sur la mallette ───────────────────────────────────────────
local function caseId(entity) return Entity(entity).state.orpCase end
local cache = {}
-- état de la mallette (rafraîchi en arrière-plan, jamais bloquant pour le menu ALT)
local function info(entity)
    local id = caseId(entity); if not id then return nil end
    local c = cache[id]
    if not c then c = { t = 0 }; cache[id] = c end
    if not c.busy and GetGameTimer() - c.t > 800 then
        c.busy = true
        lib.callback('originrp_drone:caseInfo', false, function(v) c.v = v; c.t = GetGameTimer(); c.busy = false end, id)
    end
    return c.v
end

local function deploy(entity)
    local id = caseId(entity)
    TaskTurnPedToFaceEntity(PlayerPedId(), entity, 600); Wait(600)
    -- loquets → couvercle → le drone sort replié → bras dépliés à la main
    local done = progress('Déploiement du drone…', Config.Deploy.duration, Config.Anims.kneel)
    if not done then return end
    local ok, err = lib.callback.await('originrp_drone:deploy', false, id)
    ClearPedTasks(PlayerPedId())
    if not ok then if err then notify(err, 'error') end return end
    cache[id] = nil
    notify(Config.Messages.deployed, 'success')
end

local function takeController(entity)
    local id = caseId(entity)
    local done = progress('Prise de la radiocommande…', Config.Deploy.pickupCtrl, Config.Anims.kneel)
    if not done then return end
    local ok, d = lib.callback.await('originrp_drone:takeController', false, id)
    ClearPedTasks(PlayerPedId())
    if not ok then if d then notify(d, 'error') end return end
    cache[id] = nil
    Drone.startPiloting(id, d)
end

local function store(entity)
    local id = caseId(entity)
    local done = progress('Rangement du drone…', 3500, Config.Anims.kneel)
    ClearPedTasks(PlayerPedId())
    if not done then return end
    local ok, err = lib.callback.await('originrp_drone:store', false, id)
    if not ok then if err then notify(err, 'error') end return end
    cache[id] = nil
    notify(Config.Messages.stored, 'success')
end

local function pickup(entity)
    local id = caseId(entity)
    local done = progress('Fermeture de la mallette…', 1800, Config.Anims.pickup)
    ClearPedTasks(PlayerPedId())
    if done then lib.callback.await('originrp_drone:pickupCase', false, id); cache[id] = nil end
end

local function install(entity)
    local id = caseId(entity)
    if progress('Installation du drone…', 3000, Config.Anims.kneel) then lib.callback.await('originrp_drone:install', false, id); cache[id] = nil end
    ClearPedTasks(PlayerPedId())
end

local caseModels = {}
for _, k in ipairs({ 'case', 'caseOpen' }) do caseModels[#caseModels + 1] = Config.Models[k].custom; caseModels[#caseModels + 1] = Config.Models[k].fallback end

exports.ox_target:addModel(caseModels, {
    { name = 'orp_drone_deploy', icon = 'fa-solid fa-helicopter', label = 'Déployer le drone', distance = 2.0,
      canInteract = function(e) local i = info(e); return i and i.mine and i.hasDrone and not i.deployed end, onSelect = function(d) deploy(d.entity) end },
    { name = 'orp_drone_ctrl', icon = 'fa-solid fa-gamepad', label = 'Prendre la télécommande', distance = 2.0,
      canInteract = function(e) local i = info(e); return i and i.mine and i.deployed and not i.destroyed and not i.pilot and not Drone.piloting end, onSelect = function(d) takeController(d.entity) end },
    { name = 'orp_drone_store', icon = 'fa-solid fa-box', label = 'Ranger le drone', distance = 2.0,
      canInteract = function(e) local i = info(e); return i and i.mine and i.deployed and not i.destroyed and not i.pilot end, onSelect = function(d) store(d.entity) end },
    { name = 'orp_drone_install', icon = 'fa-solid fa-screwdriver-wrench', label = 'Installer un drone neuf', distance = 2.0, items = Config.Items.drone,
      canInteract = function(e) local i = info(e); return i and i.mine and not i.hasDrone and not i.deployed end, onSelect = function(d) install(d.entity) end },
    { name = 'orp_drone_battery', icon = 'fa-solid fa-battery-half', label = 'État de la batterie', distance = 2.0,
      canInteract = function(e) return info(e) ~= nil end,
      onSelect = function(d) local i = info(d.entity); notify(('%s · batterie %d %% · état %d %%'):format(i.serial, i.battery, i.health)) end },
    { name = 'orp_drone_pickup', icon = 'fa-solid fa-hand', label = 'Ramasser la mallette', distance = 2.0,
      canInteract = function(e) local i = info(e); return i and i.mine and not i.deployed end, onSelect = function(d) pickup(d.entity) end },
})

-- ─── Épave : récupérer ─────────────────────────────────────────────────────
exports.ox_target:addModel({ Config.Models.wreck.custom, Config.Models.wreck.fallback }, {
    { name = 'orp_drone_wreck', icon = 'fa-solid fa-hand', label = "Récupérer l'épave", distance = 2.0,
      canInteract = function(e) return Entity(e).state.orpWreck ~= nil end,
      onSelect = function(d) if progress("Récupération de l'épave…", 2500, Config.Anims.pickup) then lib.callback.await('originrp_drone:takeWreck', false, NetworkGetNetworkIdFromEntity(d.entity)) end ClearPedTasks(PlayerPedId()) end },
})

-- ─── Brouilleur GPS ────────────────────────────────────────────────────────
exports('useJammer', function()
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.6, -0.98)
    if progress('Mise en route du brouilleur…', 2000, Config.Anims.kneel) then
        if lib.callback.await('originrp_drone:placeJammer', false, pos, GetEntityHeading(ped)) then notify(Config.Messages.jammerPlaced, 'success') end
    end
    ClearPedTasks(ped)
end)
exports.ox_target:addModel({ Config.Models.jammer.custom }, {
    { name = 'orp_jammer_pickup', icon = 'fa-solid fa-tower-broadcast', label = 'Ramasser le brouilleur', distance = 2.0,
      canInteract = function(e) return Config.Jammer.pickup and Entity(e).state.orpJammer ~= nil end,
      onSelect = function(d) lib.callback.await('originrp_drone:pickupJammer', false, Entity(d.entity).state.orpJammer) end },
})

-- Brouillage : un point est-il dans la zone d'un brouilleur actif ?
function Drone.jammed(coords)
    for _, j in ipairs(GlobalState.orpJammers or {}) do
        if #(coords - vector3(j.x, j.y, j.z)) <= j.r then return true end
    end
    return false
end
exports('IsJammed', Drone.jammed)

-- ─── Effets visibles par tous : feux des drones, fumée noire des épaves ────
local smokes = {}
CreateThread(function()
    while true do
        local sleep = 500
        local me = GetEntityCoords(PlayerPedId())
        for _, obj in ipairs(GetGamePool('CObject')) do
            local st = Entity(obj).state
            if st.orpDrone and #(GetEntityCoords(obj) - me) < 150.0 then
                sleep = 0
                local hp = st.orpHp or 100
                if hp > 0 and (GetGameTimer() % 1000) < 500 then   -- point rouge clignotant à l'avant
                    local nose = GetOffsetFromEntityInWorldCoords(obj, 0.0, 0.16, 0.12)
                    DrawLightWithRange(nose.x, nose.y, nose.z, 255, 20, 30, 0.8, 6.0)
                end
                if hp > 0 and hp < 40 and not smokes[obj] then   -- drone touché : il fume
                    lib.requestNamedPtfxAsset(Config.Wreck.trail.dict)
                    UseParticleFxAsset(Config.Wreck.trail.dict)
                    smokes[obj] = StartParticleFxLoopedOnEntity(Config.Wreck.trail.name, obj, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, Config.Wreck.trail.scale, false, false, false)
                end
            elseif st.orpWreck and not smokes[obj] and #(GetEntityCoords(obj) - me) < 200.0 then
                lib.requestNamedPtfxAsset(Config.Wreck.smoke.dict)
                UseParticleFxAsset(Config.Wreck.smoke.dict)
                smokes[obj] = StartParticleFxLoopedOnEntity(Config.Wreck.smoke.name, obj, 0.0, 0.0, 0.15, 0.0, 0.0, 0.0, Config.Wreck.smoke.scale, false, false, false)
            end
        end
        for obj, fx in pairs(smokes) do if not DoesEntityExist(obj) then StopParticleFxLooped(fx, false); smokes[obj] = nil end end
        Wait(sleep)
    end
end)

-- ─── Tirs sur un drone : détectés par le tireur ────────────────────────────
local function droneAt(coords, radius)
    for _, obj in ipairs(GetGamePool('CObject')) do
        if Entity(obj).state.orpDrone and (Entity(obj).state.orpHp or 1) > 0 and #(GetEntityCoords(obj) - coords) < radius then return obj end
    end
end
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local hit, coords = GetPedLastWeaponImpactCoord(ped)
            local obj = hit and droneAt(coords, 0.6)
            if not obj then   -- balle qui traverse : rayon depuis l'arme
                local cam = GetGameplayCamCoord(); local rot = GetGameplayCamRot(2)
                local rx, rz = math.rad(rot.x), math.rad(rot.z)
                local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
                local ray = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, cam.x + dir.x * 200, cam.y + dir.y * 200, cam.z + dir.z * 200, 16, ped, 0)
                local _, h, _, _, ent = GetShapeTestResult(ray)
                if h == 1 and ent ~= 0 and Entity(ent).state.orpDrone then obj = ent end
            end
            if obj then TriggerServerEvent('originrp_drone:hit', NetworkGetNetworkIdFromEntity(obj), 'bullet', 0, GetSelectedPedWeapon(ped)) end
            Wait(0)
        else
            Wait(IsPedArmed(ped, 4) and 0 or 400)
        end
    end
end)
