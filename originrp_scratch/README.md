# originrp_scratch — Borne et tickets à gratter (SA Lottery)

Dépendances : `ox_lib`, `ox_inventory`, `ox_target`.

## Installation

1. Mets le dossier `originrp_scratch` dans `resources/` et ajoute `ensure originrp_scratch` dans `server.cfg`
   (après ox_lib, ox_inventory et ox_target).
2. Ajoute l'item dans `ox_inventory/data/items.lua` :

```lua
['scratch_ticket'] = {
    label = 'Ticket à gratter',
    weight = 10,
    stack = true,
    close = true,
    description = 'CASH ROYALE — SA Lottery. Grattez les 3 cases !',
    client = { export = 'originrp_scratch.useTicket' },
},
```

3. Copie `images/scratch_ticket.png` dans `ox_inventory/web/images/`.
4. Ajuste les positions des bornes dans `config.lua` (`Config.Kiosks`).

## Fonctionnement

- ALT sur la borne → « Achetez un ticket de grattage » → choix de la quantité (500 $ le ticket, payé en liquide).
- Limite : 40 tickets par joueur et par jour (sauvegardée, remise à zéro à minuit, heure du serveur).
- Utiliser un ticket → il s'affiche à l'écran, on gratte les 3 cases à la souris (ou « Tout gratter »).
- Le tirage est fait par le serveur quand le ticket est utilisé ; le gain est versé en liquide.
  Si le joueur se déconnecte avant d'encaisser, le gain lui est versé à sa prochaine utilisation de la borne ou d'un ticket.

## Probabilités (config.lua)

- 40 % de tickets à 0 $ partout, 60 % de tickets gagnants.
- Tickets gagnants : 1 case (50 %), 2 cases (30 %), 3 cases (20 %).
- Montant d'une case gagnante : 100 $ (45 %), 200 $ (26 %), 500 $ (20 %), 1 000 $ (8 %), 2 500 $ (1 %).
- Gain moyen ≈ 308 $ par ticket (≈ 62 % de la mise). Gain max : 7 500 $.

## À savoir

- La borne utilise le modèle GTA `prop_vend_snak_01` (~2 m). Remplace `Config.Model` par ton prop streamé si tu en as un.
- Paiement en liquide ox_inventory par défaut ; pour la banque ESX / QBCore, modifie `sv_config.lua`.
- `preview.html` : aperçu à ouvrir dans un navigateur (borne 3D, achat, grattage). Inutile sur le serveur.
