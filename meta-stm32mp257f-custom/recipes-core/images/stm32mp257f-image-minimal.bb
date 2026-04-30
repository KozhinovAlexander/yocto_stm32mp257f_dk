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
