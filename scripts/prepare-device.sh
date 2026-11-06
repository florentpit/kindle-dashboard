#!/bin/sh
# Prépare le paquet local sans toucher au Kindle.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STAGE="$ROOT/.local/device"
ARCHIVE="$ROOT/.local/custom-screensaver-0.6.0-kindlehf.zip"
mkdir -p "$ROOT/.local" "$STAGE"
if [ ! -f "$ARCHIVE" ]; then
    gh release download v0.6.0 --repo chengandre/kindle-custom-screensaver \
        --pattern '*kindlehf.zip' --dir "$ROOT/.local"
fi
printf '%s  %s\n' \
    3ddd187cec61ba5d128d961fd4fabce5a54b8d852f10dd3eb4e538f970379224 \
    "$ARCHIVE" | shasum -a 256 -c -
unzip -oq "$ARCHIVE" -d "$STAGE"
mkdir -p "$STAGE/extensions/bouliac-dashboard"
for SCRIPT in refresh.sh update.sh service.sh install-service.sh bouliac-dashboard.conf; do
    cp "$ROOT/kindle/$SCRIPT" "$STAGE/extensions/bouliac-dashboard/"
done
if [ -f "$ROOT/.local/kron-paris" ]; then
    cp "$ROOT/.local/kron-paris" "$STAGE/extensions/bouliac-dashboard/kron"
    cp "$ROOT/.local/LICENSE-KindleCron" "$ROOT/.local/KindleCron-NOTICE.txt" \
        "$STAGE/extensions/bouliac-dashboard/"
fi
cp "$ROOT/kindle/diagnostic.sh" "$STAGE/documents/Diagnostic Dashboard.sh"
cp "$ROOT/site/dashboard.png" "$STAGE/screensavers/bouliac-dashboard.png"
cp "$ROOT/site/schedule.txt" "$STAGE/extensions/bouliac-dashboard/"
if [ -f "$ROOT/.local/mac-key.pub" ] && [ -f "$ROOT/.local/jobman.kpkg" ]; then
    cp "$ROOT/.local/mac-key.pub" "$STAGE/extensions/bouliac-dashboard/mac.pub"
    cp "$ROOT/.local/jobman.kpkg" "$STAGE/extensions/bouliac-dashboard/jobman.kpkg"
    cp "$ROOT/kindle/setup.sh" "$STAGE/documents/Configurer Dashboard.sh"
    COPYFILE_DISABLE=1 tar -czf "$ROOT/.local/bouliac-dashboard.tar.gz" -C "$STAGE" \
        documents extensions screensavers
fi
printf 'Paquet prêt : %s\n' "$STAGE"
