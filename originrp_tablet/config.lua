Config = {}

-- Événements qui ouvrent la tablette (déclenchés par les menus F6 / F7 de
-- originrp_menu). Clé = type de tablette, passé à sv_config.lua.
Config.OpenEvents = {
    entreprise = 'originrp_menu:entreprise:tablette',
    organisation = 'originrp_menu:organisation:tablette',
}

-- Sous-titre affiché sous le nom, selon le type
Config.Subtitles = {
    entreprise = "Tablette de l'entreprise",
    organisation = "Tablette de l'organisation",
}

-- Permissions possibles d'un grade (clé = identifiant envoyé au serveur)
Config.Permissions = {
    { key = 'coffre',      label = 'Accès au coffre' },
    { key = 'tablette',    label = 'Accès à la tablette' },
    { key = 'service',     label = 'Prise de service' },
    { key = 'recrutement', label = 'Recrutement' },
    { key = 'grades',      label = 'Gestion des grades' },
}

-- Distance max (mètres) pour « Recruter le joueur le plus proche »
Config.RecruitDistance = 3.0
