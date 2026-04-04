# LMK Controller

> Take full control of Android’s Low Memory Killer — with a clean WebUI and automatic boot persistence.

---

## Overview

The **Low Memory Killer (LMK)** is a kernel-level mechanism responsible for freeing RAM by killing background processes when memory runs low.

It relies on six thresholds (`minfree`), defined in memory pages, to decide how aggressively apps should be terminated.

Most OEM configurations are conservative — leading to:

* unnecessary app reloads
* poor multitasking
* lag when switching between apps

**LMK Controller** gives you full control over these thresholds through a simple WebUI and ensures your configuration is automatically applied on every boot.

---

## Features

* ⚡ **3 tuning profiles** — Performance, Stability, Default
* 🌐 **WebUI interface** — accessible via MMRL or KernelSU Manager
* 🔁 **Boot persistence** — settings reapplied automatically on startup
* 📜 **Boot logging** — track what happens every boot
* 🧹 **Clean uninstall** — no leftovers after removal

---

## Profiles

| Profile         | minfree (pages)                   | Behavior                                                                    |
| --------------- | --------------------------------- | --------------------------------------------------------------------------- |
| **Performance** | `0,0,0,0,0,0`                     | Disables LMK thresholds. Maximum RAM for foreground apps. Ideal for gaming. |
| **Stability**   | `1024,2048,4096,8192,12288,16384` | Balanced multitasking. Recommended for daily use.                           |
| **Default**     | `4096,5120,6144,7168,8192,9216`   | Near-AOSP values. Restores stock-like behavior.                             |

> 📌 **Note:** 1 page ≈ 4KB → `1024 pages = 4MB`

---

## Requirements

* Android 8.0+
* Magisk 20.4+ or KernelSU (with WebUI support)
* Kernel with classic LMK support:

  ```
  /sys/module/lowmemorykiller/parameters/minfree
  ```
* MMRL or compatible module manager

> ⚠️ Devices using **LMKD (userspace LMK)** may not support this module. In such cases, changes will have no effect.

---

## Installation

1. Download the latest `.zip` from **Releases**
2. Flash via Magisk / KernelSU / MMRL
3. Reboot

The boot service will be automatically installed at:

```
/data/adb/service.d/lmk_controller.sh
```

---

## Usage

1. Open MMRL (or your module manager)
2. Access the LMK Controller WebUI
3. Select a profile
4. Click **Apply Settings**

Done — your configuration will persist across reboots.

---

## Verification

After reboot, check if everything worked:

```sh
# Boot log
cat /data/adb/modules/lmk_controller_feerd/boot.log

# Current LMK values
cat /sys/module/lowmemorykiller/parameters/minfree

# Saved mode
cat /data/adb/modules/lmk_controller_feerd/lmk_mode
```

Example `boot.log`:

```
--- Boot Sat Apr 4 17:00:43 -03 2026 ---
Boot completed, applying...
Mode: gamer
Done: 0,0,0,0,0,0
```

---

## Project Structure

```
lmk_controller.zip
├── META-INF/
├── module.prop
├── install.sh
├── uninstall.sh
├── lmk_boot.sh
└── webroot/
    └── index.html
```

---

## How It Works

Instead of relying on `service.sh`, the module installs a dedicated script into:

```
/data/adb/service.d/
```

This ensures:

* consistent execution across Magisk versions
* independence from module lifecycle quirks

On boot, the script:

1. Waits for `sys.boot_completed=1`
2. Applies a short delay
3. Writes the selected `minfree` values

This guarantees your configuration is applied **after** the system sets its defaults.

---

## Troubleshooting

### Values reset after reboot

Check:

```sh
cat /data/adb/modules/lmk_controller_feerd/boot.log
```

If you see:

```
LMK path not found
```

Your kernel uses LMKD — not supported.

---

### Boot log missing

* Ensure Magisk is updated
* Confirm module is enabled
* Verify script exists:

```sh
ls -la /data/adb/service.d/lmk_controller.sh
```

---

### WebUI resets to default

Visual only — actual values are still applied correctly in the background.

---

## Uninstall

Remove via your module manager and reboot.
The boot script will be automatically removed.

---

## Changelog

### v1.0

* Initial release
* 3 tuning profiles
* WebUI support
* Boot persistence via `service.d`
* Boot logging

---

## Author

**feerd**

---

## License

MIT License — see [LICENSE](LICENSE)
