# originrp_playercard

Fiche d'un joueur (nom, ID, emploi, organisation) affichée en jeu, non cliquable,
même style que les autres menus OriginRP.

## Installation

1. Copier le dossier `originrp_playercard` dans `resources/`.
2. Ajouter `ensure originrp_playercard` dans `server.cfg`.
3. Réglages (position, durée d'affichage, textes) dans `config.lua`.

## Utilisation

La fiche s'affiche avec les données envoyées par la base :

```lua
local fiche = {
    name = 'Liam Coelho',
    id = 2,                                    -- affiché « #2 »
    job = { label = 'LSPD', grade = 'Patron', active = true, onDuty = false },
    organisation = { label = 'Families', grade = 'Recrue' },  -- nil = « Aucune »
}

-- Côté serveur (à un joueur précis) :
TriggerClientEvent('originrp_playercard:show', source, fiche)
TriggerClientEvent('originrp_playercard:show', source, fiche, 5000) -- masquée après 5 s
TriggerClientEvent('originrp_playercard:hide', source)

-- Côté client :
exports.originrp_playercard:show(fiche)
exports.originrp_playercard:hide()
```

Badges de l'emploi :
- `active = true / false` → **ACTIF** (violet) / INACTIF (gris)
- `onDuty = true / false` → **EN SERVICE** (violet) / HORS SERVICE (gris)
- laisser `nil` pour ne pas afficher le badge.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
