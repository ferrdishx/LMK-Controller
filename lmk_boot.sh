#!/system/bin/sh

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
PROP_FILE="$MODDIR/system.prop"
LMK_PATH=/sys/module/lowmemorykiller/parameters/minfree
LOGFILE=/data/local/tmp/lmk_controller.log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [lmk_controller] $*" >> "$LOGFILE"
}

normalize_mode() {
    case "$1" in
        gamer|performance) echo "gamer" ;;
        normal|balanced) echo "normal" ;;
        stable|stability) echo "stable" ;;
        *) echo "stable" ;;
    esac
}

profile_name() {
    case "$1" in
        gamer) echo "Performance" ;;
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
        log "LMK profile '$mode' skipped: $LMK_PATH missing on this kernel"
        return 0
    fi

    # Keep legacy LMK behavior unchanged for compatibility.
    case "$mode" in
        gamer)  echo "0,0,0,0,0,0" > "$LMK_PATH" ;;
        stable) echo "1024,2048,4096,8192,12288,16384" > "$LMK_PATH" ;;
        normal) echo "4096,5120,6144,7168,8192,9216" > "$LMK_PATH" ;;
    esac

    log "LMK minfree applied: $(cat "$LMK_PATH" 2>/dev/null)"
}

write_lmkd_props() {
    mode="$1"

    # LMKD is PSI/pressure-driven and reacts differently than legacy LMK.
    # We use safer, less aggressive values than direct LMK minfree translation.
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

apply_lmkd_profile() {
    mode="$1"

    write_lmkd_props "$mode"

    if command -v magisk >/dev/null 2>&1; then
        magisk resetprop --file "$PROP_FILE"
        log "LMKD props applied via magisk resetprop --file"
    else
        log "WARNING: magisk command not found; LMKD props were not applied"
        return 0
    fi

    if pidof lmkd >/dev/null 2>&1; then
        if kill -HUP "$(pidof lmkd)" 2>/dev/null; then
            log "Signaled lmkd (HUP) to reload properties"
        else
            log "HUP failed; restarting lmkd service"
            stop lmkd
            sleep 1
            start lmkd
        fi
    else
        log "lmkd process not running at apply time"
    fi

    log "LMKD ro.lmk values: low=$(getprop ro.lmk.low) medium=$(getprop ro.lmk.medium) critical=$(getprop ro.lmk.critical)"
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

    profile="$(profile_name "$saved_mode")"
    manager="$(detect_memory_manager)"

    log "--- Boot apply start (phase=${phase:-service}) ---"
    log "Detected mode: $manager"
    log "Selected profile: $profile"

    if [ "$manager" = "LMKD" ]; then
        apply_lmkd_profile "$saved_mode"
    else
        apply_lmk_profile "$saved_mode"
    fi

    log "--- Boot apply done ---"
}

main "$@"
