--[[
    Création de personnage.

    Ouvrir (depuis le script de multipersonnage / spawn de la base) :

        exports.originrp_creation:open({
            sex = 'm',                         -- optionnel
            identity = { firstname = '' },     -- optionnel : valeurs pré-remplies
        }, function(result)
            -- result.identity = { firstname, lastname, dateofbirth = 'JJ/MM/AAAA', sex = 'm'|'f', height }
            -- result.skin     = apparence complète (voir buildSkin plus bas)
            -- result.raw      = données brutes de l'interface (pour rouvrir / modifier)
            -- → envoyer au serveur pour créer le personnage, puis faire apparaître le joueur
        end)

    Sans fonction, l'événement client 'originrp_creation:finished' est déclenché
    avec (result). Le serveur doit revérifier l'identité (nom, âge, taille).

    Le personnage doit déjà être placé à l'endroit de la création (pièce, studio…)
    avant l'ouverture : la caméra se cale devant lui.
]]

local isOpen = false
local handler = nil
local cam = nil
local baseHeading = 0.0
local camState = { preset = 'body', zoom = 0.0, height = 0.0 }
local OVERLAY_COLOR_TYPE = { [1] = 1, [2] = 1, [10] = 1, [5] = 2, [8] = 2 }

---------------------------------------------------------------------------
-- Caméra
---------------------------------------------------------------------------

local function updateCamera()
    if not cam then return end
    local ped = PlayerPedId()
    local p = Config.Cameras[camState.preset] or Config.Cameras.body
    local coords = GetEntityCoords(ped)
    local rad = math.rad(baseHeading)
    local fx, fy = -math.sin(rad), math.cos(rad)
    local distance = math.max(0.35, p.distance * (1.0 + camState.zoom))
    local z = coords.z + p.height + camState.height
    SetCamCoord(cam, coords.x + fx * distance, coords.y + fy * distance, z)
    PointCamAtCoord(cam, coords.x, coords.y, z)
    SetCamFov(cam, p.fov)
end

local function createCamera()
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 45.0, false, 0)
    updateCamera()
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 600, true, true)
end

local function destroyCamera()
    if not cam then return end
    RenderScriptCams(false, true, 600, true, true)
    DestroyCam(cam, false)
    cam = nil
end

---------------------------------------------------------------------------
-- Modèle et apparence
---------------------------------------------------------------------------

local function setModel(sex)
    local model = sex == 'f' and `mp_f_freemode_01` or `mp_m_freemode_01`
    if GetEntityModel(PlayerPedId()) == model then return end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetEntityHeading(ped, baseHeading)
    FreezeEntityPosition(ped, true)
end

local function applyChar(char)
    local ped = PlayerPedId()
    local h = char.heritage or {}
    SetPedHeadBlendData(ped, h.mother or 21, h.father or 0, 0, h.mother or 21, h.father or 0, 0,
        (h.shape or 50) / 100.0, (h.skin or 50) / 100.0, 0.0, false)

    for i, value in ipairs(char.face or {}) do
        SetPedFaceFeature(ped, i - 1, (tonumber(value) or 0) / 100.0)
    end

    local hair = char.hair or {}
    SetPedComponentVariation(ped, 2, hair.style or 0, 0, 0)
    SetPedHairColor(ped, hair.color or 0, hair.highlight or 0)
    SetPedEyeColor(ped, char.eyes or 0)

    for key, o in pairs(char.overlays or {}) do
        local index = tonumber(key)
        if o.style and o.style >= 0 then
            SetPedHeadOverlay(ped, index, o.style, (o.opacity or 100) / 100.0)
            local colorType = OVERLAY_COLOR_TYPE[index]
            if colorType then SetPedHeadOverlayColor(ped, index, colorType, o.color or 0, o.color or 0) end
        else
            SetPedHeadOverlay(ped, index, 255, 0.0)
        end
    end

    for id, v in pairs(char.clothes or {}) do
        local c = Config.Clothes[id]
        if c and c.prop then
            if v.d < 0 then ClearPedProp(ped, c.prop) else SetPedPropIndex(ped, c.prop, v.d, v.t or 0, true) end
        elseif c then
            SetPedComponentVariation(ped, c.component, v.d or 0, v.t or 0, 0)
        end
    end
end

-- Nombres de styles disponibles (pour borner les sélecteurs de l'interface)
local function readCounts(char)
    local ped = PlayerPedId()
    local overlays = {}
    for i = 0, 10 do overlays[tostring(i)] = GetPedHeadOverlayNum(i) end
    local clothes = {}
    for id, c in pairs(Config.Clothes) do
        local v = (char and char.clothes and char.clothes[id]) or { d = 0 }
        local d = math.max(0, v.d or 0)
        if c.prop then
            clothes[id] = { drawables = GetNumberOfPedPropDrawableVariations(ped, c.prop), textures = GetNumberOfPedPropTextureVariations(ped, c.prop, d) }
        else
            clothes[id] = { drawables = GetNumberOfPedDrawableVariations(ped, c.component), textures = GetNumberOfPedTextureVariations(ped, c.component, d) }
        end
    end
    return { hair = GetNumberOfPedDrawableVariations(ped, 2), overlays = overlays, clothes = clothes }
end

local function palette()
    local hair, makeup = {}, {}
    for i = 0, GetNumHairColors() - 1 do
        local r, g, b = GetPedHairRgbColor(i)
        hair[#hair + 1] = ('rgb(%d,%d,%d)'):format(r, g, b)
    end
    for i = 0, GetNumMakeupColors() - 1 do
        local r, g, b = GetPedMakeupRgbColor(i)
        makeup[#makeup + 1] = ('rgb(%d,%d,%d)'):format(r, g, b)
    end
    return { hair = hair, makeup = makeup }
end

-- Apparence au format « skin » à enregistrer côté serveur
local function buildSkin(char)
    local components, props = {}, {}
    for id, v in pairs(char.clothes or {}) do
        local c = Config.Clothes[id]
        if c and c.prop then props[tostring(c.prop)] = { drawable = v.d, texture = v.t }
        elseif c then components[tostring(c.component)] = { drawable = v.d, texture = v.t } end
    end
    components['2'] = { drawable = char.hair.style, texture = 0 }
    return {
        model = char.identity.sex == 'f' and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        headBlend = char.heritage,
        faceFeatures = char.face,
        hair = char.hair,
        eyeColor = char.eyes,
        overlays = char.overlays,
        components = components,
        props = props,
    }
end

---------------------------------------------------------------------------
-- Ouverture / fermeture
---------------------------------------------------------------------------

local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    destroyCamera()
    FreezeEntityPosition(PlayerPedId(), false)
    DisplayRadar(true)
end

local function open(opts, cb)
    opts = opts or {}
    handler = cb
    local sex = opts.sex == 'f' and 'f' or 'm'
    baseHeading = GetEntityHeading(PlayerPedId())
    setModel(sex)
    FreezeEntityPosition(PlayerPedId(), true)
    DisplayRadar(false)
    camState = { preset = 'body', zoom = 0.0, height = 0.0 }
    createCamera()

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = {
        sex = sex,
        identity = opts.identity,
        palette = palette(),
        counts = readCounts(nil),
        config = {
            minAge = Config.MinAge, maxAge = Config.MaxAge,
            heightMin = Config.HeightMin, heightMax = Config.HeightMax,
            outfits = Config.Outfits,
        },
    } })
end

---------------------------------------------------------------------------
-- Rappels de l'interface
---------------------------------------------------------------------------

RegisterNUICallback('apply', function(data, cb)
    if not isOpen or type(data.char) ~= 'table' then return cb({}) end
    applyChar(data.char)
    cb({ counts = readCounts(data.char) })
end)

RegisterNUICallback('sex', function(data, cb)
    if isOpen then setModel(data.sex == 'f' and 'f' or 'm') end
    cb({ counts = readCounts(nil) })
end)

RegisterNUICallback('camera', function(data, cb)
    cb('ok')
    if Config.Cameras[data.preset] then
        camState = { preset = data.preset, zoom = 0.0, height = 0.0 }
        updateCamera()
    end
end)

RegisterNUICallback('zoom', function(data, cb)
    cb('ok')
    camState.zoom = math.max(-0.6, math.min(0.8, camState.zoom + (tonumber(data.delta) or 0) * 0.1))
    updateCamera()
end)

RegisterNUICallback('height', function(data, cb)
    cb('ok')
    camState.height = math.max(-0.9, math.min(0.6, camState.height + (tonumber(data.delta) or 0) * 0.05))
    updateCamera()
end)

RegisterNUICallback('rotate', function(data, cb)
    cb('ok')
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + (tonumber(data.direction) or 1) * Config.RotateStep)
end)

RegisterNUICallback('finish', function(data, cb)
    cb('ok')
    local char = data.char
    if not isOpen or type(char) ~= 'table' then return end
    applyChar(char)
    local id = char.identity
    local result = {
        identity = {
            firstname = id.firstname, lastname = id.lastname,
            dateofbirth = ('%02d/%02d/%04d'):format(tonumber(id.day) or 1, tonumber(id.month) or 1, tonumber(id.year) or 2000),
            sex = id.sex, height = tonumber(id.height),
        },
        skin = buildSkin(char),
        raw = char,
    }
    close()
    if handler then handler(result) else TriggerEvent('originrp_creation:finished', result) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
        destroyCamera()
        FreezeEntityPosition(PlayerPedId(), false)
        DisplayRadar(true)
    end
end)

exports('open', open)
exports('close', close)
exports('applySkin', function(raw) applyChar(raw) end)   -- réappliquer une apparence enregistrée (raw)
exports('isOpen', function() return isOpen end)
