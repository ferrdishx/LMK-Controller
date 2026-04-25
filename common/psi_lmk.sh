#!/system/bin/sh
# shellcheck disable=SC2086,SC2046,SC3043,SC3060

PSI_MEMORY_NODE="/proc/pressure/memory"
LMK_CLASSIC_NODE="/sys/module/lowmemorykiller/parameters/minfree"
LMK_CLASSIC_ADJ="/sys/module/lowmemorykiller/parameters/adj"
ZRAM_CONTROL_NODE="/sys/class/zram-control/hot_add"
VM_SWAPPINESS="/proc/sys/vm/swappiness"
VM_DIRTY_RATIO="/proc/sys/vm/dirty_ratio"
VM_DIRTY_BG_RATIO="/proc/sys/vm/dirty_background_ratio"
VM_VFSCACHE_PRESSURE="/proc/sys/vm/vfs_cache_pressure"

_psi_log() {
    local level="$1"; shift
    echo "[$(date '+%H:%M:%S')] [$level] [psi_lmk] $*" >> "$LOGFILE"
    log -p i -t "lmk_psi" "$level: $*" 2>/dev/null
}

psi_info()  { _psi_log "INFO"  "$@"; }
psi_warn()  { _psi_log "WARN"  "$@"; }
psi_error() { _psi_log "ERROR" "$@"; }

detect_kernel_type() {
    KERNEL_TYPE="unknown"

    if [ -f "$LMK_CLASSIC_NODE" ]; then
        KERNEL_TYPE="classic_lmk"
        psi_info "Detected: classic_lmk (minfree node found)"
        return 0
    fi

    if [ -f "$PSI_MEMORY_NODE" ]; then
        KERNEL_TYPE="psi_lmkd"
        psi_info "Detected: psi_lmkd (PSI available at $PSI_MEMORY_NODE)"
    else
        KERNEL_TYPE="legacy_lmkd"
        psi_warn "Detected: legacy_lmkd (lmkd without PSI)"
    fi
    return 0
}

psi_supported() {
    [ -f "$PSI_MEMORY_NODE" ] && return 0
    return 1
}

get_total_ram_gb() {
    awk '/MemTotal/ { gb = int($2 / 1024 / 1024); print (gb < 1) ? 1 : gb + 1 }' \
        /proc/meminfo
}

get_total_ram_mb() {
    awk '/MemTotal/ { print int($2 / 1024) }' /proc/meminfo
}

apply_psi_props_gamer() {
    psi_info "Applying PSI props - gamer mode"
    resetprop ro.lmk.use_psi                 true
    resetprop ro.lmk.use_minfree_levels      false
    resetprop ro.lmk.psi_partial_stall_ms    50
    resetprop ro.lmk.psi_complete_stall_ms   400
    resetprop ro.lmk.kill_heaviest_task      true
    resetprop ro.lmk.thrashing_limit         30
    resetprop ro.lmk.thrashing_limit_decay   5
    resetprop ro.lmk.swap_util_max           80
    resetprop ro.lmk.low                     0
    resetprop ro.lmk.medium                  200
    resetprop ro.lmk.critical                100
    _reinit_lmkd
}

apply_psi_props_stable() {
    psi_info "Applying PSI props - stable mode"
    resetprop ro.lmk.use_psi                 true
    resetprop ro.lmk.use_minfree_levels      false
    resetprop ro.lmk.psi_partial_stall_ms    70
    resetprop ro.lmk.psi_complete_stall_ms   500
    resetprop ro.lmk.kill_heaviest_task      false
    resetprop ro.lmk.thrashing_limit         100
    resetprop ro.lmk.thrashing_limit_decay   10
    resetprop ro.lmk.swap_util_max           90
    resetprop ro.lmk.low                     1001
    resetprop ro.lmk.medium                  900
    resetprop ro.lmk.critical                800
    _reinit_lmkd
}

apply_psi_props_normal() {
    psi_info "Applying PSI props - normal mode"
    resetprop ro.lmk.use_psi                 true
    resetprop ro.lmk.use_minfree_levels      false
    resetprop ro.lmk.psi_partial_stall_ms    100
    resetprop ro.lmk.psi_complete_stall_ms   700
    resetprop ro.lmk.kill_heaviest_task      true
    resetprop ro.lmk.thrashing_limit         100
    resetprop ro.lmk.thrashing_limit_decay   10
    resetprop ro.lmk.swap_util_max           95
    resetprop ro.lmk.low                     1001
    resetprop ro.lmk.medium                  800
    resetprop ro.lmk.critical                0
    _reinit_lmkd
}

_reinit_lmkd() {
    local lmkd_pid
    lmkd_pid=$(pidof lmkd 2>/dev/null)

    if [ -n "$lmkd_pid" ]; then
        resetprop lmkd.reinit 1 2>/dev/null && {
            psi_info "lmkd reinitialized via lmkd.reinit"
            return 0
        }
        kill -HUP "$lmkd_pid" 2>/dev/null && {
            psi_info "lmkd received SIGHUP (pid $lmkd_pid)"
            return 0
        }
    fi

    psi_warn "Restarting lmkd via stop/start"
    stop lmkd 2>/dev/null
    sleep 1
    start lmkd 2>/dev/null
}

apply_legacy_minfree() {
    local mode="$1"
    local ram_mb minfree_vals adj_vals

    if [ ! -f "$LMK_CLASSIC_NODE" ]; then
        psi_error "Node $LMK_CLASSIC_NODE not found. Skipping minfree."
        return 1
    fi

    ram_mb=$(get_total_ram_mb)

    if [ "$ram_mb" -lt 3072 ]; then
        case "$mode" in
            gamer)  minfree_vals="1024,2048,3072,4096,5120,7168"   ;;
            stable) minfree_vals="2048,3072,4096,6144,8192,10240"  ;;
            normal) minfree_vals="3072,4096,6144,8192,10240,12288" ;;
        esac
    elif [ "$ram_mb" -lt 5120 ]; then
        case "$mode" in
            gamer)  minfree_vals="1024,2048,4096,6144,8192,10240"   ;;
            stable) minfree_vals="3072,5120,8192,10240,14336,18432" ;;
            normal) minfree_vals="4096,6144,10240,12288,16384,20480" ;;
        esac
    else
        case "$mode" in
            gamer)  minfree_vals="2048,4096,6144,8192,12288,16384"   ;;
            stable) minfree_vals="4096,6144,10240,14336,18432,22528" ;;
            normal) minfree_vals="5120,8192,12288,16384,20480,24576" ;;
        esac
    fi

    adj_vals="0,1,2,4,9,15"

    psi_info "Applying legacy minfree - mode=$mode, ram=${ram_mb}MB, values=$minfree_vals"

    chmod 0664 "$LMK_CLASSIC_NODE" 2>/dev/null
    chown root:root "$LMK_CLASSIC_NODE" 2>/dev/null

    echo "$minfree_vals" > "$LMK_CLASSIC_NODE" || {
        psi_error "Failed to write to $LMK_CLASSIC_NODE"
        return 1
    }

    if [ -f "$LMK_CLASSIC_ADJ" ]; then
        chmod 0664 "$LMK_CLASSIC_ADJ" 2>/dev/null
        echo "$adj_vals" > "$LMK_CLASSIC_ADJ" 2>/dev/null
    fi

    psi_info "minfree applied: $(cat $LMK_CLASSIC_NODE 2>/dev/null)"
    return 0
}

apply_zram_swappiness() {
    local mode="$1"
    local ram_mb swappiness dirty_ratio dirty_bg vfs_pressure
    ram_mb=$(get_total_ram_mb)

    case "$mode" in
        gamer)
            swappiness=60
            dirty_ratio=20
            dirty_bg=5
            vfs_pressure=200
            ;;
        stable)
            swappiness=100
            dirty_ratio=30
            dirty_bg=10
            vfs_pressure=100
            ;;
        normal)
            swappiness=130
            dirty_ratio=40
            dirty_bg=15
            vfs_pressure=80
            ;;
    esac

    if [ "$ram_mb" -lt 3072 ]; then
        swappiness=$((swappiness + 20))
        dirty_bg=$((dirty_bg - 2))
        [ "$dirty_bg" -lt 2 ] && dirty_bg=2
    fi

    psi_info "Configuring VM - mode=$mode, swappiness=$swappiness, dirty=$dirty_ratio/$dirty_bg"

    for node in "$VM_SWAPPINESS" "$VM_DIRTY_RATIO" "$VM_DIRTY_BG_RATIO" "$VM_VFSCACHE_PRESSURE"; do
        [ -f "$node" ] && chmod 0664 "$node" 2>/dev/null
    done

    [ -f "$VM_SWAPPINESS" ]        && echo "$swappiness"   > "$VM_SWAPPINESS"
    [ -f "$VM_DIRTY_RATIO" ]       && echo "$dirty_ratio"  > "$VM_DIRTY_RATIO"
    [ -f "$VM_DIRTY_BG_RATIO" ]    && echo "$dirty_bg"     > "$VM_DIRTY_BG_RATIO"
    [ -f "$VM_VFSCACHE_PRESSURE" ] && echo "$vfs_pressure" > "$VM_VFSCACHE_PRESSURE"

    psi_info "swappiness set to: $(cat $VM_SWAPPINESS 2>/dev/null)"
}

configure_zram_compression() {
    local algo="${1:-lz4}"
    local comp_node="/sys/block/zram0/comp_algorithm"

    [ -f "$comp_node" ] || { psi_warn "Node $comp_node not found"; return 1; }

    if grep -q "$algo" "$comp_node" 2>/dev/null; then
        chmod 0664 "$comp_node" 2>/dev/null
        echo "$algo" > "$comp_node" 2>/dev/null && \
            psi_info "ZRAM compression set to $algo" || \
            psi_warn "Failed to set ZRAM compression algorithm"
    else
        psi_warn "Algorithm $algo not available. Keeping kernel default."
        psi_info "Available algorithms: $(cat $comp_node 2>/dev/null)"
    fi
}

read_psi_pressure() {
    [ -f "$PSI_MEMORY_NODE" ] || { echo "-1"; return 1; }
    awk '/^some/ { split($2, a, "="); printf "%d\n", a[2] }' "$PSI_MEMORY_NODE"
}

adjust_swappiness_by_psi() {
    local base_swappiness="${1:-100}"
    local pressure new_swappiness

    pressure=$(read_psi_pressure)

    if [ "$pressure" -lt 0 ]; then
        psi_warn "PSI unavailable for dynamic swappiness adjustment"
        return 1
    fi

    if [ "$pressure" -lt 5 ]; then
        new_swappiness=$((base_swappiness + 20))
    elif [ "$pressure" -lt 25 ]; then
        new_swappiness=$base_swappiness
    else
        new_swappiness=$((base_swappiness - 30))
        [ "$new_swappiness" -lt 10 ] && new_swappiness=10
    fi

    [ "$new_swappiness" -gt 200 ] && new_swappiness=200
    [ "$new_swappiness" -lt 1   ] && new_swappiness=1

    if [ -f "$VM_SWAPPINESS" ]; then
        echo "$new_swappiness" > "$VM_SWAPPINESS" && \
            psi_info "PSI=${pressure}% -> swappiness adjusted to $new_swappiness"
    fi
}

start_psi_swappiness_monitor() {
    local base="${1:-100}"
    local interval="${2:-60}"
    local pid_file="/data/adb/lmk_controller/psi_monitor.pid"

    psi_info "Starting PSI monitor (base=$base, interval=${interval}s)"

    if [ -f "$pid_file" ]; then
        local old_pid
        old_pid=$(cat "$pid_file" 2>/dev/null)
        kill -0 "$old_pid" 2>/dev/null && kill "$old_pid" 2>/dev/null
    fi

    (
        while true; do
            adjust_swappiness_by_psi "$base"
            sleep "$interval"
        done
    ) &

    echo "$!" > "$pid_file"
    psi_info "PSI monitor started with PID $!"
}

stop_psi_swappiness_monitor() {
    local pid_file="/data/adb/lmk_controller/psi_monitor.pid"
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        kill "$pid" 2>/dev/null && psi_info "PSI monitor stopped (pid $pid)"
        rm -f "$pid_file"
    fi
}

secure_lmk_nodes() {
    local nodes="
        /sys/module/lowmemorykiller/parameters/minfree
        /sys/module/lowmemorykiller/parameters/adj
        /proc/sys/vm/swappiness
        /proc/sys/vm/dirty_ratio
        /proc/sys/vm/dirty_background_ratio
        /proc/sys/vm/vfs_cache_pressure
        /proc/sys/vm/overcommit_memory
        /proc/sys/vm/page-cluster
    "

    for node in $nodes; do
        if [ -f "$node" ]; then
            chown root:root "$node" 2>/dev/null
            chmod 0664 "$node" 2>/dev/null
        fi
    done

    for zram_node in /sys/block/zram*/disksize /sys/block/zram*/reset \
                     /sys/block/zram*/comp_algorithm /sys/block/zram*/use_dedup; do
        [ -f "$zram_node" ] && chown root:root "$zram_node" 2>/dev/null \
                             && chmod 0600 "$zram_node" 2>/dev/null
    done

    psi_info "LMK/VM node permissions set"
}
