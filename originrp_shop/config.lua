Config = {}

Config.Title = 'Boutique OriginRP'
Config.Subtitle = 'Dépense tes Orins en véhicules, armes, packs et VIP'

-- Monnaie de la boutique
Config.Currency = { name = 'Orins', short = 'OR' }

-- Ouverture : commande et touche (nil pour désactiver la touche)
Config.Command = 'boutique'
Config.Key = nil            -- ex. 'F1'

-- Lien du site où acheter des Orins (Tebex…), ouvert dans le navigateur du joueur
Config.BuyUrl = 'https://originrp.tebex.io'

-- Packs d'Orins affichés sur l'accueil (achat sur le site ci-dessus)
Config.OrinPacks = {
    { amount = 500,  price = '4,99 €' },
    { amount = 1100, price = '9,99 €',  bonus = '+10 %' },
    { amount = 2400, price = '19,99 €', bonus = '+20 %', popular = true },
    { amount = 6500, price = '49,99 €', bonus = '+30 %' },
}

-- Catégories (onglets). icon : car, weapon, box, crown
Config.Categories = {
    { id = 'vehicles', label = 'Véhicules', icon = 'car' },
    { id = 'weapons',  label = 'Armes',     icon = 'weapon' },
    { id = 'packs',    label = 'Packs',     icon = 'box' },
    { id = 'vip',      label = 'VIP',       icon = 'crown' },
}

--[[
    Articles. Le prix est TOUJOURS relu ici par le serveur (jamais celui
    envoyé par la tablette).
        id          identifiant unique
        category    id d'une catégorie ci-dessus
        label       nom affiché
        description texte court (optionnel)
        price       prix en Orins
        image       'img/fichier.png' dans html/img/ ou URL (optionnel)
        tag         petite étiquette (optionnel), ex. 'Nouveau', '-20 %'
        featured    true pour l'afficher « À la une » sur l'accueil
        data        infos libres transmises à GiveItem (modèle, arme, durée…)
]]
Config.Items = {
    { id = 'sultanrs', category = 'vehicles', label = 'Karin Sultan RS', description = 'Sportive 4 portes, idéale en ville.', price = 1500, tag = 'Nouveau', featured = true, data = { model = 'sultanrs' } },
    { id = 'comet', category = 'vehicles', label = 'Pfister Comet', description = 'Coupé sport classique.', price = 2200, data = { model = 'comet2' } },
    { id = 'pistol', category = 'weapons', label = 'Pistolet', description = 'Arme de poing + 50 munitions.', price = 600, data = { weapon = 'WEAPON_PISTOL', ammo = 50 } },
    { id = 'starter', category = 'packs', label = 'Pack Démarrage', description = '25 000 $ + téléphone + kit de soin.', price = 800, featured = true, data = { money = 25000 } },
    { id = 'vip_gold', category = 'vip', label = 'VIP Gold · 30 jours', description = 'Salaire +20 %, garage étendu, tenue exclusive.', price = 1200, tag = 'Populaire', featured = true, data = { vip = 'gold', days = 30 } },
}
