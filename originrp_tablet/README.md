# originrp_tablet

Tablette d'organisation / d'entreprise, dans le style des menus OriginRP.

- **Onglet Membres** : type, points d'expérience, ton grade ; liste des membres avec
  statut en ligne / hors ligne, grade, temps de service, badge « En service » ;
  recherche et filtres (Tous / En ligne / En service).
  Clic sur un membre : fiche avec **Promouvoir**, **Rétrograder**, **Exclure** (avec confirmation).
- **Onglet Grades** : grades du plus haut au plus bas avec leurs permissions.
  Clic sur un grade : renommer, changer les permissions (interrupteurs), supprimer.
  **Ajouter un grade** en bas de la liste.
- **Recruter** (en haut) : joueur le plus proche ou par ID.
- Les boutons sont grisés ou masqués selon les permissions du grade du joueur
  (recrutement, gestion des grades) et on ne peut gérer que les grades inférieurs au sien.

## Installation

1. Copier le dossier `originrp_tablet` dans `resources/`.
2. Ajouter `ensure originrp_tablet` dans `server.cfg`.
3. **Brancher la base dans `sv_config.lua`** (voir ci-dessous).

La tablette s'ouvre avec « Ouvrir la tablette » des menus F6 (entreprise) et F7
(organisation) de `originrp_menu`. Depuis un autre script serveur :
`exports.originrp_tablet:open(source, 'organisation')` (ou `'entreprise'`).

## À brancher : `sv_config.lua`

Deux fonctions serveur, décrites en détail dans le fichier :

- `ServerConfig.GetData(source, kind)` → renvoie le nom, le type, l'XP, le joueur
  (`me`), les grades et les membres. `nil` = pas d'accès.
- `ServerConfig.OnAction(source, kind, action, payload)` → applique l'action
  (`recruit`, `promote`, `demote`, `kick`, `saveGrade`, `deleteGrade`) et renvoie
  `ok, message`. La tablette se met à jour automatiquement ensuite.

**Sécurité** : la tablette masque les boutons interdits, mais `OnAction` doit
toujours revérifier les permissions côté serveur.

Permissions disponibles (modifiables dans `config.lua`) : `coffre`, `tablette`,
`service`, `recrutement`, `grades`.

## Aperçu hors jeu

Ouvrir `html/index.html` dans un navigateur : données de démo, toutes les actions
fonctionnent (simulées). `index.html#grades` ouvre directement l'onglet Grades.
