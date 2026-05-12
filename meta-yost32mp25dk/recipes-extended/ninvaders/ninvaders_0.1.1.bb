DISABLE_STATIC = ""
SUMMARY = "nInvaders is a Space Invaders clone"
DESCRIPTION = "nInvaders is a Space Invaders clone based on ncurses for ASCII output."

HOMEPAGE = "https://ninvaders.sourceforge.net/"
SECTION = "libs"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://gpl.txt;md5=393a5ca445f6965873eca0259a17f833"

PV = "0.1.1"
SRC_URI = "https://deac-fra.dl.sourceforge.net/project/ninvaders/ninvaders/${PV}/ninvaders-${PV}.tar.gz"
SRC_URI[sha256sum] = "bfbc5c378704d9cf5e7fed288dac88859149bee5ed0850175759d310b61fd30b"

DEPENDS = "ncurses"
RDEPENDS:${PN} = "ncurses"

CFLAGS:append = "-O3 -Wall -fcommon"

# Pass the correct compiler and flags to the Makefile
EXTRA_OEMAKE = "CC='${CC}' CFLAGS='${CFLAGS}' LDFLAGS='${LDFLAGS}'"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 nInvaders ${D}${bindir}/${PN}
}

# Specify which files belong to the package
FILES:${PN} = "${bindir}/${PN}"
