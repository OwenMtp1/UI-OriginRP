--[[
    Adaptateur argent : retire l'amende du COMPTE BANCAIRE du joueur.
    Détecte ESX ou QBCore / Qbox automatiquement.
]]
ServerConfig = {}

local ESX, QBCore
if GetResourceState('es_extended') == 'started' then
    ESX = exports.es_extended:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Retire `amount` du compte bancaire. Le solde peut passer en négatif : une amende est toujours appliquée.
function ServerConfig.RemoveBankMoney(src, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        xPlayer.removeAccountMoney('bank', amount, 'Amende radar')
        return true
    elseif QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false end
        -- QBCore refuse un solde négatif : on force le retrait si le compte est insuffisant
        if not player.Functions.RemoveMoney('bank', amount, 'amende-radar') then
            local money = player.PlayerData.money
            money.bank = money.bank - amount
            player.Functions.SetPlayerData('money', money)
        end
        return true
    end
    print(('[originrp_radar] Aucun framework détecté : amende de %d $ non prélevée (joueur %d)'):format(amount, src))
    return false
end

-- Optionnel : envoyer l'argent à la société de police (ESX addon_account / qb-management...)
function ServerConfig.OnFine(src, amount, speed, limit, radarId)
end
