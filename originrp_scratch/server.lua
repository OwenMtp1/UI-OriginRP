local KVP_DAILY = 'originrp_scratch:daily'
local KVP_OWED = 'originrp_scratch:owed'

local Daily = { date = '', counts = {} }  -- tickets achetés aujourd'hui par identifiant
local Owed = {}                            -- gains en attente (ticket gratté mais pas encaissé) par identifiant

math.randomseed(os.time() + GetGameTimer())

-- ─── Persistance ───────────────────────────────────────────────────────────

local function today() return os.date('%Y-%m-%d') end

local function saveDaily() SetResourceKvp(KVP_DAILY, json.encode(Daily)) end
local function saveOwed() SetResourceKvp(KVP_OWED, json.encode(Owed)) end

CreateThread(function()
    local raw = GetResourceKvpString(KVP_DAILY)
    Daily = raw and json.decode(raw) or Daily
    raw = GetResourceKvpString(KVP_OWED)
    Owed = raw and json.decode(raw) or {}
end)

local function boughtToday(ident)
    if Daily.date ~= today() then
        Daily = { date = today(), counts = {} }
        saveDaily()
    end
    return Daily.counts[ident] or 0
end

-- ─── Utilitaires ───────────────────────────────────────────────────────────

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'SA Lottery', description = message, type = kind or 'inform',
        icon = 'ticket', position = Config.NotifyPosition,
    })
end

local function nearKiosk(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    for _, k in ipairs(Config.Kiosks) do
        if #(pos - k.xyz) <= Config.InteractDistance + 2.0 then return true end
    end
    return false
end

-- Paie un gain resté en attente (déconnexion pendant le grattage, etc.)
local function payOwed(src)
    local ident = ServerConfig.GetIdentifier(src)
    local amount = Owed[ident]
    if not amount or amount <= 0 then return end
    if ServerConfig.AddMoney(src, amount) then
        Owed[ident] = nil
        saveOwed()
        notify(src, ('Gain en attente encaissé : %d $'):format(amount), 'success')
    end
end

-- ─── Tirage ────────────────────────────────────────────────────────────────

-- Montant d'une case gagnante, selon les chances de Config.Amounts
local function pickAmount()
    local sum = 0
    for _, a in ipairs(Config.Amounts) do sum = sum + a.chance end
    local r = math.random() * sum
    for _, a in ipairs(Config.Amounts) do
        r = r - a.chance
        if r <= 0 then return a.amount end
    end
    return Config.Amounts[#Config.Amounts].amount
end

local function roll()
    local cases = { 0, 0, 0 }
    if math.random(1, 100) > Config.WinChance then return cases, 0 end

    local r, acc, count = math.random(1, 100), 0, 1
    for _, w in ipairs(Config.WinningCases) do
        acc = acc + w.chance
        if r <= acc then count = w.cases break end
    end

    -- cases gagnantes placées au hasard
    local slots = { 1, 2, 3 }
    for i = 3, 2, -1 do
        local j = math.random(1, i)
        slots[i], slots[j] = slots[j], slots[i]
    end

    local total = 0
    for i = 1, count do
        local amount = pickAmount()
        cases[slots[i]] = amount
        total = total + amount
    end
    return cases, total
end

-- ─── Borne ─────────────────────────────────────────────────────────────────

lib.callback.register('originrp_scratch:info', function(src)
    payOwed(src)
    local remaining = Config.DailyLimit - boughtToday(ServerConfig.GetIdentifier(src))
    return {
        price = Config.Price,
        remaining = math.max(remaining, 0),
        limit = Config.DailyLimit,
        money = ServerConfig.GetMoney(src),
    }
end)

lib.callback.register('originrp_scratch:buy', function(src, qty)
    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return { ok = false, message = 'Quantité invalide.' } end
    if not nearKiosk(src) then return { ok = false, message = 'Tu es trop loin de la borne.' } end

    local ident = ServerConfig.GetIdentifier(src)
    local remaining = Config.DailyLimit - boughtToday(ident)
    if remaining <= 0 then
        return { ok = false, message = ('Limite atteinte : %d tickets par jour.'):format(Config.DailyLimit), remaining = 0 }
    end
    if qty > remaining then
        return { ok = false, message = ('Tu ne peux plus acheter que %d ticket(s) aujourd\'hui.'):format(remaining), remaining = remaining }
    end

    local cost = qty * Config.Price
    if ServerConfig.GetMoney(src) < cost then
        return { ok = false, message = ('Il te faut %d $ en liquide.'):format(cost), remaining = remaining }
    end
    if not ServerConfig.CanCarryTickets(src, qty) then
        return { ok = false, message = 'Tu n\'as pas assez de place sur toi.', remaining = remaining }
    end
    if not ServerConfig.RemoveMoney(src, cost) then
        return { ok = false, message = 'Paiement refusé.', remaining = remaining }
    end
    if not ServerConfig.GiveTickets(src, qty) then
        ServerConfig.AddMoney(src, cost) -- remboursement
        return { ok = false, message = 'Impossible de te donner les tickets.', remaining = remaining }
    end

    Daily.counts[ident] = boughtToday(ident) + qty
    saveDaily()
    remaining = Config.DailyLimit - Daily.counts[ident]
    return {
        ok = true,
        message = ('%d ticket(s) acheté(s) pour %d $.'):format(qty, cost),
        remaining = remaining,
        money = ServerConfig.GetMoney(src),
    }
end)

-- ─── Ticket ────────────────────────────────────────────────────────────────

-- Le tirage est fait côté serveur au moment où le ticket est utilisé : le client
-- ne reçoit que les montants à afficher, et le gain est mis de côté jusqu'à l'encaissement.
lib.callback.register('originrp_scratch:open', function(src, slot)
    if not ServerConfig.GetTicketSlot(src, slot) then return nil end

    local ident = ServerConfig.GetIdentifier(src)
    payOwed(src) -- un ticket précédent non encaissé est payé d'abord

    if not ServerConfig.RemoveTicket(src, slot) then return nil end
    local cases, total = roll()

    Owed[ident] = total
    saveOwed()
    return { cases = cases, total = total }
end)

lib.callback.register('originrp_scratch:claim', function(src)
    local ident = ServerConfig.GetIdentifier(src)
    local amount = Owed[ident] or 0
    if amount > 0 then
        if not ServerConfig.AddMoney(src, amount) then
            notify(src, 'Pas assez de place : le gain sera versé plus tard.', 'error')
            return 0
        end
        notify(src, ('Ticket gagnant : %d $ !'):format(amount), 'success')
    end
    Owed[ident] = nil
    saveOwed()
    return amount
end)
