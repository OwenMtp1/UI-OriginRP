# originrp_hud

HUD à côté de la minimap : vie, armure, soif, faim, dans le style des menus OriginRP.
Les jauges se placent automatiquement à droite de la minimap, quelles que soient
la résolution et la zone de sécurité du joueur.

## Installation

1. Copier le dossier `originrp_hud` dans `resources/`.
2. Ajouter `ensure originrp_hud` dans `server.cfg` (après ESX / QBCore).
3. **Désactiver l'ancien HUD** (sinon les deux s'affichent).
4. Réglages dans `config.lua` (jauges affichées, taille, seuil d'alerte…).

## Faim / soif

- **ESX** (esx_status) et **QBCore** : détectés automatiquement, rien à faire.
- Autre système : mettre `Config.Framework = 'none'` et envoyer les valeurs (0 à 100) :

```lua
exports.originrp_hud:setStatus('hunger', 75)
exports.originrp_hud:setStatus('thirst', 40)
```

## Divers

- `/hud` affiche / masque le HUD (commande modifiable dans `config.lua`).
- Masqué automatiquement dans le menu pause, écran noir, et quand la minimap est cachée.
- Sous 20 % (réglable), la jauge passe en rouge et clignote. L'armure vide est grisée.
- `exports.originrp_hud:setVisible(false)` pour le masquer depuis un autre script (cinématique…).

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur (valeurs de démo qui évoluent).
