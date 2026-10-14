-- Vérifie la permission ACE d'un menu avant de l'ouvrir côté client.
-- Attention : cela protège seulement l'ouverture du menu. Chaque action
-- staff (kick, ban, tp…) doit aussi vérifier la permission côté serveur.
RegisterNetEvent('originrp_menu:requestOpen', function(menuId)
    local src = source
    local menu = Config.Menus[menuId]
    if not menu then return end
    if menu.ace and not IsPlayerAceAllowed(src, menu.ace) then return end
    TriggerClientEvent('originrp_menu:openAllowed', src, menuId)
end)

-- Nombre de joueurs en ligne, lu par le menu staff (GlobalState.originrp_players)
CreateThread(function()
    while true do
        local count = GetNumPlayerIndices()
        if GlobalState.originrp_players ~= count then
            GlobalState.originrp_players = count
        end
        Wait(5000)
    end
end)

---------------------------------------------------------------------------
-- Événements illégaux (KOTH, cargaisons, go-fast) : menu staff
---------------------------------------------------------------------------
-- Listes envoyées par les scripts de l'événement : exports.originrp_menu:setEventList('koth', { { id, label, description, value }, ... })
local eventLists = { koth = {}, cargaison = {}, gofast = {} }
local EVENT_KINDS = { koth = true, cargaison = true, gofast = true }

local function isStaff(src)
    return IsPlayerAceAllowed(src, 'originrp.staff')
end

local function sendLists(target)
    for kind, entries in pairs(eventLists) do
        TriggerClientEvent('originrp_menu:events:setList', target, kind, entries)
    end
end

-- Le menu demande les listes à son ouverture
RegisterNetEvent('originrp_menu:events:requestLists', function()
    local src = source
    if not isStaff(src) then return end
    sendLists(src)
end)

-- Lancer : le serveur choisit au hasard dans la liste, ou selon ses règles
RegisterNetEvent('originrp_menu:events:launch', function(data)
    local src = source
    if not isStaff(src) or type(data) ~= 'table' or not EVENT_KINDS[data.kind] then return end
    TriggerEvent('originrp_menu:events:onLaunch', src, data.kind)
end)

-- Créer, renommer, modifier, supprimer, se téléporter : action sur une entrée
RegisterNetEvent('originrp_menu:events:action', function(data)
    local src = source
    if not isStaff(src) or type(data) ~= 'table' or not EVENT_KINDS[data.kind] then return end
    TriggerEvent('originrp_menu:events:onAction', src, {
        kind = data.kind,
        id = data.id,
        action = data.action,
    })
end)

-- Mise à jour d'une liste (diffusée aux staff connectés)
exports('setEventList', function(kind, entries)
    if not EVENT_KINDS[kind] then return end
    eventLists[kind] = entries or {}
    for _, player in ipairs(GetPlayers()) do
        if isStaff(tonumber(player)) then
            TriggerClientEvent('originrp_menu:events:setList', tonumber(player), kind, eventLists[kind])
        end
    end
end)
