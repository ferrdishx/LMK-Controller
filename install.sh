SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
SERVICESH=true

print_modname() {
  ui_print "*******************************"
  ui_print "      LMK Controller           "
  ui_print "      Author: ferrdishx            "
  ui_print "      Version: v1.4.1          "
  ui_print "*******************************"
}

on_install() {
  ui_print "- Extracting files..."
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

  for required in service.sh common/psi_lmk.sh system.prop; do
    if [ ! -f "$MODPATH/$required" ]; then
      ui_print "! ERROR: $required not found after extraction."
      ui_print "! Please re-download the ZIP and try again."
      exit 1
    fi
  done

  mkdir -p /data/adb/lmk_controller
  chmod 700 /data/adb/lmk_controller

  SNAPSHOT=/data/adb/lmk_controller/original_state.conf

  if [ ! -f "$SNAPSHOT" ]; then
    ui_print "- Capturing original system state..."

    read_prop() {
      v=$(getprop "$1" 2>/dev/null)
      if [ -z "$v" ]; then
        echo "__unset__"
      else
        echo "$v"
      fi
    }

    {
      echo "ORIG_SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null)"
      echo "ORIG_DIRTY_RATIO=$(cat /proc/sys/vm/dirty_ratio 2>/dev/null)"
      echo "ORIG_DIRTY_BG_RATIO=$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null)"
      echo "ORIG_VFS_CACHE_PRESSURE=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)"
      echo "ORIG_MINFREE=\"$(cat /sys/module/lowmemorykiller/parameters/minfree 2>/dev/null)\""
      echo "ORIG_ZRAM_COMP=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null | grep -o '\[[a-z0-9]*\]' | tr -d '[]')"
      echo "ORIG_RO_LMK_LOW=$(read_prop ro.lmk.low)"
      echo "ORIG_RO_LMK_MEDIUM=$(read_prop ro.lmk.medium)"
      echo "ORIG_RO_LMK_CRITICAL=$(read_prop ro.lmk.critical)"
      echo "ORIG_RO_LMK_USE_PSI=$(read_prop ro.lmk.use_psi)"
      echo "ORIG_RO_LMK_USE_MINFREE_LEVELS=$(read_prop ro.lmk.use_minfree_levels)"
      echo "ORIG_RO_LMK_KILL_HEAVIEST_TASK=$(read_prop ro.lmk.kill_heaviest_task)"
      echo "ORIG_RO_LMK_THRASHING_LIMIT=$(read_prop ro.lmk.thrashing_limit)"
      echo "ORIG_RO_LMK_THRASHING_LIMIT_DECAY=$(read_prop ro.lmk.thrashing_limit_decay)"
      echo "ORIG_RO_LMK_SWAP_UTIL_MAX=$(read_prop ro.lmk.swap_util_max)"
      echo "ORIG_RO_LMK_PSI_PARTIAL_STALL_MS=$(read_prop ro.lmk.psi_partial_stall_ms)"
      echo "ORIG_RO_LMK_PSI_COMPLETE_STALL_MS=$(read_prop ro.lmk.psi_complete_stall_ms)"
    } > "$SNAPSHOT"

    chmod 600 "$SNAPSHOT"
    ui_print "- Snapshot saved. Uninstall will restore these values."
  else
    ui_print "- Existing snapshot found, keeping it (already installed before)."
  fi

  if [ -f /data/adb/service.d/lmk_controller.sh ]; then
    rm -f /data/adb/service.d/lmk_controller.sh
    ui_print "- Legacy service (service.d) removed."
  fi

  if [ -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    ui_print "- LMK type: classic kernel driver."
    ui_print "  Adaptive minfree mode will be used."
  elif [ -f /proc/pressure/memory ]; then
    ui_print "- LMK type: lmkd with PSI support."
    ui_print "  Smart PSI mode will be activated."
  else
    ui_print "- LMK type: lmkd without PSI (legacy mode)."
    ui_print "  Conservative props will be applied."
  fi

  if [ ! -f "$MODPATH/lmk_mode" ]; then
    echo "stable" > "$MODPATH/lmk_mode"
    ui_print "- Default mode set: stable"
  else
    ui_print "- Existing mode preserved: $(cat $MODPATH/lmk_mode)"
  fi

  ui_print "- Installation complete."
}

set_permissions() {
  set_perm_recursive "$MODPATH"             0 0 0755 0644
  set_perm "$MODPATH/service.sh"            0 0 0755
  set_perm "$MODPATH/common/psi_lmk.sh"    0 0 0755
  set_perm "$MODPATH/uninstall.sh"          0 0 0755
  [ -d "$MODPATH/webroot" ] && chmod -R 755 "$MODPATH/webroot"
}
