--[[
    Ouvrir le garage (depuis le script de garage de la base) :

    exports['<nom de la ressource>']:open({
        id = 'pillbox',                       -- identifiant du garage (renvoyé à la sortie)
        title = 'Garage',                     -- optionnel
        subtitle = 'Parking de Pillbox Hill', -- optionnel
        tabs = {                              -- un ou plusieurs onglets
            {
                id = 'perso', label = 'Mes véhicules', icon = 'car',
                vehicles = {
                    {
                        label = 'Karin Sultan RS', plate = 'ORG 123',
                        fuel = 80,                           -- en % (optionnel)
                        engine = 95, body = 70,              -- en % : la clé à molette affiche
                                                             -- l'état général (moyenne des deux)
                        model = 'sultanrs',                  -- sert à deviner la catégorie
                        category = 'car',   -- optionnel, sinon déduite du modèle :
                                            -- garage : car, bike, truck
                                            -- port   : boat, jetski, sub
                                            -- hangar : plane, heli
                        state = 'garage',   -- 'garage' (disponible), 'out' (déjà sorti), 'impound' (fourrière)
                        -- + tous les champs utiles au script (model, props, id…)
                    },
                },
            },
        },
    }, function(vehicle, garageId, tabId)
        -- le joueur a choisi « Sortir » : faire apparaître le véhicule
    end)

    Sans fonction, l'événement client '<nom de la ressource>:takeOut' est
    déclenché avec (vehicle, garageId, tabId).
    icon d'onglet : car, bike, truck, boat, plane, heli, users (entreprise / organisation)

    Fourrière (Config.Type = 'impound') : champs en plus pour chaque véhicule
        price = 250,                       -- frais à payer
        reason = 'Stationnement gênant',   -- motif (optionnel)
        date = '27/09 18:42',              -- date de mise en fourrière (optionnel)
        locked = true,                     -- saisie police : non récupérable (optionnel)
    et au niveau du menu : money = 1250   -- argent du joueur (optionnel, grise les
                                            véhicules trop chers)
    La fonction de retour est appelée quand le joueur confirme le paiement :
    le serveur doit vérifier et retirer l'argent avant de rendre le véhicule.

    Rappel : le serveur doit revérifier que le véhicule appartient bien au
    joueur et qu'il est au garage avant de le faire sortir.
]]

-- Catégorie déduite du modèle quand le script ne la donne pas
local JETSKIS = { 'seashark', 'seashark2', 'seashark3' }
local SUBMARINES = { 'submersible', 'submersible2', 'avisa', 'kosatka' }

local function inList(list, hash)
    for _, name in ipairs(list) do
        if joaat(name) == hash then return true end
    end
    return false
end

local CATEGORIZE = {
    -- Garage voitures : Voitures, Motos, Utilitaires
    car = function(hash, class)
        if class == 8 or class == 13 then return 'bike' end
        if class == 10 or class == 11 or class == 12 or class == 17 or class == 19 or class == 20 then return 'truck' end
        return 'car'
    end,
    -- Port : Bateaux, Jet-skis, Sous-marins
    boat = function(hash)
        if inList(JETSKIS, hash) then return 'jetski' end
        if inList(SUBMARINES, hash) then return 'sub' end
        return 'boat'
    end,
    -- Hangar : Avions, Hélicoptères
    air = function(hash, class)
        return class == 15 and 'heli' or 'plane'
    end,
}

-- Fourrière : mêmes catégories que le garage voitures
CATEGORIZE.impound = CATEGORIZE.car

local DEFAULT_CATEGORY = { car = 'car', boat = 'boat', air = 'plane', impound = 'car' }

local function categoryOf(veh)
    if veh.category then return veh.category end
    local model = veh.model
    local fallback = DEFAULT_CATEGORY[Config.Type] or 'car'
    if not model then return fallback end
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return fallback end
    return (CATEGORIZE[Config.Type] or CATEGORIZE.car)(hash, GetVehicleClassFromName(hash))
end

-- État général (clé à molette) : moyenne moteur + carrosserie, ou `condition` si fourni
local function conditionOf(veh)
    if veh.condition then return veh.condition end
    local engine, body = tonumber(veh.engine), tonumber(veh.body)
    if engine and body then return (engine + body) / 2 end
    return engine or body
end

local isOpen = false
local current = nil -- { data, cb }

local function close()
    if not isOpen then return end
    isOpen = false
    current = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Seule la partie affichable est envoyée à la NUI
local function display(data)
    local tabs = {}
    for t, tab in ipairs(data.tabs or {}) do
        local vehicles = {}
        for v, veh in ipairs(tab.vehicles or {}) do
            vehicles[v] = {
                label = veh.label or veh.model or 'Véhicule',
                plate = veh.plate,
                fuel = veh.fuel,
                condition = conditionOf(veh),
                category = categoryOf(veh),
                state = veh.state or 'garage',
                price = veh.price, reason = veh.reason, date = veh.date,
                locked = veh.locked == true,
            }
        end
        tabs[t] = { id = tab.id, label = tab.label, icon = tab.icon, vehicles = vehicles }
    end
    return {
        title = data.title or Config.Title,
        subtitle = data.subtitle or Config.Subtitle,
        position = Config.Position,
        type = Config.Type,
        money = data.money,
        tabs = tabs,
    }
end

local function open(data, cb)
    if type(data) ~= 'table' then return end
    current = { data = data, cb = cb }
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = display(data) })
end

RegisterNUICallback('close', function(_, cb)
    close()
    cb('ok')
end)

RegisterNUICallback('takeOut', function(req, cb)
    cb('ok')
    if not current then return end
    local tab = current.data.tabs and current.data.tabs[(tonumber(req.tab) or -1) + 1]
    local vehicle = tab and tab.vehicles and tab.vehicles[(tonumber(req.index) or -1) + 1]
    if not vehicle then return end
    if Config.Type == 'impound' then
        if vehicle.locked then return end
    elseif (vehicle.state or 'garage') ~= 'garage' then
        return
    end

    local handler, garageId = current.cb, current.data.id
    close()
    if handler then
        handler(vehicle, garageId, tab.id)
    else
        TriggerEvent(GetCurrentResourceName() .. ':takeOut', vehicle, garageId, tab.id)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)

exports('open', open)
exports('close', close)
exports('isOpen', function() return isOpen end)
