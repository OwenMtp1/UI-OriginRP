# originrp_sovereign — Sovereign .50 (pistolet lourd canon long)

Nouvelle arme pour le serveur, avec **exactement les mêmes stats que le pistolet de GTA** (`WEAPON_PISTOL`) : recul, dégâts, cadence, précision, portée, sons et animations sont **clonés depuis tes propres fichiers du jeu**. Seul le modèle change.

Design inspiré du cal .50 (Desert Eagle) avec canon long : canon à section triangulaire avec rail, frein de bouche et guidon fibre optique, culasse striée, crosse métal avec plaques caoutchouc piquetées, pontet à crochet.

- Finition **Noire** (d'origine) : camo carbone forgé noir avec écailles hexagonales, usure des arêtes.
- **Édition Halloween** (finition achetable) : camo cartoon (citrouilles, fantômes, chauves-souris, bonbons, étoiles sur nuit violette).
- Aperçu : `preview.html` (3D, tir, rechargement, inspection, boutique). Rendus dans `design/`.

## 1. Générer les .meta (stats identiques au pistolet GTA)

Je n'ai pas accès aux fichiers de GTA : c'est toi qui extrais les originaux, l'outil fait le reste.

1. Avec **OpenIV** ou **CodeWalker**, extrais depuis ton GTA V (en général `update.rpf → common → data → ai`) :
   `weapons.meta`, `weaponcomponents.meta`, `weaponanimations.meta`.
2. Lance l'outil (Python 3) :
   ```
   python3 tools/clone_pistol.py chemin/weapons.meta chemin/weaponcomponents.meta chemin/weaponanimations.meta
   ```
3. Il écrit dans `meta/` : `weapons.meta` (clone de `WEAPON_PISTOL` renommé `WEAPON_ORPSOVEREIGN`), `weaponcomponents.meta` (chargeur cloné de `COMPONENT_PISTOL_CLIP_01`, finition Halloween clonée du composant « luxe » de GTA) et `weaponanimations.meta`.

`meta/weaponarchetypes.meta` est déjà fourni. Tu peux aussi m'envoyer les 3 fichiers extraits : je lance l'outil pour toi.

> L'outil a été testé sur des fichiers d'exemple au format GTA, pas sur les vrais fichiers du jeu. S'il ne trouve pas un bloc, il te le dit.

## 2. Les modèles (dossier `stream/`)

Sources XML CodeWalker dans `xml_source/` (+ fichier Blender) :

| Modèle | Rôle |
|---|---|
| `w_pi_orpsovereign` | arme, finition noire (sans chargeur) |
| `w_pi_orpsovereign_mag1` | chargeur |
| `w_pi_orpsovereign_hw` | arme, édition Halloween |

**Étape indispensable — le squelette d'arme.** Une arme GTA a besoin d'os (`gun_root`, chargeur, bouche du canon…) pour la prise en main, le flash et les accessoires. Le plus fiable :
1. Dans Blender + Sollumz, importe `w_pi_pistol.ydr` (extrait du jeu) pour récupérer son squelette.
2. Importe `xml_source/w_pi_orpsovereign.ydr.xml`, place le modèle sur le squelette (même orientation : canon vers +X, prise en main à l'origine), exporte.
3. Fais pareil pour `_hw`, puis convertis le tout avec **CodeWalker → Tools → Import XML** et copie les `.ydr` / `.ytd` dans `stream/`.

## 3. ox_inventory

`ox_inventory/data/weapons.lua` :

```lua
-- dans Weapons
['WEAPON_ORPSOVEREIGN'] = { label = 'Sovereign .50', weight = 1100, durability = 0.1, ammoname = 'ammo-9' },

-- dans Components
['at_orpsov_halloween'] = {
    label = 'Camo Halloween (Sovereign)', type = 'skin', weight = 20,
    client = { component = { `COMPONENT_ORPSOVEREIGN_SKIN_HW` }, usetime = 2500 },
},
```

Mets la munition que tu utilises déjà pour tes pistolets à la place de `ammo-9`.

Boutique (`ox_inventory/data/shops.lua`, à adapter à ta boutique) :

```lua
OriginArmurerie = {
    name = 'Armurerie ORIGIN',
    inventory = {
        { name = 'WEAPON_ORPSOVEREIGN', price = 18500, license = 'weapon' },
        { name = 'at_orpsov_halloween', price = 6400 },
    },
    locations = { vec3(22.0, -1107.0, 29.8) },
},
```

Les prix sont aussi dans `config.lua` pour référence.

## 4. Ajouter tes camos plus tard

Envoie-moi tes images : je génère pour chaque camo un modèle `w_pi_orpsovereign_<nom>` (même forme, texture différente), j'ajoute la ligne dans `SKINS` de `tools/clone_pistol.py`, l'item `at_orpsov_<nom>` et sa ligne de boutique.

## 5. Test en jeu

Commande admin : `/sovereign` (finition noire) ou `/sovereign hw` (Halloween).
