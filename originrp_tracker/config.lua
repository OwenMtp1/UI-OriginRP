Config = {}

-- Noms des items (ox_inventory)
Config.TrackerItem = 'gps_tracker'
Config.TabletItem = 'gps_tablet'

-- Prop du traceur posé dans le monde (bien visible, clignote quand actif)
Config.PropModel = `w_ex_pe`

-- Lancer : vitesse initiale (m/s), portée max de la prévisualisation, durée max du vol (ms)
Config.ThrowSpeed = 14.0
Config.ThrowUpward = 2.5
Config.MaxFlightTime = 4000
Config.ThrowAnim = { dict = 'weapons@projectile@grenade_str', clip = 'throw_m_fb_stand' }

-- Une surface dont la normale a un z >= à cette valeur est considérée comme un sol
-- (le traceur s'y pose). En dessous, c'est un mur : il rebondit puis tombe.
Config.GroundNormalZ = 0.65
Config.WallBounce = 0.3

-- Distance d'interaction ALT « Retirer le tracker »
Config.PickupDistance = 2.0

-- Rayon (m) autour de l'impact d'une balle qui détruit le traceur
Config.ShotRadius = 0.35

-- Fréquence de rafraîchissement des points sur la carte (ms)
Config.UpdateInterval = 2000

-- Blip sur la carte GTA
Config.Blip = { sprite = 161, color = 27, scale = 0.8 }
Config.DefaultName = 'Tracker #%s'      -- %s = numéro de série (non renommé)
Config.RenamedName = 'Tracker : %s'     -- %s = nom choisi

-- Longueur max du nom d'un tracker
Config.MaxNameLength = 24

-- Lumière clignotante d'un tracker actif
Config.Light = { r = 255, g = 30, b = 60, range = 1.2, intensity = 6.0, period = 900 }
