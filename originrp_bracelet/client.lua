local selecting = false
local busy = false
local props = {}   -- serverId -> objet bracelet (local, non réseau)

local function notify(message, kind)
    lib.notify({
        title = 'Bracelet électronique',
        description = message,
        type = kind or 'inform',
        position = Config.NotifyPosition,
        icon = 'link',
    })
end

local function serverIdOf(ped)
    local player = NetworkGetPlayerIndexFromPed(ped)
    return player ~= -1 and GetPlayerServerId(player) or nil
end

-- ─── Utilisation de l'item : on attend un ALT sur une personne ─────────────

exports('useBracelet', function()
    if busy then return end
    if selecting then return notify(Config.Messages.choose) end
    selecting = true
    notify(Config.Messages.choose)

    CreateThread(function()
        local deadline = GetGameTimer() + Config.SelectTimeout
        while selecting and GetGameTimer() < deadline do Wait(200) end
        if selecting then
            selecting = false
            notify(Config.Messages.cancelled, 'error')
        end
    end)
end)

-- ─── Pose : accroupi à la jambe pendant 3 s ────────────────────────────────

local function fitBracelet(targetPed)
    local target = serverIdOf(targetPed)
    if not target then return end
    selecting = false

    local ok, message = lib.callback.await('originrp_bracelet:start', false, target)
    if not ok then
        if message then notify(message, 'error') end
        return
    end

    busy = true
    local ped = PlayerPedId()

    -- se placer au niveau de la jambe de la personne, face à elle
    local spot = GetOffsetFromEntityInWorldCoords(targetPed, Config.KneelOffset.x, Config.KneelOffset.y, Config.KneelOffset.z)
    local tc = GetEntityCoords(targetPed)
    SetEntityCoords(ped, spot.x, spot.y, spot.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, GetHeadingFromVector_2d(tc.x - spot.x, tc.y - spot.y))

    local done = lib.progressBar({
        duration = Config.Duration,
        label = 'Pose du bracelet électronique...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, sprint = true },
        anim = { dict = Config.Anim.dict, clip = Config.Anim.clip, flag = 1 },
    })

    ClearPedTasks(ped)
    TriggerServerEvent(done and 'originrp_bracelet:finish' or 'originrp_bracelet:cancel')
    if not done then notify(Config.Messages.cancelled, 'error') end
    busy = false
end

-- La personne qui reçoit le bracelet reste immobile pendant la pose
local fitting = false

RegisterNetEvent('originrp_bracelet:beingFitted', function(_, duration)
    fitting = true
    local ped = PlayerPedId()
    local untilTime = GetGameTimer() + duration + 500
    TaskStandStill(ped, duration)
    CreateThread(function()
        while fitting and GetGameTimer() < untilTime do
            DisableControlAction(0, 30, true) -- gauche / droite
            DisableControlAction(0, 31, true) -- avant / arrière
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- saut
            Wait(0)
        end
        fitting = false
    end)
end)

RegisterNetEvent('originrp_bracelet:fitCancelled', function()
    fitting = false
    ClearPedTasks(PlayerPedId())
end)

-- ─── Options ALT (ox_target) ───────────────────────────────────────────────

exports.ox_target:addGlobalPlayer({
    {
        name = 'originrp_bracelet_fit',
        icon = 'fa-solid fa-link',
        label = 'Mettre le bracelet électronique',
        distance = Config.TargetDistance,
        canInteract = function(entity)
            if not selecting or busy then return false end
            local sid = serverIdOf(entity)
            return sid ~= nil and not Player(sid).state.bracelet
        end,
        onSelect = function(data) fitBracelet(data.entity) end,
    },
    {
        name = 'originrp_bracelet_remove',
        icon = 'fa-solid fa-link-slash',
        label = 'Retirer le bracelet électronique',
        distance = Config.TargetDistance,
        canInteract = function(entity)
            local sid = serverIdOf(entity)
            return not busy and sid ~= nil and Player(sid).state.bracelet == true
        end,
        onSelect = function(data)
            local sid = serverIdOf(data.entity)
            busy = true
            local done = lib.progressBar({
                duration = Config.Duration,
                label = 'Retrait du bracelet électronique...',
                canCancel = true,
                disable = { move = true, car = true, combat = true },
                anim = { dict = Config.Anim.dict, clip = Config.Anim.clip, flag = 1 },
            })
            ClearPedTasks(PlayerPedId())
            busy = false
            if done and not lib.callback.await('originrp_bracelet:remove', false, sid) then
                notify(Config.Messages.noJob, 'error')
            end
        end,
    },
})

-- ─── Visuel : bracelet à la cheville, caché par un long pantalon ───────────

local function legsUncovered(ped)
    local list = Config.UncoveredLegs[GetEntityModel(ped)]
    if not list then return Config.ShowOnOtherPeds end
    return list[GetPedDrawableVariation(ped, 4)] == true
end

local function attachProp(ped)
    local p = Config.Prop
    lib.requestModel(p.model)
    local obj = CreateObject(p.model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(p.model)
    SetEntityCollision(obj, false, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, p.bone),
        p.offset.x, p.offset.y, p.offset.z, p.rotation.x, p.rotation.y, p.rotation.z,
        true, true, false, false, 2, true)
    return { obj = obj, ped = ped }
end

local function dropProp(sid)
    local entry = props[sid]
    if entry then
        if DoesEntityExist(entry.obj) then DeleteEntity(entry.obj) end
        props[sid] = nil
    end
end

CreateThread(function()
    while true do
        local seen = {}
        local myCoords = GetEntityCoords(PlayerPedId())

        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            local sid = GetPlayerServerId(player)
            local show = Player(sid).state.bracelet == true
                and DoesEntityExist(ped)
                and #(myCoords - GetEntityCoords(ped)) <= Config.StreamDistance
                and legsUncovered(ped)

            if show then
                seen[sid] = true
                local entry = props[sid]
                -- le ped change (respawn, changement de skin) → on recrée l'objet
                if entry and (entry.ped ~= ped or not DoesEntityExist(entry.obj)) then
                    dropProp(sid)
                    entry = nil
                end
                if not entry then props[sid] = attachProp(ped) end
            end
        end

        for sid in pairs(props) do
            if not seen[sid] then dropProp(sid) end
        end
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for sid in pairs(props) do dropProp(sid) end
end)
