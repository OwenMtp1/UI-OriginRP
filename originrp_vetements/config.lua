Config = {}

-- Catégories et prix. component = composant GTA, prop = accessoire GTA.
-- Le nombre de modèles et de couleurs est lu automatiquement sur le personnage.
Config.Categories = {
    { id = 'tops',       label = 'Haut',        icon = 'top',        component = 11, price = 120 },
    { id = 'undershirt', label = 'Sous-vêt.',   icon = 'undershirt', component = 8,  price = 60 },
    { id = 'pants',      label = 'Pantalon',    icon = 'pants',      component = 4,  price = 90 },
    { id = 'shoes',      label = 'Chaussures',  icon = 'shoes',      component = 6,  price = 80 },
    { id = 'hats',       label = 'Couvre-chef', icon = 'hat',        prop = 0,       price = 45 },
    { id = 'gloves',     label = 'Gants',       icon = 'gloves',     component = 3,  price = 35 },
    { id = 'bags',       label = 'Sac',         icon = 'bag',        component = 5,  price = 150 },
    { id = 'glasses',    label = 'Lunettes',    icon = 'glasses',    prop = 1,       price = 55 },
}

-- Degrés de rotation du personnage par appui sur A / E
Config.RotateStep = 20
