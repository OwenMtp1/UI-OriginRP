-- Envoyer une notification à un joueur depuis le serveur :
--   exports.originrp_notify:notify(source, { title = 'Staff', message = 'Tu as été soigné.', type = 'success' })
--   TriggerClientEvent('originrp_notify:send', source, { ... })   -- équivalent
exports('notify', function(target, data, kind, duration)
    TriggerClientEvent('originrp_notify:send', target, data, kind, duration)
end)
