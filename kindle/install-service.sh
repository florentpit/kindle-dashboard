#!/bin/sh
set -eu
BASE=/mnt/us/extensions/bouliac-dashboard
export TZ=Europe/Paris
chmod +x "$BASE/kron"
"$BASE/kron" -dir "$BASE/kron-data" add -timeout 3m dashboard \
    '0 * * * *' /bin/sh "$BASE/update.sh"
mntroot rw
trap 'mntroot ro >/dev/null 2>&1 || true' EXIT HUP INT TERM
cp "$BASE/bouliac-dashboard.conf" /etc/upstart/bouliac-dashboard.conf
chmod 644 /etc/upstart/bouliac-dashboard.conf
mntroot ro
trap - EXIT HUP INT TERM
initctl reload-configuration
initctl start bouliac-dashboard
"$BASE/kron" -dir "$BASE/kron-data" list
