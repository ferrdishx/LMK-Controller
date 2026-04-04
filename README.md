<p align="center">
  <img src="logo.png" width="500" alt="LMK Controller Logo"/>
</p>

<h1 align="center">LMK Controller</h1>

<p align="center">
  Full control over Android's Low Memory Killer — clean WebUI, automatic boot persistence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.0-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/platform-Magisk%20%7C%20KSU-orange?style=flat-square"/>
  <img src="https://img.shields.io/badge/android-8.0%2B-green?style=flat-square&logo=android"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square"/>
</p>

---

## What is LMK?

The **Low Memory Killer** is a kernel mechanism that frees RAM by terminating background apps based on six memory thresholds (`minfree`). Most OEMs configure these conservatively — causing unnecessary app reloads, poor multitasking and lag when switching between apps.

**LMK Controller** lets you tune these values through a visual interface and ensures your configuration survives every reboot automatically.

---

## Modes

| Mode | minfree (pages) | Best for |
|:---:|:---:|:---|
| ⚡ **Performance** | `0, 0, 0, 0, 0, 0` | Gaming — max RAM for the foreground app |
| 🌿 **Stability** | `1024, 2048, 4096, 8192, 12288, 16384` | Daily use — balanced multitasking |
| 🔵 **Default** | `4096, 5120, 6144, 7168, 8192, 9216` | Near-stock — restores AOSP-like behaviour |

> 1 page ≈ 4KB &nbsp;→&nbsp; `1024 pages = 4MB`

---

## Features

- 🌐 Clean WebUI accessible via MMRL
- 🔁 Settings persist across every reboot
- 📜 Boot log for easy diagnostics
- 🧹 Clean uninstall — removes boot service automatically
- ⚠️ Compatibility check during installation

---

## Requirements

- Android 8.0+
- [Magisk](https://github.com/topjohnwu/Magisk) 20.4+ or [KernelSU](https://github.com/tiann/KernelSU)
- [MMRL](https://github.com/DerGoogler/MMRL) or [WebUIKSU](https://github.com/adivenxnataly/KsuWebUI)
- Kernel with classic LMK node: `/sys/module/lowmemorykiller/parameters/minfree`

> ⚠️ Devices running **LMKD** (userspace LMK, common on Android 10+ with newer kernels) are not supported.

---

## Installation

1. Download the latest `.zip` from [**Releases**](../../releases/latest)
2. Flash via **MMRL**, **Magisk** or **KernelSU**
3. Reboot

The boot service is automatically installed at `/data/adb/service.d/lmk_controller.sh`. No manual steps required.

---

## Usage

1. Open **MMRL** → navigate to LMK Controller
2. Select your preferred mode
3. Tap **Apply Settings**

Your choice is saved and reapplied automatically on every boot.

---

## Verifying

After rebooting, open Termux and run:

```sh
# Boot log — confirms the script ran and what it applied
cat /data/adb/modules/lmk_controller_feerd/boot.log

# Current minfree values
cat /sys/module/lowmemorykiller/parameters/minfree

# Saved mode
cat /data/adb/modules/lmk_controller_feerd/lmk_mode
```

Expected output:

```
--- Boot Sat Apr  4 17:00:43 -03 2026 ---
Boot completed, applying...
Mode: gamer
Done: 0,0,0,0,0,0
```

---

## How boot persistence works

Instead of relying on `service.sh` (which some Magisk versions skip), the module installs a dedicated script into `/data/adb/service.d/` — a directory Magisk **always** executes on boot, regardless of module state.

On boot the script:
1. Waits for `sys.boot_completed = 1`
2. Applies a short delay to let the system set its own defaults first
3. Overwrites `minfree` with your saved values

When the module is uninstalled, `uninstall.sh` cleans up the script from `service.d` automatically.

---

## Troubleshooting

**Values revert after reboot**
```sh
cat /data/adb/modules/lmk_controller_feerd/boot.log
```
If it shows `LMK path not found` — your kernel uses LMKD and is not supported.

**Boot log not generated**
```sh
ls -la /data/adb/service.d/lmk_controller.sh
```
If the file is missing, reinstall the module.

**WebUI shows wrong mode after reboot**
The UI resets visually on load — this is cosmetic only. The actual minfree values in the kernel are correct.

---

## Project structure

```
LMK-Controller/
├── module.prop
├── install.sh        ← installs boot service during flashing
├── uninstall.sh      ← removes boot service on uninstall
├── lmk_boot.sh       ← copied to /data/adb/service.d/ on install
└── webroot/
    └── index.html    ← WebUI
```

---

## Changelog

### [v1.0](../../releases/tag/v1.0)
- Initial release
- Performance, Stability and Default modes
- WebUI via MMRL
- Boot persistence via `service.d`
- Boot logging

---

<p align="center">
  Made by <strong>feerd</strong> &nbsp;·&nbsp;
  <a href="../../releases/latest">Download</a> &nbsp;·&nbsp;
  <a href="LICENSE">MIT License</a>
</p>
