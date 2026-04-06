#!/system/bin/sh
# LMK Controller post-fs-data entrypoint.
# Optional early apply path: runs before full boot and is safe for legacy LMK writes.

MODDIR=${0%/*}
BOOT_SCRIPT="$MODDIR/lmk_boot.sh"
LOGFILE=/data/local/tmp/lmk_controller.log

if [ -x "$BOOT_SCRIPT" ]; then
    "$BOOT_SCRIPT" --post-fs-data
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [lmk_controller] ERROR: missing $BOOT_SCRIPT" >> "$LOGFILE"
fi
