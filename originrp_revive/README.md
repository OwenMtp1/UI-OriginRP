# originrp_revive — Réanimation animée avec sac d'intervention

Un joueur réanime un autre joueur dans le coma en moins de 10 s : il pose son sac médical au sol,
l'ouvre, prend le pouls, fait un massage cardiaque, puis la victime reprend son souffle.
L'animation se joue sur les personnages de tes joueurs, n'importe où sur la map.

Dépendances : `ox_lib`, `ox_inventory`, `ox_target` (+ ESX ou QBCore détectés automatiquement pour la réanimation).

## 1. Installer la ressource

1. Copie le dossier `originrp_revive` dans `resources/` et ajoute `ensure originrp_revive` dans `server.cfg`.
2. Déclare l'item dans `ox_inventory/data/items.lua` :

```lua
['medikit'] = {
    label = 'Kit de soin',
    weight = 1500,
    stack = true,
    close = true,
    description = "Sac d'intervention pour réanimer une personne dans le coma.",
    client = { export = 'originrp_revive.useMedikit' },
},
```

À ce stade tout fonctionne déjà, avec le sac médical de GTA (`xm_prop_x17_bag_med_01a`).

## 2. Activer le sac d'intervention personnalisé (fermé / ouvert)

Les modèles sont fournis au format XML de CodeWalker dans `xml_source/` (générés avec Blender + Sollumz).
Il faut les convertir une fois en fichiers binaires GTA :

1. Ouvre **CodeWalker** (RPF Explorer) sous Windows.
2. Utilise **Tools → Import XML** (ou glisse les fichiers dans un dossier ouvert en mode édition) et sélectionne
   `orp_medbag_closed.ydr.xml`, `orp_medbag_open.ydr.xml` et `orp_medbag.ytyp.xml`.
   Les dossiers de textures (`orp_medbag_closed/`, `orp_medbag_open/`) doivent rester à côté des `.xml`.
3. Tu obtiens `orp_medbag_closed.ydr`, `orp_medbag_open.ydr` et `orp_medbag.ytyp`.
4. Crée le dossier `originrp_revive/stream/` et mets-y ces 3 fichiers. Redémarre la ressource.

Le script détecte les modèles tout seul : sac fermé porté et posé, remplacé par le sac ouvert quand la main
du secouriste l'atteint, puis refermé et repris à la fin. `xml_source/orp_medbag.blend` est le fichier Blender
source si tu veux retoucher le modèle.

À ajuster en jeu si besoin (`config.lua`) :
- `Config.Props.handCustom` : position du sac dans la main ;
- `Config.MedicOffset` / `Config.BagOffset` : position du secouriste et du sac par rapport à la victime ;
- `Config.Props.bag.openAt` : moment où le sac s'ouvre.

## 3. Ce qui est joué en jeu

| Étape | Durée | Animation GTA |
|---|---|---|
| Se placer au niveau du torse | 0,6 s | déplacement |
| S'agenouiller, poser le sac à la main | 1,0 s | `pickup_object` / `putdown_low` |
| Ouvrir le sac, enfiler les gants | 0,9 s | `amb@medic@standing@kneel@idle_a` |
| Vérification 1 : conscience (tape les épaules) | 0,8 s | `tendtodead@idle_a` / `idle_a` |
| Vérification 2 : respiration (tête basculée, écoute) | 0,9 s | `tendtodead@idle_a` / `idle_b` |
| Vérification 3 : pouls carotidien | 0,7 s | `tendtodead@idle_a` / `idle_c` |
| Mains en position | 0,4 s | `mini@cpr@char_a@cpr_def` / `cpr_intro` |
| Massage cardiaque | 1,6 s | `mini@cpr@char_a@cpr_str` / `cpr_pumpchest` |
| Reprise du souffle | 1,0 s | `cpr_success` |
| Relevé accompagné (après la réanimation) | 1,5 s | secouriste `kneel@exit`, victime `get_up@sat_on_floor@to_stand` (à vérifier en jeu) |

Total : 9,4 s. Caméra cinématique pour le secouriste et la victime. X annule.
Le serveur vérifie la distance, le kit, l'état de la victime et la durée réelle avant de réanimer.

## Limites connues

- GTA n'a pas d'animation pour enfiler des gants ou tousser au réveil : ces gestes n'existent que dans l'aperçu.
  Pour les avoir en jeu, il faut une animation personnalisée (`.ycd`) — voir l'onglet « Animation personnalisée » de `revive.html`.
- Si ton système de mort laisse la victime en ragdoll, seul le secouriste est animé (la réanimation fonctionne quand même).
