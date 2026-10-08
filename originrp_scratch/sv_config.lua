--[[
    Adaptateur serveur. Par défaut : argent liquide ox_inventory (item 'money').
    Pour payer avec la banque ESX / QBCore, remplace GetMoney / RemoveMoney / AddMoney.
]]
ServerConfig = {}

local inv = exports.ox_inventory

function ServerConfig.GetIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license') or ('src:' .. src)
end

function ServerConfig.GetMoney(src)
    return inv:GetItemCount(src, 'money') or 0
end

function ServerConfig.RemoveMoney(src, amount)
    return inv:RemoveItem(src, 'money', amount)
end

function ServerConfig.AddMoney(src, amount)
    return inv:AddItem(src, 'money', amount)
end

function ServerConfig.CanCarryTickets(src, count)
    return inv:CanCarryItem(src, Config.TicketItem, count)
end

function ServerConfig.GiveTickets(src, count)
    return inv:AddItem(src, Config.TicketItem, count)
end

function ServerConfig.GetTicketSlot(src, slot)
    local item = inv:GetSlot(src, slot)
    if item and item.name == Config.TicketItem then return item end
end

function ServerConfig.RemoveTicket(src, slot)
    return inv:RemoveItem(src, Config.TicketItem, 1, nil, slot)
end
