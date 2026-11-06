#!/bin/sh
# Name: Configurer Dashboard
# DontUseFBInk
# Installation locale et accès temporaire par clé, pour configurer le dashboard.
set -eu
LOG=/mnt/us/dashboard-setup.log
exec >> "$LOG" 2>&1
date
[ -f /var/local/kmc/version ] || { echo 'Jailbreak non confirmé'; exit 1; }
tar -xzf /mnt/us/bouliac-dashboard.tar.gz -C /mnt/us
BASE=/mnt/us/extensions/bouliac-dashboard
FBINK=/mnt/us/extensions/custom-screensaver/bin/fbink_hf
chmod +x "$FBINK"
message() { "$FBINK" -p -m -M -S 4 -w "$1" || true; }
trap 'message "Installation interrompue.
Voir dashboard-setup.log"' HUP INT TERM
message 'Configuration du dashboard...'
sh /mnt/us/documents/Diagnostic\ Dashboard.sh
KPM=/var/local/kmc/bin/kpm
[ -x "$KPM" ] || KPM=$(command -v kpm)
DROPBEAR=/mnt/us/jobman/bin/dropbearmulti
if [ ! -f "$DROPBEAR" ]; then
    "$KPM" -y install "file://$BASE/jobman.kpkg"
fi
[ -f "$DROPBEAR" ]
chmod +x "$DROPBEAR"
AUTH=/mnt/us/jobman/ssh/etc/dropbear/authorized_keys
mkdir -p "$(dirname "$AUTH")"
touch "$AUTH"
KEY=$(cat "$BASE/mac.pub")
grep -Fqx "$KEY" "$AUTH" || printf '%s\n' "$KEY" >> "$AUTH"
sed -i 's/^ALLOW_PASSWORD_LOGIN *=.*/ALLOW_PASSWORD_LOGIN = false/' \
    /mnt/us/jobman/ssh/etc/config.toml
# Ne pas démarrer le serveur tant que le Wi-Fi n'a pas une adresse IPv4.
IP=$(ip -4 -o addr show wlan0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
if [ -z "$IP" ]; then
    IP=$(ifconfig wlan0 | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p')
fi
if [ -z "$IP" ]; then
    message 'Active le Wi-Fi puis relance Configurer Dashboard.'
    exit 1
fi
case "$IP" in *[!0-9.]*|'') exit 1 ;; esac
iptables -C INPUT -i wlan0 -p tcp --dport 2222 -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i wlan0 -p tcp --dport 2222 -j ACCEPT
if [ ! -f /tmp/bouliac-ssh.pid ] || ! kill -0 "$(cat /tmp/bouliac-ssh.pid)" 2>/dev/null; then
    # -s : aucune connexion par mot de passe. -p : écoute sur le Wi-Fi uniquement.
    "$DROPBEAR" dropbear -R -s -H/mnt/us -p"$IP:2222" -P /tmp/bouliac-ssh.pid
fi
printf '%s\n' "$IP" > "$BASE/ip.txt"
if [ -x "$BASE/kron" ] && ! initctl status bouliac-dashboard 2>/dev/null | grep -q start/running; then
    sh "$BASE/install-service.sh"
fi
message "Dashboard prêt pour configuration
Adresse : $IP
Port : 2222"
echo 'Configuration terminée'
