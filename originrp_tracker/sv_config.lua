--[[
    Adaptateur serveur (inventaire / identité). Par défaut : ox_inventory.
    Remplace ces fonctions pour brancher un autre inventaire.
]]
ServerConfig = {}

local inv = exports.ox_inventory

-- Identifiant persistant du joueur (les trackers lui appartiennent)
function ServerConfig.GetIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license') or ('src:' .. src)
end

-- Liste des traceurs dans les poches : { { slot = n, metadata = {...} }, ... }
function ServerConfig.GetTrackerSlots(src)
    local slots = inv:Search(src, 'slots', Config.TrackerItem) or {}
    local list = {}
    for _, item in pairs(slots) do
        list[#list + 1] = { slot = item.slot, metadata = item.metadata or {} }
    end
    return list
end

function ServerConfig.GetSlot(src, slot)
    local item = inv:GetSlot(src, slot)
    if item and item.name == Config.TrackerItem then return item end
end

function ServerConfig.SetMetadata(src, slot, metadata)
    inv:SetMetadata(src, slot, metadata)
end

function ServerConfig.RemoveSlot(src, slot)
    return inv:RemoveItem(src, Config.TrackerItem, 1, nil, slot)
end

function ServerConfig.GiveTracker(src, metadata)
    if not inv:CanCarryItem(src, Config.TrackerItem, 1, metadata) then return false end
    return inv:AddItem(src, Config.TrackerItem, 1, metadata)
end
