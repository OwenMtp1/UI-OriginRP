Config = {}

-- Logo affiché en haut à gauche des menus.
-- nil = logo "A" intégré. Pour une image : placez-la dans html/img/ puis
-- Config.Logo = 'img/logo.png'
Config.Logo = nil

-- Touches qui ouvrent un menu. Chaque joueur peut les réassigner dans
-- Paramètres > Raccourcis clavier > FiveM.
Config.Keybinds = {
    { menu = 'main', command = 'menuf5', key = 'F5', description = 'Ouvrir le menu F5' },
    { menu = 'organisation', command = 'menuf7', key = 'F7', description = 'Ouvrir le menu organisation' },
}

--[[
    Définition des menus.

    Menu :
        title       Titre affiché dans l'en-tête
        subtitle    Sous-titre (optionnel)
        key         Touche affichée à droite de l'en-tête (optionnel). Appuyer
                    dessus quand le menu est ouvert le ferme.
        onOpen      function() appelée à chaque ouverture (optionnel). Elle peut
                    renvoyer des valeurs à jour :
                    { title = ..., subtitle = ..., items = { [id] = { value = ..., checked = ... } } }
                    ou false pour empêcher l'ouverture.
        items       Liste des rubriques

    Rubrique :
        icon        Nom d'une icône (voir ICONS dans html/script.js)
        label       Titre
        description Texte secondaire (optionnel)
        disabled    true pour griser la rubrique (optionnel)
        id          Identifiant, pour modifier la rubrique en jeu (voir onOpen / setMenu)
        value       Texte affiché à droite (ex. 'Chef'). Une rubrique sans action
                    est purement informative.
        checkbox    true pour une case à cocher : le menu reste ouvert et l'état
                    (true / false) est ajouté en dernier argument de event /
                    serverEvent, et en 2e argument de onSelect.
        checked     État initial de la case (défaut : false)

        Et une (ou plusieurs) action(s) au clic :
        submenu     Id d'un autre menu de Config.Menus à ouvrir
        event       Événement client déclenché (TriggerEvent)
        serverEvent Événement serveur déclenché (TriggerServerEvent)
        command     Commande exécutée (ExecuteCommand)
        args        Table d'arguments passés à event / serverEvent (optionnel)
        onSelect    function() ... end, appelée côté client (optionnel)
        close       false pour garder le menu ouvert après l'action (défaut : true)
]]

Config.Menus = {
    main = {
        title = 'Menu F5',
        subtitle = 'Accédez à toutes les options du serveur',
        key = 'F5',
        items = {
            { icon = 'user',     label = 'Identité',   description = 'Voir et modifier votre identité',   event = 'originrp_menu:identite' },
            { icon = 'briefcase', label = 'Emplois',   description = 'Consulter les différents emplois',  event = 'originrp_menu:emplois' },
            { icon = 'phone',    label = 'Téléphone',  description = 'Vos contacts et messages',          event = 'originrp_menu:telephone' },
            { icon = 'car',      label = 'Véhicules',  description = 'Gérer vos véhicules',               event = 'originrp_menu:vehicules' },
            { icon = 'run',      label = 'Animations', description = 'Accéder aux animations',            event = 'originrp_menu:animations' },
            { icon = 'settings', label = 'Paramètres', description = 'Régler vos préférences',            event = 'originrp_menu:parametres' },
        },
    },

    organisation = {
        title = 'Organisation',              -- remplacé par le nom de l'organisation (onOpen)
        subtitle = 'Menu organisation',
        key = 'F7',
        items = {
            { id = 'grade',   icon = 'star',   label = 'Grade',              description = 'Votre rang dans l\'organisation', value = '-' },
            { id = 'service', icon = 'badge',  label = 'Prendre son service', description = 'Passer en service ou hors service', checkbox = true, serverEvent = 'originrp_menu:organisation:service' },
            { id = 'tablette', icon = 'tablet', label = 'Ouvrir la tablette', description = 'Accéder à la tablette de l\'organisation', event = 'originrp_menu:organisation:tablette' },
        },

        -- À adapter à la base : renvoie le nom de l'organisation, le grade et
        -- l'état du service du joueur. Exemples :
        --
        -- ESX :
        --   local job = ESX.GetPlayerData().job  -- ou .job2 / .faction selon la base
        --   return { title = job.label, items = { grade = { value = job.grade_label } } }
        --
        -- QBCore (gangs) :
        --   local gang = QBCore.Functions.GetPlayerData().gang
        --   if gang.name == 'none' then return false end
        --   return { title = gang.label, items = { grade = { value = gang.grade.name } } }
        onOpen = function()
            return nil
        end,
    },

    -- Exemple de sous-menu : dans "main", remplacez
    --   event = 'originrp_menu:parametres'
    -- par
    --   submenu = 'parametres'
    -- et décommentez ce bloc.
    --[[
    parametres = {
        title = 'Paramètres',
        subtitle = 'Régler vos préférences',
        items = {
            { icon = 'bell',  label = 'Notifications', description = 'Activer ou couper les notifications', event = 'originrp_menu:notifs' },
            { icon = 'eye',   label = 'Affichage',     description = 'Masquer ou afficher le HUD',          command = 'hud' },
        },
    },
    ]]
}
