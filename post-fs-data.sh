#!/system/bin/sh
# LMK Controller — post-fs-data
# Runs earlier in the boot process (before most system services).

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree

[ -f "$LMK_PATH" ] || exit 0
[ -f "$CONFIG_FILE" ] || exit 0

MODE=$(tr -d '[:space:]' < "$CONFIG_FILE")

case "$MODE" in
    gamer)
        echo "0,0,0,0,0,0" > "$LMK_PATH"
        ;;
    stable)
        echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH"
        ;;
    normal)
        echo "4096,5120,6144,7168,8192,9216" > "$LMK_PATH"
        ;;
esac