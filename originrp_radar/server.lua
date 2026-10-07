local KVP_KEY = 'originrp_radar:custom'
local Radars = {}     -- id -> { id, x, y, z, h, limit, custom }
local Down = {}       -- id -> timestamp de réinstallation
local LastFlash = {}  -- 'source:id' -> os.time()

-- ─── Liste des radars ──────────────────────────────────────────────────────

local function publish()
    local list = {}
    for _, r in pairs(Radars) do list[#list + 1] = r end
    table.sort(list, function(a, b) return a.id < b.id end)
    GlobalState.radarList = list
    GlobalState.radarDown = Down
end

local function saveCustom()
    local custom = {}
    for _, r in pairs(Radars) do
        if r.custom then custom[#custom + 1] = r end
    end
    SetResourceKvp(KVP_KEY, json.encode(custom))
end

CreateThread(function()
    for i, r in ipairs(Config.Radars) do
        local id = 'cfg' .. i
        Radars[id] = { id = id, x = r.coords.x, y = r.coords.y, z = r.coords.z, h = r.heading, limit = r.limit or Config.DefaultLimit }
    end
    local raw = GetResourceKvpString(KVP_KEY)
    for _, r in ipairs(raw and json.decode(raw) or {}) do Radars[r.id] = r end
    publish()
end)

-- ─── Amendes ───────────────────────────────────────────────────────────────

local function fineFor(over)
    for _, tier in ipairs(Config.Fines) do
        if over <= tier.over then return tier.amount end
    end
    return Config.Fines[#Config.Fines].amount
end

RegisterNetEvent('originrp_radar:flash', function(id)
    local src = source
    local radar = Radars[id]
    if not radar or Down[id] then return end

    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return end

    local pos = GetEntityCoords(veh)
    if #(pos - vector3(radar.x, radar.y, radar.z)) > Config.DetectRadius + 15.0 then return end

    -- vitesse mesurée côté serveur (le client ne peut pas tricher sur le montant)
    local speed = math.floor(#GetEntityVelocity(veh) * 3.6 + 0.5)
    local over = speed - radar.limit
    if over <= Config.Tolerance then return end

    local key = src .. ':' .. id
    local now = os.time()
    if LastFlash[key] and now - LastFlash[key] < Config.Cooldown then return end
    LastFlash[key] = now

    local amount = fineFor(over)
    ServerConfig.RemoveBankMoney(src, amount)
    ServerConfig.OnFine(src, amount, speed, radar.limit, id)

    TriggerClientEvent('originrp_radar:flashed', src, {
        speed = speed, limit = radar.limit, amount = amount, plate = GetVehicleNumberPlateText(veh),
    })
end)

AddEventHandler('playerDropped', function()
    local prefix = source .. ':'
    for key in pairs(LastFlash) do
        if key:sub(1, #prefix) == prefix then LastFlash[key] = nil end
    end
end)

-- ─── Destruction : uniquement bombe collante / roquette ────────────────────

AddEventHandler('explosionEvent', function(_, ev)
    if not Config.DestroyExplosions[ev.explosionType] then return end
    local pos = vector3(ev.posX, ev.posY, ev.posZ)
    local changed = false
    for id, r in pairs(Radars) do
        if not Down[id] and #(pos - vector3(r.x, r.y, r.z)) <= Config.DestroyRadius then
            Down[id] = os.time() + Config.RespawnMinutes * 60
            changed = true
            TriggerClientEvent('originrp_radar:destroyed', -1, id)
        end
    end
    if changed then publish() end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now, changed = os.time(), false
        for id, t in pairs(Down) do
            if now >= t then Down[id] = nil changed = true end
        end
        if changed then publish() end
    end
end)

-- ─── Commande admin ────────────────────────────────────────────────────────

RegisterCommand('radar', function(src, args)
    if src == 0 then return end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)

    if args[1] == 'add' then
        local id = ('c%d'):format(os.time())
        Radars[id] = {
            id = id, x = c.x, y = c.y, z = c.z - 1.0, h = GetEntityHeading(ped),
            limit = tonumber(args[2]) or Config.DefaultLimit, custom = true,
        }
        saveCustom(); publish()
        TriggerClientEvent('ox_lib:notify', src, { description = ('Radar posé (%d km/h).'):format(Radars[id].limit), type = 'success' })
    elseif args[1] == 'remove' then
        local best, dist
        for id, r in pairs(Radars) do
            local d = #(c - vector3(r.x, r.y, r.z))
            if r.custom and d < 10.0 and (not dist or d < dist) then best, dist = id, d end
        end
        if best then
            Radars[best] = nil
            saveCustom(); publish()
            TriggerClientEvent('ox_lib:notify', src, { description = 'Radar supprimé.', type = 'success' })
        end
    end
end, true)
