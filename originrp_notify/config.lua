Config = {}

-- Logo à gauche : nil = logo Origin intégré. Pour une image : la placer dans
-- html/img/ (et l'ajouter dans fxmanifest.lua) puis Config.Logo = 'img/logo.png'
Config.Logo = nil

-- Position : 'top-right', 'top-left', 'bottom-right', 'bottom-left', 'top'
Config.Position = 'top-right'
Config.Offset = { x = 24, y = 24 } -- marge en pixels depuis le bord

-- Durée d'affichage par défaut (millisecondes)
Config.Duration = 5000

-- Titre par défaut selon le type quand aucun titre n'est donné
Config.Titles = {
    info = 'Information',
    success = 'Succès',
    error = 'Erreur',
    warning = 'Attention',
}
