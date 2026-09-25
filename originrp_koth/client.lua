local visible = Config.ShowOnStart
local entries = {}
local title = Config.Title

local function nuiConfig()
    return {
        title = title,
        subtitle = Config.Subtitle,
        maxRows = Config.MaxRows,
        pointsLabel = Config.PointsLabel,
        position = Config.Position,
        offset = Config.Offset,
    }
end

-- Liste attendue : { { name = 'cartelgoon', points = 0, id = 12 }, ... }
-- `id` (server id, optionnel) permet de surligner la ligne du joueur local.
local function normalize(list)
    local myId = GetPlayerServerId(PlayerId())
    local result = {}
    for i, entry in ipairs(list or {}) do
        local id = tonumber(entry.id or entry.source)
        result[i] = {
            key = tostring(id or entry.name or i),
            name = tostring(entry.name or ('Joueur ' .. i)),
            points = tonumber(entry.points or entry.score) or 0,
            me = id ~= nil and id == myId,
        }
    end
    return result
end

local function setLeaderboard(list, newTitle)
    entries = normalize(list)
    if newTitle then title = tostring(newTitle) end
    SendNUIMessage({ action = 'update', entries = entries, title = title })
end

local function show()
    visible = true
    SendNUIMessage({ action = 'show' })
end

local function hide()
    visible = false
    SendNUIMessage({ action = 'hide' })
end

-- La page NUI demande l'état au chargement (évite de perdre les messages
-- envoyés avant qu'elle soit prête, ex. après un restart).
RegisterNUICallback('ready', function(_, cb)
    cb({ config = nuiConfig(), entries = entries, visible = visible })
end)

RegisterNetEvent('originrp_koth:update', function(list, newTitle)
    setLeaderboard(list, newTitle)
end)

RegisterNetEvent('originrp_koth:show', show)
RegisterNetEvent('originrp_koth:hide', hide)

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

exports('setLeaderboard', setLeaderboard)
exports('show', show)
exports('hide', hide)
exports('isVisible', function() return visible end)
