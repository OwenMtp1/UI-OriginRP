-- Pilotage du drone : vol, caméra, vie, batterie, liaison radio (portée / brouillage)
local P = nil            -- session de pilotage en cours
Drone.piloting = false

local K = Config.Keys
local function lerp(a, b, k) return a + (b - a) * k end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function ui(data) SendNUIMessage(data) end

local function setVision(v)
    SetNightvision(v == 2); SetSeethrough(v == 1)
end

local function holdController(mode)
    local ped = PlayerPedId()
    if P.rc and DoesEntityExist(P.rc) then DeleteEntity(P.rc) end
    ClearPedTasks(ped)
    if mode == 'held' then
        local a = Config.RCAttach
        P.rc = Drone.holdProp('controller', a.bone, a.offset, a.rotation)
        Drone.anim(Config.Anims.holdRC, 49)
    else
        -- posée au sol devant le pilote, il reste accroupi devant l'écran
        local m = Drone.model('controller'); lib.requestModel(m, 3000)
        local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.55, -0.97)
        P.rc = CreateObject(m, pos.x, pos.y, pos.z, true, true, false)
        SetEntityHeading(P.rc, GetEntityHeading(ped) + 180.0); PlaceObjectOnGroundProperly(P.rc); FreezeEntityPosition(P.rc, true)
        Drone.anim(Config.Anims.kneelIdle, 1)
    end
    P.mode = mode
end

local function stopPiloting()
    if not P then return end
    local s = P; P = nil; Drone.piloting = false
    setVision(0)
    RenderScriptCams(false, true, 600, true, true)
    if s.cam then DestroyCam(s.cam, false) end
    if s.rc and DoesEntityExist(s.rc) then DeleteEntity(s.rc) end
    ClearPedTasks(PlayerPedId())
    if s.trail then StopParticleFxLooped(s.trail, false) end
    if DoesEntityExist(s.ent) and not s.destroyed then
        SetEntityVelocity(s.ent, 0.0, 0.0, 0.0); SetEntityHasGravity(s.ent, true)
        PlaceObjectOnGroundProperly(s.ent); FreezeEntityPosition(s.ent, true)
    end
    TriggerServerEvent('originrp_drone:flying', s.id, false)
    TriggerServerEvent('originrp_drone:release', s.id)
    ui({ action = 'close' })
end

function Drone.startPiloting(id, d)
    local ent = NetToObj(d.netId)
    local t = GetGameTimer() + 3000
    while (not DoesEntityExist(ent) or not NetworkHasControlOfEntity(ent)) and GetGameTimer() < t do
        ent = NetToObj(d.netId); NetworkRequestControlOfEntity(ent); Wait(0)
    end
    if not DoesEntityExist(ent) then return end
    P = { id = id, ent = ent, netId = d.netId, battery = d.battery, health = d.health, home = d.home, serial = d.serial,
        vel = vector3(0, 0, 0), yaw = GetEntityHeading(ent), yawV = 0.0, pitch = 0.0, roll = 0.0, camPitch = -15.0,
        fov = Config.Flight.fovMax, vision = 0, light = false, rec = false, recT = 0, flying = false,
        auto = nil, jamT = 0, lastHit = 0, warned = {}, signal = 'ok' }
    Drone.piloting = true
    FreezeEntityPosition(ent, false); SetEntityDynamic(ent, true); SetEntityHasGravity(ent, false); SetEntityCollision(ent, true, true)
    ActivatePhysics(ent)
    holdController('held')
    P.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    AttachCamToEntity(P.cam, ent, 0.0, 0.16, -0.07, true)
    SetCamFov(P.cam, P.fov)
    RenderScriptCams(true, true, 700, true, true)
    ui({ action = 'open', serial = d.serial })
    CreateThread(function() Drone.loop() end)
end

-- ─── Événements serveur ────────────────────────────────────────────────────
RegisterNetEvent('originrp_drone:battery', function(v) if P then P.battery = v end end)
RegisterNetEvent('originrp_drone:health', function(hp, kind) if P then P.health = hp; ui({ action = 'hit', hp = hp, kind = kind }) end end)
RegisterNetEvent('originrp_drone:batteryEmpty', function() if P then P.auto = 'land'; P.battery = 0 end end)

RegisterNetEvent('originrp_drone:destroyed', function(netId, id)
    if not P or P.netId ~= netId then return end
    P.destroyed = true; P.signal = 'destroyed'
    ui({ action = 'nosignal', reason = 'destroyed' })
    local ent = P.ent
    -- chute libre en vrille avec traînée de fumée noire
    lib.requestNamedPtfxAsset(Config.Wreck.trail.dict); UseParticleFxAsset(Config.Wreck.trail.dict)
    P.trail = StartParticleFxLoopedOnEntity(Config.Wreck.trail.name, ent, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, Config.Wreck.trail.scale * 1.6, false, false, false)
    SetEntityHasGravity(ent, true)
    local v = GetEntityVelocity(ent)
    SetEntityVelocity(ent, v.x * 0.6, v.y * 0.6, math.min(v.z, -1.0))
    SetEntityAngularVelocity(ent, math.random() * 4 - 2, math.random() * 4 - 2, 6.0)
    local start = GetGameTimer()
    CreateThread(function()
        while DoesEntityExist(ent) and GetGameTimer() - start < 9000 do
            if GetGameTimer() - start > 600 and (GetEntityHeightAboveGround(ent) < 0.6 or #(GetEntityVelocity(ent)) < 0.4) then break end
            Wait(50)
        end
        if DoesEntityExist(ent) then
            local p = GetEntityCoords(ent)
            TriggerServerEvent('originrp_drone:wreck', id, vector3(p.x, p.y, p.z - math.max(0.0, GetEntityHeightAboveGround(ent) - 0.05)), GetEntityHeading(ent))
        end
        Wait(4500)   -- l'écran reste sur « AUCUN SIGNAL »
        stopPiloting()
    end)
end)

-- ─── Boucle de vol ─────────────────────────────────────────────────────────
function Drone.loop()
    local lastUi, lastFlying = 0, false
    while P do
        local dt = GetFrameTime()
        local ent, ped = P.ent, PlayerPedId()
        if not DoesEntityExist(ent) then stopPiloting(); break end
        DisableAllControlActions(0); EnableControlAction(0, 249, true)   -- push-to-talk reste actif
        local pos, me = GetEntityCoords(ent), GetEntityCoords(ped)
        local dist = #(pos - me)
        local agl = GetEntityHeightAboveGround(ent)

        -- liaison radio
        if not P.destroyed then
            if Drone.jammed(pos) or Drone.jammed(me) then P.signal = 'jammed'
            elseif dist > Config.Signal.range then P.signal = 'range'
            elseif dist > Config.Signal.weakFrom then P.signal = 'weak'
            else P.signal = 'ok' end
        end
        local linked = P.signal == 'ok' or P.signal == 'weak'

        -- commandes
        local fwd, side, up, turn = 0.0, 0.0, 0.0, 0.0
        if linked and not P.destroyed and not P.auto then
            fwd = GetDisabledControlNormal(0, 32) - GetDisabledControlNormal(0, 33)
            side = GetDisabledControlNormal(0, 35) - GetDisabledControlNormal(0, 34)
            up = (IsDisabledControlPressed(0, K.up) and 1 or 0) - (IsDisabledControlPressed(0, K.down) and 1 or 0)
            turn = (IsDisabledControlPressed(0, K.yawRight) and 1 or 0) - (IsDisabledControlPressed(0, K.yawLeft) and 1 or 0)
            P.camPitch = clamp(P.camPitch - GetDisabledControlNormal(0, 2) * 6.0, -89.0, 15.0)
            if IsDisabledControlJustPressed(0, K.zoomIn) then P.fov = math.max(Config.Flight.fovMin, P.fov / 1.25) end
            if IsDisabledControlJustPressed(0, K.zoomOut) then P.fov = math.min(Config.Flight.fovMax, P.fov * 1.25) end
            if IsDisabledControlJustPressed(0, K.vision) then P.vision = (P.vision + 1) % 3; setVision(P.vision) end
            if IsDisabledControlJustPressed(0, K.light) then P.light = not P.light end
            if IsDisabledControlJustPressed(0, K.rec) then P.rec = not P.rec; P.recT = 0 end
            if IsDisabledControlJustPressed(0, K.rth) then P.auto = 'rth' end
        elseif P.auto and IsDisabledControlJustPressed(0, K.rth) and P.auto == 'rth' then P.auto = nil end
        if IsDisabledControlJustPressed(0, K.place) and not P.destroyed then holdController(P.mode == 'held' and 'placed' or 'held') end
        if IsDisabledControlJustPressed(0, K.exit) and not P.destroyed then
            if P.flying then P.auto = 'land'; P.exitAfter = true else stopPiloting(); break end
        end

        -- pilotes automatiques : retour, atterrissage, brouillage, batterie
        if P.signal == 'range' and not P.destroyed then P.auto = 'rth' end
        if P.battery <= Config.Battery.landAt and P.flying then P.auto = 'land' end
        if P.signal == 'jammed' then
            P.jamT = P.jamT + dt
            fwd, side, turn = math.sin(GetGameTimer() / 900) * 0.08, math.cos(GetGameTimer() / 1100) * 0.08, 0.0   -- dérive sans GPS
            up = P.jamT > Config.Signal.jamLandAfter and -0.35 or 0.0
        else P.jamT = 0 end
        if P.auto == 'rth' and linked == false and P.signal ~= 'range' then P.auto = nil end
        if P.auto == 'rth' then
            local to = me - pos; local h = #(vector2(to.x, to.y))
            local want = math.deg(math.atan(-to.x, to.y)); local dy = ((want - P.yaw + 540) % 360) - 180
            turn = clamp(dy / 30, -1, 1); fwd = h > 4 and (math.abs(dy) < 35 and clamp(h / 15, 0.2, 1) or 0) or 0
            up = (agl < 15 and h > 8) and 0.6 or 0
            if h <= 4 then P.auto = 'land' end
            if P.signal ~= 'range' and P.signal ~= 'jammed' and h < Config.Signal.weakFrom and P.autoFromRange then P.auto = nil; P.autoFromRange = false end
        end
        if P.signal == 'range' then P.autoFromRange = true end
        if P.auto == 'land' then fwd, side, turn = 0, 0, 0; up = -clamp(agl / 3 + 0.25, 0.25, 0.8) end

        -- dynamique
        if not P.destroyed then
            if not P.flying and up > 0.3 and P.battery > Config.Battery.landAt then P.flying = true end
            if P.flying then
                local spd = IsDisabledControlPressed(0, K.boost) and Config.Flight.boostSpeed or Config.Flight.maxSpeed
                local yr = math.rad(P.yaw); local fx, fy = -math.sin(yr), math.cos(yr)
                local tv = vector3((fx * fwd + fy * side) * spd, (fy * fwd - fx * side) * spd, up * Config.Flight.climb)
                if agl > Config.Flight.maxAltitude and tv.z > 0 then tv = vector3(tv.x, tv.y, 0) end
                local k = 1 - math.exp(-dt * Config.Flight.accel)
                local prev = P.vel
                P.vel = vector3(lerp(P.vel.x, tv.x, k), lerp(P.vel.y, tv.y, k), lerp(P.vel.z, tv.z, k))
                P.yawV = lerp(P.yawV, -turn * Config.Flight.yawSpeed, 1 - math.exp(-dt * 5)); P.yaw = (P.yaw + P.yawV * dt) % 360
                -- inclinaison selon l'accélération demandée (repère du drone)
                local ax, ay = tv.x - P.vel.x, tv.y - P.vel.y
                local lf, ls = ax * fx + ay * fy, ax * fy - ay * fx
                P.pitch = lerp(P.pitch, clamp(-(lf * 1.6 + fwd * 9), -24, 24), 1 - math.exp(-dt * 6))
                P.roll = lerp(P.roll, clamp(ls * 1.6 + side * 9, -24, 24), 1 - math.exp(-dt * 6))
                local hover = math.sin(GetGameTimer() / 400) * 0.05 * clamp(agl, 0, 1)
                SetEntityVelocity(ent, P.vel.x, P.vel.y, P.vel.z + hover)
                SetEntityRotation(ent, P.pitch, P.roll, P.yaw, 2, true)
                -- choc
                if HasEntityCollidedWithAnything(ent) and GetGameTimer() - P.lastHit > Config.Health.collisionCooldown then
                    local speed = #prev
                    if speed > Config.Health.collisionMinSpeed then
                        P.lastHit = GetGameTimer()
                        TriggerServerEvent('originrp_drone:hit', P.netId, 'collision', speed)
                        P.vel = vector3(-prev.x * 0.35, -prev.y * 0.35, math.abs(prev.z) * 0.2)
                    end
                end
                -- atterri
                if agl < 0.25 and up <= 0 then
                    P.flying = false; P.vel = vector3(0, 0, 0); SetEntityVelocity(ent, 0.0, 0.0, 0.0)
                    if P.auto == 'land' then P.auto = nil end
                    if P.exitAfter then stopPiloting(); break end
                end
            else
                SetEntityVelocity(ent, 0.0, 0.0, -0.2); P.pitch, P.roll = 0.0, 0.0
                SetEntityRotation(ent, 0.0, 0.0, P.yaw, 2, true)
            end
            -- explosion à proximité
            if IsExplosionInSphere(-1, pos.x, pos.y, pos.z, Config.Health.explosionRadius) then TriggerServerEvent('originrp_drone:hit', P.netId, 'explosion', 0) end
        end
        if P.flying ~= lastFlying then lastFlying = P.flying; TriggerServerEvent('originrp_drone:flying', P.id, P.flying) end
        if P.flying and not P.destroyed then P.battery = math.max(0, P.battery - dt / Config.Battery.flightSeconds * 100) end

        -- caméra embarquée (nacelle stabilisée)
        if P.cam then
            SetCamRot(P.cam, P.camPitch, 0.0, P.yaw, 2)
            SetCamFov(P.cam, lerp(GetCamFov(P.cam), P.fov, 0.2))
            if P.signal == 'weak' then ShakeCam(P.cam, 'HAND_SHAKE', 0.15) end
        end
        if P.light and not P.destroyed then
            local dir = vector3(-math.sin(math.rad(P.yaw)) * 0.4, math.cos(math.rad(P.yaw)) * 0.4, -1.0)
            DrawSpotLight(pos.x, pos.y, pos.z - 0.1, dir.x, dir.y, dir.z, 255, 255, 240, 60.0, 8.0, 0.0, 22.0, 30.0)
        end
        if P.rec then P.recT = P.recT + dt end
        for _, w in ipairs(Config.Battery.warn) do
            if P.battery <= w and not P.warned[w] then P.warned[w] = true; Drone.notify(('Batterie faible : %d %%'):format(w), 'warning') end
        end

        -- interface de la radiocommande
        if GetGameTimer() - lastUi > 100 then
            lastUi = GetGameTimer()
            local v = GetEntityVelocity(ent)
            ui({ action = 'update', alt = agl, spd = #v * 3.6, dist = dist, hdg = (360 - P.yaw) % 360, bat = P.battery,
                hp = P.health, signal = P.signal, vision = P.vision, zoom = Config.Flight.fovMax / P.fov, rec = P.rec, recT = P.recT,
                light = P.light, mode = P.mode, auto = P.auto, flying = P.flying, jamT = P.jamT, serial = P.serial })
        end
        Wait(0)
    end
end

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then stopPiloting() end end)
