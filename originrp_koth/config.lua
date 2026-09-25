Config = {}

Config.Title = 'KOTH'
Config.Subtitle = 'Classement en direct'

-- Nombre de lignes affichées. Si le joueur local n'est pas dans le top,
-- sa ligne remplace la dernière pour qu'il voie toujours sa position.
Config.MaxRows = 5

-- Texte affiché après le score
Config.PointsLabel = 'pts'

-- Position à l'écran : 'top-left', 'top-right', 'bottom-left',
-- 'bottom-right', 'left' ou 'right'
Config.Position = 'top-left'
Config.Offset = { x = 24, y = 24 } -- marge en pixels depuis le bord

-- Afficher le classement dès la connexion (sinon via show / update)
Config.ShowOnStart = false

-- Masquer le classement quand le menu pause (Échap) est ouvert
Config.HideInPauseMenu = true
