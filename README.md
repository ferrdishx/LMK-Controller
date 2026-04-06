<p align="center">
  <img src="Icon.png" width="500" alt="LMK Controller Logo"/>
</p>

<h1 align="center">LMK Controller</h1>

<p align="center">
  Full control over Android's Low Memory Killer — clean WebUI, automatic boot persistence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.2--beta-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/platform-Magisk%20%7C%20KSU-orange?style=flat-square"/>
  <img src="https://img.shields.io/badge/android-8.0%2B-green?style=flat-square&logo=android"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square"/>
</p>

<p align="center">
  <a href="https://t.me/lmkcontrollerchat">
    <img src="https://img.shields.io/badge/Telegram-Chat-blue?style=flat-square&logo=telegram"/>
  </a>
  <a href="https://t.me/lmkcontroller">
    <img src="https://img.shields.io/badge/Telegram-News-blue?style=flat-square&logo=telegram"/>
  </a>
  <a href="https://github.com/ferrdishx/LKM-Controller/issues">
    <img src="https://img.shields.io/github/issues/ferrdishx/LKM-Controller?style=flat-square"/>
  </a>
</p>

---

## What is LMK?

The **Low Memory Killer** is a kernel mechanism that frees RAM by terminating background apps based on six memory thresholds (`minfree`). Most OEMs configure these conservatively, causing unnecessary app reloads, poor multitasking and lag when switching between apps.

**LMK Controller** lets you tune these values through a visual interface and ensures your configuration survives every reboot automatically.

---

## Modes

| Mode | minfree (pages) | Best for |
|:---:|:---:|:---|
| ⚡ **Performance** | `0, 0, 0, 0, 0, 0` | Gaming / max RAM for the foreground app |
| 🌿 **Stability** | `1024, 2048, 4096, 8192, 12288, 16384` | Daily use / balanced multitasking |
| 🔵 **Default** | `4096, 5120, 6144, 7168, 8192, 9216` | Near-stock / restores AOSP-like behaviour |

> 1 page ≈ 4KB &nbsp;→&nbsp; `1024 pages = 4MB`

---

## Features

- 🌐 Clean WebUI accessible via MMRL
- 🔁 Settings persist across every reboot
- 📜 Boot log for easy diagnostics
- 🧹 Clean uninstall, removes boot service automatically
- ⚠️ Compatibility check during installation
- 🆕 **LMKD support**  works on both classic LMK and userspace LMKD kernels

---

## Requirements

- Android 8.0+
- [Magisk](https://github.com/topjohnwu/Magisk) 20.4+ or [KernelSU](https://github.com/tiann/KernelSU)
- [MMRL](https://github.com/DerGoogler/MMRL) or compatible module manager

### How to check your kernel type

Open Termux and run:

```sh
# If this file exists → Classic LMK
ls /sys/module/lowmemorykiller/parameters/minfree

# If blank or missing → LMKD
getprop ro.lmk.use_minfree_levels
```

Both are supported. The module detects your kernel type automatically during installation.

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
# Boot log
cat /data/adb/modules/lmk_controller_feerd/boot.log

# Saved mode
cat /data/adb/modules/lmk_controller_feerd/lmk_mode

# Classic LMK only
cat /sys/module/lowmemorykiller/parameters/minfree

# LMKD only
getprop ro.lmk.low
getprop ro.lmk.medium
getprop ro.lmk.critical
```

---

## How boot persistence works

Instead of relying on `service.sh` (which some Magisk versions skip), the module installs a dedicated script into `/data/adb/service.d/`  a directory Magisk **always** executes on boot, regardless of module state.

**Classic LMK**  writes directly to `/sys/module/lowmemorykiller/parameters/minfree`.

**LMKD**  writes a `system.prop` file with the correct `ro.lmk.*` properties and applies them via `magisk resetprop --file`, then signals the LMKD process to reload.

When the module is uninstalled, `uninstall.sh` cleans up the script from `service.d` automatically.

---

## Troubleshooting

**Boot log not generated**
```sh
ls -la /data/adb/service.d/lmk_controller.sh
```
If the file is missing, reinstall the module.

**Values revert after reboot**

Check the boot log. If it shows `ERROR: minfree not found` your device uses LMKD, update to v1.2-beta which adds LMKD support.

**WebUI shows wrong mode after reboot**

The UI resets visually on load, cosmetic only. The actual values applied in the kernel are correct.

---

## Project structure

```
LMK-Controller/
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary
│               └── updater-script
├── module.prop
├── install.sh
├── uninstall.sh
├── lmk_boot.sh
├── post-fs-data.sh
├── service.sh
├── logo.png
└── webroot/
    └── index.html
```

---

## Changelog

### [v1.2-beta](../../releases/tag/v1.2-beta)
- Added LMKD support, module now works on both Classic LMK and LMKD kernels
- Fixed extraction error on install (`! Unzip error`) affecting some Magisk forks
- Boot script now uses `magisk resetprop --file` for reliable prop application on LMKD
- Improved installation output with clear success/error messages
- Boot log now shows kernel type (`classic` or `lmkd`)

### [v1.1](../../releases/tag/v1.1)
- Fixed extraction error on install
- Improved LMKD detection message during installation
- Added compatibility check instructions to README

### [v1.0](../../releases/tag/v1.0)
- Initial release
- Performance, Stability and Default modes
- WebUI via MMRL
- Boot persistence via `service.d`
- Boot logging

---

## Contributors

Thanks to everyone who helped test and improve this module.

| | Name | Contribution |
|:---:|:---:|:---|
| 👤 | George Machen | Beta testing LMKD support on Pixel 4a (5G) |

---

<p align="center">
  Made by <strong>feerd</strong> &nbsp;·&nbsp;
  <a href="../../releases/latest">Download</a> &nbsp;·&nbsp;
  <a href="https://t.me/lmkcontrollerchat">Telegram</a> &nbsp;·&nbsp;
  <a href="LICENSE">MIT License</a>
</p>
