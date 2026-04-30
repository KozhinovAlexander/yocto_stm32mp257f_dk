#!/usr/bin/env bash
# setup-layers.sh - Clone (or update) all Yocto layers for STM32MP257F-DK
# Usage: bash scripts/setup-layers.sh
# Run from the repository root.

set -euo pipefail

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAYERS_DIR="${REPO_ROOT}/layers"
BRANCH="scarthgap"

declare -A LAYER_URLS=(
  [poky]="https://github.com/yoctoproject/poky.git"
  [meta-openembedded]="https://github.com/openembedded/meta-openembedded.git"
  [meta-st-stm32mp]="https://github.com/STMicroelectronics/meta-st-stm32mp.git"
  [meta-st-openstlinux]="https://github.com/STMicroelectronics/meta-st-openstlinux.git"
)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
info "Setting up Yocto layers for STM32MP257F-DK (branch: ${BRANCH})"
mkdir -p "${LAYERS_DIR}"

for layer in "${!LAYER_URLS[@]}"; do
  url="${LAYER_URLS[$layer]}"
  dest="${LAYERS_DIR}/${layer}"

  if [ -d "${dest}/.git" ]; then
    info "Updating existing layer: ${layer}"
    git -C "${dest}" fetch origin "${BRANCH}" \
      || warn "fetch failed for ${layer}, continuing with current state"
    git -C "${dest}" reset --hard "origin/${BRANCH}" \
      || warn "reset failed for ${layer}, continuing with current state"
  else
    info "Cloning ${layer} from ${url}"
    git clone --branch "${BRANCH}" --single-branch "${url}" "${dest}" \
      || error "Failed to clone ${layer}"
  fi
done

# ---------------------------------------------------------------------------
# Symlink the custom layer into layers/
# ---------------------------------------------------------------------------
CUSTOM_LAYER_SRC="${REPO_ROOT}/meta-stm32mp257f-custom"
CUSTOM_LAYER_LINK="${LAYERS_DIR}/meta-stm32mp257f-custom"

if [ ! -d "${CUSTOM_LAYER_SRC}" ]; then
  error "Custom layer directory not found: ${CUSTOM_LAYER_SRC}"
fi

if [ -L "${CUSTOM_LAYER_LINK}" ]; then
  info "Symlink already exists: ${CUSTOM_LAYER_LINK}"
elif [ -d "${CUSTOM_LAYER_LINK}" ]; then
  warn "${CUSTOM_LAYER_LINK} is a real directory, not a symlink — leaving as-is"
else
  ln -s "${CUSTOM_LAYER_SRC}" "${CUSTOM_LAYER_LINK}"
  info "Created symlink: ${CUSTOM_LAYER_LINK} -> ${CUSTOM_LAYER_SRC}"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
info "All layers ready in: ${LAYERS_DIR}"
echo ""
echo "  Next steps:"
echo "    source layers/poky/oe-init-build-env build"
echo "    cp conf/bblayers.conf.sample  build/conf/bblayers.conf"
echo "    cp conf/local.conf.sample     build/conf/local.conf"
echo "    # Edit build/conf/bblayers.conf and replace ##OEROOT## with:"
echo "    #   $(realpath "${REPO_ROOT}")"
echo "    bitbake stm32mp257f-image-minimal"
echo ""
