local throwing = false
local tabletOpen = false
local trackerObjects = {}   -- objets traceurs proches : { entity, serial, active }
local blips = {}            -- serial -> blip

local CONTROL_ATTACK, CONTROL_AIM = 24, 25
local SHAPE_FLAGS = 1 | 2 | 4 | 8 | 16
local GRAVITY = 9.81

-- ─── Utilitaires ───────────────────────────────────────────────────────────

local function rotationToDirection(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local c = math.abs(math.cos(x))
    return vector3(-math.sin(z) * c, math.cos(z) * c, math.sin(x))
end

local function loadModel(model)
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(model)
end

local function raycast(from, to, ignore)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, SHAPE_FLAGS, ignore, 7)
    local _, hit, coords, normal, entity = GetShapeTestResult(handle)
    return hit == 1, coords, normal, entity
end

local function launchState()
    local ped = PlayerPedId()
    local origin = GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0) -- main droite
    local dir = rotationToDirection(GetGameplayCamRot(2))
    return origin + dir * 0.4, dir * Config.ThrowSpeed + vector3(0.0, 0.0, Config.ThrowUpward)
end

-- ─── Lancer (fonctionne comme une bombe collante) ──────────────────────────

local function drawTrajectory(ped)
    local pos, vel = launchState()
    local step = 0.05
    for _ = 1, 40 do
        local nextPos = pos + vel * step
        vel = vel - vector3(0.0, 0.0, GRAVITY * step)
        local hit, coords, _, entity = raycast(pos, nextPos, ped)
        if hit then
            local sticky = entity ~= 0 and (IsEntityAPed(entity) or IsEntityAVehicle(entity))
            DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, 0.12, 0.12, 0.12,
                sticky and 80 or 255, sticky and 255 or 90, sticky and 120 or 90, 200, false, false, 2, false)
            return
        end
        DrawMarker(28, nextPos.x, nextPos.y, nextPos.z, 0, 0, 0, 0, 0, 0, 0.04, 0.04, 0.04, 139, 92, 246, 160, false, false, 2, false)
        pos = nextPos
    end
end

local function stickTo(obj, entity, coords)
    local bone = 0
    local offset = GetOffsetFromEntityGivenWorldCoords(entity, coords.x, coords.y, coords.z)
    if IsEntityAPed(entity) then
        -- sur une personne : fixé au torse pour suivre les animations
        bone = GetPedBoneIndex(entity, 24818)
        local bonePos = GetWorldPositionOfEntityBone(entity, bone)
        offset = offset - GetOffsetFromEntityGivenWorldCoords(entity, bonePos.x, bonePos.y, bonePos.z)
    end
    AttachEntityToEntity(obj, entity, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0,
        false, false, false, false, 2, true)
end

local function simulateFlight(obj, ped)
    local pos, vel = launchState()
    local last = GetGameTimer()
    local deadline = last + Config.MaxFlightTime

    while GetGameTimer() < deadline do
        Wait(0)
        local now = GetGameTimer()
        local dt = math.min((now - last) / 1000.0, 0.05)
        last = now

        local nextPos = pos + vel * dt
        vel = vel - vector3(0.0, 0.0, GRAVITY * dt)
        local hit, coords, normal, entity = raycast(pos, nextPos, ped)

        if hit then
            if entity ~= 0 and (IsEntityAPed(entity) or IsEntityAVehicle(entity)) then
                -- collé sur la personne / le véhicule (à l'arrêt ou en mouvement)
                SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z, false, false, false)
                stickTo(obj, entity, coords)
                return
            elseif normal.z >= Config.GroundNormalZ then
                -- raté : il tombe et reste au sol
                SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z + 0.02, false, false, false)
                SetEntityRotation(obj, 0.0, 0.0, math.random(0, 359) + 0.0, 2, true)
                return
            else
                -- mur : petit rebond puis chute
                local d = vel.x * normal.x + vel.y * normal.y + vel.z * normal.z
                vel = (vel - normal * (2.0 * d)) * Config.WallBounce
                nextPos = coords + normal * 0.05
            end
        end

        pos = nextPos
        SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)
        SetEntityRotation(obj, now * 0.6 % 360, 0.0, now * 0.4 % 360, 2, true)
    end

    -- vol trop long : posé au sol sous sa position
    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    SetEntityCoordsNoOffset(obj, pos.x, pos.y, found and groundZ + 0.02 or pos.z, false, false, false)
end

local function throwTracker(slot)
    local ped = PlayerPedId()
    local serial = lib.callback.await('originrp_tracker:throw', false, slot)
    if not serial then return end

    lib.requestAnimDict(Config.ThrowAnim.dict)
    TaskPlayAnim(ped, Config.ThrowAnim.dict, Config.ThrowAnim.clip, 8.0, -8.0, 900, 48, 0.0, false, false, false)
    Wait(350)

    if not loadModel(Config.PropModel) then return end
    local pos = launchState()
    local obj = CreateObject(Config.PropModel, pos.x, pos.y, pos.z, true, true, false)
    SetModelAsNoLongerNeeded(Config.PropModel)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)

    simulateFlight(obj, ped)
    SetEntityCollision(obj, true, true)

    local netId = NetworkGetNetworkIdFromEntity(obj)
    SetNetworkIdCanMigrate(netId, true)
    TriggerServerEvent('originrp_tracker:placed', serial, netId)
end

exports('useTracker', function(_, slot)
    if throwing or tabletOpen or IsPedInAnyVehicle(PlayerPedId(), false) then return end
    throwing = true
    lib.showTextUI('[Clic gauche] Lancer le traceur  \n[Clic droit] Annuler', { icon = 'satellite-dish' })

    CreateThread(function()
        local ped = PlayerPedId()
        while throwing do
            Wait(0)
            DisableControlAction(0, CONTROL_ATTACK, true)
            DisableControlAction(0, CONTROL_AIM, true)
            DisablePlayerFiring(PlayerId(), true)
            drawTrajectory(ped)

            if IsDisabledControlJustPressed(0, CONTROL_AIM) or IsEntityDead(ped) then
                break
            elseif IsDisabledControlJustPressed(0, CONTROL_ATTACK) then
                lib.hideTextUI()
                throwTracker(slot.slot)
                break
            end
        end
        lib.hideTextUI()
        throwing = false
    end)
end)

-- ─── Traceurs dans le monde : lumière, ALT, tirs ───────────────────────────

CreateThread(function()
    while true do
        local list = {}
        local coords = GetEntityCoords(PlayerPedId())
        for _, obj in ipairs(GetGamePool('CObject')) do
            if GetEntityModel(obj) == Config.PropModel then
                local bag = Entity(obj).state.gpsTracker
                if bag and #(coords - GetEntityCoords(obj)) < 150.0 then
                    list[#list + 1] = { entity = obj, serial = bag.serial, active = bag.active }
                end
            end
        end
        trackerObjects = list
        Wait(1000)
    end
end)

CreateThread(function()
    local L = Config.Light
    while true do
        local sleep = 500
        if #trackerObjects > 0 then
            sleep = 0
            local blinkOn = GetGameTimer() % L.period < L.period * L.onRatio
            local ped = PlayerPedId()
            local myCoords = GetEntityCoords(ped)

            for _, t in ipairs(trackerObjects) do
                if t.active and blinkOn and DoesEntityExist(t.entity) then
                    local p = GetOffsetFromEntityInWorldCoords(t.entity, 0.03, 0.0, 0.03)
                    if #(myCoords - p) <= L.maxDistance then
                        -- petit point rouge (LED) + halo très léger
                        DrawMarker(28, p.x, p.y, p.z, 0, 0, 0, 0, 0, 0, L.dot, L.dot, L.dot,
                            L.r, L.g, L.b, 230, false, false, 2, false, nil, nil, false)
                        DrawLightWithRange(p.x, p.y, p.z, L.r, L.g, L.b, L.range, L.intensity)
                    end
                end
            end

            -- un tir proche d'un traceur le détruit
            if IsPedShooting(ped) then
                local ok, impact = GetPedLastWeaponImpactCoord(ped)
                if ok then
                    for _, t in ipairs(trackerObjects) do
                        if DoesEntityExist(t.entity) and #(impact - GetEntityCoords(t.entity)) <= Config.ShotRadius then
                            TriggerServerEvent('originrp_tracker:shot', NetworkGetNetworkIdFromEntity(t.entity))
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('originrp_tracker:destroyedFx', function(coords)
    if #(GetEntityCoords(PlayerPedId()) - coords) > 80.0 then return end
    lib.requestNamedPtfxAsset('core')
    UseParticleFxAsset('core')
    StartParticleFxNonLoopedAtCoord('ent_sht_electrical_box', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.6, false, false, false)
    PlaySoundFromCoord(-1, 'Short_Transition_In', coords.x, coords.y, coords.z, 'PLAYER_SWITCH_CUSTOM_SOUNDSET', false, 15, false)
end)

-- ALT sur le traceur, au point précis où il est collé
exports.ox_target:addModel(Config.PropModel, {
    {
        name = 'originrp_tracker_remove',
        icon = 'fa-solid fa-satellite-dish',
        label = 'Retirer le tracker',
        distance = Config.PickupDistance,
        canInteract = function(entity)
            return Entity(entity).state.gpsTracker ~= nil
        end,
        onSelect = function(data)
            local ped = PlayerPedId()
            lib.requestAnimDict('pickup_object')
            TaskPlayAnim(ped, 'pickup_object', 'putdown_low', 8.0, -8.0, 800, 48, 0.0, false, false, false)
            Wait(500)
            if lib.callback.await('originrp_tracker:pickup', false, NetworkGetNetworkIdFromEntity(data.entity)) then
                lib.notify({ title = 'Traceur GPS', description = 'Traceur récupéré.', type = 'success' })
            end
        end,
    },
})

-- ─── Points sur la carte GTA ───────────────────────────────────────────────

RegisterNetEvent('originrp_tracker:blips', function(list)
    for serial, blip in pairs(blips) do
        if not list[serial] then
            RemoveBlip(blip)
            blips[serial] = nil
        end
    end
    for serial, t in pairs(list) do
        local blip = blips[serial]
        if not blip then
            blip = AddBlipForCoord(t.x, t.y, t.z)
            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipAsShortRange(blip, false)
            blips[serial] = blip
        else
            SetBlipCoords(blip, t.x, t.y, t.z)
        end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(t.label)
        EndTextCommandSetBlipName(blip)
    end
    if tabletOpen then SendNUIMessage({ action = 'positions', list = list }) end
end)

-- ─── Tablette de suivi ─────────────────────────────────────────────────────

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    ClearPedTasks(PlayerPedId())
end

exports('useTablet', function()
    if tabletOpen or throwing then return end
    local data = lib.callback.await('originrp_tracker:getData', false)
    if not data then return end
    tabletOpen = true
    SetNuiFocus(true, true)
    TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_TOURIST_MAP', 0, true)
    SendNUIMessage({ action = 'open', data = data, maxName = Config.MaxNameLength })
end)

RegisterNetEvent('originrp_tracker:message', function(msg)
    if tabletOpen then SendNUIMessage({ action = 'message', message = msg }) end
end)

local function reply(cb, data)
    if data then SendNUIMessage({ action = 'update', data = data }) end
    cb(1)
end

RegisterNUICallback('close', function(_, cb) closeTablet() cb(1) end)

RegisterNUICallback('refresh', function(_, cb)
    reply(cb, lib.callback.await('originrp_tracker:getData', false))
end)

RegisterNUICallback('sync', function(body, cb)
    local res = lib.callback.await('originrp_tracker:sync', false, body.slot, body.force == true)
    cb(res or { ok = false })
    if res and res.data then SendNUIMessage({ action = 'update', data = res.data }) end
end)

RegisterNUICallback('toggle', function(body, cb)
    reply(cb, lib.callback.await('originrp_tracker:toggle', false, body.serial))
end)

RegisterNUICallback('rename', function(body, cb)
    reply(cb, lib.callback.await('originrp_tracker:rename', false, body.serial, body.name))
end)

RegisterNUICallback('forget', function(body, cb)
    reply(cb, lib.callback.await('originrp_tracker:forget', false, body.serial))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, blip in pairs(blips) do RemoveBlip(blip) end
    if tabletOpen then SetNuiFocus(false, false) end
end)
