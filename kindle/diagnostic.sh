#!/bin/sh
# Name: Diagnostic Dashboard
# DontUseFBInk
OUT=/mnt/us/dashboard-diagnostic.txt
exec > "$OUT" 2>&1
date
uname -a
cat /etc/prettyversion.txt 2>/dev/null
df -h /mnt/us /var/local
command -v curl sha256sum lipc-wait-event lipc-get-prop lipc-set-prop
lipc-get-prop com.lab126.powerd state
lipc-get-prop com.lab126.cmd wirelessEnable
lipc-probe -a | awk '
    /^com[.]lab126[.]powerd$/ {p=1; print; next}
    p && /^[^ \t]/ {exit}
    p {print}
'
ip address show 2>/dev/null || ifconfig
ls -ld /etc/upstart /var/local/kmc /mnt/us/extensions
ls /var/local/kmc/bin
