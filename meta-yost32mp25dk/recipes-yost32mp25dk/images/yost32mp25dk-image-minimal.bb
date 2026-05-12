SUMMARY = "OpenSTLinux core image."
LICENSE = "Apache-2.0"

include recipes-st/images/st-image.inc

inherit core-image

IMAGE_LINGUAS = "en-us"

hostname = "yost32mp25dk"

IMAGE_FEATURES += "\
    package-management  \
    ssh-server-dropbear \
    hwcodecs            \
    tools-profile       \
    "

IMAGE_FEATURES:remove = " \
    splash \
    dropbear \
    "

#
# INSTALL addons
#
CORE_IMAGE_EXTRA_INSTALL += " \
    resize-helper \
    packagegroup-framework-core-base \
    packagegroup-framework-tools-base \
    packagegroup-core-ssh-dropbear \
    packagegroup-yost32mp25dk-apps \
    packagegroup-yost32mp25dk-games \
    ${@bb.utils.contains('COMBINED_FEATURES', 'optee', 'packagegroup-optee-core', '', d)} \
    ${@bb.utils.contains('COMBINED_FEATURES', 'optee', 'packagegroup-optee-test', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'm33td', 'm33td-reset', '', d)} \
    tcpdump \
    "
