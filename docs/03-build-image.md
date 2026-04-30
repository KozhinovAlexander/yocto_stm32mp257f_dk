# 03 – Build Image

This guide explains how to build the `stm32mp257f-image-minimal` Yocto image
for the STM32MP257F-DK board.

---

## Option A – kas (Recommended)

[kas](https://kas.readthedocs.io/) handles layer cloning and configuration
automatically from a single YAML file.

```bash
# Install kas (once)
pip3 install --user kas

# Clone this repo
git clone https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk.git
cd yocto_stm32mp257f_dk

# Build (kas clones layers, writes bblayers.conf/local.conf, and runs bitbake)
kas build kas/kas-stm32mp257f-dk.yml
```

The first build takes 4–8 hours on an 8-core machine. Subsequent builds with a
warm `sstate-cache` complete in 15–30 minutes.

---

## Option B – Manual Build

### Step 1: Clone All Layers

```bash
git clone https://github.com/KozhinovAlexander/yocto_stm32mp257f_dk.git
cd yocto_stm32mp257f_dk
bash scripts/setup-layers.sh
```

The script clones all upstream layers into `./layers/` and symlinks
`meta-stm32mp257f-custom` into `layers/`.

### Step 2: Initialise the Build Environment

```bash
source layers/poky/oe-init-build-env build
```

This creates the `build/` directory and sets up environment variables.

### Step 3: Copy Sample Configuration

```bash
# From inside the build/ directory:
cp ../conf/bblayers.conf.sample conf/bblayers.conf
cp ../conf/local.conf.sample    conf/local.conf
```

Edit `conf/bblayers.conf` and replace every occurrence of `##OEROOT##` with
the absolute path to the repository root. For example:

```bash
sed -i "s|##OEROOT##|$(realpath ..)|g" conf/bblayers.conf
```

### Step 4: Build

```bash
bitbake stm32mp257f-image-minimal
```

---

## Tuning `local.conf`

| Variable | Default | Purpose |
|----------|---------|---------|
| `BB_NUMBER_THREADS` | `cpu_count()` | Number of BitBake tasks run in parallel |
| `PARALLEL_MAKE` | `-j<cpu_count>` | Make jobs per recipe |
| `DL_DIR` | `${TOPDIR}/../downloads` | Shared download cache |
| `SSTATE_DIR` | `${TOPDIR}/../sstate-cache` | Shared state cache (speeds up rebuilds) |
| `TMPDIR` | `${TOPDIR}/tmp` | Temporary build directory |

Recommended overrides for a large machine:

```bitbake
BB_NUMBER_THREADS = "16"
PARALLEL_MAKE     = "-j16"
DL_DIR     = "/srv/yocto/downloads"
SSTATE_DIR = "/srv/yocto/sstate-cache"
```

---

## Deploy Artifacts

After a successful build, artifacts are in:

```
build/tmp/deploy/images/stm32mp257f-dk/
```

| File | Description |
|------|-------------|
| `stm32mp257f-image-minimal-stm32mp257f-dk.rootfs.wic.xz` | Compressed disk image (SD/eMMC) |
| `tf-a-stm32mp257f-dk.stm32` | TF-A BL2 binary |
| `fip-stm32mp257f-dk-optee.bin` | FIP (OP-TEE + U-Boot) |
| `Image` | Linux kernel image |
| `stm32mp257f-dk.dtb` | Device tree blob |
| `flashlayout_stm32mp257f-image-minimal/FlashLayout_emmc_*.tsv` | eMMC flashlayout for STM32CubeProgrammer |

---

## Useful BitBake Commands

```bash
# Show all recipes provided by visible layers
bitbake-layers show-recipes

# Show layer stack with priorities
bitbake-layers show-layers

# List all tasks for a recipe
bitbake stm32mp257f-image-minimal -c listtasks

# Open an interactive shell inside a recipe's build environment
bitbake stm32mp257f-image-minimal -c devshell

# Invalidate sstate and force a full recipe rebuild
bitbake stm32mp257f-image-minimal -c cleansstate && bitbake stm32mp257f-image-minimal

# Open kernel menuconfig
bitbake virtual/kernel -c menuconfig

# Generate the cross-compilation SDK / toolchain
bitbake stm32mp257f-image-minimal -c populate_sdk

# Show all variables for a recipe (useful for debugging)
bitbake -e stm32mp257f-image-minimal | grep "^IMAGE_INSTALL"
```

---

## SDK / Cross-Toolchain

Generate an installable SDK tarball:

```bash
bitbake stm32mp257f-image-minimal -c populate_sdk
```

The SDK installer is placed in `build/tmp/deploy/sdk/`. Run it on any
Ubuntu/Debian machine to get a self-contained `aarch64-poky-linux` toolchain:

```bash
chmod +x poky-glibc-x86_64-stm32mp257f-image-minimal-cortexa35-toolchain-5.0.sh
./poky-glibc-x86_64-stm32mp257f-image-minimal-cortexa35-toolchain-5.0.sh
source /opt/poky/5.0/environment-setup-cortexa35-poky-linux
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `No space left on device` | Disk full | Free ≥ 50 GB; move `TMPDIR`, `DL_DIR`, `SSTATE_DIR` to a larger partition |
| `Fetcher failure` for GitHub URLs | Network or rate-limit | Set `BB_NO_NETWORK = "0"` and retry; or pre-populate `DL_DIR` |
| `Please set a valid MACHINE` | `local.conf` not copied or edited | Copy `conf/local.conf.sample` and verify `MACHINE = "stm32mp257f-dk"` |
| `ERROR: Layer 'meta-st-stm32mp' is not compatible` | Wrong branch cloned | Run `scripts/setup-layers.sh` to reset all layers to `scarthgap` |
| `QA Issue: … installed but not in any package` | Missing `FILES_*` in recipe | Add the path to `FILES_${PN}` in your `.bb` file |
| Build hangs at `Sstate: …` | Network timeout fetching sstate mirror | Set `BB_NO_NETWORK = "1"` or configure a local sstate mirror |
| `ACCEPT_EULA` error | EULA not accepted | Add `ACCEPT_EULA_stm32mp257f-dk = "1"` to `local.conf` |
