#!/bin/sh
# Démarre l'écran de veille et le planificateur natif RTC.
set -eu
BASE=/mnt/us/extensions/bouliac-dashboard
SS=/mnt/us/extensions/custom-screensaver
export TZ=Europe/Paris
export PATH=/var/local/kmc/bin:/usr/sbin:/usr/bin:/sbin:/bin
SS_PID=''
KRON_PID=''
cleanup() {
    trap - EXIT HUP INT TERM
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
    sh "$SS/custom_ss_daemon.sh" >> "$BASE/screensaver.log" 2>&1 &
    SS_PID=$!
fi
"$BASE/kron" -dir "$BASE/kron-data" -logmax 256 daemon >> "$BASE/scheduler.log" 2>&1 &
KRON_PID=$!
while kill -0 "$KRON_PID" 2>/dev/null; do
    if [ -n "$SS_PID" ] && ! kill -0 "$SS_PID" 2>/dev/null; then
        echo 'Le service écran de veille s’est arrêté' >&2
        exit 1
    fi
    sleep 30
done
exit 1
