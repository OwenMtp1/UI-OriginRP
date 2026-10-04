Config = {}

-- Âge et taille autorisés
Config.MinAge = 18
Config.MaxAge = 90
Config.HeightMin = 150
Config.HeightMax = 210

-- Caméras (distance devant le personnage, hauteur, champ de vision)
Config.Cameras = {
    face  = { distance = 0.75, height = 0.65, fov = 32 },
    torso = { distance = 1.5,  height = 0.35, fov = 40 },
    body  = { distance = 2.8,  height = 0.05, fov = 45 },
}

-- Degrés de rotation par appui sur A / E
Config.RotateStep = 15

-- Vêtements : composants / accessoires GTA
Config.Clothes = {
    tops       = { component = 11 },
    undershirt = { component = 8 },
    arms       = { component = 3 },
    pants      = { component = 4 },
    shoes      = { component = 6 },
    chain      = { component = 7 },
    hat        = { prop = 0 },
    glasses    = { prop = 1 },
}

-- Tenues de départ (seul choix vestimentaire proposé à la création) : { modèle, couleur } par pièce.
-- La première tenue de chaque liste est appliquée par défaut.
-- Valeurs indicatives pour les modèles freemode de base : à ajuster selon les
-- vêtements installés sur le serveur.
Config.Outfits = {
    m = {
        { label = 'Décontracté',  desc = 'T-shirt, jean et baskets', clothes = { tops = { 0, 0 }, undershirt = { 15, 0 }, arms = { 0, 0 }, pants = { 1, 0 }, shoes = { 1, 0 } } },
        { label = 'Sportswear',   desc = 'Survêtement et running', clothes = { tops = { 7, 0 }, undershirt = { 15, 0 }, arms = { 0, 0 }, pants = { 5, 0 }, shoes = { 31, 0 } } },
        { label = 'Chic',         desc = 'Chemise, pantalon et chaussures de ville', clothes = { tops = { 4, 0 }, undershirt = { 31, 0 }, arms = { 4, 0 }, pants = { 10, 0 }, shoes = { 10, 0 } } },
    },
    f = {
        { label = 'Décontractée', desc = 'Top, jean et baskets', clothes = { tops = { 0, 0 }, undershirt = { 14, 0 }, arms = { 0, 0 }, pants = { 0, 0 }, shoes = { 1, 0 } } },
        { label = 'Sportswear',   desc = 'Brassière, legging et running', clothes = { tops = { 10, 0 }, undershirt = { 14, 0 }, arms = { 5, 0 }, pants = { 10, 0 }, shoes = { 10, 0 } } },
        { label = 'Chic',         desc = 'Chemisier, pantalon et escarpins', clothes = { tops = { 7, 0 }, undershirt = { 14, 0 }, arms = { 5, 0 }, pants = { 6, 0 }, shoes = { 0, 0 } } },
    },
}
