Config = {}

Config.Item = 'electronic_bracelet'

-- Jobs autorisés à poser / retirer un bracelet. nil = tout le monde peut le poser.
Config.AllowedJobs = nil -- ex. { police = 0, sheriff = 0 } (job = grade minimum)

-- Jobs autorisés à retirer un bracelet (option ALT « Retirer le bracelet électronique », rend l'item)
Config.RemoveJobs = { police = 0, sheriff = 0 }

-- Mode « pose » : durée pendant laquelle l'option ALT reste disponible après avoir utilisé l'item (ms)
Config.SelectTimeout = 15000
Config.TargetDistance = 2.0

-- Pose : durée et animation (accroupi au niveau de la jambe)
Config.Duration = 3000
Config.Anim = { dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a' }
-- Position du poseur par rapport à la personne (devant elle, légèrement à sa gauche, au niveau de la jambe)
Config.KneelOffset = vector3(-0.15, 0.62, 0.0)

-- Notifications (en bas à gauche)
Config.NotifyPosition = 'bottom-left'
Config.Messages = {
    placed = 'Vous avez mis un bracelet électronique à %s',
    received = 'Un bracelet électronique vous a été mis à la jambe',
    removed = 'Vous avez retiré le bracelet électronique de %s',
    removedTarget = 'Votre bracelet électronique a été retiré',
    already = 'Cette personne porte déjà un bracelet électronique.',
    choose = 'Faites ALT sur la personne à qui mettre le bracelet.',
    cancelled = 'Pose du bracelet annulée.',
    noJob = "Vous n'êtes pas habilité à poser un bracelet électronique.",
    tooFar = 'La personne est trop loin.',
}

-- Prop du bracelet attaché à la cheville gauche.
-- Aucun bracelet électronique n'existe dans GTA de base : remplacez par votre prop streamé
-- (ex. `originrp_ankle_monitor`). En attendant on utilise un petit boîtier vanilla.
Config.Prop = {
    model = `prop_cs_cuffs_01`,
    bone = 14201,                           -- SKEL_L_Foot (cheville gauche)
    offset = vector3(-0.09, 0.0, 0.02),
    rotation = vector3(0.0, 90.0, 0.0),
}

-- Jambes découvertes : le bracelet n'est visible QUE si le bas (composant 4)
-- fait partie de ces drawables. Tout autre pantalon = long pantalon → bracelet caché.
-- Ces numéros sont des exemples (shorts / sous-vêtements des peds freemode) :
-- vérifiez-les avec votre pack de vêtements.
Config.UncoveredLegs = {
    [`mp_m_freemode_01`] = { [12] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [42] = true, [54] = true, [61] = true, [62] = true },
    [`mp_f_freemode_01`] = { [2] = true, [10] = true, [12] = true, [14] = true, [15] = true, [16] = true, [17] = true, [25] = true },
}
-- Pour les peds non freemode (ped addon...) : bracelet visible ou non
Config.ShowOnOtherPeds = true

-- Distance à laquelle les bracelets des autres joueurs sont affichés
Config.StreamDistance = 40.0
