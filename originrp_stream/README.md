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
| `twitch-overlay-transparent.png`, `twitch-alerte-transparent.png` (1920 × 1080), `tiktok-live-transparent.png` (1080 × 1920) | PNG transparents de l'overlay, d'une alerte et de l'overlay TikTok LIVE |

Les fichiers `apercu-*` et `exemple-*` servent seulement d'aperçu.

## Liens en ligne pour OBS (`obs.html`)

`obs.html` liste toutes les bannières et tous les écrans animés, avec un aperçu en direct, l'adresse à copier
et la taille à régler dans OBS. Une fois le dépôt publié avec GitHub Pages, le staff n'a rien à télécharger :

`https://owenmtp1.github.io/UI-OriginRP/originrp_stream/obs.html`

Dans OBS : **Sources › + › Navigateur**, décocher **Fichier local**, coller l'adresse copiée dans **URL**, régler la taille,
puis cocher **Actualiser le navigateur quand la scène devient active** pour rejouer l'animation d'entrée.

Publication (une seule fois) : sur GitHub, **Settings › Pages › Build and deployment**, Source **Deploy from a branch**,
choisir la branche par défaut du dépôt et le dossier **/ (root)**, puis **Save**. L'adresse est prête au bout d'une à deux minutes,
et chaque modification poussée sur cette branche est mise en ligne automatiquement.

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

Pour ajouter des paramètres, décocher « Fichier local » et coller l'adresse complète, par exemple :
`file:///C:/kit/originrp_stream/twitch/debut.html?min=10&nom=Kenzo`

L'overlay laisse libres le bas à gauche (minimap et HUD) et le bas au centre (compteur de vitesse).
Le cadre caméra est en bas à droite : placer la webcam dessous.

## Annonces

- `twitch/annonce.html?nom=Pseudo&heure=21h00` (1920 × 1080) : visuel « En live » pour Discord, X, Instagram.
- `tiktok/annonce.html?nom=Pseudo&heure=21h00` (1080 × 1920) : story ou post TikTok.

## Bannière TikTok du haut

`export/tiktok-banniere-haut-malou.png`, `-simba.png`, `-communication.png` et `-owen.png` (1080 × 656) remplissent la bande
au-dessus du gameplay, avec le personnage, le pseudo et le rôle.

La page est animée (source Navigateur dans OBS, 1080 × 656) : entrée du personnage, du logo, du pseudo et du poste
au chargement (≈ 2 s), puis halo du personnage qui respire, reflet sur le pseudo, lumière qui court sur le filet du bas,
anneaux du logo qui tournent et particules. `&intro=0` affiche directement le visuel sans l'entrée.

Owen : `tiktok/banniere-haut.html?nom=Owen&role=Co-fondateur d'Origin RP&perso=owen.png`.
Le personnage d'Owen (`commun/persos/owen.png`) est une illustration dans le style de Malou, légèrement plus proche du style GTA ; la capture 3D d'origine est gardée : `perso=owen-render.png`.
Simba : `tiktok/banniere-haut.html?nom=Simba&role=Fondateur d'Origin RP&perso=simba.png` (ancienne capture 3D : `perso=simba-render.png`).
Équipe de communication : `tiktok/banniere-haut.html?nom=OriginRP&role=Équipe de communication OriginRP&perso=communication.png` (première version : `perso=communication-v1.png`).
Un pseudo ou un poste trop long est réduit automatiquement pour tenir sur une ligne.
Pour un autre streamer : `tiktok/banniere-haut.html?nom=Pseudo&role=Streamer officiel`, puis capture en 1080 × 656
(ou me demander l'export). Le contenu est décalé vers le bas pour ne pas passer sous les onglets TikTok.

Le personnage de Malou est à gauche (`commun/persos/malou.png`, illustration détourée). Les anciens dessins
sont gardés : `?perso=malou-gta` et `?perso=malou-cartoon`.
ajouter son image (PNG détouré ou SVG) dans `commun/persos/` puis `?nom=Pseudo&perso=fichier.png`.

## Bannière TikTok du bas

`export/tiktok-banniere-bas.png` (1080 × 656) remplit exactement la bande sous le gameplay quand une vidéo 16:9
est centrée dans un format TikTok 1080 × 1920. Dans CapCut : placer le gameplay au centre, puis la bannière collée en bas.
Version animée pour OBS : `tiktok/banniere-bas.html` (1080 × 656), avec entrée du logo, des mots et du lien Discord,
puis lien Discord qui pulse, lumière sur le filet du haut et particules.

## Alertes

`twitch/alertes.html` montre le design des alertes (follow, abonné, don, raid) et les fait défiler en démo.
Pour tester une alerte précise : `?type=sub&nom=Lyna&montant=3` (types : `follow`, `sub`, `don`, `raid`).

Les vraies alertes sont déclenchées par **Streamlabs** ou **StreamElements** : le design doit être recopié dans
leur éditeur d'alertes (HTML / CSS personnalisés). Il faut savoir quel outil les streamers utilisent pour l'adapter.

## Remarques

- Les polices (Montserrat, Inter) se chargent depuis Google Fonts : il faut une connexion Internet (c'est le cas dans OBS).
- Les visuels sont faits pour 1080p. En 720p, OBS les met à l'échelle automatiquement.
