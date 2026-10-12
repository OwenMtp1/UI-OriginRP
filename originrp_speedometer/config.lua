Config = {}

-- Unité : 'kmh' ou 'mph'
Config.Unit = 'kmh'

-- Vitesse maximale affichée sur le cadran (dans l'unité choisie)
Config.MaxSpeed = 300

-- Taille du compteur (1.0 = cadran de 250 px en 1080p)
Config.Scale = 1.0

-- Distance au bas de l'écran, en % de la hauteur
Config.Bottom = 3

-- Afficher le compteur seulement au conducteur (false = passagers aussi)
Config.DriverOnly = false

-- Source de l'essence : 'auto' (LegacyFuel, ox_fuel, ps-fuel, cdn-fuel sinon natif),
-- 'legacy', 'ox', 'native'
Config.Fuel = 'auto'

-- Seuils d'alerte (en %) : essence et état du moteur passent en rouge
Config.LowFuel = 15
Config.LowEngine = 30

-- Voyant de ceinture (piloté par votre script de ceinture, voir README)
Config.Seatbelt = true

-- Fréquence de mise à jour (ms)
Config.Refresh = 80
