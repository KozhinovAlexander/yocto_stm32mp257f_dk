SUMMARY = "Custom sample image for STM32MP257F-DK"
DESCRIPTION = "A custom sample Yocto image for the STM32MP257F-DK evaluation board \
               featuring a full command-line environment with development and debug tools."
HOMEPAGE = "https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk"
LICENSE = "MIT"

inherit core-image

# =========================================================================
# Image features
# =========================================================================
IMAGE_FEATURES += "ssh-server-openssh"
IMAGE_FEATURES += "tools-debug"
IMAGE_FEATURES += "tools-profile"
IMAGE_FEATURES += "package-management"

# =========================================================================
# Additional packages
# =========================================================================
IMAGE_INSTALL:append = " \
    packagegroup-core-full-cmdline \
    i2c-tools \
    usbutils \
    iproute2 \
    ethtool \
    iperf3 \
    can-utils \
    python3 \
    python3-pip \
    htop \
    nano \
    git \
    curl \
    wget \
    strace \
    gdb \
    util-linux \
    e2fsprogs \
"
