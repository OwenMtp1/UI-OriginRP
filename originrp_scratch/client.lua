local kiosks = {}  -- objets des bornes
local blips = {}
local uiOpen = false

local function openUi(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

local function closeUi()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    ClearPedTasks(PlayerPedId())
end

-- ─── Borne : achat ─────────────────────────────────────────────────────────

local function openShop()
    if uiOpen then return end
    local info = lib.callback.await('originrp_scratch:info', false)
    if not info then return end
    openUi({ action = 'shop', price = info.price, remaining = info.remaining, limit = info.limit, money = info.money })
end

RegisterNUICallback('buy', function(body, cb)
    local res = lib.callback.await('originrp_scratch:buy', false, body.qty)
    cb(res or { ok = false, message = 'Erreur.' })
    if res and res.ok then
        PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
    end
end)

-- ─── Ticket : grattage ─────────────────────────────────────────────────────

exports('useTicket', function(_, slot)
    if uiOpen then return end
    local result = lib.callback.await('originrp_scratch:open', false, slot.slot)
    if not result then return end
    TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_TOURIST_MAP', 0, true)
    openUi({ action = 'ticket', cases = result.cases })
end)

RegisterNUICallback('claim', function(_, cb)
    cb(lib.callback.await('originrp_scratch:claim', false) or 0)
end)

RegisterNUICallback('scratchSound', function(_, cb)
    PlaySoundFrontend(-1, 'CLICK_BACK', 'WEB_NAVIGATION_SOUNDS_PHONE', true)
    cb(1)
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb(1)
end)

-- ─── Bornes dans le monde ──────────────────────────────────────────────────

CreateThread(function()
    lib.requestModel(Config.Model)
    for i, k in ipairs(Config.Kiosks) do
        local obj = CreateObject(Config.Model, k.x, k.y, k.z, false, false, false)
        SetEntityHeading(obj, k.w)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        kiosks[i] = obj

        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'originrp_scratch_buy',
                icon = 'fa-solid fa-ticket',
                label = Config.TargetLabel,
                distance = Config.InteractDistance,
                onSelect = openShop,
            },
        })

        if Config.Blip.enabled then
            local b = AddBlipForCoord(k.x, k.y, k.z)
            SetBlipSprite(b, Config.Blip.sprite)
            SetBlipColour(b, Config.Blip.color)
            SetBlipScale(b, Config.Blip.scale)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(Config.Blip.label)
            EndTextCommandSetBlipName(b)
            blips[i] = b
        end
    end
    SetModelAsNoLongerNeeded(Config.Model)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in pairs(kiosks) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    for _, b in pairs(blips) do RemoveBlip(b) end
    if uiOpen then SetNuiFocus(false, false) end
end)
