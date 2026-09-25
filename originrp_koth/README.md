# originrp_koth

Classement KOTH affiché en jeu (non cliquable), même style que le menu F5.

## Installation

1. Copier le dossier `originrp_koth` dans `resources/`.
2. Ajouter `ensure originrp_koth` dans `server.cfg`.
3. Réglages (titre, position, nombre de lignes…) dans `config.lua`.

## Utilisation (depuis le script KOTH)

Côté serveur, envoyer le classement à tous les joueurs à chaque changement de score :

```lua
TriggerClientEvent('originrp_koth:update', -1, {
    { id = 12, name = 'cartelgoon', points = 0 },
    { id = 7,  name = 'Nyxo',       points = 25 },
})
TriggerClientEvent('originrp_koth:show', -1) -- afficher
TriggerClientEvent('originrp_koth:hide', -1) -- masquer (fin de partie)
```

- `id` = server id du joueur (optionnel) : sa propre ligne est surlignée, et s'il
  n'est pas dans le top, sa position s'affiche quand même en dernière ligne.
- Le tri par points est fait automatiquement.
- Un 2e argument optionnel change le titre : `TriggerClientEvent('originrp_koth:update', -1, liste, 'KOTH - Sandy')`.

Côté client, les mêmes actions existent en exports :
`exports.originrp_koth:setLeaderboard(liste, titre)`, `show()`, `hide()`, `isVisible()`.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur (données de démo qui évoluent toutes les 1,5 s).
