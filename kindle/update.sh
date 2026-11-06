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
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Début de mise à jour"
# Le réglage wirelessEnable peut rester à 1 pendant que le pilote et le DNS
# dorment. Réaffirmer le réglage et attendre une vraie connexion HTTPS.
lipc-set-prop com.lab126.cmd wirelessEnable 1
READY=0
for ATTEMPT in 1 2 3 4 5 6 7 8; do
    if curl --fail --silent --show-error --location --proto '=https' \
        --connect-timeout 3 --max-time 5 \
        https://florentpit.github.io/kindle-dashboard/version.txt -o /dev/null; then
        READY=1
        break
    fi
    if [ "$ATTEMPT" = 4 ]; then
        case "$(lipc-get-prop com.lab126.powerd state 2>/dev/null || true)" in
            screenSaver|readyToSuspend|suspended)
                lipc-set-prop com.lab126.cmd wirelessEnable 0
                sleep 2
                lipc-set-prop com.lab126.cmd wirelessEnable 1
                ;;
        esac
    fi
    sleep 5
done
[ "$READY" = 1 ] || { echo 'Réseau indisponible ; écran précédent conservé.'; exit 1; }
sh "$BASE/refresh.sh"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Mise à jour terminée"
