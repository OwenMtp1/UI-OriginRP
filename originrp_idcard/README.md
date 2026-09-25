# originrp_idcard

Carte d'identité du comté de Los Santos : nom, prénom, sexe, date de naissance,
taille, lieu de naissance, date de création, photo (vide par défaut).

## Installation

1. Copier le dossier `originrp_idcard` dans `resources/`.
2. Ajouter `ensure originrp_idcard` dans `server.cfg` (après ESX / QBCore).
3. Réglages dans `config.lua` (commandes, durée, position…).

## En jeu

- `/carte` : regarder sa propre carte.
- `/montrercarte` : montrer sa carte au joueur le plus proche (3 m max, vérifié par le serveur).
  Les deux joueurs voient la carte.
- Retour arrière / Échap / clic droit pour la ranger (sinon elle disparaît après 10 s).

## Données

- **ESX** : `firstName`, `lastName`, `sex`, `dateofbirth`, `height` (esx_identity). Automatique.
- **QBCore** : `charinfo` (prénom, nom, sexe, naissance, nationalité) + citizenid. Automatique.
- Autre base, ou pour ajouter la date de création / une photo : `Config.Framework = 'custom'`
  et compléter `Config.GetIdentity` dans `config.lua` (format décrit dans le fichier).

Les données sont toujours lues **côté serveur** : un joueur ne peut pas montrer une fausse carte.

## Depuis un autre script

```lua
-- Serveur (ex. item « carte d'identité » utilisable) :
exports.originrp_idcard:showCard(source)            -- à soi-même
exports.originrp_idcard:showCard(source, cible)     -- à un autre joueur

-- Client :
exports.originrp_idcard:showToClosest()
exports.originrp_idcard:close()
```

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
