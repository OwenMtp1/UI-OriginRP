# originrp_garage

Menu garage dans la DA OriginRP (même style que le menu F5).

- Onglets (ex. « Mes véhicules », « Entreprise ») avec le nombre de véhicules.
- Filtre par catégorie (Tous, Voitures, Motos, Utilitaires, Bateaux, Aériens, Urgence),
  affiché automatiquement dès qu'un onglet contient au moins deux catégories.
- Chaque véhicule : icône de sa catégorie, nom, plaque, jauges carburant / moteur (en rose sous 25 %),
  bouton **Sortir**, ou statut « Déjà sorti » / « Fourrière ».
- Souris ou clavier : ↑ ↓ choisir, Entrée sortir, ← → / Tab changer d'onglet, Échap fermer.
- Écran vide soigné quand aucun véhicule n'est rangé.

## Installation

1. Copier le dossier `originrp_garage` dans `resources/`.
2. Ajouter `ensure originrp_garage` dans `server.cfg`.
3. Position et textes par défaut dans `config.lua`.

## Utilisation (depuis le script de garage de la base)

Le menu ne fait qu'afficher : c'est le script de garage qui envoie la liste et fait
apparaître le véhicule choisi.

```lua
exports.originrp_garage:open({
    id = 'pillbox',
    subtitle = 'Parking de Pillbox Hill',
    tabs = {
        { id = 'perso', label = 'Mes véhicules', icon = 'car', vehicles = {
            { label = 'Karin Sultan RS', plate = 'ORG 123', model = 'sultanrs', fuel = 80, engine = 95, state = 'garage', props = props },
        } },
    },
}, function(vehicle, garageId, tabId)
    -- faire sortir le véhicule (vehicle contient tous les champs envoyés : props, model…)
end)
```

- `state` : `'garage'` (disponible), `'out'` (déjà sorti), `'impound'` (fourrière).
- `category` : `car`, `bike`, `truck`, `boat`, `air`, `emergency`. Si elle n'est pas donnée,
  elle est déduite automatiquement de la classe GTA du `model`.
- `icon` d'onglet : `car`, `users`, `truck`, `bike`.
- Sans fonction de retour, l'événement client `originrp_garage:takeOut` est déclenché.
- Le serveur doit toujours revérifier que le véhicule appartient au joueur avant de le sortir.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
