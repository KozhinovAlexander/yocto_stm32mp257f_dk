CURRENT_DIR := $(CURDIR)
BUILD_DIR := $(CURRENT_DIR)/build
SHELL := /bin/bash

# STM32_Programmer_CLI_DIR - shall point to STM32CubeProgrammer installation directory - update if necessary
STM32_Programmer_CLI_DIR ?= $(HOME)/STMicroelectronics/STM32Cube/STM32CubeProgrammer
STM32_Programmer_CLI := $(STM32_Programmer_CLI_DIR)/bin/STM32_Programmer_CLI

# DISTRO variable can be set to one of the following values:
#	openstlinux-weston - default ST's provided linux distribution with GUI
#	openstlinux-rt - real time linux based on  X-LINUX-RT (PREEMPT_RT patchset)
DISTRO ?= openstlinux-rt
POKY_VERSION ?= scarthgap

SOC ?= stm32mp2
BOARD_VARIANT := $(SOC)57f-dk
BOOT_CHAIN := optee

BUILD_TARGET ?= yost32mp25dk-image-minimal
MACHINE ?= yost32mp25dk
ifeq ($(DISTRO),openstlinux-rt)
MACHINE := $(MACHINE)-rt
BOOT_CHAIN := $(BOOT_CHAIN)min
endif

OUT_IMGS_DIR := $(BUILD_DIR)/tmp-glibc/deploy/images/$(MACHINE)
OUT_IMGS_SCRIPT_DIR := $(OUT_IMGS_DIR)/scripts
TSV_DIR := $(OUT_IMGS_DIR)/flashlayout_$(BUILD_TARGET)/$(BOOT_CHAIN)
FLASH_LAYOUT := FlashLayout_sdcard_$(BOARD_VARIANT)-$(BOOT_CHAIN)
FLASH_LAYOUT_RAW_DIR := $(TSV_DIR)/../..

all: build create_sdcard_from_flashlayout

install_dependencies:
	@sudo apt update
	@sudo apt install -y wget git unzip texinfo gcc build-essential \
		socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
		iputils-ping python3-git python3-jinja2 python3-subunit zstd lz4 \
		file locales libacl1 chrpath diffstat g++ gawk cmake make libusb-1.0-0 \
		picocom minicom nfs-kernel-server bmap-tools tftpd-hpa gdisk;

fix_app_armor:
	@echo 0 | sudo tee /proc/sys/kernel/apparmor_restrict_unprivileged_userns

# for choosen modules see: https://github.com/STMicroelectronics/oe-manifest
git_submodules_configure:
	@declare -A modules_map=( \
		["poky"]="https://git.yoctoproject.org/git/poky" \
		["meta-openembedded"]="https://git.openembedded.org/meta-openembedded" \
		["meta-st-stm32mp"]="https://github.com/STMicroelectronics/meta-st-stm32mp" \
		["meta-st-stm32mp-addons"]="https://github.com/STMicroelectronics/meta-st-stm32mp-addons" \
		["meta-st-openstlinux"]="https://github.com/STMicroelectronics/meta-st-openstlinux" \
		["meta-st-x-linux-rt"]="git@github.com:STMicroelectronics/meta-st-x-linux-rt.git" \
	); \
	for key in "$${!modules_map[@]}"; do \
		value="$${modules_map[$$key]}"; \
		pushd $(CURRENT_DIR); \
		git submodule add --force --name $$key $$value $$key; \
		cd $$key && git checkout $(POKY_VERSION); \
		popd; \
	done;
	$(MAKE) git_submodules_update

git_submodules_update:
	git submodule update --init --recursive

env:
	@source $(CURRENT_DIR)/poky/oe-init-build-env

# ACCEPT_EULA_${MACHINE} = "1" - accept EULA, otherwise broken image will be generated
local_conf:
	@conf=$(BUILD_DIR)/conf/local.conf; \
	sed -i '/^DISTRO/d' $$conf && echo 'DISTRO="$(DISTRO)"' >> $$conf; \
	sed -i '/^MACHINE/d' $$conf && echo 'MACHINE="$(MACHINE)"' >> $$conf; \
	sed -i '/^ACCEPT_EULA/d' $$conf && echo 'ACCEPT_EULA_${MACHINE} = "1"' >> $$conf;

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
		$(CURRENT_DIR)/meta-st-x-linux-rt \
		$(CURRENT_DIR)/meta-yost32mp25dk;

fetch_sources:
	@source $(CURRENT_DIR)/poky/oe-init-build-env && bitbake --runall=fetch $(BUILD_TARGET)

build: env local_conf bblayers_configure
	@source $(CURRENT_DIR)/poky/oe-init-build-env && bitbake $(BUILD_TARGET)

create_sdcard_from_flashlayout:
	@rm -f $(FLASH_LAYOUT_RAW_DIR)/$(FLASH_LAYOUT).raw
	@source $(CURRENT_DIR)/poky/oe-init-build-env && \
	$(OUT_IMGS_SCRIPT_DIR)/create_sdcard_from_flashlayout.sh $(TSV_DIR)/$(FLASH_LAYOUT).tsv

# usage: make flash MICROSD_CARD=/dev/sdX
flash:
	@umount $(MICROSD_CARD) || true
	@sudo dd if=$(FLASH_LAYOUT_RAW_DIR)/$(FLASH_LAYOUT).raw \
	of=$(MICROSD_CARD) bs=8M conv=fdatasync status=progress

configure_stm32_programmer:
	@sudo cp $(STM32_Programmer_CLI_DIR)/Drivers/rules/*.rules /etc/udev/rules.d/
	@sudo udevadm control --reload-rules
	@sudo udevadm trigger

flash_stm32_programmer: configure_stm32_programmer
	@set -e; \
	tsvfname=$(FLASH_LAYOUT).tsv; \
	tsvf_dir=$(TSV_DIR); \
	tsvf=$$tsvf_dir/$$tsvfname; \
	tsvf_copy=$$tsvf_dir/../../.$$tsvfname; \
	rm -f $$tsvf_copy; \
	cp $$tsvf $$tsvf_copy ; \
	dev_idx=$$($(STM32_Programmer_CLI) -l usb | grep -o 'USB[0-9]\+'); \
	$(STM32_Programmer_CLI) -c port=$$dev_idx -d $$tsvf_copy; \
	$(STM32_Programmer_CLI) -c port=$$dev_idx --detach; \
	rm -f $$tsvf_copy;

build_u_boot:
	@source $(CURRENT_DIR)/poky/oe-init-build-env; \
	bitbake -c clean u-boot-stm32mp; \
	bitbake u-boot-stm32mp

sdk: env local_conf bblayers_configure
	@source $(CURRENT_DIR)/poky/oe-init-build-env; \
	bitbake $(BUILD_TARGET) -c populate_sdk;

sdk_install:
	@source $(CURRENT_DIR)/poky/oe-init-build-env; \
	sdk_file=$$(ls $(BUILD_DIR)/tmp-glibc/deploy/sdk/$$(MACHINE)*.sh); \
	chmod +x $$sdk_file; \
	$$sdk_file

wipe:
	@git clean -xdf $(CURRENT_DIR)

clean:
	@source $(CURRENT_DIR)/poky/oe-init-build-env && \
	devtool reset $(BUILD_TARGET) && \
	bitbake $(BUILD_TARGET) -c cleansstate; \
	rm -rf $(BUILD_DIR)/conf/local.conf; \
	rm -rf $(BUILD_DIR)/cache;
