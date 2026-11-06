# Dashboard Kindle — installé et vérifié le 6 novembre 2026

## Résultat et préférences validées

Dashboard de veille autonome pour Bouliac (33270), avec **mise à jour à chaque
heure pleine, 24 h/24**, via Wi-Fi. Le Mac n'est pas nécessaire au fonctionnement.
Le Kindle conserve son interface de lecture habituelle.

Mise en page finale demandée par Florent :
- grandes polices, lisibilité confirmée sur l'appareil ;
- météo actuelle, quatre créneaux horaires et trois jours de prévisions ;
- titre compact « Actualité IA » ;
- **trois actualités sans numérotation**, dont deux sujets TLDR AI et une
  actualité récente de TechCrunch, The Verge ou MIT Technology Review ;
- pas de section « Le fil », pas de pied de page ni de mention Open-Meteo ;
- uniquement **l'heure de dernière mise à jour en haut**, sans heure prévue.

Les titres et résumés restent en anglais. Titres : 46 px natifs ; résumés :
36 px natifs. La météo et les grands caractères ont été validés par Florent.
La dernière composition à trois articles est téléchargée et affichée après reboot.

## Appareil

- Kindle Basic 5 / 11e génération, modèle 2024, sauge.
- Série G093L207548406G7 ; USB 1949:9981.
- Firmware 5.19.5, build 4794270058.
- Linux 4.9.77-lab126 ARMv7, écran 1072×1448, 8 bits gris.
- **Jailbreak réussi**, KMC v2.6.0, scriptlets fonctionnels.
- OTA bloquées : services otaupd, otav3 et ota-update arrêtés, exécutables
  désactivés par le jailbreak. Racine remontée en lecture seule.

## Hébergement et génération

Dépôt : https://github.com/florentpit/kindle-dashboard
Image : https://florentpit.github.io/kindle-dashboard/dashboard.png
HTML de diagnostic : https://florentpit.github.io/kindle-dashboard/dashboard.html

- Open-Meteo pour Bouliac (44.8193, -0.50265).
- TLDR AI + flux IA TechCrunch, The Verge et MIT Technology Review.
- Générateur Python, Pillow, Chrome headless ; polices locales Inter et Newsreader.
- GitHub Actions : **45 * * * *** en UTC, donc h45 à Paris aussi, pour préparer
  l'affichage à l'heure pleine suivante. GitHub Pages sert la branche gh-pages.
- Sorties : dashboard.png, dashboard.html, dashboard.sha256, version.txt,
  schedule.txt. L'heure affichée correspond à la génération du contenu.
- Les trois articles et les grandes polices sont conservés ; si des titres sont
  très longs, le résumé est raccourci pour empêcher tout débordement.

## Installation sur le Kindle

`/mnt/us/extensions/bouliac-dashboard/` :
- refresh.sh : HTTPS, SHA-256 et en-tête PNG vérifiés, remplacement atomique,
  dernier écran valide conservé en cas d'échec. Dessin uniquement en veille.
- update.sh : activation du Wi-Fi, attente d'une vraie connexion HTTPS avec
  jusqu'à 12 tentatives, puis téléchargement. Une reconnexion radio est tentée
  si nécessaire en veille. Le réglage Wi-Fi initial est restauré à la fin.
- service.sh : démarre l'écran de veille et le planificateur dans des sessions
  séparées, afin que leur nettoyage ne reçoive pas deux SIGTERM.
- kron : KindleCron v0.2.0, source 79e4b43dc2701852f991875873c72fbfb3314245,
  ARMv7 statique, compilation avec timetzdata. Licence et lien source à côté.
- kron-data/ : tâche, état persistant et journaux.

Tâche native : `0 * * * *`, durée maximale 3 minutes. Le planificateur utilise
UTC : les heures pleines UTC coïncident avec celles de Paris, y compris au
changement d'heure. Les libellés et dates du générateur utilisent Europe/Paris.

Écran de veille : chengandre/kindle-custom-screensaver v0.6.0, dans
`/mnt/us/extensions/custom-screensaver/`. Il écoute powerd, dessine le dashboard
et restaure le renderer Amazon à l'arrêt. Image dans
`/mnt/us/screensavers/bouliac-dashboard.png`.

Upstart : `/etc/upstart/bouliac-dashboard.conf`, démarrage sur framework_ready,
arrêt avec framework. Reprise après vrai reboot vérifiée.

## Vérifications réalisées

- Génération locale et GitHub Actions, publication Pages : réussies.
- Quatre tests Python : PNG valide, téléchargement tronqué, HTML d'erreur avec
  somme correcte, calendrier horaire aux changements d'heure (23/25 heures).
- Tests amont KindleCron réussis ; rtcWakeup et abortSuspend présents.
- Téléchargement HTTPS et validation de l'image exécutés sur le Kindle.
- Affichage en veille et grandes polices confirmés par Florent.
- Réveil RTC automatique observé dans les journaux.
- Test avec coupure et reconnexion du Wi-Fi : tâche rtc-cold-test terminée
  avec exit 0 à **18:50:50 Paris**, après attente de la connexion réseau.
- Mise à jour horaire réelle réussie à **19:00:32 Paris**.
- Arrêt/redémarrage du service : restauration du renderer stock et reprise vérifiées.
- Vrai reboot : nouvel identifiant de démarrage, service start/running,
  écran de veille READY et tâche horaire conservée, racine en lecture seule.
- Après reboot, dernier téléchargement réussi à **19:08:24 Paris**, puis
  dashboard redessiné en veille à 19:08:26.
- Le dispositif SSH temporaire de vérification du reboot et les tâches de test
  ont été retirés. Aucune dépendance de fonctionnement au Mac n'a été ajoutée.

## Maintenance et accès

Jobman 1.2.2 est installé. Adresse observée : 192.168.1.27, SSH port 22.
Authentification par clé ; mots de passe désactivés pour cet accès.

Depuis le Mac, après activation de Wi-Fi SSH dans Jobman :
`ssh -i .local/mac-key -o IdentitiesOnly=yes -o UserKnownHostsFile=.local/known_hosts root@192.168.1.27`

Les clés, journaux, paquets personnalisés et captures sont dans `.local/`,
ignoré par Git. Ne pas les publier. Le SSH n'est pas activé automatiquement
aux prochains démarrages ; l'activer via Jobman si une maintenance est nécessaire.

Commandes sur le Kindle :
- `initctl status bouliac-dashboard`
- `initctl stop bouliac-dashboard`
- `initctl start bouliac-dashboard`
- `TZ=UTC /mnt/us/extensions/bouliac-dashboard/kron -dir /mnt/us/extensions/bouliac-dashboard/kron-data list`

Journaux :
- `/mnt/us/extensions/bouliac-dashboard/kron-data/kron.log`
- `/mnt/us/extensions/bouliac-dashboard/kron-data/state/dashboard.log`
- `/mnt/us/extensions/bouliac-dashboard/last-success.txt`
- `/mnt/us/extensions/custom-screensaver/custom_ss.log`

**Arrêter le service avant de remplacer un binaire.** Écraser un exécutable
pendant son utilisation a provoqué un SIGBUS lors du déploiement ; le service
et le binaire ont été rétablis et revalidés. Préférer un fichier temporaire
puis un renommage pour remplacer les scripts.

Préparation :
- scripts/build-kron.sh : compilation du planificateur avec ses fuseaux.
- scripts/prepare-device.sh : paquet local, sans accès à l'appareil.
- kindle/setup.sh : Configurer Dashboard, pour la mise en place initiale.
- kindle/install-service.sh : tâche horaire et service Upstart.

## Historique jailbreak

Shadow officiel v1.0.2 plantait dans libusb 1.0.29 après reconnexion. Le build
natif libusb 1.0.30 nécessitait aussi une correction de fermeture du transport
Darwin et de l'énumération pendant l'attente du vrai débranchement.
Correction : patches/shadow-macos-usb.patch ; sources et reconstruction dans
scripts/build-shadow-macos.sh et scripts/jailbreak-local.sh.
**Ne plus relancer le jailbreak sur cet appareil déjà jailbreaké.**

Le contrôle UI refuse Terminal ; Florent avait lancé les commandes sudo du Mac
manuellement. Le contrôle SSH du Kindle n'a pas besoin de sudo.
Privilégier un redémarrage normal par le menu quand l'appareil répond.
