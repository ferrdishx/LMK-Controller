<p align="center">
  <img src="Icon.png" width="400" alt="LMK Controller" />
</p>

<h1 align="center">LMK Controller</h1>

<p align="center">
  Full control over Android's Low Memory Killer.<br/>
  Adaptive kernel detection, three tuning profiles, clean WebUI, automatic boot persistence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.3-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/platform-Magisk%20%7C%20KSU-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/android-8.0%2B-green?style=flat-square&logo=android" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square" />
</p>

<p align="center">
  <a href="https://t.me/lmkcontrollerchat">
    <img src="https://img.shields.io/badge/Telegram-Chat-blue?style=flat-square&logo=telegram" />
  </a>
  <a href="https://t.me/lmkcontroller">
    <img src="https://img.shields.io/badge/Telegram-News-blue?style=flat-square&logo=telegram" />
  </a>
  <a href="https://github.com/ferrdishx/LMK-Controller/issues">
    <img src="https://img.shields.io/github/issues/ferrdishx/LMK-Controller?style=flat-square" />
  </a>
</p>

---

## Overview

The **Low Memory Killer** is the kernel subsystem responsible for freeing RAM by terminating background processes when memory runs low. Android exposes this through two distinct mechanisms depending on the kernel version.

**Classic LMK** is a kernel driver controlled via `/sys/module/lowmemorykiller/parameters/minfree`. Six thresholds defined in pages determine at which memory levels each process priority class gets killed. This is the standard path on kernels 4.9 and older.

**LMKD** is a userspace daemon that handles memory kills outside the kernel. On modern kernels it operates in **PSI mode**, reacting to memory pressure stall events with millisecond precision via `/proc/pressure/memory`. On older kernels without PSI it falls back to a simpler threshold model.

Most OEMs ship conservative defaults that cause unnecessary app reloads, stuttering on app switches and degraded multitasking. LMK Controller lets you tune the relevant parameters for your kernel type through a single interface, with settings that survive every reboot automatically.

---

## Kernel Detection

At boot the module identifies your kernel type and applies the correct tuning strategy. No manual configuration is required.

| Kernel Type | Detection Condition | Applied Strategy |
|---|---|---|
| `classic_lmk` | `/sys/module/lowmemorykiller/parameters/minfree` exists | Writes minfree thresholds directly to the kernel node |
| `psi_lmkd` | `/proc/pressure/memory` exists | Sets `ro.lmk.*` PSI props and starts a dynamic swappiness monitor |
| `legacy_lmkd` | Neither node found | Sets `ro.lmk.*` props without PSI and reinitialises lmkd |

---

## Profiles

### Classic LMK — minfree thresholds

Values are in pages. One page equals approximately 4 KB. Thresholds scale with device RAM automatically: separate value sets are applied for devices under 3 GB, between 3 GB and 5 GB, and above 5 GB.

| Profile | Values (pages) | Best for |
|---|---|---|
| ⚡ Performance | `1024, 2048, 4096, 6144, 8192, 10240` | Gaming and maximum RAM availability for the foreground app |
| 🌿 Stability | `1024, 2048, 4096, 8192, 12288, 16384` | Daily use and balanced multitasking |
| 🔵 Default | `4096, 5120, 6144, 7168, 8192, 9216` | Near-stock behaviour, close to AOSP defaults |

### PSI LMKD — key properties

| Property | Performance | Stability | Default |
|---|---|---|---|
| `psi_partial_stall_ms` | 50 | 70 | 100 |
| `psi_complete_stall_ms` | 400 | 500 | 700 |
| `kill_heaviest_task` | true | false | true |
| `thrashing_limit` | 30 | 100 | 100 |
| `swap_util_max` | 80 | 90 | 95 |
| `ro.lmk.low` | 0 | 1001 | 1001 |
| `ro.lmk.medium` | 200 | 900 | 800 |
| `ro.lmk.critical` | 100 | 800 | 0 |

### VM and ZRAM

| Parameter | Performance | Stability | Default |
|---|---|---|---|
| `vm.swappiness` | 60 | 100 | 130 |
| `vm.dirty_ratio` | 20 | 30 | 40 |
| `vm.dirty_background_ratio` | 5 | 10 | 15 |
| `vm.vfs_cache_pressure` | 200 | 100 | 80 |
| ZRAM compression | `lz4` | `zstd` | `zstd` |

On devices with less than 3 GB of RAM, swappiness is automatically increased by 20 and `dirty_background_ratio` is reduced to a minimum of 2 to compensate for the smaller memory pool.

In Stability and Default profiles a background PSI monitor runs every 60 seconds and adjusts swappiness dynamically based on current memory pressure. Performance mode disables this monitor to eliminate any scheduling overhead.

---

## Features

- 🌐 Clean WebUI accessible via MMRL
- 🔁 Settings persist across every reboot via `service.d`
- 🧠 Automatic kernel type detection at boot
- 📊 Dynamic swappiness monitor driven by real-time PSI readings
- 🗜️ ZRAM compression algorithm selection per profile
- 📜 Detailed boot log at `/data/adb/lmk_controller/service.log`
- 🧹 Clean uninstall with automatic boot service removal
- ⚠️ Compatibility check during installation

---

## Requirements

- Android 8.0 or higher
- [Magisk](https://github.com/topjohnwu/Magisk) 20.4+ or [KernelSU](https://github.com/tiann/KernelSU)
- [KSU WebUI](https://github.com/adivenxnataly/KsuWebUI/releases/download/1.0-11/KsuWebUI-1.0-11-release.apk) or any compatible module manager

---

## Installation

1. Download the latest `.zip` from [Releases](https://github.com/ferrdishx/LMK-Controller/releases/latest)
2. Flash via MMRL, Magisk or KernelSU
3. Reboot

The module installs a persistent boot service at `/data/adb/service.d/lmk_controller.sh`. No manual steps are required.

---

## Usage

1. Open MMRL and navigate to LMK Controller
2. Select a profile
3. Tap **Apply Settings**

The selected profile is saved to `/data/adb/modules/lmk_controller_feerd/lmk_mode` and reapplied automatically on every subsequent boot.

---

## Verifying

After rebooting, the following commands confirm that the configuration was applied correctly.

```sh
cat /data/adb/lmk_controller/service.log

cat /data/adb/modules/lmk_controller_feerd/lmk_mode

cat /sys/module/lowmemorykiller/parameters/minfree

getprop ro.lmk.low
getprop ro.lmk.medium
getprop ro.lmk.critical
getprop ro.lmk.psi_partial_stall_ms

cat /proc/sys/vm/swappiness
```

---

## How Boot Persistence Works

The module installs a script into `/data/adb/service.d/`, a directory that Magisk executes on every boot regardless of module state. At boot the script sources `common/psi_lmk.sh`, detects the kernel type, reads the saved profile from `lmk_mode`, and applies the full configuration covering minfree thresholds or `ro.lmk.*` props, VM parameters and ZRAM compression.

For PSI LMKD, after applying props the script signals `lmkd` to reinitialise via `lmkd.reinit`, falls back to `SIGHUP`, and as a last resort performs a stop/start cycle. This avoids requiring a second reboot for property changes to take effect.

When the module is uninstalled, `uninstall.sh` removes the `service.d` entry automatically.

---

## Checking Your Kernel Type Manually

```sh
ls /sys/module/lowmemorykiller/parameters/minfree

cat /proc/pressure/memory

getprop ro.lmk.use_psi
```

The module handles all three cases automatically at boot. These commands are only needed for diagnostic purposes.

---

## Troubleshooting

**Boot log not generated**

```sh
ls -la /data/adb/service.d/lmk_controller.sh
```

If the file is missing, reinstall the module.

**Settings revert after reboot**

Check the boot log. If it reports `ERROR` or `unknown kernel type`, open an issue and attach the full log output.

**WebUI shows wrong profile after reboot**

The interface resets visually on load. This is cosmetic only. The values written to the kernel at boot are correct. Verify by checking the log or running the commands above.

**Kitsune Mask (Magisk Delta)**

Known compatibility issues are under investigation. Standard Magisk and KernelSU are fully supported.

---

## Project Structure

```
LMK-Controller/
├── META-INF/com/google/android/
│   ├── update-binary
│   └── updater-script
├── common/
│   └── psi_lmk.sh
├── webroot/
│   └── index.html
├── module.prop
├── install.sh
├── uninstall.sh
├── lmk_boot.sh
├── post-fs-data.sh
├── service.sh
└── logo.png
```

---

## Changelog

### [v1.3](https://github.com/ferrdishx/LMK-Controller/releases/tag/v1.3) — Apr 25, 2026

**Fixed**

- Performance profile no longer sets all Classic LMK minfree thresholds to zero, which could cause OOM hard bricks on low-RAM devices. Values now follow the same RAM-aware scaling already used by the boot script
- Performance profile on PSI LMKD now enables the critical kill tier (`ro.lmk.critical 100`). Previously this tier was disabled, leaving no safety net before the kernel OOM killer took over
- `ro.lmk.medium` in Performance profile raised from 100 to 200 pages for a more realistic kill threshold
- Same PSI corrections applied to the legacy LMKD path in `service.sh`
- WebUI inline `resetprop` command for Performance profile updated to match the corrected values
- PSI props display grid in the WebUI updated to reflect the new `medium` and `critical` values

### [v1.2-beta](https://github.com/ferrdishx/LMK-Controller/releases/tag/v1.2-beta) — Apr 6, 2026

**Added**

- Full LMKD support: module now detects and handles Classic LMK, PSI LMKD and Legacy LMKD kernels automatically
- `common/psi_lmk.sh` centralised library covering all kernel detection, minfree tuning, PSI prop application, ZRAM compression and VM configuration logic
- Dynamic swappiness monitor driven by real-time PSI readings, active in Stability and Default profiles
- Per-profile ZRAM compression algorithm selection (`lz4` for Performance, `zstd` for Stability and Default)
- RAM-aware minfree scaling with separate value sets for devices under 3 GB, between 3 GB and 5 GB, and above 5 GB

**Fixed**

- Extraction error on install (`! Unzip error`) affecting some Magisk forks
- lmkd reinitialisation now follows a proper fallback sequence: `lmkd.reinit` prop, then `SIGHUP`, then stop/start as a last resort

**Improved**

- Boot log now reports kernel type, total RAM and all final applied values
- Installation output updated with clearer success and error messages

### [v1.1](https://github.com/ferrdishx/LMK-Controller/releases/tag/v1.1) — Apr 5, 2026

**Fixed**

- Extraction error (`Error while unpacking.`) during installation on both flat and nested ZIP structures

**Improved**

- LMKD detection warning during installation made more descriptive
- Added manual kernel compatibility check instructions to README

**Known Issue**

- Kitsune Mask (Magisk Delta) users may experience compatibility issues, under investigation

### [v1.0](https://github.com/ferrdishx/LMK-Controller/releases/tag/v1.0) — Apr 4, 2026

**Initial Release**

- Three tuning profiles: Performance, Stability and Default
- WebUI accessible via MMRL
- Automatic boot persistence via `/data/adb/service.d/`
- Boot log for diagnostics at `/data/adb/modules/lmk_controller_feerd/boot.log`
- Clean uninstall with automatic boot service removal
- Requires Magisk 20.4+ and a kernel with Classic LMK support

---

## Contributors

| | Name | Contribution |
|---|---|---|
| 👤 | George Machen | Beta testing LMKD support on Pixel 4a (5G) |

---

<p align="center">
  Made by <strong>feerd</strong>
  &nbsp;·&nbsp;
  <a href="https://github.com/ferrdishx/LMK-Controller/releases/latest">Download</a>
  &nbsp;·&nbsp;
  <a href="https://t.me/lmkcontrollerchat">Telegram</a>
  &nbsp;·&nbsp;
  <a href="LICENSE">MIT License</a>
</p>
