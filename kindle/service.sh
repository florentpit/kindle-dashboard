#!/bin/sh
# Démarre l'écran de veille et le planificateur natif RTC.
set -eu
BASE=/mnt/us/extensions/bouliac-dashboard
SS=/mnt/us/extensions/custom-screensaver
# Chaque heure UTC est aussi une heure pleine à Paris, y compris lors des
# changements d'heure. Les libellés français sont calculés par le générateur.
export TZ=UTC
export PATH=/var/local/kmc/bin:/usr/sbin:/usr/bin:/sbin:/bin
SS_PID=''
KRON_PID=''
WAIT_PID=''
cleanup() {
    trap - EXIT HUP INT TERM
    [ -z "$WAIT_PID" ] || kill "$WAIT_PID" 2>/dev/null || true
    [ -z "$KRON_PID" ] || kill "$KRON_PID" 2>/dev/null || true
    [ -z "$SS_PID" ] || kill "$SS_PID" 2>/dev/null || true
    wait || true
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM
echo sequential > /tmp/custom_ss_mode
if [ -f /tmp/custom_ss_daemon.pid ] && kill -0 "$(cat /tmp/custom_ss_daemon.pid)" 2>/dev/null; then
    echo 'Écran de veille personnalisé déjà actif'
else
    # Sessions séparées : Upstart signale le groupe du service. Sans cela,
    # les enfants recevraient un second SIGTERM pendant leur nettoyage.
    setsid sh "$SS/custom_ss_daemon.sh" >> "$BASE/screensaver.log" 2>&1 &
    SS_PID=$!
fi
setsid "$BASE/kron" -dir "$BASE/kron-data" -logmax 256 daemon >> "$BASE/scheduler.log" 2>&1 &
KRON_PID=$!
while kill -0 "$KRON_PID" 2>/dev/null; do
    if [ -n "$SS_PID" ] && ! kill -0 "$SS_PID" 2>/dev/null; then
        echo 'Le service écran de veille s’est arrêté' >&2
        exit 1
    fi
    # Un wait intégré au shell est interrompu immédiatement par SIGTERM.
    # Un sleep au premier plan retarderait le nettoyage jusqu'à son terme.
    sleep 30 &
    WAIT_PID=$!
    wait "$WAIT_PID" || true
    WAIT_PID=''
done
exit 1
