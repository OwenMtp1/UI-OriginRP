Config = {}

-- Source de la faim / soif : 'auto' (détecte ESX ou QBCore), 'esx', 'qb'
-- ou 'none' (valeurs envoyées par un autre script avec
-- exports.originrp_hud:setStatus('hunger', 75)).
Config.Framework = 'auto'

-- Jauges rondes (au-dessus), dans l'ordre (retirer une ligne pour la masquer)
Config.Gauges = { 'thirst', 'hunger' }

-- Barres sur la longueur (en dessous), dans l'ordre
Config.Bars = { 'health', 'armor' }

-- Longueur des barres en pixels (en 1080p, avant Config.Scale)
Config.BarWidth = 210

-- Afficher la valeur (0 à 100) au bout des barres
Config.ShowValues = true

-- Taille générale (1.0 = jauges de 44 px en 1080p)
Config.Scale = 1.0

-- Espace entre la minimap et les jauges, en pixels
Config.Gap = 14

-- Sous ce pourcentage, la jauge passe en rouge et clignote
Config.LowThreshold = 20

-- Masquer la jauge d'armure quand elle est vide
Config.HideArmorWhenEmpty = false

-- Masquer le HUD quand la minimap est cachée
Config.HideWithMinimap = true

-- Commande pour afficher / masquer le HUD (nil pour désactiver)
Config.ToggleCommand = 'hud'
