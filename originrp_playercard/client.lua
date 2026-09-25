local visible = false
local hideAt = 0

--[[
    Données attendues :
    {
        name = 'Liam Coelho',
        id = 2,                                -- server id (affiché « #2 »)
        job = { label = 'LSPD', grade = 'Patron', active = true, onDuty = false },
        organisation = { label = 'Families', grade = 'Recrue' },   -- nil = « Aucune »
    }
    job.active / job.onDuty : nil pour ne pas afficher le badge.
]]
local function show(data, duration)
    if type(data) ~= 'table' then return end
    visible = true
    SendNUIMessage({ action = 'show', data = data })

    duration = duration or Config.Duration
    if duration and duration > 0 then
        local token = GetGameTimer() + duration
        hideAt = token
        SetTimeout(duration, function()
            if hideAt == token and visible then
                visible = false
                SendNUIMessage({ action = 'hide' })
            end
        end)
    else
        hideAt = 0
    end
end

local function hide()
    visible = false
    hideAt = 0
    SendNUIMessage({ action = 'hide' })
end

RegisterNUICallback('ready', function(_, cb)
    cb({
        position = Config.Position,
        offset = Config.Offset,
        labels = Config.Labels,
    })
end)

RegisterNetEvent('originrp_playercard:show', show)
RegisterNetEvent('originrp_playercard:hide', hide)

if Config.HideInPauseMenu then
    CreateThread(function()
        local paused = false
        while true do
            local isPaused = IsPauseMenuActive()
            if isPaused ~= paused then
                paused = isPaused
                SendNUIMessage({ action = 'pause', paused = paused })
            end
            Wait(250)
        end
    end)
end

exports('show', show)
exports('hide', hide)
exports('isVisible', function() return visible end)
