--[[
    Ouvrir le garage (depuis le script de garage de la base) :

    exports.originrp_garage:open({
        id = 'pillbox',                       -- identifiant du garage (renvoyé à la sortie)
        title = 'Garage',                     -- optionnel
        subtitle = 'Parking de Pillbox Hill', -- optionnel
        tabs = {                              -- un ou plusieurs onglets
            {
                id = 'perso', label = 'Mes véhicules', icon = 'car',
                vehicles = {
                    {
                        label = 'Karin Sultan RS', plate = 'ORG 123',
                        fuel = 80, engine = 95,              -- en % (optionnels)
                        model = 'sultanrs',                  -- sert à deviner la catégorie
                        category = 'car',   -- optionnel : car, bike, truck, boat, air, emergency
                        state = 'garage',   -- 'garage' (disponible), 'out' (déjà sorti), 'impound' (fourrière)
                        -- + tous les champs utiles au script (model, props, id…)
                    },
                },
            },
        },
    }, function(vehicle, garageId, tabId)
        -- le joueur a choisi « Sortir » : faire apparaître le véhicule
    end)

    Sans fonction, l'événement client 'originrp_garage:takeOut' est déclenché
    avec (vehicle, garageId, tabId).
    icon d'onglet : car, users (entreprise / organisation), truck, bike

    Rappel : le serveur doit revérifier que le véhicule appartient bien au
    joueur et qu'il est au garage avant de le faire sortir.
]]

-- Catégorie déduite de la classe GTA du modèle quand le script ne la donne pas
local CLASS_CATEGORY = {
    [8] = 'bike', [13] = 'bike',
    [10] = 'truck', [11] = 'truck', [12] = 'truck', [17] = 'truck', [20] = 'truck',
    [14] = 'boat',
    [15] = 'air', [16] = 'air',
    [18] = 'emergency', [19] = 'emergency',
}

local function categoryOf(veh)
    if veh.category then return veh.category end
    local model = veh.model
    if not model then return 'car' end
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return 'car' end
    return CLASS_CATEGORY[GetVehicleClassFromName(hash)] or 'car'
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
                fuel = veh.fuel, engine = veh.engine,
                category = categoryOf(veh),
                state = veh.state or 'garage',
            }
        end
        tabs[t] = { id = tab.id, label = tab.label, icon = tab.icon, vehicles = vehicles }
    end
    return {
        title = data.title or Config.Title,
        subtitle = data.subtitle or Config.Subtitle,
        position = Config.Position,
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
    if not vehicle or (vehicle.state or 'garage') ~= 'garage' then return end

    local handler, garageId = current.cb, current.data.id
    close()
    if handler then
        handler(vehicle, garageId, tab.id)
    else
        TriggerEvent('originrp_garage:takeOut', vehicle, garageId, tab.id)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)

exports('open', open)
exports('close', close)
exports('isOpen', function() return isOpen end)
