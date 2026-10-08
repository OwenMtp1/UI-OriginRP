--[[
    Adaptateur serveur (inventaire / identité). Par défaut : ox_inventory.
    Remplace ces fonctions pour brancher un autre inventaire.
]]
ServerConfig = {}

local inv = exports.ox_inventory

function ServerConfig.GetIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license') or ('src:' .. src)
end

function ServerConfig.GetName(src)
    return GetPlayerName(src) or 'Inconnu'
end

function ServerConfig.HasKit(src)
    return (inv:Search(src, 'count', Config.Item) or 0) > 0
end

function ServerConfig.IsAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end
