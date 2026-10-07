# originrp_bracelet — Bracelet électronique

Dépendances : `ox_lib`, `ox_inventory`, `ox_target`.

## Item (`ox_inventory/data/items.lua`)

```lua
['electronic_bracelet'] = {
    label = 'Bracelet électronique',
    weight = 350,
    stack = true,
    close = true,
    description = 'Bracelet de surveillance à poser à la cheville.',
    client = { export = 'originrp_bracelet.useBracelet' },
},
```

## Fonctionnement

1. Utiliser l'item → notification « Faites ALT sur la personne à qui mettre le bracelet » (15 s pour choisir).
2. ALT sur un joueur → « Mettre le bracelet électronique ».
3. Le poseur se place au niveau de la jambe, accroupi, animation de 3 s (annulable). La personne reste immobile.
4. Notifications en bas à gauche :
   - poseur : « Vous avez mis un bracelet électronique à (nom du personnage) »
   - personne : « Un bracelet électronique vous a été mis à la jambe »
5. Le bracelet est attaché à la cheville gauche et n'est affiché que si le bas (composant 4) est un short / sous-vêtement
   (`Config.UncoveredLegs`). Avec un long pantalon il est caché, mais toujours porté.
6. Retrait : ALT → « Retirer le bracelet électronique », réservé à `Config.RemoveJobs` (rend l'item).

Le bracelet est sauvegardé par joueur (KVP) et réappliqué à la connexion.
Exports serveur : `HasBracelet(src)`, `SetBracelet(src, bool)`. Statebag : `Player(src).state.bracelet`.

## À adapter

- `sv_config.lua` : nom RP du personnage et job (ESX / QBCore, exemples en commentaire).
- `Config.UncoveredLegs` : numéros des shorts / sous-vêtements de ton pack de vêtements.
- `Config.Prop` : GTA n'a pas de bracelet électronique de base ; remplace le modèle par ton prop streamé.

Aperçu interactif : `preview.html`.
