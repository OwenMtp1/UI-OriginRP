Config = {}

-- Logo affiché en haut à gauche des menus.
-- nil = logo "A" intégré. Pour une image : placez-la dans html/img/ puis
-- Config.Logo = 'img/logo.png'
Config.Logo = nil

-- Touches qui ouvrent un menu. Chaque joueur peut les réassigner dans
-- Paramètres > Raccourcis clavier > FiveM.
Config.Keybinds = {
    { menu = 'main', command = 'menuf5', key = 'F5', description = 'Ouvrir le menu F5' },
}

--[[
    Définition des menus.

    Menu :
        title       Titre affiché dans l'en-tête
        subtitle    Sous-titre (optionnel)
        key         Touche affichée à droite de l'en-tête (optionnel). Appuyer
                    dessus quand le menu est ouvert le ferme.
        items       Liste des rubriques

    Rubrique :
        icon        Nom d'une icône (voir ICONS dans html/script.js)
        label       Titre
        description Texte secondaire (optionnel)
        disabled    true pour griser la rubrique (optionnel)

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
