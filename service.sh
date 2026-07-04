#!/system/bin/sh
# shellcheck disable=SC2086,SC3043,SC3060

MODDIR=/data/adb/modules/lmk_controller_feerd
CONFIG_FILE="$MODDIR/lmk_mode"
DATA_DIR=/data/adb/lmk_controller
LOGFILE="$DATA_DIR/service.log"

mkdir -p "$DATA_DIR"

if [ -f "$MODDIR/common/psi_lmk.sh" ]; then
    . "$MODDIR/common/psi_lmk.sh"
else
    echo "$(date '+%H:%M:%S') [FATAL] common/psi_lmk.sh not found!" >> "$LOGFILE"
    exit 1
fi

svc_log() { echo "$(date '+%H:%M:%S') [SVC] $*" >> "$LOGFILE"; }

svc_log "=== LMK Controller service.sh started ==="
svc_log "Module version: $(grep ^version $MODDIR/module.prop 2>/dev/null | cut -d= -f2)"

i=0
while [ "$i" -lt 30 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && break
    sleep 2
    i=$((i + 1))
done

if [ "$(getprop sys.boot_completed)" != "1" ]; then
    svc_log "WARN: boot_completed not detected after 60s - proceeding anyway"
fi

sleep 3
svc_log "Boot complete. Starting LMK configuration."

secure_lmk_nodes

MODE="stable"
if [ -f "$CONFIG_FILE" ]; then
    SAVED=$(tr -d '[:space:]' < "$CONFIG_FILE")
    case "$SAVED" in
        gamer|stable|normal)
            MODE="$SAVED"
            svc_log "Mode loaded from file: $MODE"
            ;;
        *)
            svc_log "WARN: unknown mode '$SAVED', falling back to stable"
            ;;
    esac
else
    svc_log "No config file found, using default mode: $MODE"
fi

detect_kernel_type
svc_log "Kernel type detected: $KERNEL_TYPE"

RAM_MB=$(get_total_ram_mb)
RAM_GB=$(get_total_ram_gb)
svc_log "Total RAM: ${RAM_MB}MB (~${RAM_GB}GB)"

case "$KERNEL_TYPE" in
    psi_lmkd)
        svc_log "Activating PSI mode for lmkd"

        case "$MODE" in
            gamer)  apply_psi_props_gamer  ;;
            stable) apply_psi_props_stable ;;
            normal) apply_psi_props_normal ;;
        esac

        if [ "$MODE" = "gamer" ]; then
            configure_zram_compression "lz4"
        else
            configure_zram_compression "zstd" || configure_zram_compression "lz4"
        fi

        apply_zram_swappiness "$MODE"

        PSI_NOW=$(read_psi_pressure)
        svc_log "Initial PSI pressure (avg10): ${PSI_NOW}%"

        if [ "$MODE" != "gamer" ]; then
            case "$MODE" in
                stable) PSI_BASE_SWAP=100 ;;
                normal) PSI_BASE_SWAP=130 ;;
                *)      PSI_BASE_SWAP=100 ;;
            esac
            start_psi_swappiness_monitor "$PSI_BASE_SWAP" 60
        else
            svc_log "PSI monitor disabled in gamer mode"
        fi
        ;;

    legacy_lmkd)
        svc_log "FALLBACK: lmkd without PSI - applying legacy props"

        resetprop ro.lmk.use_psi false 2>/dev/null

        case "$MODE" in
            gamer)
                resetprop ro.lmk.low                 0
                resetprop ro.lmk.medium              200
                resetprop ro.lmk.critical            100
                resetprop ro.lmk.kill_heaviest_task  true
                resetprop ro.lmk.thrashing_limit     30
                resetprop ro.lmk.use_minfree_levels  false
                ;;
            stable)
                resetprop ro.lmk.low                 1001
                resetprop ro.lmk.medium              900
                resetprop ro.lmk.critical            800
                resetprop ro.lmk.kill_heaviest_task  false
                resetprop ro.lmk.thrashing_limit     100
                resetprop ro.lmk.use_minfree_levels  false
                ;;
            normal)
                resetprop ro.lmk.low                 1001
                resetprop ro.lmk.medium              800
                resetprop ro.lmk.critical            0
                resetprop ro.lmk.kill_heaviest_task  true
                resetprop ro.lmk.thrashing_limit     100
                resetprop ro.lmk.use_minfree_levels  false
                ;;
        esac

        _reinit_lmkd
        apply_zram_swappiness "$MODE"
        configure_zram_compression "lz4"
        ;;

    classic_lmk)
        svc_log "FALLBACK: classic LMK driver - applying adaptive minfree"
        apply_legacy_minfree "$MODE"
        apply_zram_swappiness "$MODE"
        configure_zram_compression "lz4"
        ;;

    *)
        svc_log "ERROR: unknown kernel type ($KERNEL_TYPE). No action taken."
        ;;
esac

start_whitelist_monitor 20

svc_log "--- Final State ---"
svc_log "Mode:                        $MODE"
svc_log "Kernel:                      $KERNEL_TYPE"
svc_log "RAM:                         ${RAM_MB}MB"
svc_log "swappiness:                  $(cat /proc/sys/vm/swappiness 2>/dev/null)"
svc_log "minfree:                     $(cat /sys/module/lowmemorykiller/parameters/minfree 2>/dev/null || echo 'N/A')"
svc_log "ro.lmk.use_psi:              $(getprop ro.lmk.use_psi 2>/dev/null || echo 'N/A')"
svc_log "ro.lmk.psi_partial_stall_ms: $(getprop ro.lmk.psi_partial_stall_ms 2>/dev/null || echo 'N/A')"
svc_log "ro.lmk.psi_complete_stall_ms:$(getprop ro.lmk.psi_complete_stall_ms 2>/dev/null || echo 'N/A')"
svc_log "lmkd PID:                    $(pidof lmkd 2>/dev/null || echo 'not found')"
svc_log "=== Configuration complete ==="
