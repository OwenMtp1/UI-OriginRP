# originrp_creation

Création de personnage dans la DA OriginRP : panneau latéral lisible, 6 étapes, caméra pilotée.

| Étape | Contenu |
| --- | --- |
| **Identité** | Prénom, nom (lettres uniquement, majuscule auto), date de naissance (âge 18–90), sexe (change le modèle), taille. Erreurs affichées sous chaque champ, impossible d'avancer tant que ce n'est pas valide. |
| **Héritage** | Mère et père parmi les 46 parents GTA avec leur **portrait officiel** (texture `char_creator_portraits` du jeu), ressemblance et teint de peau. |
| **Visage** | Les 20 traits GTA regroupés : Nez, Sourcils, Pommettes, Yeux, Mâchoire (curseurs −100 / +100). |
| **Apparence** | Cheveux (coupe, couleur, mèches avec la vraie palette du jeu), Pilosité (barbe, sourcils, torse), Yeux, Maquillage (yeux, blush, rouge à lèvres), Peau (vieillissement, teint, imperfections, soleil, grains de beauté). |
| **Vêtements** | Tenues prêtes à porter + réglage fin de chaque pièce (modèle / couleur), sans grille de cases vides. |
| **Résumé** | Récapitulatif avec liens « Modifier », case de confirmation obligatoire avant « Valider le personnage ». |

- Boutons **Aléatoire** et **Réinitialiser** sur chaque étape d'apparence.
- Étapes cliquables (une fois l'identité valide), barre de progression.
- Caméra : préréglages **Visage / Buste / Corps** (changent aussi automatiquement selon l'étape),
  **molette** pour zoomer, **Z / S** pour la hauteur, **A / E** pour pivoter.
- Nombre de coupes, styles et vêtements lu sur le personnage : les sélecteurs ne dépassent jamais.

## Installation

1. Copier le dossier `originrp_creation` dans `resources/`.
2. Ajouter `ensure originrp_creation` dans `server.cfg`.
3. Réglages (âge, taille, caméras, tenues prêtes à porter) dans `config.lua`.
   Les tenues fournies sont indicatives : adapter les numéros aux vêtements du serveur.

## Utilisation

Le script de sélection / spawn de la base place le joueur dans la pièce de création puis :

```lua
exports.originrp_creation:open({ sex = 'm' }, function(result)
    -- result.identity : firstname, lastname, dateofbirth (JJ/MM/AAAA), sex, height
    -- result.skin     : apparence complète (modèle, héritage, visage, cheveux, calques, vêtements)
    TriggerServerEvent('ma_base:createCharacter', result.identity, result.skin)
end)
```

**Le serveur doit revérifier l'identité** (format du nom, âge, taille) avant d'enregistrer.
`exports.originrp_creation:applySkin(result.raw)` réapplique une apparence enregistrée.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur (`index.html#3` ouvre directement l'étape 4).
