Config = {}

-- Framework pour lire l'identité : 'auto' (ESX ou QBCore), 'esx', 'qb'
-- ou 'custom' (utilise Config.GetIdentity ci-dessous)
Config.Framework = 'auto'

-- Commandes (nil pour désactiver)
Config.CommandSelf = 'carte'          -- regarder sa propre carte
Config.CommandShow = 'montrercarte'   -- montrer sa carte au joueur le plus proche
Config.CommandLicenseSelf = 'permis'          -- regarder son permis
Config.CommandLicenseShow = 'montrerpermis'   -- montrer son permis au joueur le plus proche

-- Refuser d'afficher le permis si le joueur n'a aucune catégorie
Config.RequireLicense = true

-- ESX (esx_license) : nom des licences pour chaque catégorie
Config.EsxLicenseTypes = { car = 'drive', bike = 'drive_bike', truck = 'drive_truck' }

-- Distance max (mètres) pour montrer sa carte à quelqu'un
Config.ShowDistance = 3.0

-- Durée d'affichage en millisecondes (0 = jusqu'à Retour arrière / Échap)
Config.Duration = 10000

-- Position : 'center', 'right', 'left'
Config.Position = 'right'

-- Lieu de naissance quand la base n'en a pas
Config.DefaultBirthplace = 'Los Santos'

--[[
    Pour une base sans ESX / QBCore, ou pour ajouter des infos (date de
    création, numéro, photo…), mettre Config.Framework = 'custom' et
    compléter cette fonction (côté serveur). Elle doit renvoyer :
    {
        lastname = 'Azar', firstname = 'Raph',
        sex = 'm',                    -- 'm' / 'f' (ou 'Homme' / 'Femme')
        birthdate = '22/11/2001',     -- 'JJ/MM/AAAA' ou 'AAAA-MM-JJ'
        height = 185,                 -- en cm (optionnel)
        birthplace = 'Los Santos',    -- optionnel
        created = '31/07/2025',       -- date de création (optionnel)
        number = 'LS-004815',         -- n° de carte (optionnel)
        photo = 'https://…',          -- URL d'une photo (optionnel, sinon vide)
    }
]]
Config.GetIdentity = function(source)
    return nil
end

-- Base sans ESX / QBCore : catégories du permis du joueur (côté serveur)
-- Doit renvoyer { car = true/false, bike = true/false, truck = true/false }
Config.GetLicenses = function(source)
    return nil
end
