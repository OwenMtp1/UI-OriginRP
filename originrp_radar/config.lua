Config = {}

-- Vitesse de base (km/h) quand un radar n'a pas de limite propre
Config.DefaultLimit = 70

-- Tolérance avant flash (km/h) : 0 = flashé dès 71 km/h
Config.Tolerance = 0

-- Barème : amende selon l'écart au-dessus de la limite (km/h). De 100 $ à 1500 $.
Config.Fines = {
    { over = 10,       amount = 100 },   --  1 à 10 km/h
    { over = 20,       amount = 250 },   -- 11 à 20
    { over = 30,       amount = 400 },   -- 21 à 30
    { over = 40,       amount = 600 },   -- 31 à 40
    { over = 50,       amount = 800 },   -- 41 à 50
    { over = 60,       amount = 1000 },  -- 51 à 60
    { over = 80,       amount = 1250 },  -- 61 à 80
    { over = math.huge, amount = 1500 }, -- plus de 80 km/h
}

Config.Message = 'Une amende pour vitesse excessive de %s $ vous a été distribuée'
Config.NotifyPosition = 'top-right'

-- Un même véhicule n'est pas reflashé par le même radar avant ce délai (s)
Config.Cooldown = 30

-- Zone de détection : distance au radar (m) et angle du cône devant la caméra (degrés)
Config.DetectRadius = 25.0
Config.DetectAngle = 70.0

-- Classes de véhicules exemptées (18 = urgences : police, ambulance...)
Config.ExemptClasses = { [18] = true }

-- Prop du radar (caméra sur poteau)
Config.Model = `prop_cctv_pole_01a`
Config.Blip = { enabled = true, sprite = 184, color = 1, scale = 0.6, label = 'Radar de vitesse' }

-- Indestructible SAUF par ces explosions (types GTA) :
--  2 = bombe collante, 4 = roquette (lance-missile / lance-missile guidé)
Config.DestroyExplosions = { [2] = true, [4] = true }
Config.DestroyRadius = 4.0
-- Temps avant que le radar soit réinstallé (min)
Config.RespawnMinutes = 30

-- Radars fixes. heading = direction dans laquelle la caméra regarde (vers les véhicules qui arrivent).
Config.Radars = {
    { coords = vector3(239.8, -1020.5, 29.2), heading = 340.0, limit = 70 },
    { coords = vector3(-542.1, -846.3, 29.4), heading = 90.0 },
    { coords = vector3(1056.2, -393.9, 67.1), heading = 220.0, limit = 90 },
}

-- Commande admin pour poser un radar à sa position (sauvegardé) : /radar add [limite] | /radar remove
Config.AdminAce = 'command.radar'
