# Dashboard Kindle — état du projet (6 novembre 2026)

## Objectif
Afficher sur l'écran de veille d'un Kindle un dashboard avec la météo de
Bouliac (33270) et les dernières actus IA (TLDR AI + TechCrunch/The Verge/MIT
Tech Review), mis à jour 3×/jour (7h, 12h, 18h, heure de Paris), sans dépendre
du Mac une fois en place.

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
   - **Point de vigilance** : toute manipulation de ce type modifie le
     logiciel interne de l'appareil en dehors du cadre prévu par Amazon et
     peut annuler la garantie ou rendre l'appareil instable si une étape
     est mal suivie. Mieux vaut suivre pas à pas la documentation officielle
     de la méthode retenue (README du dépôt GitHub correspondant) plutôt
     qu'une reconstruction a posteriori.
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
