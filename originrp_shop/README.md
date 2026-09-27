# originrp_shop

Tablette boutique dans la DA OriginRP (cadre de tablette, gris dominant, accents violets, logo Origin).

- **Accueil** : solde, VIP actif, nombre d'achats ; packs d'Orins (ouvrent le site de paiement) ;
  articles « À la une ».
- **Catégories** (Véhicules, Armes, Packs, VIP… configurables) : cartes avec image, étiquette,
  prix, recherche et tri par prix. Bouton grisé « Solde insuffisant » si le joueur n'a pas assez.
- **Historique** des achats.
- Fenêtre de **confirmation** avant chaque achat (solde avant / après).

## Installation

1. Copier le dossier `originrp_shop` dans `resources/`.
2. Ajouter `ensure originrp_shop` dans `server.cfg`.
3. `/boutique` ouvre la tablette (touche optionnelle dans `config.lua`).

## Configuration

- `config.lua` : titre, monnaie, lien du site (`Config.BuyUrl`), packs d'Orins, catégories et
  **articles** (prix, description, image, étiquette, à la une, `data` libre pour la livraison).
  Images : les mettre dans `html/img/` (ex. `image = 'img/sultan.png'`) ou une URL.
- `sv_config.lua` (**à brancher sur la base**) : `GetBalance`, `RemoveBalance`, `AddBalance`,
  `GiveItem`, `GetVip`, `GetHistory`, `AddHistory`. Le solde est commun à tous les
  personnages : utiliser la licence du compte.

## Sécurité

La tablette n'envoie que l'identifiant de l'article. Le serveur relit le prix dans
`config.lua`, vérifie le solde, retire les Orins, livre l'article et **rembourse
automatiquement** si la livraison échoue. Un seul achat à la fois par joueur.
`RemoveBalance` doit être atomique côté base (ex. `UPDATE ... SET orins = orins - ? WHERE orins >= ?`).

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur (achats simulés).
`index.html#vehicles`, `#weapons`, `#packs`, `#vip` ou `#history` ouvrent directement un onglet.
