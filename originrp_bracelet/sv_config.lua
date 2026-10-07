--[[
    Adaptateur serveur (inventaire / identité / job). Par défaut : ox_inventory.
    Remplace ces fonctions pour brancher ton framework (ESX / QBCore).
]]
ServerConfig = {}

local inv = exports.ox_inventory

function ServerConfig.GetIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license') or ('src:' .. src)
end

-- Nom RP du personnage affiché dans la notification
function ServerConfig.GetCharacterName(src)
    -- ESX : local x = ESX.GetPlayerFromId(src) return x and x.getName()
    -- QBCore : local p = QBCore.Functions.GetPlayer(src) return p and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname)
    return GetPlayerName(src)
end

-- Job du joueur : renvoie name, grade
function ServerConfig.GetJob(src)
    -- ESX : local x = ESX.GetPlayerFromId(src) return x.job.name, x.job.grade
    return nil, 0
end

function ServerConfig.HasItem(src)
    return (inv:Search(src, 'count', Config.Item) or 0) > 0
end

function ServerConfig.RemoveItem(src)
    return inv:RemoveItem(src, Config.Item, 1)
end

function ServerConfig.GiveItem(src)
    if inv:CanCarryItem(src, Config.Item, 1) then inv:AddItem(src, Config.Item, 1) end
end
