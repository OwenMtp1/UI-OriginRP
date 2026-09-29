# originrp_tatoueur

Salon de tatouage dans la DA OriginRP, en panneau latéral pour laisser le personnage visible.

- Espèces et carte du joueur.
- 6 zones : Tête, Torse, Bras G., Bras D., Jambe G., Jambe D., avec le prix du motif
  (configurables dans `config.lua`).
- Recherche de motif, grille des motifs, « Aucun » pour voir la zone sans nouveau tatouage,
  badge « Possédé » sur les tatouages déjà faits.
- Clic = aperçu direct sur le personnage. Paiement **Espèces** / **Carte** avec confirmation.
- **A / E** (ou les boutons) pour faire pivoter le personnage, Échap pour fermer.
- En fermant, seuls les tatouages possédés restent.

## Installation

1. Copier le dossier `originrp_tatoueur` dans `resources/`.
2. Ajouter `ensure originrp_tatoueur` dans `server.cfg`.

## Utilisation

Le script de la base envoie la liste des motifs (nom, `collection`, `overlay` GTA) et les
tatouages possédés : exemple complet en haut de `client.lua`. Après vérification et paiement
côté serveur, appeler `exports.originrp_tatoueur:purchaseResult(true, 'Tatouage réalisé !')`
(ou `false` + message). La sauvegarde des tatouages reste au script de la base.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
