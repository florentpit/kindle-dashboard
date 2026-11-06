#!/bin/sh
# Téléchargement atomique : une panne réseau laisse le dernier écran intact.
set -eu
BASE=${DASHBOARD_HOME:-/mnt/us/extensions/bouliac-dashboard}
URL=${DASHBOARD_URL:-https://florentpit.github.io/kindle-dashboard}
IMAGES=${DASHBOARD_IMAGES:-/mnt/us/screensavers}
mkdir -p "$BASE" "$IMAGES"
WORK=$(mktemp -d "$BASE/.download.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
trap 'exit 1' HUP INT TERM

download() {
    curl --fail --silent --show-error --location --proto '=https' \
        --connect-timeout 10 --max-time 30 --retry 1 \
        "$URL/$1?ts=$(date +%s)" -o "$WORK/$1"
}

download dashboard.sha256
download dashboard.png
EXPECTED=$(awk 'NR == 1 {print $1}' "$WORK/dashboard.sha256")
[ "${#EXPECTED}" -eq 64 ]
case "$EXPECTED" in *[!0-9a-f]*) exit 1 ;; esac
ACTUAL=$(sha256sum "$WORK/dashboard.png" | awk '{print $1}')
[ "$EXPECTED" = "$ACTUAL" ]
# PNG, IHDR, 1072 x 1448. Refuse notamment une page HTML d'erreur HTTP 200.
HEADER=$(od -An -tx1 -N24 "$WORK/dashboard.png" | tr -d ' \n')
[ "$HEADER" = '89504e470d0a1a0a0000000d4948445200000430000005a8' ]

if download schedule.txt && awk '
    length($0) != 10 || $0 ~ /[^0-9]/ || (NR > 1 && $0 <= prev) {bad=1}
    {prev=$0} END {exit (bad || NR < 3 || NR > 60)}
' "$WORK/schedule.txt"; then
    mv "$WORK/schedule.txt" "$BASE/schedule.txt"
fi
mv "$WORK/dashboard.png" "$IMAGES/bouliac-dashboard.png"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$BASE/last-success.txt"

# Ne dessine jamais par-dessus un livre ou les menus.
case "$(lipc-get-prop com.lab126.powerd state 2>/dev/null || true)" in
    screenSaver|readyToSuspend|suspended)
        if [ -f /tmp/custom_ss_shield.pid ]; then
            /mnt/us/extensions/custom-screensaver/bin/screensaver_draw \
                "$IMAGES/bouliac-dashboard.png"
        fi
        ;;
esac
