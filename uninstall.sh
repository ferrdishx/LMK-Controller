#!/system/bin/sh

DATA_DIR=/data/adb/lmk_controller
SNAPSHOT="$DATA_DIR/original_state.conf"
LOGFILE="$DATA_DIR/uninstall.log"

rm -f /data/adb/service.d/lmk_controller.sh

echo "--- Uninstall $(date) ---" > "$LOGFILE"

if [ -f "$SNAPSHOT" ]; then
    . "$SNAPSHOT"

    [ -n "$ORIG_SWAPPINESS" ] && [ -f /proc/sys/vm/swappiness ] && echo "$ORIG_SWAPPINESS" > /proc/sys/vm/swappiness
    [ -n "$ORIG_DIRTY_RATIO" ] && [ -f /proc/sys/vm/dirty_ratio ] && echo "$ORIG_DIRTY_RATIO" > /proc/sys/vm/dirty_ratio
    [ -n "$ORIG_DIRTY_BG_RATIO" ] && [ -f /proc/sys/vm/dirty_background_ratio ] && echo "$ORIG_DIRTY_BG_RATIO" > /proc/sys/vm/dirty_background_ratio
    [ -n "$ORIG_VFS_CACHE_PRESSURE" ] && [ -f /proc/sys/vm/vfs_cache_pressure ] && echo "$ORIG_VFS_CACHE_PRESSURE" > /proc/sys/vm/vfs_cache_pressure
    [ -n "$ORIG_MINFREE" ] && [ -f /sys/module/lowmemorykiller/parameters/minfree ] && echo "$ORIG_MINFREE" > /sys/module/lowmemorykiller/parameters/minfree
    [ -n "$ORIG_ZRAM_COMP" ] && [ -f /sys/block/zram0/comp_algorithm ] && echo "$ORIG_ZRAM_COMP" > /sys/block/zram0/comp_algorithm 2>/dev/null

    for p in ro.lmk.low ro.lmk.medium ro.lmk.critical ro.lmk.use_psi ro.lmk.use_minfree_levels \
             ro.lmk.kill_heaviest_task ro.lmk.thrashing_limit ro.lmk.thrashing_limit_decay \
             ro.lmk.swap_util_max ro.lmk.psi_partial_stall_ms ro.lmk.psi_complete_stall_ms; do
        varname="ORIG_$(echo $p | tr '.' '_' | tr '[:lower:]' '[:upper:]')"
        eval val="\$$varname"
        if [ -n "$val" ] && [ "$val" != "__unset__" ]; then
            resetprop "$p" "$val" 2>/dev/null
        elif [ "$val" = "__unset__" ]; then
            resetprop --delete "$p" 2>/dev/null
        fi
    done

    resetprop lmkd.reinit 1 2>/dev/null || kill -HUP "$(pidof lmkd)" 2>/dev/null

    echo "restored from snapshot" >> "$LOGFILE"
    rm -f "$SNAPSHOT"
else
    echo "no snapshot found, leaving system state untouched" >> "$LOGFILE"
fi

for pf in "$DATA_DIR/whitelist_monitor.pid" "$DATA_DIR/psi_monitor.pid"; do
    if [ -f "$pf" ]; then
        kill "$(cat "$pf" 2>/dev/null)" 2>/dev/null
        rm -f "$pf"
    fi
done
