# Dashboard Kindle — reprise du 6 novembre 2026

## Objectif et préférences actuelles

Dashboard de veille pour Bouliac (33270) : météo, prévisions et actualités IA
américaines (TLDR AI, TechCrunch, The Verge, MIT Technology Review).
**Florent a remplacé les trois mises à jour quotidiennes par une mise à jour
à chaque heure pleine, 24 h/24.** Il demande aussi des polices beaucoup plus
grandes : la nouvelle maquette est générée et publiée côté code, à afficher
sur l'appareil pour validation. Les titres restent en anglais.

Le Kindle doit être autonome sur le Wi-Fi et conserver son usage normal de
lecture. Pas de dépendance au Mac après installation.

## Appareil et accès

- Kindle Basic 5 / 11e génération, modèle 2024, sauge.
- Série : G093L207548406G7 ; USB 1949:9981.
- Firmware confirmé : 5.19.5, build 4794270058.
- Linux 4.9.77-lab126, ARMv7, écran 1072×1448, 8 bits gris.
- **Jailbreak réussi**, environnement KMC v2.6.0. Les scriptlets fonctionnent.
- OTA vérifié : otaupd, otav3 et ota-update arrêtés ; exécutables de mise à
  jour désactivés par le jailbreak. Racine remontée en lecture seule.
- Jobman 1.2.2 installé. Florent a activé Wi-Fi SSH dans Jobman.
- Adresse communiquée : **192.168.1.27**, port **22**.
- Accès testé par clé (pas par mot de passe) :
  `ssh -i .local/mac-key -o IdentitiesOnly=yes -o UserKnownHostsFile=.local/known_hosts root@192.168.1.27`
- Les clés, journaux et captures sont dans `.local/`, ignoré par Git.
  Ne jamais ajouter la clé privée ou les paquets personnalisés au dépôt public.
- Le serveur SSH lancé par Jobman n'est pas installé au démarrage. Après un
  redémarrage, rouvrir Jobman et activer Wi-Fi SSH si un accès est nécessaire.

## Hébergement et génération

Dépôt : https://github.com/florentpit/kindle-dashboard
Image : https://florentpit.github.io/kindle-dashboard/dashboard.png

- Open-Meteo pour Bouliac (44.8193, -0.50265).
- Générateur Pillow + Chrome headless ; polices locales Inter et Newsreader.
- PNG natif 1072×1448 en niveaux de gris, `dashboard.sha256`, `version.txt`
  et `schedule.txt` (14 jours d'instants UTC).
- GitHub Actions : génération horaire à **h45**, fuseau Europe/Paris, pour
  l'affichage à l'heure pleine suivante. Publication sur gh-pages / Pages.
- Nouvelle maquette : résumés 36 px au lieu de 21, titres 46 px au lieu de 29,
  quatre créneaux météo, trois jours de prévisions, deux sujets TLDR et un fil
  complémentaire. Contenu réduit si nécessaire, sans réduire les polices.
- Dernier commit de mise en page poussé : **05e30eb**. Les tests/génération
  GitHub et le déploiement Pages ont réussi. Le HTML publié a été vérifié :
  résumés à 18 px CSS (36 px natifs), titres à 23 px CSS (46 px natifs).

## Logiciels installés sur le Kindle

`/mnt/us/extensions/bouliac-dashboard/` :

- `refresh.sh` : téléchargement HTTPS, vérification SHA-256 et en-tête PNG,
  remplacement atomique, conservation du dernier écran valide en cas d'échec.
  Ne dessine que si l'appareil est en veille et que le shield est actif.
- `update.sh` : lance le téléchargement et gère l'activation du Wi-Fi.
- `service.sh` : lance l'écran de veille et le planificateur RTC.
- `kron` : KindleCron v0.2.0, source 79e4b43dc2701852f991875873c72fbfb3314245,
  ARMv7 statique avec `-tags timetzdata`. La dernière version du service
  utilise UTC pour le cron horaire : les heures pleines UTC coïncident
  toujours avec celles de Paris, sans ambiguïté au changement d’heure.
  Cette version du service n’est pas encore transférée sur le Kindle. Licence et source indiquées à côté du binaire.
- `kron-data/` : tâches, état persistant et journaux du planificateur.

Écran de veille : chengandre/kindle-custom-screensaver v0.6.0, dans
`/mnt/us/extensions/custom-screensaver/`. Écoute les événements powerd,
masque le renderer Amazon en veille et le restaure à l'arrêt.
Image : `/mnt/us/screensavers/bouliac-dashboard.png`.

Service Upstart installé : `/etc/upstart/bouliac-dashboard.conf`, démarrage
sur `framework_ready`. Il est **start/running**, mais sa reprise après un vrai
redémarrage reste à tester.

## État exact des vérifications et prochaine action

- Téléchargement réel depuis le Kindle : réussi, SHA-256 et PNG valides.
- Premier affichage en veille : confirmé correct par Florent, mais il juge
  ensuite les polices beaucoup trop petites. La nouvelle version agrandie
  doit maintenant remplacer cette image sur l'appareil.
- Les quatre tests Python passent (cache protégé contre téléchargement
  tronqué/HTML, PNG valide, calendrier horaire DST de 23/25 heures).
- Les tests amont KindleCron passent. Présence de rtcWakeup et abortSuspend
  confirmée sur cet appareil.
- Test RTC ponctuel nommé `rtc-test`, à **17:19:48 Europe/Paris**, exécutant
  update.sh. L'appareil a été mis en veille via powerButton et laissé sans
  connexion de contrôle jusqu'à cette heure.
- **Résultat RTC pas encore vérifié** : après l'heure du test, SSH et ping ne
  répondent plus. Il faut lire les journaux pour distinguer réveil RTC et
  réactivation réseau. Ne pas prétendre que l'autonomie en veille est validée.
- Florent a reçu cette dernière consigne : réveiller le Kindle puis vérifier
  dans Jobman que Wi-Fi SSH est activé ; communiquer la nouvelle IP si elle
  a changé. En attente de sa réponse. 192.168.1.27 ne répond toujours pas.
- Récupérer ensuite :
  `/mnt/us/extensions/bouliac-dashboard/kron-data/kron.log`,
  `kron-data/state/rtc-test.log`, `last-success.txt`, le statut powerd.
- Le planning actuellement installé sur le Kindle est encore **7/12/18** :
  le remplacer après ce test par `0 * * * *` ; la modification horaire est
  déjà faite côté cloud et dans `kindle/install-service.sh`.
- Mettre à jour le client refresh.sh (limite du calendrier relevée à 400 lignes),
  installer l'image aux grandes polices et les derniers scripts corrigés.
- Tester ensuite le réveil horaire réel, puis le démarrage après reboot.

## Scripts de préparation

- `scripts/build-kron.sh` : reconstruit le planificateur avec les fuseaux intégrés.
- `scripts/prepare-device.sh` : compose un paquet local, sans toucher à l'appareil.
- `kindle/setup.sh` : scriptlet Configurer Dashboard ; corrigé pour ne pas
  réinstaller Jobman quand il est déjà présent. La version encore sur l'appareil
  essaie de le réinstaller et peut échouer au deuxième lancement.
- `kindle/install-service.sh` : installe la tâche horaire et le service Upstart.

## Historique USB utile

Shadow officiel v1.0.2 plantait dans libusb 1.0.29 après reconnexion. Un build
natif libusb 1.0.30 ne plantait plus mais perdait encore le périphérique.
`patches/shadow-macos-usb.patch` corrige la fermeture du transport Darwin et
l'énumération pendant l'attente du rebranchement. L'essai corrigé a atteint
Address leak collected puis Payload delivered, suivi du jailbreak confirmé.
Sources et reconstruction : scripts/build-shadow-macos.sh, scripts/jailbreak-local.sh.
**Ne plus relancer le jailbreak sur cet appareil déjà jailbreaké.**

L'outil de contrôle UI refuse Terminal ; les commandes sudo du Mac ont été
lancées manuellement par Florent. Le contrôle SSH du Kindle fonctionne sans sudo.
Un redémarrage normal par le menu suffit quand l'appareil répond ; ne pas
répéter inutilement la consigne générique de maintien 40 secondes.
