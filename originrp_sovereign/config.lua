Config = {}

Config.Weapon = {
    name = 'WEAPON_ORPSOVEREIGN',
    label = 'ORIGIN Sovereign',
    labelKey = 'WT_ORPSOV',
}

-- Finitions vendues en boutique (composants « skin »). Ajoute tes futurs camos ici
-- après avoir généré leur modèle (voir README) et les avoir déclarés dans tools/clone_pistol.py (SKINS).
Config.Skins = {
    { item = 'at_orpsov_halloween', label = 'Édition Halloween', component = 'COMPONENT_ORPSOVEREIGN_SKIN_HW', price = 6400 },
}

-- prix de l'arme (finition noire d'origine)
Config.WeaponPrice = 18500
