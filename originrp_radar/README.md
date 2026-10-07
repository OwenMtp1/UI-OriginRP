# originrp_radar — Radars de vitesse automatiques

Tout est dans `radar.html` : onglet **Aperçu** (simulation) et onglet **Script Lua** (code + téléchargement).
Les mêmes fichiers Lua sont dans ce dossier.

- Limite de base 70 km/h (`Config.DefaultLimit`, modifiable par radar).
- Amende selon l'écart : 100 / 250 / 400 / 600 / 800 / 1000 / 1250 / 1500 $ (`Config.Fines`).
- Vitesse revérifiée côté serveur, montant retiré du compte bancaire (ESX ou QBCore détectés automatiquement).
- Notification : « Une amende pour vitesse excessive de X $ vous a été distribuée » + flash et son d'appareil photo.
- Indestructible (balles, chocs, feu) sauf bombe collante et roquette ; réinstallé après 30 min.
- Véhicules d'urgence exemptés. Commande admin `/radar add [limite]` et `/radar remove` (ace `command.radar`).
