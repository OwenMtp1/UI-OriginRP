Config = {}

-- ─── Items (ox_inventory) ──────────────────────────────────────────────────
Config.Items = {
    case = 'drone_case',          -- mallette complète (drone + radiocommande), métadonnées : batterie, vie, n° de série
    drone = 'drone_or_d2',        -- drone de remplacement à installer dans une mallette vide
    jammer = 'brouilleur_gps',    -- brouilleur GPS posable
    wreck = 'drone_epave',        -- épave récupérée après destruction (preuve, revente…)
}

-- Qui peut utiliser une mallette posée par quelqu'un d'autre ? (le propriétaire peut toujours)
-- nil = tout le monde. Ex. { police = 0, sheriff = 0 }
Config.SharedJobs = { police = 0, sheriff = 0 }

-- ─── Modèles ───────────────────────────────────────────────────────────────
-- true : props OriginRP du dossier stream/ (à générer avec CodeWalker, voir README)
-- false : props GTA de remplacement
Config.CustomProps = true

Config.Models = {
    case       = { custom = `orp_dronecase`,      fallback = `prop_gun_case_01` },
    caseOpen   = { custom = `orp_dronecase_open`, fallback = `prop_gun_case_01` },
    drone      = { custom = `orp_drone`,          fallback = `ch_prop_casino_drone_01a` },
    droneFold  = { custom = `orp_drone_folded`,   fallback = `ch_prop_casino_drone_01a` },
    wreck      = { custom = `orp_drone_wreck`,    fallback = `ch_prop_casino_drone_01a` },
    controller = { custom = `orp_drone_rc`,       fallback = `prop_cs_tablet` },
    jammer     = { custom = `prop_cs_walkie_talkie`, fallback = `prop_cs_walkie_talkie` },
}

-- ─── Vol ───────────────────────────────────────────────────────────────────
Config.Flight = {
    maxSpeed = 18.0,        -- m/s (≈ 65 km/h)
    boostSpeed = 24.0,      -- m/s avec Maj
    climb = 5.0,            -- m/s vertical
    yawSpeed = 90.0,        -- °/s
    accel = 1.6,            -- réactivité (plus haut = plus nerveux)
    maxAltitude = 120.0,    -- au-dessus du sol
    takeoffHeight = 3.0,
    fovMax = 70.0, fovMin = 8.0,   -- zoom optique ×1 à ×8 environ
}

-- ─── Vie du drone (barre de vie) ───────────────────────────────────────────
Config.Health = {
    max = 100,
    collisionMinSpeed = 4.0,   -- m/s : en dessous, un contact ne fait pas de dégâts
    collisionDamage = 6.0,     -- dégâts par m/s au-dessus du seuil (≈ 4 chocs francs détruisent le drone)
    collisionMax = 45,         -- dégâts max par choc
    collisionCooldown = 1000,  -- ms entre deux chocs comptés
    bulletDamage = 34,         -- dégâts par balle (3 balles = détruit)
    weaponDamage = {           -- surcharge par arme (hash → dégâts)
        [`WEAPON_STUNGUN`] = 100,
        [`WEAPON_SNIPERRIFLE`] = 100, [`WEAPON_HEAVYSNIPER`] = 100, [`WEAPON_PUMPSHOTGUN`] = 70,
    },
    explosionRadius = 4.0,     -- une explosion à moins de 4 m détruit le drone
}

-- ─── Batterie : 2 h de vol, recharge dans la mallette ──────────────────────
Config.Battery = {
    flightSeconds = 7200,      -- 100 % → 0 % en 2 h de vol
    chargeSeconds = 3600,      -- 0 % → 100 % en 1 h rangé dans sa mallette (posée ou dans l'inventaire)
    warn = { 20, 10, 5 },      -- alertes à l'écran (%)
    landAt = 2,                -- en dessous : atterrissage forcé
}

-- ─── Liaison radio, portée et brouillage ───────────────────────────────────
Config.Signal = {
    range = 350.0,             -- au-delà : AUCUN SIGNAL (hors de portée) + retour automatique
    weakFrom = 250.0,          -- image qui se dégrade
    jamLandAfter = 20,         -- s brouillé avant atterrissage d'urgence sur place
}

-- Brouilleur GPS (item posable) — d'autres scripts peuvent aussi en créer via l'export AddJammer
Config.Jammer = {
    radius = 60.0,
    duration = 600,            -- s actif une fois posé
    pickup = true,             -- ramassable (ALT)
}

-- ─── Épave ─────────────────────────────────────────────────────────────────
Config.Wreck = {
    lifetime = 900,            -- s avant disparition
    smoke = { dict = 'core', name = 'ent_amb_smoke_foundry', scale = 0.55 },     -- fumée noire sur l'épave
    trail = { dict = 'core', name = 'ent_amb_smoke_foundry', scale = 0.35 },     -- traînée pendant la chute
}

-- ─── Touches (contrôles GTA) ───────────────────────────────────────────────
Config.Keys = {
    up = 22, down = 36,              -- Espace / Ctrl gauche
    yawLeft = 44, yawRight = 38,     -- Q / E
    boost = 21,                      -- Maj
    vision = 306,                    -- N
    light = 182,                     -- L
    rec = 45,                        -- R
    rth = 74,                        -- H
    place = 47,                      -- G : poser / reprendre la radiocommande
    exit = 177,                      -- Retour arrière / Échap : quitter le pilotage (le drone atterrit)
    zoomIn = 241, zoomOut = 242,     -- molette
}

-- Animations
Config.Anims = {
    place     = { 'anim@heists@money_grab@briefcase', 'put_down_case' },
    kneel     = { 'amb@medic@standing@tendtodead@idle_a', 'idle_a' },
    kneelIdle = { 'amb@medic@standing@kneel@base', 'base' },
    holdRC    = { 'amb@world_human_seat_wall_tablet@female@base', 'base' },
    pickup    = { 'pickup_object', 'pickup_low' },
}

-- Position de la radiocommande dans les mains (os 28422 = main droite)
Config.RCAttach = { bone = 28422, offset = vector3(0.0, -0.02, -0.02), rotation = vector3(10.0, 0.0, 0.0) }

Config.Deploy = {
    duration = 6500,           -- ms : loquets, couvercle, sortie du drone, bras dépliés
    pickupCtrl = 2500,         -- ms : prise de la radiocommande
    droneOffset = vector3(-0.9, 0.2, 0.0),   -- drone posé à droite de la mallette
}

Config.NotifyPosition = 'top-right'
Config.Messages = {
    notOwner = "Cette mallette ne t'appartient pas.",
    noDrone = 'La mallette est vide : installe un drone OR-D2.',
    tooFar = 'Le drone doit être posé près de sa mallette.',
    deployed = 'Drone déployé. Prends la radiocommande pour le piloter.',
    stored = 'Drone rangé, la batterie se recharge.',
    destroyed = 'Ton drone a été détruit.',
    batteryEmpty = 'Batterie vide : atterrissage forcé.',
    jammerPlaced = 'Brouilleur GPS actif.',
}
