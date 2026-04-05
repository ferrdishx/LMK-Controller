#!/system/bin/sh
# Installed automatically by the module to /data/adb/service.d/ xd

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree
LOGFILE="$MODDIR/boot.log"

echo "--- Boot $(date) ---" > "$LOGFILE"

[ -f "$LMK_PATH" ]    || { echo "LMK path not found" >> "$LOGFILE"; exit 0; }
[ -f "$CONFIG_FILE" ] || { echo "No config file"     >> "$LOGFILE"; exit 0; }

# Wait for Android to finish setting its own LMK values
i=0
while [ "$i" -lt 30 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && break
    sleep 2
    i=$((i + 1))
done
sleep 5

echo "Boot completed, applying..." >> "$LOGFILE"

MODE=$(tr -d '[:space:]' < "$CONFIG_FILE")
echo "Mode: $MODE" >> "$LOGFILE"

case "$MODE" in
    gamer)  echo "0,0,0,0,0,0"                    > "$LMK_PATH" ;;
    stable) echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH" ;;
    normal) echo "4096,5120,6144,7168,8192,9216"   > "$LMK_PATH" ;;
esac

echo "Done: $(cat $LMK_PATH)" >> "$LOGFILE"
