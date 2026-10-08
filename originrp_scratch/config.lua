Config = {}

Config.TicketItem = 'scratch_ticket'
Config.Price = 500             -- prix d'un ticket ($)
Config.DailyLimit = 40         -- tickets max par joueur et par jour (remis à zéro à minuit, heure du serveur)

-- Probabilités (en %)
Config.WinChance = 60          -- 60 % de tickets gagnants, 40 % de tickets à 0 $ partout
Config.WinningCases = {        -- parmi les tickets gagnants : nombre de cases gagnantes
    { cases = 1, chance = 50 },
    { cases = 2, chance = 30 },
    { cases = 3, chance = 20 },
}
-- Montant d'une case gagnante : chaque montant a la même chance
Config.Amounts = { 50, 100, 200, 500 }

-- Bornes : coords = position au sol, w = orientation (la face avant regarde dans cette direction)
-- Positions d'exemple devant des supérettes : ajuste-les sur ton serveur.
Config.Kiosks = {
    vector4(29.9, -1349.6, 29.33, 180.0),     -- 24/7 Strawberry (Innocence Blvd)
    vector4(-50.2, -1755.4, 29.42, 50.0),     -- LTD Davis (Grove St)
    vector4(1136.5, -982.3, 46.42, 275.0),    -- Rob's Liquor Mirror Park
}
Config.Model = `prop_vend_snak_01`  -- distributeur GTA (~2 m), remplaçable par un prop streamé
Config.InteractDistance = 2.0
Config.TargetLabel = 'Achetez un ticket de grattage'

Config.Blip = { enabled = true, sprite = 431, color = 2, scale = 0.7, label = 'Tickets à gratter' }
Config.NotifyPosition = 'top-right'
