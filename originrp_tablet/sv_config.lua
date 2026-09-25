--[[
    À BRANCHER SUR LA BASE (côté serveur uniquement).

    GetData(source, kind) doit renvoyer les données de la tablette du joueur,
    ou nil s'il n'y a pas accès. kind = 'entreprise' ou 'organisation'.

    {
        name = 'Cartelgoon',          -- nom affiché en haut
        type = 'Cartel',              -- « Type » (optionnel)
        xp = 200,                     -- « Points d'expérience » (optionnel)
        me = { id = 'ABC123', grade = 4 },   -- joueur qui ouvre la tablette
        grades = {                    -- du plus haut au plus bas
            { level = 4, name = 'Chef',  permissions = { 'coffre', 'tablette', 'service', 'recrutement', 'grades' } },
            { level = 0, name = 'Recrue', permissions = { 'service' } },
        },
        members = {
            { id = 'ABC123', name = 'Malou Malou', grade = 4, online = true, onDuty = true, serviceTime = 2 },
            -- serviceTime en minutes
        },
    }

    OnAction(source, kind, action, payload) : appelée quand le joueur agit
    dans la tablette. Doit renvoyer ok (true / false) et un message affiché
    au joueur (optionnel). Après l'action, GetData est rappelée et la
    tablette se met à jour toute seule.

    action / payload :
        'recruit'     { target = serverId }
        'promote'     { id = membre }
        'demote'      { id = membre }
        'kick'        { id = membre }
        'saveGrade'   { level = n, name = '...', permissions = { ... }, new = true/false }
        'deleteGrade' { level = n }

    IMPORTANT : revérifier ici les permissions du joueur (grade, recrutement,
    gestion des grades…). La tablette masque les boutons interdits mais le
    serveur doit toujours avoir le dernier mot.
]]

ServerConfig = {}

ServerConfig.GetData = function(source, kind)
    return nil
end

ServerConfig.OnAction = function(source, kind, action, payload)
    return false, "Action non disponible pour le moment."
end
