Config = {}

-- Item (ox_inventory) : utilisable par tous les joueurs
Config.Item = 'scene_kit'

-- Permission admin : peut terminer n'importe quelle scène (ace : add_ace group.admin command.scene allow)
Config.AdminAce = 'command.scene'

-- Limites
Config.Cooldown = 120          -- secondes entre deux scènes d'un même joueur
Config.DefaultMinutes = 10     -- durée par défaut
Config.MaxMinutes = 30         -- durée maximale
Config.MaxTitle = 40           -- longueur max du titre
Config.MaxProps = 6            -- nombre max de props par scène
Config.PlaceDistance = 5.0     -- distance devant le joueur où la scène est posée (m)
Config.Spread = 2.2            -- rayon de disposition des props autour du centre (m)

-- Portée
Config.Radius = 150.0          -- joueurs notifiés (m)
Config.Area = 35.0             -- rayon affiché sur la carte (m)

Config.NotifyPosition = 'top-right'
Config.Blip = { sprite = 161, color = 27, scale = 0.8, alpha = 90, label = 'Scène : %s' }

Config.Notify = {
    created = 'Nouvelle scène : « %s » — %s',
    ended = 'La scène « %s » est terminée.',
}

-- Décors. Les noms de modèles sont des props GTA courants : vérifie-les sur ton serveur
-- avant la mise en production (un modèle inconnu fait simplement disparaître ce prop).
Config.Templates = {
    accident = {
        label = 'Accident de la route',
        description = 'Cônes et barrières autour d\'un véhicule accidenté.',
        icon = 'car-burst',
        props = { 'prop_roadcone02a', 'prop_roadcone02a', 'prop_barrier_work05', 'prop_flare_01' },
    },
    roadblock = {
        label = 'Barrage',
        description = 'Barrière de route pour bloquer une voie.',
        icon = 'road-barrier',
        props = { 'prop_barrier_work06a', 'prop_barrier_work05', 'prop_roadcone02a', 'prop_roadcone02a' },
    },
    crime = {
        label = 'Scène de crime',
        description = 'Cônes et balisage autour d\'une zone sécurisée.',
        icon = 'user-secret',
        props = { 'prop_mp_cone_03', 'prop_mp_cone_03', 'prop_barrier_work05', 'prop_flare_01' },
    },
    heist = {
        label = 'Braquage',
        description = 'Mallette et liasses de billets sur le sol.',
        icon = 'sack-dollar',
        props = { 'prop_security_case_01', 'prop_cash_pile_01', 'prop_flare_01', 'prop_mp_cone_03' },
    },
    ambush = {
        label = 'Embuscade',
        description = 'Caisses et cartons pour se cacher.',
        icon = 'eye',
        props = { 'prop_crate_11e', 'prop_boxpile_07d', 'prop_mp_cone_03' },
    },
    protest = {
        label = 'Manifestation',
        description = 'Barrières et balisage pour contenir une foule.',
        icon = 'bullhorn',
        props = { 'prop_barrier_work06a', 'prop_barrier_work05', 'prop_roadcone02a', 'prop_flare_01' },
    },
}
