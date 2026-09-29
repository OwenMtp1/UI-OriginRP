Config = {}

-- Zones du corps et prix par motif (le prix d'un motif peut aussi être donné motif par motif)
Config.Zones = {
    { id = 'head',      label = 'Tête',     icon = 'head',  price = 300 },
    { id = 'torso',     label = 'Torse',    icon = 'torso', price = 400 },
    { id = 'left_arm',  label = 'Bras G.',  icon = 'arm',   price = 250 },
    { id = 'right_arm', label = 'Bras D.',  icon = 'arm',   price = 250 },
    { id = 'left_leg',  label = 'Jambe G.', icon = 'leg',   price = 250 },
    { id = 'right_leg', label = 'Jambe D.', icon = 'leg',   price = 250 },
}

-- Degrés de rotation du personnage par appui sur A / E
Config.RotateStep = 20
