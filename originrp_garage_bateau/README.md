# originrp_garage_bateau

Port (garage bateaux) dans la DA OriginRP (même style que le menu F5).
Fait partie d'une série de 3 ressources indépendantes, même code, seul `Config.Type` change :
`originrp_garage` (voitures), `originrp_garage_bateau` (port), `originrp_garage_avion` (hangar).

- Onglets (ex. « Mes … », « Entreprise ») avec le nombre d'éléments.
- Filtre par catégorie : `boat` (Bateaux), `jetski` (Jet-skis), `sub` (Sous-marins).
  Affiché dès qu'un onglet contient au moins deux catégories.
- Chaque élément : icône de sa catégorie, nom, immatriculation, jauge carburant et jauge
  d'état (clé à molette = moyenne moteur + carrosserie), en rose sous 25 %,
  bouton **Sortir**, ou statut « Déjà sorti » / « Fourrière ».
- Souris ou clavier : ↑ ↓ choisir, Entrée sortir, ← → / Tab changer d'onglet, Échap fermer.

## Installation

1. Copier le dossier `originrp_garage_bateau` dans `resources/`.
2. Ajouter `ensure originrp_garage_bateau` dans `server.cfg`.
3. Position et textes par défaut dans `config.lua` (ne pas changer `Config.Type`).

## Utilisation (depuis le script de garage de la base)

Le menu ne fait qu'afficher : c'est le script de garage qui envoie la liste et fait
apparaître l'élément choisi.

```lua
exports.originrp_garage_bateau:open({
    id = 'mon_garage',
    subtitle = 'Nom de l\'emplacement',
    tabs = {
        { id = 'perso', vehicles = {
            { label = 'Shitzu Squalo', plate = 'SEA 77', model = 'squalo', fuel = 80, engine = 95, body = 70, state = 'garage', props = props },
        } },
    },
}, function(vehicle, garageId, tabId)
    -- faire sortir l'élément (vehicle contient tous les champs envoyés : props, model…)
end)
```

- `state` : `'garage'` (disponible), `'out'` (déjà sorti), `'impound'` (fourrière).
- `category` : `boat` (Bateaux), `jetski` (Jet-skis), `sub` (Sous-marins). Si elle n'est pas donnée, elle est déduite du `model`.
- `icon` d'onglet (optionnel) : `car`, `bike`, `truck`, `boat`, `plane`, `heli`, `users`.
- Sans fonction de retour, l'événement client `originrp_garage_bateau:takeOut` est déclenché.
- Le serveur doit toujours revérifier que l'élément appartient au joueur avant de le sortir.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
