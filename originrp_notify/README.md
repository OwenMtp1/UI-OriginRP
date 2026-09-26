# originrp_notify

Notifications dans le style des UI OriginRP. **Une seule notification à la fois** :
si une nouvelle arrive, l'actuelle sort en glissant et la nouvelle entre.
Si la même notification est envoyée plusieurs fois, elle reste affichée avec un
compteur (×2, ×3…) et son temps repart à zéro.

Design violet avec le logo Origin à gauche (`html/img/logo.png`, remplaçable via `Config.Logo`).
4 types, repérés par la pastille à côté du titre : `info` (violet), `success` (vert),
`error` (rouge), `warning` (orange). Une barre violette en haut montre le temps restant.

## Installation

1. Copier le dossier `originrp_notify` dans `resources/`.
2. Ajouter `ensure originrp_notify` dans `server.cfg` (avant les scripts qui l'utilisent).
3. Réglages (position, durée, titres par défaut) dans `config.lua`.

## Utilisation

```lua
-- Client
exports.originrp_notify:notify('Tu as été soigné.')
exports.originrp_notify:notify({ title = 'Staff', message = 'Tu as été soigné.', type = 'success', duration = 5000 })

-- Serveur
exports.originrp_notify:notify(source, { title = 'Staff', message = 'Tu as été soigné.', type = 'success' })
TriggerClientEvent('originrp_notify:send', source, { title = 'Staff', message = 'Tu as été soigné.' })
```

## Remplacer les notifications de la base

- **ESX** : dans `es_extended/client/functions.lua`, remplacer le contenu de
  `ESX.ShowNotification(message, notifyType, length)` par
  `exports.originrp_notify:notify({ message = message, type = notifyType, duration = length })`.
- **QBCore** : dans `qb-core/client/functions.lua`, remplacer le contenu de
  `QBCore.Functions.Notify(text, texttype, length)` par
  `exports.originrp_notify:notify({ message = type(text) == 'table' and text.text or text, title = type(text) == 'table' and text.caption or nil, type = texttype == 'primary' and 'info' or texttype, duration = length })`.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur : les 4 types défilent.
