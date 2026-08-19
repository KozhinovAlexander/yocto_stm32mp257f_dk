FROM ubuntu:22.04

ARG USER_NAME=yocto
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update \
	&& apt install -y wget git unzip texinfo gcc build-essential \
		socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
		iputils-ping python3-git python3-jinja2 python3-subunit zstd lz4 \
		file locales libacl1 chrpath diffstat g++ gawk cmake make libusb-1.0-0 \
		picocom minicom nfs-kernel-server bmap-tools tftpd-hpa locales gdisk \
	&& apt upgrade -y \
	&& apt clean \
	&& rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN groupadd --gid ${USER_GID} ${USER_NAME} \
	&& useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USER_NAME}

USER ${USER_NAME}
WORKDIR /workspace

CMD ["bash"]
