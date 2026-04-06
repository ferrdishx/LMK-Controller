#!/system/bin/sh
# LMK Controller — Boot Service

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree
LOGFILE="$MODDIR/boot.log"

log() { echo "$(date '+%H:%M:%S') $1" >> "$LOGFILE"; }

echo "--- Boot $(date) ---" > "$LOGFILE"
log "service.sh started"

# Wait for boot — timeout after 60s to avoid hanging forever
i=0
while [ "$i" -lt 30 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && break
    sleep 2
    i=$((i + 1))
done
log "Boot wait done (sys.boot_completed=$(getprop sys.boot_completed))"
sleep 2

# Classic LMK node not present
if [ ! -f "$LMK_PATH" ]; then
    log "ERROR: $LMK_PATH not found."
    exit 0
fi

# Read saved mode
MODE="stable"
if [ -f "$CONFIG_FILE" ]; then
    SAVED=$(tr -d '[:space:]' < "$CONFIG_FILE")
    log "Config found: '$SAVED'"
    case "$SAVED" in
        gamer|stable|normal) MODE="$SAVED" ;;
        *) log "Unknown mode, using stable." ;;
    esac
else
    log "No config file, using stable."
fi

log "Applying mode: $MODE"

case "$MODE" in
    gamer)
        echo "0,0,0,0,0,0" > "$LMK_PATH"
        setprop sys.lmk.minfree_levels "0:0,0:0,0:0,0:0,0:0,0:0"
        ;;
    stable)
        echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH"
        setprop ro.lmk.low 1001
        setprop sys.lmk.minfree_levels "1024:0,2048:100,4096:200,8192:250,12288:900,16384:950"
        ;;
    normal)
        echo "4096,5120,6144,7168,8192,9216" > "$LMK_PATH"
        ;;
esac

log "Done. minfree now: $(cat $LMK_PATH 2>/dev/null)"