#!/bin/sh
# À exécuter sur le Mac avec sudo, après confirmation du build sur l'appareil.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN="$ROOT/.local/shadow/shadow-native-fixed"
[ "$(id -u)" -eq 0 ] || { echo 'Lancer ce script avec sudo.' >&2; exit 1; }
[ -x "$BIN" ] || { echo 'Binaire Shadow natif absent.' >&2; exit 1; }
killall ptpcamerad 2>/dev/null || true
printf '4794270058\n' | "$BIN" --debug > "$ROOT/.local/shadow/install-native.log" 2>&1
