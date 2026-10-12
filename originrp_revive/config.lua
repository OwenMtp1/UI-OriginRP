Config = {}

-- Item nécessaire pour réanimer (ox_inventory)
Config.Item = 'medikit'
Config.ConsumeItem = true          -- le kit est consommé à la fin de la réanimation

-- Jobs autorisés : nil = tout le monde ayant un kit. Ex. { ambulance = 0, police = 2 }
Config.Jobs = nil

Config.Distance = 2.5              -- distance max pour lancer la réanimation (m)
Config.CancelKey = 73              -- X : annuler pendant l'animation

-- Déroulé (ms). Total = 9 000 ms, toujours sous les 10 s demandées.
Config.Steps = {
    approach = 600,   -- se placer à côté du torse
    kneel    = 1400,  -- s'agenouiller et poser le sac médical
    check    = 1500,  -- ouvrir le sac, prendre le pouls
    intro    = 900,   -- placer les mains
    cpr      = 3600,  -- massage cardiaque
    success  = 1000,  -- la personne reprend son souffle
}

-- Position du secouriste par rapport à la personne au sol (x = côté, y = vers la tête)
Config.MedicOffset = vector3(-0.6, 0.05, 0.0)
-- Position du sac médical posé au sol
Config.BagOffset = vector3(-0.55, -0.55, 0.0)

-- Accessoires. Sac d'intervention personnalisé (dossier stream/) : version fermée et ouverte.
-- Si les modèles ne sont pas installés, le sac GTA de secours est utilisé.
Config.Props = {
    bag = {
        closed = `orp_medbag_closed`,
        open = `orp_medbag_open`,
        fallback = `xm_prop_x17_bag_med_01a`,
        openAt = 0.3,   -- moment (0-1) de l'étape « check » où la main ouvre le sac
    },
    -- position du sac dans la main droite (sac GTA de secours / sac personnalisé : poignée en haut, origine au fond)
    hand = { bone = 57005, offset = vector3(0.36, 0.0, -0.04), rotation = vector3(-90.0, 0.0, 90.0) },
    handCustom = { bone = 57005, offset = vector3(0.42, 0.0, 0.0), rotation = vector3(0.0, 280.0, 53.0) },  -- à affiner en jeu
}

-- Animations GTA
Config.Anims = {
    putdown      = { 'pickup_object', 'putdown_low' },
    kneelEnter   = { 'amb@medic@standing@kneel@enter', 'enter' },
    check        = { 'amb@medic@standing@tendtodead@idle_a', 'idle_a' },
    medicIntro   = { 'mini@cpr@char_a@cpr_def', 'cpr_intro' },
    patientIntro = { 'mini@cpr@char_b@cpr_def', 'cpr_intro' },
    medicCpr     = { 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest' },
    patientCpr   = { 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest' },
    medicWin     = { 'mini@cpr@char_a@cpr_str', 'cpr_success' },
    patientWin   = { 'mini@cpr@char_b@cpr_str', 'cpr_success' },
    kneelExit    = { 'amb@medic@standing@kneel@exit', 'exit' },
}

-- Caméra cinématique pendant la réanimation (secouriste et patient)
Config.CinematicCamera = true

Config.NotifyPosition = 'top-right'
Config.Messages = {
    noKit = 'Il te faut un kit de soin.',
    noJob = "Tu n'es pas habilité à réanimer.",
    notDead = "Cette personne n'a pas besoin d'être réanimée.",
    tooFar = 'Rapproche-toi de la personne.',
    busy = 'Une réanimation est déjà en cours.',
    cancelled = 'Réanimation annulée.',
    medicDone = 'Tu as réanimé %s.',
    patientDone = 'Tu as été réanimé par %s.',
    nobody = 'Personne à réanimer à proximité.',
}
