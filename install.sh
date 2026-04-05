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
  # Extract webroot handling both flat and nested ZIP structures
  unzip -o "$ZIPFILE" "webroot/*" -d "$MODPATH" >&2 || \
  unzip -o "$ZIPFILE" "*/webroot/*" -d "$MODPATH" >&2

  ui_print "- Checking compatibility..."
  if [ ! -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    ui_print "! WARNING: Classic LMK not detected."
    ui_print "! Your kernel likely uses LMKD (userspace LMK)."
    ui_print "! Run this to confirm:"
    ui_print "!   getprop ro.lmk.use_minfree_levels"
    ui_print "! Module will install but boot apply may have no effect."
  else
    ui_print "- Classic LMK detected. Good to go."
  fi

  ui_print "- Installing boot service..."
  mkdir -p /data/adb/service.d
  cp "$MODPATH/lmk_boot.sh" /data/adb/service.d/lmk_controller.sh
  chmod 755 /data/adb/service.d/lmk_controller.sh
  ui_print "- Boot service installed."
}

set_permissions() {
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  set_perm "$MODPATH/lmk_boot.sh" 0 0 0755
  chmod -R 755 "$MODPATH/webroot"
}
