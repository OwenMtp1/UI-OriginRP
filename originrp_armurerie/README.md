# originrp_armurerie

Armurerie dans la DA OriginRP (panneau violet, arcs lumineux).

- En-tête : espèces et carte du joueur.
- **Permis de port d'arme** : bandeau « requis » avec son prix et paiement espèces / carte,
  ou « valide » une fois obtenu. Les catégories marquées `license = true` (armes à feu,
  munitions) sont verrouillées (cadenas, « Permis requis ») sans permis.
- Onglets Mêlée / Armes à feu / Munitions (configurables) avec le nombre d'articles.
- Chaque article : nom, description, prix, quantité (munitions), paiement **Espèces** ou
  **Carte**. Un premier clic affiche « Confirmer · prix », un second valide. Bouton grisé si
  le moyen de paiement n'a pas assez d'argent.
- Clavier : ← → / Tab changer d'onglet, Échap fermer.

## Installation

1. Copier le dossier `originrp_armurerie` dans `resources/`.
2. Ajouter `ensure originrp_armurerie` dans `server.cfg`.

## Utilisation

Le script d'armurerie de la base ouvre le menu avec ses articles et reçoit les achats :
exemple complet en haut de `client.lua` (`exports.originrp_armurerie:open(data, handlers)`),
puis `update(...)` pour rafraîchir l'argent / le permis et `notify(...)` pour un message.

**Le serveur doit relire le prix dans sa propre config et vérifier l'argent, le permis et
la quantité** avant de donner quoi que ce soit : le menu n'envoie que l'identifiant.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur.
