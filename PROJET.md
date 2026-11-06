# Dashboard Kindle — état du projet (6 novembre 2026)

## Objectif
Afficher sur l'écran de veille d'un Kindle un dashboard avec la météo de
Bouliac (33270) et les dernières actus IA (TLDR AI + TechCrunch/The Verge/MIT
Tech Review), mis à jour 3×/jour (7h, 12h, 18h, heure de Paris), sans dépendre
du Mac une fois en place.

## Reprise du 6 novembre — état réel de l'installation

- Dashboard régénéré et contrôlé visuellement, toujours en 1072×1448 gris.
- Planification cloud corrigée : trois générations à 6h30, 11h30 et 17h30,
  `timezone: Europe/Paris`, pour les affichages prévus à 7h, 12h et 18h.
- Le générateur publie aussi `schedule.txt` (14 jours d'instants UTC calculés
  en heure de Paris) et `dashboard.sha256`.
- Client de téléchargement atomique : `kindle/refresh.sh`. Vérification du
  SHA-256 et de l'en-tête PNG/résolution avant remplacement de l'image ;
  conservation du cache en cas d'échec ; dessin uniquement en veille.
- Quatre tests passent : téléchargement valide, image tronquée, page HTML
  avec somme correcte, changements d'heure été/hiver.
- Écran de veille retenu : **chengandre/kindle-custom-screensaver v0.6.0**,
  testé en amont sur Kindle 11 / 5.19.5. Paquet vérifié par SHA-256 et préparé
  dans `.local/device/` avec `sh scripts/prepare-device.sh`.
- **Jailbreak non terminé** : Shadow v1.0.2 a détecté le bon appareil et
  transféré `jb.sh`, puis son binaire Mac a planté dans
  `libusb_release_interface` après la reconnexion, avant `chain.Fire`.
  Aucun envoi du payload d'exécution n'a été observé.
- Shadow a ensuite été compilé depuis sa source avec Go 1.27.3 et la
  bibliothèque libusb Homebrew 1.0.30. Ses tests cmd/shadow, usbdev, mtp et
  chain passent. Binaire : `.local/shadow/shadow-native`.
- Le second essai n'a trouvé aucun Kindle en USB et s'est arrêté proprement
  après attente. La correction du plantage n'a donc pas encore pu être
  vérifiée sur le matériel.
- L'utilisateur a confirmé de nouveau **5.19.5 (4794270058)**.
- Journaux locaux : `.local/shadow/install.log` et `install-native.log`.
  `.local/` est ignoré par Git.
- **Prochain prérequis** : obtenir une connexion USB de données stable,
  puis relancer Shadow avec les droits administrateur via la fenêtre macOS.
  Ne demander le débranchement/rebranchement qu'après le message de Shadow.
- **Encore à faire après le jailbreak** : transférer le paquet, exécuter
  `Diagnostic Dashboard` pour identifier les interfaces powerd réelles,
  installer et tester le réveil RTC/rafraîchissement automatique, la reprise
  après redémarrage et l'affichage physique. Le téléchargement et le paquet
  préparés ne constituent pas encore un service autonome installé.

## Matériel
- **Kindle 11e génération, modèle 2024** (basique, couleur sauge), connecté
  en USB-C au Mac, reconnu en MTP comme « Amazon Kindle » (VID 0x1949, PID
  0x9981).
- Numéro de série : `G093L207548406G7`.
- **Firmware actuel : Kindle 5.19.5, build 4794270058** (vu dans Paramètres →
  Options de l'appareil → Infos sur l'appareil). Mode avion activé pour
  bloquer les mises à jour OTA.
- Écran : 6 pouces, 300 ppi → résolution 1072×1448 (portrait).

## Ce qui est fait
1. **Générateur du dashboard** : [generator/generate.py](generator/generate.py)
   - Récupère la météo via l'API Open-Meteo (gratuite, sans clé) pour
     Bouliac (lat 44.8193, lon -0.50265).
   - Récupère les 3 premiers articles de la dernière édition de TLDR AI
     (flux RSS `https://tldr.tech/api/rss/ai`, puis scraping de la page de
     l'édition pour le résumé de chaque article) + quelques titres récents
     de TechCrunch, The Verge, MIT Technology Review.
   - Compose une page HTML (polices Inter + Newsreader, en local dans
     `generator/fonts/`), la rend en PNG via Chrome headless
     (`--headless=new --screenshot`), puis la convertit en niveaux de gris
     avec Pillow.
   - Sortie : `site/dashboard.png` (1072×1448, 8 bits gris) + `site/dashboard.html`
     + `site/version.txt`.
   - Un script JS en fin de page retire les derniers blocs (actus, fil
     d'actu) si le contenu dépasse la hauteur de l'écran, pour que l'image
     ne soit jamais coupée.
2. **Automatisation cloud** : [.github/workflows/dashboard.yml](.github/workflows/dashboard.yml)
   - Tourne sur GitHub Actions, cron à 5h30/6h30, 10h30/11h30, 16h30/17h30
     UTC (couvre 7h/12h/18h Paris été comme hiver), + déclenchement manuel
     et à chaque push.
   - Publie `site/` sur la branche `gh-pages` du dépôt (GitHub Pages),
     avec `force_orphan: true` pour ne garder qu'un commit à chaque fois.
3. **Dépôt GitHub** : https://github.com/florentpit/kindle-dashboard
   - Public (nécessaire pour GitHub Pages gratuit).
   - `gh` est authentifié sur ce Mac (compte `florentpit`), `git push`
     fonctionne.
   - **Image publiée en continu à** :
     `https://florentpit.github.io/kindle-dashboard/dashboard.png`
   - Un premier run automatique (12h00) a réussi et produit une image
     identique à celle générée en local.
4. **Mise en page validée** pour l'écran 1072×1448 du Kindle 2024 (voir
   capture envoyée dans la conversation) : en-tête date/ville, météo du
   jour + heures suivantes + 5 prochains jours, section actus IA (TLDR),
   fil de titres, pied de page avec sources et heure de prochaine mise à
   jour.

## Ce qui reste à faire
1. **Jailbreak du Kindle** (nécessaire pour qu'il affiche une image
   personnalisée en écran de veille et se mette à jour seul).
   - Piste identifiée : outil **Shadow** (dépôt GitHub `KindleModding/Shadow`),
     jailbreak MTP qui couvre les firmwares 5.19.4 à 5.19.6, avec une entrée
     de base de données précise pour le build `4794270058` (celui du
     Kindle ci-dessus) sur un modèle « Kindle Basic 5 (2024) ».
   - Le site de référence communautaire est **kindlemodding.org** (rubrique
     « Jailbreaking »), qui liste plusieurs méthodes selon le firmware
     (Shadow, Véra, SpringBreak, AdBreak, Sanctuary, SpiderCat, Nosebleed).
     Un assistant interactif y aide à choisir la bonne méthode selon le
     modèle et le firmware exacts : https://kindlemodding.org/jailbreak-wizard.html
   - Ce site documente aussi les étapes suivantes une fois le jailbreak
     fait : désactiver les mises à jour auto, installer un gestionnaire de
     paquets (KPM), et éventuellement un accès SSH/réseau par Wi-Fi pour ne
     plus dépendre d'un câble.

2. **Identifier comment personnaliser l'écran de veille** une fois le
   jailbreak fait : kindlemodding.org mentionne la possibilité de changer
   les écrans de veille par défaut, mais le mécanisme précis (dossier,
   script, extension) n'a pas encore été confirmé pour ce firmware — à
   vérifier dans la documentation « What's Next » / post-jailbreak du site
   une fois le jailbreak réalisé.
3. **Scripter la récupération automatique** : une fois le Kindle
   jailbreaké et un accès shell/SSH disponible, écrire un script (sur le
   Kindle, programmé via `cron` ou équivalent une fois dispo) qui, à 7h/12h/18h :
   - se réveille,
   - vérifie le Wi-Fi,
   - télécharge `https://florentpit.github.io/kindle-dashboard/dashboard.png`,
   - le place comme image d'écran de veille,
   - se rendort.
4. **Tester sur l'appareil réel** et ajuster la mise en page si besoin
   (contraste, taille de police, cadrage) après un premier affichage réel.

## Décisions prises avec l'utilisateur
- Ville : **Bouliac (33270)**.
- Hébergement du générateur : **GitHub Actions + GitHub Pages** (gratuit),
  plutôt qu'un VPS personnel — ce dernier reste une option pour plus tard.
- Langue des actus : titres en anglais (sources américaines d'origine),
  pas de traduction pour l'instant.
- Le dashboard remplace uniquement l'image d'écran de veille, rien d'autre
  sur l'appareil.
- Objectif explicite : le Kindle doit fonctionner **seul**, dépendant
  uniquement du Wi-Fi, pas du Mac, une fois tout en place.

## Fichiers du projet
```
Kindle/
├── PROJET.md                     ce fichier
├── generator/
│   ├── generate.py               générateur du dashboard
│   └── fonts/                    Inter.ttf, Newsreader.ttf
├── site/                         sortie locale (ignorée par git)
│   ├── dashboard.html
│   ├── dashboard.png
│   └── version.txt
└── .github/workflows/
    └── dashboard.yml             automatisation GitHub Actions
```

## Pour reprendre ce travail
- Dépôt : https://github.com/florentpit/kindle-dashboard
- Image en ligne : https://florentpit.github.io/kindle-dashboard/dashboard.png
- Référence jailbreak : https://kindlemodding.org/jailbreaking/
- Dépôt de l'outil pressenti : https://github.com/KindleModding/Shadow
