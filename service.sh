#!/system/bin/sh
# LMK Controller service entrypoint.
# Magisk runs this on every boot; delegate to lmk_boot.sh for profile handling.

MODDIR=${0%/*}
BOOT_SCRIPT="$MODDIR/lmk_boot.sh"
LOGFILE=/data/local/tmp/lmk_controller.log

if [ -x "$BOOT_SCRIPT" ]; then
    sleep 5
    "$BOOT_SCRIPT" service
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [lmk_controller] ERROR: missing $BOOT_SCRIPT" >> "$LOGFILE"
fi
