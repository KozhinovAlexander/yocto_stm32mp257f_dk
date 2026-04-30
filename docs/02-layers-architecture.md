# 02 – Layers Architecture

This document describes the Yocto layer stack used to build the STM32MP257F-DK
image, the boot chain, and the WIC partition layout.

---

## Layer Stack Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  LEVEL 4 – meta-stm32mp257f-custom            (priority 10)         │
│                                                                     │
│  • stm32mp257f-image-minimal.bb  (custom image)                     │
│  • u-boot-stm32mp257f_%.bbappend (board U-Boot config)              │
│  • Application recipes and packagegroups                            │
├─────────────────────────────────────────────────────────────────────┤
│  LEVEL 3 – meta-st-openstlinux               (priority 8)           │
│                                                                     │
│  • openstlinux-weston DISTRO definition                             │
│  • Weston/Wayland compositor recipes                                │
│  • ST-specific EULA handling                                        │
├─────────────────────────────────────────────────────────────────────┤
│  LEVEL 2 – meta-st-stm32mp                   (priority 7)           │
│                                                                     │
│  • MACHINE = stm32mp257f-dk definition                              │
│  • TF-A BL2 (Trusted Firmware-A)                                    │
│  • OP-TEE secure OS                                                 │
│  • U-Boot 2023.x bootloader                                         │
│  • Linux 6.x kernel + STM32MP2 device trees                        │
│  • WIC image partitioning (FlashLayout TSV)                         │
├─────────────────────────────────────────────────────────────────────┤
│  LEVEL 1 – meta-openembedded                  (priority 6)          │
│                                                                     │
│  • meta-oe          – hundreds of extra recipes                     │
│  • meta-python      – Python 3 packages                             │
│  • meta-networking  – network tools (iproute2, tcpdump, etc.)       │
│  • meta-multimedia  – GStreamer, codecs                             │
│  • meta-filesystems – ext4, btrfs, squashfs helpers                 │
├─────────────────────────────────────────────────────────────────────┤
│  LEVEL 0 – poky / OE-Core                    (priority 5)           │
│                                                                     │
│  • meta             – OE-Core recipes (busybox, glibc, openssl, …)  │
│  • meta-poky        – Poky distro definitions                       │
│  • meta-yocto-bsp   – Reference BSP machines                        │
│  • BitBake build engine                                             │
│  • Cross-compilation toolchain (aarch64-poky-linux)                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Layer Registry

| # | Layer | Repository | Branch | Role |
|---|-------|------------|--------|------|
| 0a | `meta` | [yoctoproject/poky](https://github.com/yoctoproject/poky) | `scarthgap` | OE-Core recipes, toolchain |
| 0b | `meta-poky` | [yoctoproject/poky](https://github.com/yoctoproject/poky) | `scarthgap` | Poky distro config |
| 0c | `meta-yocto-bsp` | [yoctoproject/poky](https://github.com/yoctoproject/poky) | `scarthgap` | Reference BSP machines |
| 1a | `meta-oe` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Extra recipes |
| 1b | `meta-python` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Python 3 packages |
| 1c | `meta-networking` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Network tools |
| 1d | `meta-multimedia` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Multimedia/GStreamer |
| 1e | `meta-filesystems` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Filesystem tools |
| 2  | `meta-st-stm32mp` | [STMicroelectronics/meta-st-stm32mp](https://github.com/STMicroelectronics/meta-st-stm32mp) | `scarthgap` | STM32MP2 BSP |
| 3  | `meta-st-openstlinux` | [STMicroelectronics/meta-st-openstlinux](https://github.com/STMicroelectronics/meta-st-openstlinux) | `scarthgap` | ST OpenSTLinux distro |
| 4  | `meta-stm32mp257f-custom` | [KozhinovAlexander/yocto_stm32mp257f_dk](https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk) | `main` | Custom layer (this repo) |

---

## Boot Chain

```
Power-on
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Boot ROM (read-only, on-chip)                                  │
│  Selects boot device from DIP switches → loads TF-A BL2        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  TF-A BL2 (Trusted Firmware-A, first-stage bootloader)          │
│  • Runs in EL3 (Secure Privilege Level 3)                       │
│  • Initialises DRAM controller, loads OP-TEE and U-Boot FIP     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  OP-TEE (Open Portable Trusted Execution Environment)           │
│  • Secure OS running in TrustZone                               │
│  • Provides TEE services to the normal world                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  U-Boot (second-stage bootloader)                               │
│  • Runs in EL2 / normal world                                   │
│  • Initialises peripherals, loads kernel + DTB from bootfs      │
│  • Passes device tree to Linux                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Linux 6.x Kernel                                               │
│  • Boots from kernel Image + stm32mp257f-dk.dtb                 │
│  • Mounts rootfs from eMMC / SD card                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Root File System (rootfs)                                      │
│  • systemd, Weston, dropbear SSH, custom applications           │
└─────────────────────────────────────────────────────────────────┘
```

---

## WIC Partition Layout

The ST BSP generates a WIC image (`.wic.xz`) with the following partition layout
(for eMMC boot):

| # | Partition | FS / Type | Contents |
|---|-----------|-----------|---------|
| 1 | `fsbl1` | raw binary | TF-A BL2 (first copy) |
| 2 | `fsbl2` | raw binary | TF-A BL2 (redundant copy) |
| 3 | `fip` | raw binary | FIP image (OP-TEE + U-Boot) |
| 4 | `bootfs` | FAT32 | `Image`, `*.dtb`, U-Boot environment |
| 5 | `vendorfs` | ext4 | ST vendor firmware blobs |
| 6 | `rootfs` | ext4 | Root file system |
| 7 | `userfs` | ext4 | Persistent user data |

The flashlayout `FlashLayout_emmc_*.tsv` (auto-generated in
`tmp/deploy/images/stm32mp257f-dk/`) describes the partitions and is consumed
directly by STM32CubeProgrammer.

---

## Yocto Release Compatibility

| Yocto Release | Codename | STM32MP2 / MP257 | Notes |
|---------------|----------|------------------|-------|
| 5.0 | **Scarthgap** | ✅ Fully supported | LTS until April 2026 |
| 4.3 | Nanbield | ⚠️ Partial | `meta-st-stm32mp` support limited |
| 4.0 | Kirkstone | ❌ No STM32MP2 | STM32MP1 only |
| 3.4 | Honister | ❌ No STM32MP2 | STM32MP1 only |

> **Always use the `scarthgap` branch** of all layers listed in the registry.

---

## How BitBake Resolves Recipe Priorities

When two layers provide a recipe with the same name, BitBake uses
`BBFILE_PRIORITY` to decide which one wins:

```
Higher number = higher priority = wins the conflict
```

Example: `meta-stm32mp257f-custom` (priority 10) can override any recipe
from `meta-st-stm32mp` (priority 7) simply by placing a `.bbappend` or a
replacement `.bb` in the custom layer.

The priority is set in `meta-stm32mp257f-custom/conf/layer.conf`:

```bitbake
BBFILE_PRIORITY_stm32mp257f-custom = "10"
```
