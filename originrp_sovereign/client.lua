-- Nom affiché dans le jeu (roue des armes, notifications)
CreateThread(function()
    AddTextEntry(Config.Weapon.labelKey, Config.Weapon.label)
end)

-- Commande de test (admin) : /sovereign [hw] — donne l'arme, avec la finition Halloween si demandé
RegisterCommand('sovereign', function(_, args)
    local ped = PlayerPedId()
    local hash = joaat(Config.Weapon.name)
    GiveWeaponToPed(ped, hash, 60, false, true)
    if args[1] == 'hw' then GiveWeaponComponentToPed(ped, hash, joaat('COMPONENT_ORPSOVEREIGN_SKIN_HW')) end
end, true)
