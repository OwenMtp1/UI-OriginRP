# originrp_drone — Unité drone OR-D2 « Vigie »

Drone de surveillance réaliste pour serveur GTA RP : mallette de transport à poser au sol, déploiement par ALT, radiocommande à écran (tenue en main ou posée), **barre de vie** (chocs, balles, explosions), **destruction** avec chute et fumée noire, **batterie de 2 h** rechargée dans la mallette, **perte de signal** (brouillage GPS, portée).

Aperçus (ouvrir dans un navigateur) :
- `preview.html` : simulation complète dans une rue de Los Santos (animation de lancement, pilotage, tests vie / batterie / brouillage).
- `ordinateur.html` : la radiocommande ORIGIN RC-7 et son écran de pilotage.
- `design/galerie_drone.html` et `design/*.png` : rendus des props, dont le drone détruit (`final_wreck.png`).

## 1. Dépendances

`ox_lib`, `ox_inventory`, `ox_target`, OneSync. ESX ou QBCore détectés automatiquement pour les métiers (`sv_config.lua`).

## 2. Items ox_inventory (`ox_inventory/data/items.lua`)

```lua
['drone_case'] = {
    label = 'Mallette drone OR-D2', weight = 9800, stack = false, close = true,
    description = 'Drone de surveillance, radiocommande et batteries.',
    client = { export = 'originrp_drone.useCase' },
},
['drone_or_d2'] = { label = 'Drone OR-D2 (neuf)', weight = 3700, stack = false },
['brouilleur_gps'] = {
    label = 'Brouilleur GPS', weight = 800, stack = false, close = true,
    client = { export = 'originrp_drone.useJammer' },
},
['drone_epave'] = { label = 'Épave de drone', weight = 3000, stack = false },
```

La mallette garde dans ses métadonnées : numéro de série, batterie, état (vie) et présence du drone. Une mallette donnée sans métadonnées démarre à 100 %.

## 3. Props (dossier `stream/`)

Les modèles sont fournis au format XML CodeWalker dans `xml_source/` (fichier Blender inclus) :

| Modèle | Rôle |
|---|---|
| `orp_drone` | drone déplié (en vol / posé) |
| `orp_drone_folded` | drone replié (dans la mallette) |
| `orp_drone_wreck` | épave : bras arraché, hélices cassées, coque noircie |
| `orp_dronecase` / `orp_dronecase_open` | mallette fermée / ouverte |
| `orp_drone_rc` | radiocommande à écran |

Conversion (une seule fois) : **CodeWalker → Tools → Import XML**, sélectionner tous les `.ydr.xml` et `orp_drone.ytyp.xml` de `xml_source/` (avec leurs dossiers de textures), exporter, puis copier les `.ydr` et `orp_drone.ytyp` dans `stream/`.

Sans ces fichiers, mets `Config.CustomProps = false` : le script utilise des props GTA de remplacement.

> Le drone fait ~52 000 triangles (beaucoup de détails). Si tu veux l'alléger, ouvre `xml_source/orp_drone_props.blend` et ajoute un modificateur *Decimate* avant l'export Sollumz.

## 4. En jeu

1. **Utiliser la mallette** (inventaire) : le personnage la pose au sol.
2. **ALT sur la mallette** :
   - *Déployer le drone* : loquets, couvercle, le drone est sorti et posé à côté ;
   - *Prendre la télécommande* : la caméra passe sur le drone, l'écran de la radiocommande s'affiche ;
   - *Ranger le drone* : quand il est posé près de la mallette — **la batterie se recharge** ;
   - *Installer un drone neuf* : mallette vide après destruction (item `drone_or_d2`) ;
   - *État de la batterie* / *Ramasser la mallette*.

### Commandes de vol

| Touche | Action |
|---|---|
| Z Q S D | se déplacer |
| Espace / Ctrl | monter / descendre (Espace au sol = décoller) |
| A / E | tourner |
| Maj | vitesse rapide |
| Souris / molette | incliner la caméra / zoom |
| N | vision optique → thermique → nocturne |
| L | projecteur |
| R | enregistrement |
| H | retour automatique au pilote |
| G | poser / reprendre la radiocommande |
| Retour arrière | atterrir puis quitter le pilotage |

## 5. Vie du drone

`Config.Health` : 100 points.
- **Chocs** : au-dessus de 4 m/s, ≈ 6 points par m/s (4 chocs francs = détruit).
- **Balles** : 34 points (3 balles), surchargeable par arme.
- **Explosions** : destruction immédiate à moins de 4 m.

À 0 : le drone tombe en vrille avec une traînée de fumée, se transforme en **épave fumante** (fumée noire visible par tous), et l'écran du pilote affiche **« AUCUN SIGNAL — Votre drone a été détruit »**. L'épave peut être récupérée (ALT) pendant 15 min (`drone_epave`). Sous 40 % de vie, le drone fume déjà en vol.

## 6. Batterie

`Config.Battery` : **2 h de vol** (100 % → 0 %), décompte fait par le serveur. Alertes à 20, 10 et 5 %, atterrissage forcé à 2 %. La recharge se fait **dans la mallette** : 1 h pour 0 → 100 %, que la mallette soit posée ou dans l'inventaire.

## 7. Signal, portée et brouillage

- Au-delà de 250 m l'image se dégrade ; au-delà de **350 m** : **« AUCUN SIGNAL — Hors de portée »**, le drone revient seul vers le pilote.
- Si le drone ou le pilote est dans la zone d'un **brouilleur GPS** : **« AUCUN SIGNAL — Le réseau rencontre des perturbations »**, les commandes ne répondent plus, le drone dérive puis se pose sur place au bout de 20 s.
- Item `brouilleur_gps` : se pose au sol, rayon 60 m, actif 10 min, ramassable (ALT).
- D'autres scripts peuvent créer une zone de brouillage :

```lua
-- serveur
local id = exports.originrp_drone:AddJammer(vector3(x, y, z), 60.0, 600)
exports.originrp_drone:RemoveJammer(id)
-- client
local brouille = exports.originrp_drone:IsJammed(GetEntityCoords(PlayerPedId()))
```

## 8. Configuration

Tout est dans `config.lua` : métiers autorisés à utiliser la mallette d'un autre (`Config.SharedJobs`), vitesses, altitude max, dégâts, batterie, portée, brouilleur, effets de fumée, touches, animations.

## 9. À vérifier en jeu

- Les positions de la radiocommande dans les mains (`Config.RCAttach`) et l'animation de tenue sont à ajuster selon tes peds.
- Les effets de fumée (`Config.Wreck`) utilisent des particules GTA ; tu peux les remplacer par d'autres si tu préfères un rendu différent.
- La détection des balles est faite par le client du tireur (impact + rayon), avec une limite anti-abus côté serveur.
