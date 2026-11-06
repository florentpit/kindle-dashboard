#!/bin/sh
# Planificateur RTC natif, avec les fuseaux horaires intégrés pour Europe/Paris.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC="$ROOT/.local/kindle-cron-source"
REV=79e4b43dc2701852f991875873c72fbfb3314245
mkdir -p "$ROOT/.local"
if [ ! -d "$SRC" ]; then
    git clone --no-checkout https://github.com/lennardollesch/KindleCron.git "$SRC"
fi
[ -z "$(git -C "$SRC" status --porcelain)" ] || {
    echo 'La source KindleCron contient des modifications ; les conserver avant de reconstruire.' >&2
    exit 1
}
git -C "$SRC" checkout --detach "$REV"
cd "$SRC/kron"
go test -tags timetzdata ./...
GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -tags timetzdata \
    -trimpath -ldflags='-s -w -X main.Version=v0.2.0-paris-tzdata' \
    -o "$ROOT/.local/kron-paris" .
cp "$SRC/LICENSE" "$ROOT/.local/LICENSE-KindleCron"
printf '%s\n' "KindleCron v0.2.0 — $REV" \
    'Source: https://github.com/lennardollesch/KindleCron/tree/v0.2.0' \
    'Build: GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=0 go build -tags timetzdata' \
    'Licence: AGPL-3.0-or-later, voir LICENSE-KindleCron' \
    > "$ROOT/.local/KindleCron-NOTICE.txt"
