# UI-OriginRP

## originrp_menu

Menus NUI (style violet « glass ») pour FiveM, standalone (aucune dépendance ESX / QBCore).

### Installation

1. Copier le dossier `originrp_menu` dans `resources/`.
2. Ajouter `ensure originrp_menu` dans `server.cfg`.
3. En jeu : **F5** ouvre le menu (réassignable dans les raccourcis clavier FiveM).

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

Exports : `exports.originrp_menu:openMenu('main')`, `closeMenu()`, `isOpen()`.

### Aperçu hors jeu

Ouvrir `originrp_menu/html/index.html` dans un navigateur (données de démo, avec un exemple de sous-menu sur « Paramètres »).
