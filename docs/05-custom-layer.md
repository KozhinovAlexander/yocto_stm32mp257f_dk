# 05 – Custom Layer

This guide walks you through the `meta-stm32mp257f-custom` layer included in
this repository, following the style of Bootlin's Yocto lab tutorial adapted
for STM32MP2 / Scarthgap.

---

## Why a Custom Layer?

**Never modify upstream layers.** Upstream layers (`meta-st-stm32mp`,
`meta-openembedded`, `poky`) receive regular updates and security fixes.
Modifying them directly makes updates painful and creates merge conflicts.

Instead, create a custom layer that:

- **Overrides** upstream recipes with `.bbappend` files
- **Adds** new recipes without touching upstream code
- Is versioned in your own repository (this repo)

---

## Layer Structure

```
meta-stm32mp257f-custom/
├── conf/
│   └── layer.conf                          ← Layer metadata and priority
├── recipes-bsp/
│   └── u-boot/
│       └── u-boot-stm32mp257f_%.bbappend   ← Board U-Boot extensions
└── recipes-core/
    └── images/
        └── stm32mp257f-image-minimal.bb    ← Custom image recipe
```

---

## `layer.conf` Explained

```bitbake
# Add this layer directory to BBPATH so BitBake finds recipes
BBPATH .= ":${LAYERDIR}"

# Tell BitBake where to find .bb and .bbappend files
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
             ${LAYERDIR}/recipes-*/*/*.bbappend"

# Unique collection name
BBFILE_COLLECTIONS += "stm32mp257f-custom"

# Filename pattern that belongs to this collection
BBFILE_PATTERN_stm32mp257f-custom = "^${LAYERDIR}/"

# Priority 10 overrides all upstream layers (max default is ~8)
BBFILE_PRIORITY_stm32mp257f-custom = "10"

# Declare Yocto release compatibility
LAYERSERIES_COMPAT_stm32mp257f-custom = "scarthgap"

# Declare dependencies: OE-Core ("core") and the ST BSP layer
LAYERDEPENDS_stm32mp257f-custom = "core meta-st-stm32mp"
```

---

## Custom Image Recipe

`recipes-core/images/stm32mp257f-image-minimal.bb` builds on ST's
`st-image-core.bb` and adds extra packages:

```bitbake
SUMMARY = "Minimal custom image for STM32MP257F-DK"
DESCRIPTION = "Console image with SSH, networking tools, and custom apps."

require recipes-core/images/st-image-core.bb

IMAGE_INSTALL:append = " \
    packagegroup-core-ssh-dropbear \
    i2c-tools \
    iproute2 \
    ethtool \
    htop \
    nano \
    tcpdump \
"

EXTRA_IMAGE_FEATURES += "debug-tweaks"
IMAGE_BASENAME = "stm32mp257f-image-minimal"
```

Build it with:

```bash
bitbake stm32mp257f-image-minimal
```

---

## Hello World Application Recipe

Create a simple C application recipe:

**`recipes-apps/hello-stm32/hello-stm32.bb`**

```bitbake
SUMMARY = "Hello World for STM32MP257F-DK"
DESCRIPTION = "Minimal C application demonstrating a custom recipe."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://hello-stm32.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o hello-stm32 hello-stm32.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 hello-stm32 ${D}${bindir}/
}
```

Place the C source in `recipes-apps/hello-stm32/files/hello-stm32.c`:

```c
#include <stdio.h>
int main(void) {
    printf("Hello from STM32MP257F-DK!\n");
    return 0;
}
```

Add to image: `IMAGE_INSTALL:append = " hello-stm32"`

---

## Kernel Configuration Fragment

To enable a kernel driver without forking the kernel recipe, use a config
fragment in a `.bbappend`:

**`recipes-kernel/linux/linux-stm32mp_%.bbappend`**

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://enable-can.cfg"
```

**`recipes-kernel/linux/files/enable-can.cfg`**

```
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_FLEXCAN=y
```

---

## U-Boot `.bbappend`

`recipes-bsp/u-boot/u-boot-stm32mp257f_%.bbappend` extends the upstream U-Boot
recipe for this board:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Uncomment to add a custom U-Boot patch or environment file:
# SRC_URI += "file://0001-stm32mp257f-dk-custom-env.patch"
```

Place patches in `recipes-bsp/u-boot/files/`.

---

## External Git Repository Recipe

For an application hosted in a Git repository, use `SRCREV` and `inherit
autotools pkgconfig`:

```bitbake
SUMMARY     = "My STM32 Daemon"
LICENSE     = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=..."

SRC_URI  = "git://github.com/example/my-stm32-daemon.git;branch=main;protocol=https"
SRCREV   = "abc123deadbeefabc123deadbeefabc123deadbe"

S = "${WORKDIR}/git"

inherit autotools pkgconfig systemd

SYSTEMD_SERVICE:${PN} = "my-stm32-daemon.service"

do_install:append() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${S}/my-stm32-daemon.service \
                    ${D}${systemd_unitdir}/system/
}
```

---

## Packagegroup Recipe

Group related packages into a packagegroup for reuse across images:

**`recipes-core/packagegroups/packagegroup-stm32mp-tools.bb`**

```bitbake
SUMMARY = "STM32MP257F development tools"
inherit packagegroup

RDEPENDS:${PN} = " \
    i2c-tools       \
    spidev-test     \
    devmem2         \
    ethtool         \
    iproute2        \
    tcpdump         \
    htop            \
    nano            \
"
```

Add to your image: `IMAGE_INSTALL:append = " packagegroup-stm32mp-tools"`

---

## Pre-submission Checklist

Before committing your layer changes to a shared branch, verify:

- [ ] `layer.conf` has `LAYERSERIES_COMPAT_stm32mp257f-custom = "scarthgap"`
- [ ] `BBFILE_PRIORITY` is set and does not collide with other custom layers
- [ ] All recipes have a valid `LICENSE` and `LIC_FILES_CHKSUM`
- [ ] `SRCREV` is pinned to a specific commit (no floating branches)
- [ ] `SRC_URI` checksums (`md5`/`sha256`) are present for all local files
- [ ] `do_install` uses `${D}${bindir}` (not hardcoded paths)
- [ ] No `SRC_URI` points to `localhost` or a private host
- [ ] `bitbake-layers show-recipes <your-recipe>` shows only your layer
- [ ] `bitbake <your-recipe>` completes without QA warnings
- [ ] The `layer-check.yml` CI workflow passes on GitHub
