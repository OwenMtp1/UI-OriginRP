--[[
    À BRANCHER SUR LA BASE (côté serveur uniquement).

    Le solde d'Orins est commun à tous les personnages : utiliser la licence
    Rockstar / l'identifiant du compte, pas celui du personnage.
]]

ServerConfig = {}

-- Solde d'Orins du joueur (nombre)
ServerConfig.GetBalance = function(source)
    return 0
end

-- Retire des Orins. Doit renvoyer true si c'est fait (solde suffisant).
ServerConfig.RemoveBalance = function(source, amount)
    return false
end

-- Rembourse (appelé si GiveItem échoue après le paiement)
ServerConfig.AddBalance = function(source, amount)
end

-- Donne l'article (véhicule, arme, pack, VIP…). item = ligne de Config.Items.
-- Doit renvoyer true, ou false + raison pour annuler et rembourser.
ServerConfig.GiveItem = function(source, item)
    return false, "Livraison non configurée."
end

-- VIP actif : { label = 'VIP Gold', expires = '26/10/2026' } ou nil
ServerConfig.GetVip = function(source)
    return nil
end

-- Historique des achats, du plus récent au plus ancien :
-- { { label = 'Karin Sultan RS', price = 1500, date = '27/09/2026 14:32' }, ... }
ServerConfig.GetHistory = function(source)
    return {}
end

-- Enregistre un achat dans l'historique (base de données)
ServerConfig.AddHistory = function(source, item)
end
