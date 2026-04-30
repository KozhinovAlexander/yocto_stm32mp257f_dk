# yocto_stm32mp257f_dk

[![Layer Sanity Check](https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk/actions/workflows/layer-check.yml/badge.svg)](https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk/actions/workflows/layer-check.yml)

A fully documented, buildable Yocto project for the
[STM32MP257F-DK](https://www.st.com/en/evaluation-tools/stm32mp257f-dk.html)
development board, built on **Yocto Scarthgap 5.0 LTS** and inspired by
[Bootlin's Yocto lab tutorial](https://bootlin.com/doc/training/yocto/yocto-stm32mp1-labs.pdf),
adapted to STM32MP2.

---

## Board Specifications

| Feature        | Details                                      |
|----------------|----------------------------------------------|
| SoC            | STM32MP257F (2× Cortex-A35 @ 1.5 GHz + M33) |
| RAM            | 2 GB LPDDR4                                  |
| Storage        | 8 GB eMMC + microSD slot                     |
| Connectivity   | Gigabit Ethernet, WiFi 802.11ac, Bluetooth 5 |
| USB            | 2× USB Type-A (Host), 1× USB Type-C (OTG)   |
| Display        | MIPI DSI connector                           |
| Debug          | UART4/CN14, JTAG/SWD                         |
| Boot modes     | SD card, eMMC, engineering/DFU               |

---

## Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  LEVEL 4 – meta-stm32mp257f-custom (this repo, priority 10)     │
│  Custom image recipe, bbappends, application recipes            │
├─────────────────────────────────────────────────────────────────┤
│  LEVEL 3 – meta-st-openstlinux (priority 8)                     │
│  ST OpenSTLinux distro, Weston/Wayland compositor               │
├─────────────────────────────────────────────────────────────────┤
│  LEVEL 2 – meta-st-stm32mp (priority 7)                         │
│  STM32MP2 BSP: TF-A, OP-TEE, U-Boot, Linux kernel, DTBs        │
├─────────────────────────────────────────────────────────────────┤
│  LEVEL 1 – meta-openembedded (priority 6)                       │
│  meta-oe, meta-python, meta-networking, meta-multimedia,        │
│  meta-filesystems                                               │
├─────────────────────────────────────────────────────────────────┤
│  LEVEL 0 – poky / OE-Core (priority 5)                         │
│  BitBake engine, toolchain, libc, core utilities                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer Registry

| Priority | Layer | Repository | Branch | Role |
|----------|-------|------------|--------|------|
| 10 | `meta-stm32mp257f-custom` | this repo | `main` | Custom image, recipes, bbappends |
| 8  | `meta-st-openstlinux` | [STMicroelectronics/meta-st-openstlinux](https://github.com/STMicroelectronics/meta-st-openstlinux) | `scarthgap` | ST OpenSTLinux distro |
| 7  | `meta-st-stm32mp` | [STMicroelectronics/meta-st-stm32mp](https://github.com/STMicroelectronics/meta-st-stm32mp) | `scarthgap` | STM32MP2 BSP (TF-A, OP-TEE, U-Boot, kernel) |
| 6  | `meta-oe`, `meta-python`, `meta-networking`, `meta-multimedia`, `meta-filesystems` | [openembedded/meta-openembedded](https://github.com/openembedded/meta-openembedded) | `scarthgap` | Extra recipes |
| 5  | `meta`, `meta-poky`, `meta-yocto-bsp` | [yoctoproject/poky](https://github.com/yoctoproject/poky) | `scarthgap` | OE-Core, toolchain, BitBake |

---

## Quick Start

### Option A — kas (recommended)

```bash
# 1. Install kas
pip3 install kas

# 2. Clone this repo
git clone https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk.git
cd yocto_stm32mp257f_dk

# 3. Build (kas handles layer cloning and configuration automatically)
kas build kas/kas-stm32mp257f-dk.yml
```

### Option B — manual

```bash
# 1. Clone this repo and fetch all layers
git clone https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk.git
cd yocto_stm32mp257f_dk
bash scripts/setup-layers.sh

# 2. Initialize build environment
source layers/poky/oe-init-build-env build
cp ../conf/bblayers.conf.sample conf/bblayers.conf
cp ../conf/local.conf.sample    conf/local.conf
# Edit conf/bblayers.conf — replace ##OEROOT## with the absolute path to the repo root

# 3. Build the minimal image
bitbake stm32mp257f-image-minimal
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [01 – Environment Setup](docs/01-environment-setup.md) | Host OS requirements, apt dependencies, kas, Git config, CI runner setup |
| [02 – Layers Architecture](docs/02-layers-architecture.md) | Layer stack, boot chain, WIC partition layout, compatibility matrix |
| [03 – Build Image](docs/03-build-image.md) | kas vs manual build, local.conf tuning, artifacts, troubleshooting |
| [04 – Flashing](docs/04-flashing.md) | DIP switches, SD card, eMMC via STM32CubeProgrammer, serial console |
| [05 – Custom Layer](docs/05-custom-layer.md) | Bootlin-style walkthrough: add recipes, bbappends, kernel fragments |

---

## CI

| Workflow | Runner | Trigger | Purpose |
|----------|--------|---------|---------|
| [layer-check.yml](.github/workflows/layer-check.yml) | `ubuntu-24.04` (GitHub-hosted) | Every push & PR | Validate layer/recipe structure (no full build) |
| [ci.yml](.github/workflows/ci.yml) | `self-hosted, yocto-builder` | Push to `main` & manual | Full Yocto build + artifact upload |

> **Note:** The full CI build (`ci.yml`) requires a self-hosted runner with ≥ 200 GB free disk.
> See [docs/01-environment-setup.md](docs/01-environment-setup.md) for runner registration instructions.

---

## License

This project is licensed under the MIT License. Upstream layers retain their own licenses
(GPLv2 for Linux/U-Boot/TF-A; MIT/Apache-2.0 for OE recipes; ST proprietary EULA for BSP
binary blobs).
