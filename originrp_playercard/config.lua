Config = {}

-- Position à l'écran : 'top-left', 'top-right', 'bottom-left',
-- 'bottom-right', 'left' ou 'right'
Config.Position = 'right'
Config.Offset = { x = 24, y = 24 } -- marge en pixels depuis le bord

-- Masquage automatique après X millisecondes (0 = reste affichée
-- jusqu'à hide())
Config.Duration = 0

-- Textes
Config.Labels = {
    job = 'Emploi',
    organisation = 'Organisation',
    none = 'Aucune',
    active = 'Actif',
    inactive = 'Inactif',
    onDuty = 'En service',
    offDuty = 'Hors service',
}

-- Masquer la fiche quand le menu pause (Échap) est ouvert
Config.HideInPauseMenu = true
