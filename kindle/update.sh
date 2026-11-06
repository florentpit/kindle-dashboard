#!/bin/sh
# Une exécution planifiée ; le gestionnaire RTC maintient l'appareil éveillé.
set -eu
BASE=/mnt/us/extensions/bouliac-dashboard
ORIGINAL_WIFI=$(lipc-get-prop com.lab126.cmd wirelessEnable 2>/dev/null || echo 1)
cleanup() {
    if [ "$ORIGINAL_WIFI" = 0 ]; then
        lipc-set-prop com.lab126.cmd wirelessEnable 0 || true
    fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
if [ "$ORIGINAL_WIFI" = 0 ]; then
    lipc-set-prop com.lab126.cmd wirelessEnable 1
    sleep 5
fi
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Début de mise à jour"
sh "$BASE/refresh.sh"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Mise à jour terminée"
