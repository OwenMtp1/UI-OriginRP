local isOpen = false

-- Valeurs modifiées en jeu (titre, valeur d'une rubrique, case cochée…),
-- par menu : overrides[menuId] = { title = ..., items = { [itemId] = { ... } } }
local overrides = {}

local ITEM_FIELDS = { 'label', 'description', 'icon', 'value', 'checked', 'disabled' }

local function hasAction(item)
    return item.event or item.serverEvent or item.command or item.onSelect
end

local function merge(menuId, data)
    if type(data) ~= 'table' then return end
    local target = overrides[menuId] or { items = {} }
    overrides[menuId] = target
    if data.title ~= nil then target.title = data.title end
    if data.subtitle ~= nil then target.subtitle = data.subtitle end
    for itemId, fields in pairs(data.items or {}) do
        target.items[itemId] = target.items[itemId] or {}
        for _, field in ipairs(ITEM_FIELDS) do
            if fields[field] ~= nil then target.items[itemId][field] = fields[field] end
        end
    end
end

local function itemOverride(menuId, item)
    local menu = overrides[menuId]
    return item.id and menu and menu.items[item.id] or {}
end

local function field(override, item, name)
    if override[name] ~= nil then return override[name] end
    return item[name]
end

-- Copie des menus sans les fonctions (onSelect), seule la partie
-- affichable est envoyée à la NUI.
local function buildNuiMenus()
    local menus = {}
    for id, menu in pairs(Config.Menus) do
        local items = {}
        for i, item in ipairs(menu.items or {}) do
            local o = itemOverride(id, item)
            local value = field(o, item, 'value')
            items[i] = {
                icon = field(o, item, 'icon'),
                label = field(o, item, 'label'),
                description = field(o, item, 'description'),
                value = value ~= nil and tostring(value) or nil,
                disabled = field(o, item, 'disabled') == true,
                checkbox = item.checkbox == true,
                checked = field(o, item, 'checked') == true,
                submenu = item.submenu,
                static = not item.submenu and not item.checkbox and not hasAction(item),
                close = not item.submenu and not item.checkbox and item.close ~= false,
            }
        end
        local o = overrides[id] or {}
        menus[id] = {
            title = o.title or menu.title,
            subtitle = o.subtitle or menu.subtitle,
            key = menu.key,
            counter = menu.counter == true,
            hints = menu.hints == true,
            items = items,
        }
    end
    return menus
end

local function refresh()
    if isOpen then
        SendNUIMessage({ action = 'refresh', menus = buildNuiMenus() })
    end
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local pendingData = {}

local function showMenu(menuId, data)
    if isOpen then return end
    local menu = Config.Menus[menuId]

    if menu.onOpen then
        local ok, result = pcall(menu.onOpen)
        if not ok then
            print(('[originrp_menu] Erreur onOpen (%s) : %s'):format(menuId, result))
        elseif result == false then
            return -- onOpen peut refuser l'ouverture (ex. pas d'organisation)
        else
            merge(menuId, result)
        end
    end
    merge(menuId, data)

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        root = menuId,
        menus = buildNuiMenus(),
        logo = Config.Logo,
    })
end

-- data (optionnel) : { title = ..., subtitle = ..., items = { [itemId] = { value = ..., checked = ... } } }
local function openMenu(menuId, data)
    if isOpen then return end
    local menu = Config.Menus[menuId]
    if not menu then
        print(('[originrp_menu] Menu inconnu : %s'):format(tostring(menuId)))
        return
    end

    -- Menu protégé par une permission ACE : le serveur vérifie avant d'ouvrir
    if menu.ace then
        pendingData[menuId] = data or false
        TriggerServerEvent('originrp_menu:requestOpen', menuId)
        return
    end

    showMenu(menuId, data)
end

RegisterNetEvent('originrp_menu:openAllowed', function(menuId)
    local data = pendingData[menuId]
    if data == nil then return end -- pas de demande en attente
    pendingData[menuId] = nil
    showMenu(menuId, data or nil)
end)

-- Met à jour un menu, même ouvert. Ex. :
-- exports.originrp_menu:setMenu('organisation', { items = { service = { checked = true } } })
local function setMenu(menuId, data)
    merge(menuId, data)
    refresh()
end

for _, bind in ipairs(Config.Keybinds) do
    RegisterCommand(bind.command, function()
        if isOpen then closeMenu() else openMenu(bind.menu) end
    end, false)
    RegisterKeyMapping(bind.command, bind.description, 'keyboard', bind.key)
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

-- La NUI envoie seulement l'id du menu et l'index de la rubrique :
-- l'action exécutée est toujours celle définie dans config.lua.
RegisterNUICallback('select', function(data, cb)
    cb('ok')

    local menuId = data.menu
    local menu = Config.Menus[menuId]
    local item = menu and menu.items[(tonumber(data.index) or -1) + 1]
    if not item or item.submenu then return end

    local o = itemOverride(menuId, item)
    if field(o, item, 'disabled') then return end

    local args = { table.unpack(item.args or {}) }
    local checked

    if item.checkbox then
        checked = not field(o, item, 'checked')
        if item.id then
            merge(menuId, { items = { [item.id] = { checked = checked } } })
        else
            item.checked = checked
        end
        args[#args + 1] = checked
        refresh()
    elseif item.close ~= false then
        closeMenu()
    end

    if item.event then TriggerEvent(item.event, table.unpack(args)) end
    if item.serverEvent then TriggerServerEvent(item.serverEvent, table.unpack(args)) end
    if item.command then ExecuteCommand(item.command) end
    if item.onSelect then item.onSelect(item, checked) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('setMenu', setMenu)
exports('isOpen', function() return isOpen end)
