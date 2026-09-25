# UI-OriginRP

| Ressource | Contenu |
| --- | --- |
| `originrp_menu` | Menus F5, F7 (Organisation), F10 (Staff) |
| `originrp_koth` | Classement KOTH |
| `originrp_playercard` | Fiche joueur (nom, ID, emploi, organisation) |

## originrp_menu

Menus NUI (style violet « glass ») pour FiveM, standalone (aucune dépendance ESX / QBCore).

### Installation

1. Copier le dossier `originrp_menu` dans `resources/`.
2. Ajouter `ensure originrp_menu` dans `server.cfg`.
3. En jeu : **F5** ouvre le menu principal, **F7** le menu organisation,
   **F10** le menu staff (réassignables dans les raccourcis clavier FiveM).

### Contrôles

| Action | Souris | Clavier |
| --- | --- | --- |
| Choisir une rubrique | Survol | ↑ / ↓ |
| Valider | Clic gauche | Entrée / Espace |
| Retour | Clic droit / bouton ← | Retour arrière / ← |
| Fermer | — | Échap / F5 |

### Ajouter ou modifier un menu

Tout se fait dans `config.lua` (voir les commentaires en haut de `Config.Menus`).
Chaque rubrique peut ouvrir un sous-menu (`submenu`) ou déclencher un événement
client (`event`), serveur (`serverEvent`), une commande (`command`) ou une fonction (`onSelect`).

Exemple côté script pour réagir à une rubrique :

```lua
AddEventHandler('originrp_menu:identite', function()
    -- ouvrir votre interface d'identité
end)
```

Exports : `exports.originrp_menu:openMenu('main')`, `closeMenu()`, `setMenu(id, données)`, `isOpen()`.

### Menu F7 — Organisation

| Rubrique | Type | Ce qu'il faut brancher |
| --- | --- | --- |
| Grade | Valeur affichée à droite | Renvoyée par `onOpen` dans `config.lua` |
| Prendre son service | Case à cocher | Event serveur `originrp_menu:organisation:service` reçu avec `true` / `false` |
| Ouvrir la tablette | Action | Event client `originrp_menu:organisation:tablette` |

Le nom de l'organisation (titre) et le grade viennent de la base : il faut compléter
la fonction `onOpen` du menu `organisation` dans `config.lua` (exemples ESX et
QBCore en commentaire). Si `onOpen` renvoie `false`, le menu ne s'ouvre pas
(ex. joueur sans organisation).

```lua
-- server.lua de la base
RegisterNetEvent('originrp_menu:organisation:service', function(enService)
    local src = source
    -- passer le joueur en service / hors service
end)
```

Pour synchroniser la case si le service change ailleurs :
`exports.originrp_menu:setMenu('organisation', { items = { service = { checked = true } } })`.

### Menu F10 — Staff

Réservé aux joueurs ayant la permission ACE `originrp.staff` (vérifiée par le serveur).
Dans `server.cfg` :

```cfg
add_ace group.admin originrp.staff allow
add_principal identifier.license:XXXXXXXX group.admin   # pour chaque membre du staff
```

| Rubrique | Event client déclenché |
| --- | --- |
| Reports | `originrp_menu:staff:reports` |
| Moi | `originrp_menu:staff:moi` |
| Joueurs | `originrp_menu:staff:joueurs` |
| Gestion du serveur | `originrp_menu:staff:serveur` |
| Bans | `originrp_menu:staff:bans` |
| Paramètres | `originrp_menu:staff:parametres` |

- « X en ligne » est calculé automatiquement par `server.lua`.
- « X en attente » : le système de reports doit faire, côté serveur,
  `GlobalState.originrp_reports = nombreDeReports` à chaque nouveau report / report traité.
- **Important** : la permission protège seulement l'ouverture du menu. Chaque action
  staff (kick, ban, téléportation…) doit revérifier la permission côté serveur.

### Aperçu hors jeu

Ouvrir `originrp_menu/html/index.html` dans un navigateur (données de démo, avec un exemple de sous-menu sur « Paramètres »).
`index.html#organisation` et `index.html#staff` ouvrent directement ces menus. Menu fermé : F5, F7 ou F10 pour le rouvrir.
