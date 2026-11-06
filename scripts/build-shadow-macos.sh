#!/bin/sh
# Compilation reproductible du client officiel avec correction du transport Mac.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REV=8019ed3f59a1176bf287291cd0bdaf18a177decb
SRC="$ROOT/.local/shadow/source"
command -v go >/dev/null
command -v pkg-config >/dev/null
pkg-config --atleast-version=1.0.30 libusb-1.0
mkdir -p "$ROOT/.local/shadow"
if [ ! -d "$SRC" ]; then
    git clone --no-checkout https://github.com/KindleModding/Shadow.git "$SRC"
fi
cd "$SRC"
[ -z "$(git status --porcelain)" ] || {
    echo 'La source contient déjà des modifications ; conserver ce dossier avant de reconstruire.' >&2
    exit 1
}
git checkout --detach "$REV"
git apply "$ROOT/patches/shadow-macos-usb.patch"
go test ./cmd/shadow ./internal/usbdev ./internal/mtp ./internal/chain
go build -o "$ROOT/.local/shadow/shadow-native-fixed" ./cmd/shadow
