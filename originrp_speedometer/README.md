# originrp_speedometer

Compteur de vitesse en bas de l'écran, dans le style des UI OriginRP :

- grand cadran violet avec graduations, vitesse animée et unité (km/h ou mph) ;
- arc fin du **régime moteur**, qui passe en rouge dans la zone rouge ;
- **rapport** engagé (N au point mort, R en rouge en marche arrière) ;
- voyants **phares** (code / pleins phares) et **ceinture** (rouge clignotant si non bouclée) ;
- jauges **essence** et **état du moteur** de chaque côté, en rouge sous le seuil d'alerte.

Masqué hors véhicule, à vélo et dans le menu pause.

## Installation

1. Copier le dossier `originrp_speedometer` dans `resources/`.
2. Ajouter `ensure originrp_speedometer` dans `server.cfg`.
3. **Désactiver l'ancien compteur** (sinon les deux s'affichent).
4. Réglages dans `config.lua` : unité, vitesse max du cadran, taille, position, seuils d'alerte.

## Essence

`Config.Fuel = 'auto'` détecte LegacyFuel, ps-fuel, cdn-fuel et ox_fuel, sinon le niveau natif du jeu.

## Ceinture

Le voyant reflète l'état envoyé par votre script de ceinture :

```lua
exports.originrp_speedometer:setSeatbelt(true)        -- bouclée
TriggerEvent('originrp_speedometer:seatbelt', false)  -- débouclée
```

Sans script de ceinture, mettre `Config.Seatbelt = false` pour masquer le voyant.

## Divers

- `exports.originrp_speedometer:setVisible(false)` masque le compteur (cinématique…).
- `Config.DriverOnly = true` pour ne l'afficher qu'au conducteur.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur (accélérations et freinages de démo).
