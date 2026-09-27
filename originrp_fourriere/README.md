# originrp_fourriere

Menu fourrière dans la DA OriginRP, même code et même style que les garages
(`originrp_garage`, `originrp_garage_bateau`, `originrp_garage_avion`), avec `Config.Type = 'impound'`.

- Argent du joueur affiché en haut (optionnel).
- Filtre par catégorie : Voitures, Motos, Utilitaires.
- Chaque véhicule : nom, plaque, date et motif de la mise en fourrière, et :
  - **Récupérer · 250 $** → un premier clic affiche **Confirmer · 250 $** (orange) pendant
    quelques secondes, un second clic valide ;
  - **Il manque 550 $** si le joueur n'a pas assez d'argent ;
  - **Saisie police** (cadenas) si le véhicule est bloqué.
- Souris ou clavier : ↑ ↓ choisir, Entrée récupérer (deux fois pour confirmer), Échap fermer.

## Installation

1. Copier le dossier `originrp_fourriere` dans `resources/`.
2. Ajouter `ensure originrp_fourriere` dans `server.cfg`.
3. Position et textes par défaut dans `config.lua` (ne pas changer `Config.Type`).

## Utilisation (depuis le script de fourrière de la base)

```lua
exports.originrp_fourriere:open({
    id = 'davis',
    subtitle = 'Fourrière de Davis',
    money = 1250,                              -- argent du joueur (optionnel)
    tabs = {
        { id = 'perso', vehicles = {
            { label = 'Karin Sultan RS', plate = 'ORG 123', model = 'sultanrs',
              price = 250, reason = 'Stationnement gênant', date = '27/09 18:42', props = props },
            { label = 'Vapid Speedo', plate = 'LS 5521', model = 'speedo',
              price = 500, reason = 'Saisie judiciaire', date = '24/09 09:30', locked = true },
        } },
    },
}, function(vehicle, impoundId, tabId)
    -- le joueur a confirmé : côté serveur, vérifier et retirer vehicle.price,
    -- puis faire sortir le véhicule
end)
```

- Sans fonction de retour, l'événement client `originrp_fourriere:takeOut` est déclenché.
- **Le paiement doit être fait et vérifié côté serveur** (argent suffisant, véhicule du
  joueur, non bloqué) : le menu ne fait qu'afficher et demander confirmation.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
