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

-- Accessoires. Vérifie les noms de modèles sur ton serveur (un modèle inconnu est simplement ignoré).
Config.Props = {
    bag = { model = `xm_prop_x17_bag_med_01a`, fallback = `prop_ld_health_pack` },
    hand = { bone = 57005, offset = vector3(0.36, 0.0, -0.04), rotation = vector3(-90.0, 0.0, 90.0) },
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
