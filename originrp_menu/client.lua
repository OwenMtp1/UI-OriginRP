local isOpen = false

-- Copie des menus sans les fonctions (onSelect), seule la partie
-- affichable est envoyée à la NUI.
local function buildNuiMenus()
    local menus = {}
    for id, menu in pairs(Config.Menus) do
        local items = {}
        for i, item in ipairs(menu.items or {}) do
            items[i] = {
                icon = item.icon,
                label = item.label,
                description = item.description,
                disabled = item.disabled == true,
                submenu = item.submenu,
                close = item.submenu == nil and item.close ~= false,
            }
        end
        menus[id] = {
            title = menu.title,
            subtitle = menu.subtitle,
            key = menu.key,
            items = items,
        }
    end
    return menus
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu(menuId)
    if isOpen then return end
    if not Config.Menus[menuId] then
        print(('[originrp_menu] Menu inconnu : %s'):format(tostring(menuId)))
        return
    end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        root = menuId,
        menus = buildNuiMenus(),
        logo = Config.Logo,
    })
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

    local menu = Config.Menus[data.menu]
    local item = menu and menu.items[(tonumber(data.index) or -1) + 1]
    if not item or item.disabled or item.submenu then return end

    if item.close ~= false then closeMenu() end

    local args = item.args or {}
    if item.event then TriggerEvent(item.event, table.unpack(args)) end
    if item.serverEvent then TriggerServerEvent(item.serverEvent, table.unpack(args)) end
    if item.command then ExecuteCommand(item.command) end
    if item.onSelect then item.onSelect(item) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('isOpen', function() return isOpen end)
