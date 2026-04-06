SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
SERVICESH=false

print_modname() {
  ui_print "*******************************"
  ui_print "      LMK Controller           "
  ui_print "      Author: feerd            "
  ui_print "      Version: v1.2 beta       "
  ui_print "*******************************"
}

on_install() {
  ui_print "- Extracting files..."
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

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
