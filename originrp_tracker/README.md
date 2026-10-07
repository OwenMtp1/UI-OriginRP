# originrp_tracker — Traceur GPS collant + tablette de suivi

Dépendances : `ox_lib`, `ox_inventory`, `ox_target` (OneSync activé).

## Items (`ox_inventory/data/items.lua`)

```lua
['gps_tracker'] = {
    label = 'Traceur GPS',
    weight = 150,
    stack = false,
    close = true,
    description = 'Petit traceur aimanté. Se lance comme une bombe collante.',
    client = { export = 'originrp_tracker.useTracker' },
},

['gps_tablet'] = {
    label = 'Tablette GPS',
    weight = 600,
    stack = false,
    close = true,
    description = 'Tablette de suivi des traceurs synchronisés.',
    client = { export = 'originrp_tracker.useTablet' },
},
```

## Fonctionnement

- **Lancer** : utiliser `gps_tracker` → trajectoire affichée, clic gauche pour lancer, clic droit pour annuler.
  Il se colle sur une personne ou un véhicule (à l'arrêt ou en mouvement). S'il rate, il rebondit sur les murs et tombe par terre.
  Le traceur reste visible et clignote en rouge quand il est actif.
- **Retirer** : ALT (ox_target) sur le traceur → « Retirer le tracker », il revient dans l'inventaire (même n° de série).
- **Tirer dessus** : une balle qui touche le traceur le détruit ; le propriétaire est prévenu dans le journal de la tablette.
- **Tablette** (`gps_tablet`) :
  - *Synchroniser* : détecte automatiquement les traceurs non synchronisés présents dans la poche.
    Si le traceur est déjà actif chez quelqu'un : « Ce tracker est déjà actif. Voulez-vous forcer la déconnexion ? ».
    En cas de « Oui », l'ancien propriétaire reçoit : « Tracker … a été déconnecté de force pour être synchronisé sur un autre appareil. »
  - *Mes trackers* : activer / désactiver, renommer, désynchroniser.
    Un traceur actif apparaît sur la carte GTA (`Tracker #XXXX`, ou `Tracker : <nom>` une fois renommé).
    S'il est dans une poche, le point suit la personne qui le porte.

Réglages dans `config.lua` (prop, puissance du lancer, rayon de tir, blip, lumière).
Branchement inventaire / identité dans `sv_config.lua`. Les propriétaires et noms sont sauvegardés en KVP.

Icônes d'inventaire : copier `images/gps_tracker.png` et `images/gps_tablet.png` dans `ox_inventory/web/images/`.

Aperçus : `tablet-preview.html` (interface de la tablette, jouable), `items.html` (visuels des items : inventaire, en main, sur une personne / une voiture) et `preview.html` (simulation interactive).
