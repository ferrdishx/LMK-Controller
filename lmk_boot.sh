#!/system/bin/sh

MODDIR=${0%/*}
if [ ! -f "$MODDIR/lmk_mode" ] && [ -f /data/adb/modules/lmk_controller_feerd/lmk_mode ]; then
    # Fallback for legacy installs that execute this script from /data/adb/service.d.
    MODDIR=/data/adb/modules/lmk_controller_feerd
fi
CONFIG_FILE="$MODDIR/lmk_mode"
PROP_FILE="$MODDIR/system.prop"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree
LOGFILE=/data/local/tmp/lmk_controller.log

log_applied() {
    echo "[$(date '+%H:%M:%S')] Mode=$1 Profile=$2 $3" >> "$LOGFILE"
}

normalize_mode() {
    case "$1" in
        gamer|performance) echo "gamer" ;;
        extreme) echo "extreme" ;;
        normal|balanced) echo "normal" ;;
        stable|stability) echo "stable" ;;
        *) echo "stable" ;;
    esac
}

profile_name() {
    case "$1" in
        gamer) echo "Performance" ;;
        extreme) echo "EXTREME" ;;
        normal) echo "Balanced" ;;
        stable) echo "Stability" ;;
        *) echo "Stability" ;;
    esac
}

detect_memory_manager() {
    # Requested behavior:
    # - /system/bin/lmkd exists => LMKD
    # - otherwise => legacy LMK
    if [ -f /system/bin/lmkd ]; then
        echo "LMKD"
    else
        echo "LMK"
    fi
}

apply_lmk_profile() {
    mode="$1"

    if [ ! -f "$LMK_PATH" ]; then
        return 1
    fi

    if [ "$mode" = "extreme" ]; then
        # EXTREME is LMKD-only by design; LMK falls back to performance behavior.
        mode="gamer"
    fi

    case "$mode" in
        gamer)  echo "0,0,0,0,0,0" > "$LMK_PATH" ;;
        stable) echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH" ;;
        normal) echo "4096,5120,6144,7168,8192,9216" > "$LMK_PATH" ;;
    esac

    return 0
}

write_lmkd_props() {
    mode="$1"

    # LMKD is PSI/pressure-driven and reacts differently than legacy LMK.
    # We use safer values than direct LMK minfree translation.
    case "$mode" in
        gamer)
            cat > "$PROP_FILE" <<'PROPS'
ro.lmk.low=970
ro.lmk.medium=920
ro.lmk.critical=860
ro.lmk.kill_heaviest_task=true
ro.lmk.thrashing_limit=45
ro.lmk.thrashing_limit_decay=55
ro.lmk.swap_util_max=95
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
        extreme)
            cat > "$PROP_FILE" <<'PROPS'
ro.lmk.low=980
ro.lmk.medium=930
ro.lmk.critical=870
ro.lmk.kill_heaviest_task=false
ro.lmk.thrashing_limit=80
ro.lmk.thrashing_limit_decay=90
ro.lmk.swap_util_max=100
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
        stable)
            cat > "$PROP_FILE" <<'PROPS'
ro.lmk.low=1001
ro.lmk.medium=950
ro.lmk.critical=900
ro.lmk.kill_heaviest_task=false
ro.lmk.thrashing_limit=100
ro.lmk.thrashing_limit_decay=80
ro.lmk.swap_util_max=80
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
        normal)
            cat > "$PROP_FILE" <<'PROPS'
ro.lmk.low=990
ro.lmk.medium=930
ro.lmk.critical=880
ro.lmk.kill_heaviest_task=true
ro.lmk.thrashing_limit=70
ro.lmk.thrashing_limit_decay=65
ro.lmk.swap_util_max=90
ro.lmk.use_psi=true
ro.lmk.use_minfree_levels=false
PROPS
            ;;
    esac
}

apply_extreme_profile() {
    # Risk note:
    # EXTREME attempts to keep apps alive for as long as possible on LMKD devices.
    # This can increase RAM pressure and cause lag, UI slowdowns, and heavier swap usage.
    echo 100 > /proc/sys/vm/swappiness 2>/dev/null || true
    write_lmkd_props extreme
}

reload_lmkd_if_running() {
    if pidof lmkd >/dev/null 2>&1; then
        if kill -HUP "$(pidof lmkd)" 2>/dev/null; then
            return 0
        fi
        stop lmkd
        sleep 1
        start lmkd
        return 0
    fi
    return 1
}

apply_lmkd_profile() {
    mode="$1"

    if [ "$mode" = "extreme" ]; then
        apply_extreme_profile
    else
        write_lmkd_props "$mode"
    fi

    if command -v magisk >/dev/null 2>&1; then
        magisk resetprop --file "$PROP_FILE"
    else
        return 1
    fi

    reload_lmkd_if_running
    return 0
}

wait_for_boot_if_needed() {
    # Default path waits for boot complete to avoid racing with system services.
    if [ "$1" = "--post-fs-data" ]; then
        return 0
    fi

    i=0
    while [ "$i" -lt 30 ]; do
        [ "$(getprop sys.boot_completed)" = "1" ] && break
        sleep 2
        i=$((i + 1))
    done
    sleep 2
}

main() {
    phase="$1"

    wait_for_boot_if_needed "$phase"

    saved_mode="stable"
    if [ -f "$CONFIG_FILE" ]; then
        saved_mode="$(normalize_mode "$(tr -d '[:space:]' < "$CONFIG_FILE")")"
    fi

    profile="$saved_mode"
    manager="$(detect_memory_manager)"

    if [ "$manager" = "LMKD" ]; then
        apply_lmkd_profile "$saved_mode"
    else
        if [ "$saved_mode" = "extreme" ]; then
            profile="gamer"
        fi
        apply_lmk_profile "$profile"
    fi

    if [ $? -eq 0 ]; then
        log_applied "$manager" "$(profile_name "$profile")" "Applied"
    else
        log_applied "$manager" "$(profile_name "$profile")" "Skipped"
    fi
}

main "$@"
