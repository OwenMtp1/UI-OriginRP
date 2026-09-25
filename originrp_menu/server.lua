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
