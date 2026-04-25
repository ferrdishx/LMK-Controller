SKIPMOUNT=false
<<<<<<< HEAD
PROPFILE=false
POSTFSDATA=false
SERVICESH=false
=======
PROPFILE=true
POSTFSDATA=false
SERVICESH=true
>>>>>>> 335ec37 (new files)

print_modname() {
  ui_print "*******************************"
  ui_print "      LMK Controller           "
  ui_print "      Author: feerd            "
<<<<<<< HEAD
  ui_print "      Version: v1.2 beta       "
=======
  ui_print "      Version: v1.3            "
>>>>>>> 335ec37 (new files)
  ui_print "*******************************"
}

on_install() {
  ui_print "- Extracting files..."
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

<<<<<<< HEAD
  if [ ! -f "$MODPATH/lmk_boot.sh" ]; then
    ui_print "! lmk_boot.sh missing after extraction, retrying..."
    unzip -o "$ZIPFILE" "lmk_boot.sh" -d "$MODPATH" >&2
  fi

  if [ ! -f "$MODPATH/lmk_boot.sh" ]; then
    ui_print "! ERROR: lmk_boot.sh could not be extracted."
    ui_print "! Please re-download the ZIP and try again."
    exit 1
  fi

  if [ -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    ui_print "- Classic LMK detected."
  else
    ui_print "- LMKD detected."
    ui_print "- LMKD mode is supported in this version."
  fi

  ui_print "- Installing boot service..."
  mkdir -p /data/adb/service.d
  cp "$MODPATH/lmk_boot.sh" /data/adb/service.d/lmk_controller.sh
  chmod 755 /data/adb/service.d/lmk_controller.sh

  if [ -f /data/adb/service.d/lmk_controller.sh ]; then
    ui_print "- Boot service installed successfully."
  else
    ui_print "! ERROR: Failed to install boot service."
    exit 1
  fi
}

set_permissions() {
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  set_perm "$MODPATH/lmk_boot.sh" 0 0 0755
  chmod -R 755 "$MODPATH/webroot"
}
=======
  for required in service.sh common/psi_lmk.sh system.prop; do
    if [ ! -f "$MODPATH/$required" ]; then
      ui_print "! ERROR: $required not found after extraction."
      ui_print "! Please re-download the ZIP and try again."
      exit 1
    fi
  done

  mkdir -p /data/adb/lmk_controller
  chmod 700 /data/adb/lmk_controller

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
>>>>>>> 335ec37 (new files)
