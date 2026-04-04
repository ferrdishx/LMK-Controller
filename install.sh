SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
SERVICESH=false

print_modname() {
  ui_print "*******************************"
  ui_print "      LMK Controller           "
  ui_print "      Author: feerd            "
  ui_print "      Version: v1.0            "
  ui_print "*******************************"
}

on_install() {
  ui_print "- Extracting module files..."
  unzip -o "$ZIPFILE" "webroot/*" -d "$MODPATH" >&2

  ui_print "- Checking compatibility..."
  if [ ! -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    ui_print "! WARNING: Classic LMK not detected in this kernel."
    ui_print "! The module might have limited effect."
  else
    ui_print "- LMK detected."
  fi

  ui_print "- Installing boot service..."
  mkdir -p /data/adb/service.d
  cp "$MODPATH/lmk_boot.sh" /data/adb/service.d/lmk_controller.sh
  chmod 755 /data/adb/service.d/lmk_controller.sh
  ui_print "- Boot service installed."
}

set_permissions() {
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  chmod -R 755 "$MODPATH/webroot"
}