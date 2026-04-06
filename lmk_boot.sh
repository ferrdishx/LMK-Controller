#!/system/bin/sh

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree
LOGFILE="$MODDIR/boot.log"
PROP_FILE="$MODDIR/system.prop"

echo "--- Boot $(date) ---" > "$LOGFILE"

[ -f "$CONFIG_FILE" ] || { echo "no config file" >> "$LOGFILE"; exit 0; }

i=0
while [ "$i" -lt 30 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && break
    sleep 2
    i=$((i + 1))
done
sleep 5

MODE=$(tr -d '[:space:]' < "$CONFIG_FILE")
echo "mode: $MODE" >> "$LOGFILE"

if [ -f "$LMK_PATH" ]; then
    echo "type: classic" >> "$LOGFILE"
    case "$MODE" in
        gamer)  echo "0,0,0,0,0,0"                    > "$LMK_PATH" ;;
        stable) echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH" ;;
        normal) echo "4096,5120,6144,7168,8192,9216"   > "$LMK_PATH" ;;
    esac
    echo "minfree: $(cat $LMK_PATH)" >> "$LOGFILE"
else
    echo "type: lmkd" >> "$LOGFILE"

    case "$MODE" in
        gamer)
            cat > "$PROP_FILE" << 'PROPS'
ro.lmk.low=0
ro.lmk.medium=100
ro.lmk.critical=0
ro.lmk.kill_heaviest_task=true
ro.lmk.thrashing_limit=30
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
        stable)
            cat > "$PROP_FILE" << 'PROPS'
ro.lmk.low=1001
ro.lmk.medium=900
ro.lmk.critical=800
ro.lmk.kill_heaviest_task=false
ro.lmk.thrashing_limit=100
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
        normal)
            cat > "$PROP_FILE" << 'PROPS'
ro.lmk.low=1001
ro.lmk.medium=800
ro.lmk.critical=0
ro.lmk.kill_heaviest_task=true
ro.lmk.thrashing_limit=30
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
    esac

    magisk resetprop --file "$PROP_FILE"
    echo "props applied via resetprop --file" >> "$LOGFILE"

    if ! kill -HUP "$(pidof lmkd)" 2>/dev/null; then
        echo "HUP failed, restarting lmkd" >> "$LOGFILE"
        stop lmkd
        sleep 1
        start lmkd
    fi

    echo "lmkd props: low=$(getprop ro.lmk.low) medium=$(getprop ro.lmk.medium) critical=$(getprop ro.lmk.critical)" >> "$LOGFILE"
fi

echo "done" >> "$LOGFILE"