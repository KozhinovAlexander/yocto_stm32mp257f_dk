# yocto_stm32mp257f_dk

A custom sample Yocto image for the [STM32MP257F-DK](https://www.st.com/en/evaluation-tools/stm32mp257f-dk.html) evaluation board, built with [Yocto Project Scarthgap (5.0)](https://docs.yoctoproject.org/5.0/) and the [STMicroelectronics BSP layer](https://github.com/STMicroelectronics/meta-st-stm32mp).

## Board Overview

The STM32MP257F-DK Discovery Kit is based on the STM32MP257F microprocessor featuring:
- Dual-core Arm® Cortex®-A35 @ up to 1.5 GHz
- Arm® Cortex®-M33 coprocessor @ up to 400 MHz
- Arm® Mali-C55 GPU
- Wi-Fi® 802.11 b/g/n/ac and Bluetooth® 5.0

## Repository Structure

```
.
├── kas/
│   └── custom-image.yml         # Kas build configuration
├── meta-custom-stm32mp257f/     # Custom Yocto layer
│   ├── conf/
│   │   └── layer.conf           # Layer configuration
│   └── recipes-core/
│       └── images/
│           └── custom-image.bb  # Custom image recipe
└── README.md
```

## What Is Built

The `custom-image` recipe produces a Linux system image for the STM32MP257F-DK board that includes:

- Full command-line environment (`packagegroup-core-full-cmdline`)
- OpenSSH server (remote access)
- Debug and profiling tools (`strace`, `gdb`, tools-debug, tools-profile)
- Package manager (opkg)
- Networking utilities (`iproute2`, `ethtool`, `iperf3`, `curl`, `wget`)
- Hardware debug tools (`i2c-tools`, `usbutils`, `can-utils`)
- Development tools (`git`, `python3`, `python3-pip`, `nano`)
- System utilities (`htop`, `util-linux`, `e2fsprogs`)
- systemd init system

## Prerequisites

### Host System Requirements

- Ubuntu 22.04 LTS or later (recommended)
- At least **100 GB** of free disk space
- At least **8 GB** of RAM (16 GB+ recommended)

### Required Host Packages

Install the required packages on Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev xterm python3-subunit mesa-common-dev \
    zstd liblz4-tool file locales libacl1
```

### Install kas

[kas](https://kas.readthedocs.io/) is used to manage the Yocto layers and build configuration:

```bash
pip3 install kas
```

## Build Instructions

### 1. Clone this repository

```bash
git clone https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk.git
cd yocto_stm32mp257f_dk
```

### 2. Build the image

```bash
kas build kas/custom-image.yml
```

kas will automatically:
1. Fetch all required layers (poky, meta-openembedded, meta-st-stm32mp)
2. Configure the build environment
3. Build the `custom-image` for the `stm32mp25-disco` machine

### 3. Locate the output image

After a successful build, the image artifacts are located at:

```
build/tmp/deploy/images/stm32mp25-disco/
```

The default image archive (enabled by `IMAGE_FSTYPES += "tar.gz"` in the kas config) is:

```
build/tmp/deploy/images/stm32mp25-disco/custom-image-stm32mp25-disco.tar.gz
```

To produce a raw SD card image (`.wic`), see the [Flashing the SD Card](#flashing-the-sd-card) section below.

## Flashing the SD Card

### Using bmaptool (recommended)

```bash
# Install bmaptool
sudo apt-get install bmap-tools

# Flash the image (replace /dev/sdX with your SD card device)
sudo bmaptool copy \
    build/tmp/deploy/images/stm32mp25-disco/custom-image-stm32mp25-disco.wic.bz2 \
    /dev/sdX
```

### Using dd

```bash
bzcat build/tmp/deploy/images/stm32mp25-disco/custom-image-stm32mp25-disco.wic.bz2 \
    | sudo dd of=/dev/sdX bs=4M status=progress conv=fdatasync
```

> **Note:** To generate a `.wic` SD card image, enable WIC output by adding the following to your `kas/custom-image.yml` under `local_conf_header`:
> ```
> IMAGE_FSTYPES += "wic wic.bz2 wic.bmap"
> WKS_FILE = "${OPTEE_WIC_FILE}"
> ```

## Accessing the Board

### Serial Console

Connect to the board via the micro-USB debug port:

```bash
sudo minicom -D /dev/ttyUSB0 -b 115200
```

### SSH Access

After boot, connect over the network (DHCP assigned IP by default):

```bash
ssh root@<board-ip-address>
```

No password is set by default (add one or configure SSH keys via a `bbappend` to `shadow`).

## Customising the Image

### Adding Packages

Edit `meta-custom-stm32mp257f/recipes-core/images/custom-image.bb` and add your package names to `IMAGE_INSTALL:append`:

```bitbake
IMAGE_INSTALL:append = " \
    my-package \
"
```

### Adding a New Layer

Add the layer repository to `kas/custom-image.yml` under `repos`:

```yaml
repos:
  my-extra-layer:
    url: https://github.com/example/meta-my-layer
    branch: scarthgap
```

Then add the layer path to `BBLAYERS` via the `layers:` key.

### Accepting the ST EULA

The build requires acceptance of the STMicroelectronics EULA to include proprietary firmware (GPU drivers, Wi-Fi/BT firmware, etc.).  
This is handled automatically by the `ACCEPT_EULA_stm32mp25-disco = "1"` setting in `kas/custom-image.yml`.  
Review the EULA at `layers/meta-st-stm32mp/conf/eula/stm32mp25-disco` before accepting.

## References

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [meta-st-stm32mp BSP layer](https://github.com/STMicroelectronics/meta-st-stm32mp)
- [kas documentation](https://kas.readthedocs.io/)
- [STM32MP257F-DK product page](https://www.st.com/en/evaluation-tools/stm32mp257f-dk.html)
- [STM32MP25 Wiki](https://wiki.st.com/stm32mpu/wiki/STM32MP25_microprocessor)
