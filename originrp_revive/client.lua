local running = false      -- je réanime quelqu'un
local cancelled = false
local bag = nil
local cam = nil

local function notify(message, kind)
    lib.notify({ title = 'Réanimation', description = message, type = kind or 'inform', icon = 'heart-pulse', position = Config.NotifyPosition })
end

local function totalDuration()
    local t = 0
    for _, ms in pairs(Config.Steps) do t = t + ms end
    return t
end

local function playAnim(ped, anim, flag, duration)
    lib.requestAnimDict(anim[1])
    TaskPlayAnim(ped, anim[1], anim[2], 4.0, -4.0, duration or -1, flag or 0, 0.0, false, false, false)
end

-- ─── Caméra cinématique (travelling lent autour de la scène) ───────────────

local function stopCam()
    if not cam then return end
    RenderScriptCams(false, true, 900, true, true)
    DestroyCam(cam, false)
    cam = nil
end

local function startCam(center)
    if not Config.CinematicCamera or cam then return end
    local c = GetEntityCoords(center)
    local base = GetEntityHeading(center)
    local total = totalDuration()
    local start = GetGameTimer()
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, 42.0)
    RenderScriptCams(true, true, 900, true, true)
    CreateThread(function()
        while cam do
            local k = math.min((GetGameTimer() - start) / total, 1.0)
            local e = k * k * (3 - 2 * k)                    -- easing doux
            local a = math.rad(base + 130 + 80 * e)
            local r, h = 2.7 - 0.8 * e, 1.5 - 0.6 * e
            SetCamCoord(cam, c.x + math.cos(a) * r, c.y + math.sin(a) * r, c.z + h)
            PointCamAtCoord(cam, c.x, c.y, c.z - 0.25)
            Wait(0)
        end
    end)
end

-- ─── Sac médical ───────────────────────────────────────────────────────────

local function bagModel()
    local p = Config.Props.bag
    if IsModelInCdimage(p.model) then return p.model end
    return p.fallback
end

local function deleteBag()
    if bag and DoesEntityExist(bag) then DeleteEntity(bag) end
    bag = nil
end

local function spawnBagInHand(ped)
    local model = bagModel()
    if not lib.requestModel(model, 3000) then return end
    bag = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(model)
    local h = Config.Props.hand
    AttachEntityToEntity(bag, ped, GetPedBoneIndex(ped, h.bone), h.offset.x, h.offset.y, h.offset.z,
        h.rotation.x, h.rotation.y, h.rotation.z, true, true, false, true, 1, true)
end

local function placeBag(patient)
    if not bag then return end
    DetachEntity(bag, true, false)
    local p = GetOffsetFromEntityInWorldCoords(patient, Config.BagOffset.x, Config.BagOffset.y, Config.BagOffset.z)
    SetEntityCoords(bag, p.x, p.y, p.z, false, false, false, false)
    SetEntityHeading(bag, GetEntityHeading(patient) + 90.0)
    PlaceObjectOnGroundProperly(bag)
    FreezeEntityPosition(bag, true)
end

-- ─── Déroulé côté secouriste ───────────────────────────────────────────────

-- Attend `ms` en bloquant les déplacements ; X annule
local function waitStep(ms, onTick)
    local finish = GetGameTimer() + ms
    while GetGameTimer() < finish do
        Wait(0)
        DisableControlAction(0, 30, true) DisableControlAction(0, 31, true)
        DisableControlAction(0, 21, true) DisableControlAction(0, 22, true)
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true)
        if IsControlJustPressed(0, Config.CancelKey) then cancelled = true end
        if onTick then onTick(1 - (finish - GetGameTimer()) / ms) end
        if cancelled then return false end
    end
    return true
end

local function step(name)
    TriggerServerEvent('originrp_revive:step', name)
end

local function abort(ped)
    ClearPedTasks(ped)
    deleteBag()
    stopCam()
    lib.hideTextUI()
    running = false
    TriggerServerEvent('originrp_revive:cancel')
    notify(Config.Messages.cancelled, 'error')
end

local function revive(patient)
    if running then return end
    local player = NetworkGetPlayerIndexFromPed(patient)
    if player == -1 then return end

    local ok, message = lib.callback.await('originrp_revive:start', false, GetPlayerServerId(player))
    if not ok then
        if message then notify(message, 'error') end
        return
    end

    running, cancelled = true, false
    local ped = PlayerPedId()
    local S, A = Config.Steps, Config.Anims
    lib.showTextUI('[X] Annuler la réanimation', { icon = 'heart-pulse' })
    startCam(patient)

    -- 1. se placer au niveau du torse, face à la personne
    local spot = GetOffsetFromEntityInWorldCoords(patient, Config.MedicOffset.x, Config.MedicOffset.y, Config.MedicOffset.z)
    local tc = GetEntityCoords(patient)
    local heading = GetHeadingFromVector_2d(tc.x - spot.x, tc.y - spot.y)
    step('approach')
    TaskGoStraightToCoord(ped, spot.x, spot.y, spot.z, 1.0, S.approach, heading, 0.05)
    if not waitStep(S.approach) then return abort(ped) end
    SetEntityCoords(ped, spot.x, spot.y, spot.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, heading)

    -- 2. s'agenouiller et poser le sac médical à côté
    spawnBagInHand(ped)
    playAnim(ped, A.putdown, 0, S.kneel)
    step('kneel')
    local placed = false
    if not waitStep(S.kneel, function(k)
        if not placed and k > 0.55 then placed = true placeBag(patient) end
    end) then return abort(ped) end
    if not placed then placeBag(patient) end

    -- 3. ouvrir le sac et prendre le pouls
    playAnim(ped, A.check, 1)
    step('check')
    if not waitStep(S.check) then return abort(ped) end

    -- 4. mains en position, puis massage cardiaque
    playAnim(ped, A.medicIntro, 0)
    step('intro')
    if not waitStep(S.intro) then return abort(ped) end

    playAnim(ped, A.medicCpr, 1)
    step('cpr')
    if not waitStep(S.cpr) then return abort(ped) end

    -- 5. la personne reprend son souffle
    playAnim(ped, A.medicWin, 0)
    step('success')
    if not waitStep(S.success) then return abort(ped) end

    TriggerServerEvent('originrp_revive:finish')
    lib.hideTextUI()
    stopCam()
    playAnim(ped, A.kneelExit, 0, 1200)
    SetTimeout(700, deleteBag)
    running = false
end

RegisterNetEvent('originrp_revive:medicCancel', function()
    if running then cancelled = true end
end)

-- ─── Côté patient ──────────────────────────────────────────────────────────

local patientActive = false

RegisterNetEvent('originrp_revive:patientStart', function()
    patientActive = true
    startCam(PlayerPedId())
end)

RegisterNetEvent('originrp_revive:patientStep', function(name)
    if not patientActive then return end
    local ped = PlayerPedId()
    -- sur un ped totalement mort (ragdoll), GTA ne joue pas d'animation : seul le secouriste est animé
    if IsEntityDead(ped) then return end
    local A = Config.Anims
    if name == 'intro' then
        playAnim(ped, A.patientIntro, 2)
    elseif name == 'cpr' then
        playAnim(ped, A.patientCpr, 1)
    elseif name == 'success' then
        playAnim(ped, A.patientWin, 2)
    end
end)

RegisterNetEvent('originrp_revive:patientStop', function(success)
    patientActive = false
    stopCam()
    if success then
        AnimpostfxPlay('SuccessNeutral', 0, false)
        SetTimeout(1500, function() AnimpostfxStop('SuccessNeutral') end)
    end
end)

-- Réanimation de secours si aucun framework n'est détecté
RegisterNetEvent('originrp_revive:fallbackRevive', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
end)

-- ─── Lancement : ALT sur la personne ou utilisation du kit ────────────────

local function isDown(ped)
    if IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped) then return true end
    local player = NetworkGetPlayerIndexFromPed(ped)
    if player == -1 then return false end
    local st = Player(GetPlayerServerId(player)).state
    return st.isDead or st.dead or st.isLaststand or false
end

local function hasKit()
    return (exports.ox_inventory:Search('count', Config.Item) or 0) > 0
end

exports.ox_target:addGlobalPlayer({
    {
        name = 'originrp_revive',
        icon = 'fa-solid fa-heart-pulse',
        label = 'Réanimer',
        distance = Config.Distance,
        canInteract = function(entity)
            return not running and isDown(entity) and hasKit()
        end,
        onSelect = function(data) revive(data.entity) end,
    },
})

exports('useMedikit', function()
    if running then return end
    local me = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= PlayerPedId() and isDown(ped) then
            local d = #(me - GetEntityCoords(ped))
            if d <= Config.Distance and (not bestDist or d < bestDist) then best, bestDist = ped, d end
        end
    end
    if not best then return notify(Config.Messages.nobody, 'error') end
    revive(best)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    deleteBag()
    stopCam()
end)
