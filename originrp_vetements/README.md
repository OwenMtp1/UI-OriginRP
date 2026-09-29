# originrp_vetements

Magasin de vêtements dans la DA OriginRP, en panneau latéral pour laisser le personnage visible.

- Espèces et carte du joueur.
- 8 catégories : Haut, Sous-vêtement, Pantalon, Chaussures, Couvre-chef, Gants, Sac, Lunettes
  (configurables dans `config.lua` avec leur prix).
- Grille des modèles (N° 00, 01…) : **le nombre de modèles et de couleurs est lu
  automatiquement sur le personnage**. Clic = aperçu direct sur le personnage.
- Choix de la couleur (‹ Couleur 1 / 5 ›), prix, paiement **Espèces** / **Carte** avec confirmation.
- **A / E** (ou les boutons) pour faire pivoter le personnage, Échap pour fermer.
- En fermant, la tenue d'origine est remise, sauf les achats validés.

## Installation

1. Copier le dossier `originrp_vetements` dans `resources/`.
2. Ajouter `ensure originrp_vetements` dans `server.cfg`.

## Utilisation

Exemple complet en haut de `client.lua` :
`exports.originrp_vetements:open({ money = … }, { onBuy = function(purchase, method) … end })`.
Après vérification et paiement côté serveur, appeler
`exports.originrp_vetements:purchaseResult(true, 'Haut acheté.')` pour garder le vêtement
(ou `false` + message en cas de refus). La sauvegarde de la tenue reste au script de la base.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
