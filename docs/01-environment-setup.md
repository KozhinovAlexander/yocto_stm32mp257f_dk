# 01 – Environment Setup

This guide prepares your host machine for building Yocto images for the
STM32MP257F-DK board.

---

## Supported Host Operating Systems

| OS | Version | Status |
|----|---------|--------|
| Ubuntu | 22.04 LTS | ✅ Fully supported |
| Ubuntu | 24.04 LTS | ✅ Fully supported |
| Debian | 12 (Bookworm) | ✅ Fully supported |
| Fedora | 38 | ✅ Supported |
| Fedora | 39 | ✅ Supported |
| macOS / Windows | any | ❌ Not supported (use a VM or container) |

> **Recommendation:** Ubuntu 24.04 LTS on bare metal or a VM with KVM acceleration.

---

## Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU cores | 4 | 8–16 |
| RAM | 8 GB | 16–32 GB |
| Disk space | 50 GB | 200 GB |
| Internet | Required | Required |

> The `sstate-cache` alone can exceed 20 GB; the full build tree typically needs
> 60–100 GB of free space.

---

## Install Host Dependencies (Ubuntu / Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
  gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect \
  xz-utils debianutils iputils-ping python3-git python3-jinja2 \
  libegl1-mesa libsdl1.2-dev xterm zstd liblz4-tool file \
  locales libacl1 lz4 python3-subunit

# Generate the en_US.UTF-8 locale (required by BitBake)
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

---

## Install Host Dependencies (Fedora)

```bash
sudo dnf install -y \
  gawk make wget tar bzip2 gzip python3 unzip perl patch \
  diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo \
  chrpath ccache perl-Data-Dumper perl-Text-ParseWords \
  perl-Thread-Queue perl-bignum socat python3-pexpect \
  findutils which file cpio python3-pip xz python3-GitPython \
  python3-jinja2 SDL-devel xterm rpcgen mesa-libGL-devel \
  zstd lz4 libacl
```

---

## Install `kas`

[kas](https://kas.readthedocs.io/) is a build tool that manages layer cloning
and configuration for Yocto projects.

```bash
pip3 install --user kas

# Verify installation
kas --version
```

Add `~/.local/bin` to your `PATH` if it is not already there:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Configure Git

Yocto recipes fetch sources from remote Git repositories. Configure your
identity to avoid warnings during the build:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

---

## Self-Hosted GitHub Actions Runner

The `ci.yml` workflow (full Yocto build) requires a self-hosted runner due to
the large disk requirements (100+ GB).

### 1. Register the Runner

1. Go to **Settings → Actions → Runners** in your GitHub repository.
2. Click **New self-hosted runner** and select **Linux**.
3. Follow the on-screen instructions to download and configure the runner.
4. Add the label `yocto-builder` during configuration.

### 2. Create Persistent Cache Directories

```bash
sudo mkdir -p /srv/yocto/sstate-cache /srv/yocto/downloads
sudo chown -R $(id -u):$(id -g) /srv/yocto
```

These directories are shared across builds to dramatically speed up incremental
builds (from ~5 hours cold → ~20 minutes warm).

### 3. Install Runner as a Service

```bash
cd ~/actions-runner
sudo ./svc.sh install
sudo ./svc.sh start
```

### 4. Install Build Dependencies on the Runner

Follow the [Install Host Dependencies](#install-host-dependencies-ubuntu--debian)
section above on the runner machine as well.

---

## Verify Your Setup

```bash
# Python 3 (required by BitBake)
python3 --version   # expect 3.8 or later

# Git
git --version       # expect 2.x

# kas
kas --version       # expect 4.x or later

# Available disk space
df -h .
```
