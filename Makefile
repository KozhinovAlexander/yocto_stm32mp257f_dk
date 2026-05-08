CURRENT_DIR := $(CURDIR)
BUILD_DIR := $(CURRENT_DIR)/build
SHELL := /bin/bash

# STM32_Programmer_CLI_DIR - shall point to STM32CubeProgrammer installation directory - update if necessary
STM32_Programmer_CLI_DIR ?= $(HOME)/STMicroelectronics/STM32Cube/STM32CubeProgrammer
STM32_Programmer_CLI := $(STM32_Programmer_CLI_DIR)/bin/STM32_Programmer_CLI

# DISTRO variable can be set to one of the following values:
#	openstlinux-weston - default ST's provided linux distribution
#	openstlinux-rt - real time linux based on  X-LINUX-RT (PREEMPT_RT patchset)
DISTRO ?= openstlinux-rt

SOC ?= stm32mp2
MACHINE := $(SOC)
BOARD_VARIANT := $(SOC)57f-dk

BUILD_TARGET := st-image-core
BOOT_CHAIN := optee

ifeq ($(DISTRO),openstlinux-rt)
# openstlinux-rt - case, only st-image-core supported
BUILD_TARGET := st-image-core
MACHINE := $(SOC)-rt-perf
BOARD_VARIANT:= $(BOARD_VARIANT)-perf-rt
BOOT_CHAIN := $(BOOT_CHAIN)min
endif

FLASH_LAYOUT := FlashLayout_sdcard_$(BOARD_VARIANT)-$(BOOT_CHAIN)

POKY_VERSION ?= scarthgap
OUT_IMGS_DIR := $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)
OUT_IMGS_SCRIPT_DIR := $(OUT_IMGS_DIR)/scripts


all: fix_app_armor build create_sdcard_from_flashlayout

install_dependencies:
	@sudo apt update
	@sudo apt install -y wget git unzip texinfo gcc build-essential \
		socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
		iputils-ping python3-git python3-jinja2 python3-subunit zstd lz4 \
		file locales libacl1 chrpath diffstat g++ gawk cmake make libusb-1.0-0 \
		picocom minicom nfs-kernel-server bmap-tools

fix_app_armor:
	@echo 0 | sudo tee /proc/sys/kernel/apparmor_restrict_unprivileged_userns

# for choosen modules see: https://github.com/STMicroelectronics/oe-manifest
git_submodules_configure:
	@declare -A modules_map=( \
		["poky"]="https://git.yoctoproject.org/git/poky" \
		["openembedded-core"]="git://git.openembedded.org/openembedded-core" \
		["meta-openembedded"]="https://git.openembedded.org/meta-openembedded" \
		["meta-st-stm32mp"]="https://github.com/STMicroelectronics/meta-st-stm32mp" \
		["meta-st-stm32mp-addons"]="https://github.com/STMicroelectronics/meta-st-stm32mp-addons" \
		["meta-st-openstlinux"]="https://github.com/STMicroelectronics/meta-st-openstlinux" \
		["meta-st-x-linux-rt"]="git@github.com:STMicroelectronics/meta-st-x-linux-rt.git" \
	); \
	for key in "$${!modules_map[@]}"; do \
		value="$${modules_map[$$key]}"; \
		echo "$$key: $$value"; \
	done; \
	git submodule update --init --recursive

env:
	@source $(CURRENT_DIR)/poky/oe-init-build-env

# TODO: use custom layer instead of the target below
# INHERIT += "rm_work" - will remove the package work directory
#	once a package is built to save space on hard drive
# ASSUME_PROVIDED:remove="virtual/crypt-native" - crypt-native will be downloaded and
#	build instead of expected being on the host
local_conf:
	@conf=$(BUILD_DIR)/conf/local.conf; \
	sed -i '/^DISTRO/d' $$conf && echo 'DISTRO="$(DISTRO)"' >> $$conf; \
	sed -i '/^MACHINE/d' $$conf && echo 'MACHINE="$(MACHINE)"' >> $$conf; \
	sed -i '/^INHERIT += "rm_work"/d' $$conf && echo 'INHERIT += "rm_work"' >> $$conf; \
	sed -i '/^ASSUME_PROVIDED:remove="virtual\/crypt-native"/d' $$conf && echo 'ASSUME_PROVIDED:remove="virtual/crypt-native"' >> $$conf; \
	sed -i '/^ACCEPT_EULA_$(MACHINE)="1"/d' $$conf && echo 'ACCEPT_EULA_$(MACHINE)="1"' >> $$conf;

bblayers_configure:
	@source $(CURRENT_DIR)/poky/oe-init-build-env; \
	bitbake-layers add-layer \
		$(CURRENT_DIR)/meta-openembedded/meta-oe \
		$(CURRENT_DIR)/meta-openembedded/meta-python \
		$(CURRENT_DIR)/meta-openembedded/meta-gnome \
		$(CURRENT_DIR)/meta-openembedded/meta-multimedia \
		$(CURRENT_DIR)/meta-openembedded/meta-networking \
		$(CURRENT_DIR)/meta-openembedded/meta-webserver \
		$(CURRENT_DIR)/meta-st-stm32mp \
		$(CURRENT_DIR)/meta-st-openstlinux \
		$(CURRENT_DIR)/meta-st-stm32mp-addons \
		$(CURRENT_DIR)/meta-st-x-linux-rt;

fetch_sources:
	@source $(CURRENT_DIR)/poky/oe-init-build-env && bitbake --runall=fetch $(BUILD_TARGET)

build: env local_conf bblayers_configure
	@source $(CURRENT_DIR)/poky/oe-init-build-env && bitbake $(BUILD_TARGET)

create_sdcard_from_flashlayout:
	@source $(CURRENT_DIR)/poky/oe-init-build-env && $(OUT_IMGS_SCRIPT_DIR)/create_sdcard_from_flashlayout.sh \
	$(OUT_IMGS_DIR)/flashlayout_$(BUILD_TARGET)/$(BOOT_CHAIN)/$(FLASH_LAYOUT).tsv

# usage: make flash MICROSD_CARD=/dev/sdX
flash:
	@umount $(MICROSD_CARD) || true
	@sudo dd if=$(OUT_IMGS_DIR)/flashlayout_$(BUILD_TARGET)/$(BOOT_CHAIN)/$(FLASH_LAYOUT).raw \
	of=$(MICROSD_CARD) bs=8M conv=fdatasync status=progress

configure_stm32_programmer:
	@sudo cp $(STM32_Programmer_CLI_DIR)/Drivers/rules/*.rules /etc/udev/rules.d/
	@sudo udevadm control --reload-rules
	@sudo udevadm trigger

flash_stm32_programmer: configure_stm32_programmer
	@set -e; \
	tsvfname=$(FLASH_LAYOUT).tsv; \
	tsvf_dir=$(OUT_IMGS_DIR)/flashlayout_$(BUILD_TARGET)/$(BOOT_CHAIN); \
	tsvf=$$tsvf_dir/$$tsvfname; \
	tsvf_copy=$$tsvf_dir/../../.$$tsvfname; \
	rm -f $$tsvf_copy; \
	cp $$tsvf $$tsvf_copy ; \
	dev_idx=$$($(STM32_Programmer_CLI) -l usb | grep -o 'USB[0-9]\+'); \
	$(STM32_Programmer_CLI) -c port=$$dev_idx -w $$tsvf_copy -tm 12000; \
	rm -f $$tsvf_copy;

wipe:
	@git clean -xdf $(CURRENT_DIR)

clean:
	@source $(CURRENT_DIR)/poky/oe-init-build-env && \
	devtool reset $(BUILD_TARGET) && \
	bitbake $(BUILD_TARGET) -c cleansstate;
