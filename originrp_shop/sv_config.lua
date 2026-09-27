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


--[[
    CATALOGUE MODIFIABLE EN JEU (optionnel)

    Par défaut la boutique utilise Config.Items (config.lua).
    Pour que les modifications faites dans la tablette admin soient gardées,
    stocker le catalogue en base et renvoyer ici la liste (même format que
    config.lua). nil = utiliser config.lua.
]]
ServerConfig.GetItems = function() return nil end

-- Réglages : { title, subtitle, rechargeUrl, open = true/false,
--              currencyName, currencyShort }  (nil = config.lua)
ServerConfig.GetSettings = function() return nil end

--[[
    GESTION INTERNE (tablette admin)

    GetAdminData(source, context) doit renvoyer :
    {
        since = '26/09/2026',                      -- début des statistiques
        stats = {
            orinsSold = 0, orders = 0, refunds = 0, pendingAccounts = 0,
            ingamePurchases = 0, orinsSpent = 0, vipActive = 0, negativeBalances = 0,
        },
        breakdown = { vehicles = 0, weapons = 0, packs = 0, vip = 0 },   -- achats par catégorie
        recentOrders = {   -- commandes du site (Tebex…)
            { player = 'Malou', label = 'Pack 2 400 OR', amount = 2400, price = '19,99 €', date = '27/09 14:02', status = 'ok' },
            -- status : 'ok', 'pending' (compte pas encore lié), 'refunded'
        },
        recentMoves = {    -- mouvements d'Orins
            { player = 'Malou', label = 'Achat Karin Sultan RS', amount = -1500, date = '27/09 14:05' },
        },
        players = { ... },         -- résultats de recherche pour context.query :
            -- { id = 'license:xxx', name = 'Malou Malou', balance = 350, vip = 'VIP Gold', purchases = 3, online = true }
        selectedPlayer = { ... },  -- joueur context.selected (mêmes champs + history = { ... })
    }

    OnAdminAction(source, action, payload) : appliquer l'action, renvoyer ok, message.
        'resetStats'    {}
        'saveSettings'  { title, subtitle, open, currencyName, currencyShort }
        'saveItem'      { item = { id, category, label, description, price, image, tag, featured, data }, new = true/false }
        'deleteItem'    { id }
        'adjustBalance' { id = identifiant joueur, amount = +/- n, reason = '...' }
    (La permission admin est déjà vérifiée par server.lua avant l'appel.)
]]
ServerConfig.GetAdminData = function(source, context)
    return {}
end

ServerConfig.OnAdminAction = function(source, action, payload)
    return false, "Gestion non configurée (sv_config.lua)."
end
