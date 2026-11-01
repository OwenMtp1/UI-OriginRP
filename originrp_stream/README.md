# Kit stream — Origin Roleplay

Visuels Twitch et TikTok pour les streamers du serveur, dans la DA violette d'Origin Roleplay.

## Avant tout

Le lien Discord (`discord.gg/originfr`), le slogan et le texte de connexion se modifient dans `config.js`.
Tous les visuels lisent ce fichier.

## Images prêtes à envoyer (`export/`)

| Fichier | Où le mettre |
| --- | --- |
| `twitch-photo-profil.png` (800 × 800) | Twitch : Paramètres › Profil › Photo de profil |
| `tiktok-photo-profil.png` | TikTok : Modifier le profil › Photo |
| `twitch-banniere-profil.png` (1200 × 480) | Twitch : Paramètres › Profil › Bannière de profil |
| `twitch-hors-ligne.png` (1920 × 1080) | Twitch : Paramètres › Chaîne › Bannière du lecteur vidéo |
| `twitch-panneau-*.png` (320 × 160) | Twitch : À propos › Modifier les panneaux (un panneau par image) |
| `twitch-debut.png`, `twitch-pause.png`, `twitch-fin.png` | Version image fixe des écrans animés |

Les fichiers `apercu-*` et `exemple-*` servent seulement d'aperçu.

## Écrans animés pour OBS

Dans OBS : **Sources › + › Navigateur**, cocher **Fichier local**, choisir le fichier, puis régler la taille indiquée.
Cocher **Actualiser le navigateur quand la scène devient active** pour relancer le compte à rebours.

| Fichier | Taille | Paramètres (à ajouter après le nom du fichier) |
| --- | --- | --- |
| `twitch/debut.html` | 1920 × 1080 | `?min=5` durée du compte à rebours, `&nom=Pseudo` |
| `twitch/pause.html` | 1920 × 1080 | `?min=3` (optionnel) |
| `twitch/fin.html` | 1920 × 1080 | `?nom=Pseudo` |
| `twitch/overlay.html` | 1920 × 1080, transparent | `?nom=Pseudo`, `&cam=0` sans cadre caméra |
| `twitch/alertes.html` | 1920 × 1080, transparent | voir « Alertes » |
| `tiktok/live.html` | 1080 × 1920, transparent | — |
| `tiktok/banniere-bas.html` | 1080 × 1920, transparent | `?seule=1` : bannière seule (1080 × 460) |

Pour ajouter des paramètres, décocher « Fichier local » et coller l'adresse complète, par exemple :
`file:///C:/kit/originrp_stream/twitch/debut.html?min=10&nom=Kenzo`

L'overlay laisse libres le bas à gauche (minimap et HUD) et le bas au centre (compteur de vitesse).
Le cadre caméra est en bas à droite : placer la webcam dessous.

## Annonces

- `twitch/annonce.html?nom=Pseudo&heure=21h00` (1920 × 1080) : visuel « En live » pour Discord, X, Instagram.
- `tiktok/annonce.html?nom=Pseudo&heure=21h00` (1080 × 1920) : story ou post TikTok.

## Bannière TikTok du bas

- `export/tiktok-banniere-bas.png` (1080 × 460, fond transparent autour) : la bannière seule, à poser en bas d'une vidéo dans CapCut ou TikTok.
- `tiktok/banniere-bas.html` (1080 × 1920, transparent) : la même, animée, placée en bas de l'écran, à ajouter comme source navigateur.

Sur TikTok, le pseudo et la description de la vidéo s'affichent en bas : remonter la bannière si elle est cachée.

Ouvrir la page dans un navigateur avec le bon pseudo, puis faire une capture à la bonne taille
(ou me demander l'export PNG pour un streamer).

## Alertes

`twitch/alertes.html` montre le design des alertes (follow, abonné, don, raid) et les fait défiler en démo.
Pour tester une alerte précise : `?type=sub&nom=Lyna&montant=3` (types : `follow`, `sub`, `don`, `raid`).

Les vraies alertes sont déclenchées par **Streamlabs** ou **StreamElements** : le design doit être recopié dans
leur éditeur d'alertes (HTML / CSS personnalisés). Il faut savoir quel outil les streamers utilisent pour l'adapter.

## Remarques

- Les polices (Montserrat, Inter) se chargent depuis Google Fonts : il faut une connexion Internet (c'est le cas dans OBS).
- Les visuels sont faits pour 1080p. En 720p, OBS les met à l'échelle automatiquement.
