--[[
    Afficher une notification :
        exports.originrp_notify:notify('Tu as été soigné.')
        exports.originrp_notify:notify({ title = 'Staff', message = 'Tu as été soigné.', type = 'success', duration = 5000 })
    type : 'info' (défaut), 'success', 'error', 'warning'
]]
local function notify(data, kind, duration)
    if type(data) ~= 'table' then
        data = { message = data, type = kind, duration = duration }
    end
    local notifType = Config.Titles[data.type] and data.type or 'info'
    SendNUIMessage({
        action = 'notify',
        title = data.title or Config.Titles[notifType],
        message = tostring(data.message or ''),
        type = notifType,
        duration = tonumber(data.duration) or Config.Duration,
    })
end

RegisterNUICallback('ready', function(_, cb)
    cb({ position = Config.Position, offset = Config.Offset, logo = Config.Logo })
end)

RegisterNetEvent('originrp_notify:send', notify)

exports('notify', notify)
