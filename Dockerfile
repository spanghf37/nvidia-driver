FROM registry.access.redhat.com/ubi8/ubi:8.2


ARG DRIVER_VERSION
ENV DRIVER_VERSION=${DRIVER_VERSION:-440.64.00}

ARG BASE_URL
ENV BASE_URL=${BASE_URL:-https://us.download.nvidia.com/tesla}

ARG PUBLIC_KEY
ENV PUBLIC_KEY=${PUBLIC_KEY:-empty}

ARG PRIVATE_KEY

ARG KERNEL_VERSION
ENV KERNEL_VERSION=${KERNEL_VERSION:-4.18.0-147.3.1.el8_1.x86_64}

COPY nvidia-driver-disconnected /usr/local/bin/nvidia-driver-disconnected

# Required to build on specific RHCOS kernel version (not RHEL kernel version)
RUN yum config-manager --set-enabled rhel-8-for-x86_64-baseos-eus-rpms

# Required to build on specific RHCOS kernel version (not RHEL kernel version)
RUN dnf install -y "kernel-headers-${KERNEL_VERSION}" "kernel-devel-${KERNEL_VERSION}" --releasever=8.2

# Required to build on specific RHCOS kernel version (not RHEL kernel version)
RUN yum config-manager --set-disabled rhel-8-for-x86_64-baseos-eus-rpms

RUN dnf install --setopt tsflags=nodocs -y ca-certificates curl gcc glibc.i686 make cpio kmod \
    elfutils-libelf elfutils-libelf-devel \
    && rm -rf /var/cache/yum/*

RUN curl -fsSL -o /usr/local/bin/donkey https://github.com/3XX0/donkey/releases/download/v1.1.0/donkey \
    && curl -fsSL -o /usr/local/bin/extract-vmlinux https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux \
    && chmod +x /usr/local/bin/donkey /usr/local/bin/extract-vmlinux

RUN ln -s /sbin/ldconfig /sbin/ldconfig.real \
 && chmod +x /usr/local/bin/nvidia-driver-disconnected \
 && ln -sf /usr/local/bin/nvidia-driver-disconnected /usr/local/bin/nvidia-driver

RUN cd /tmp \
    && curl -fSslL -O $BASE_URL/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run \
    && sh NVIDIA-Linux-x86_64-$DRIVER_VERSION.run -x \
    && cd NVIDIA-Linux-x86_64-$DRIVER_VERSION \
    && ./nvidia-installer --silent --no-kernel-module --install-compat32-libs --no-nouveau-check --no-nvidia-modprobe \
       --no-rpms --no-backup --no-check-for-alternate-installs --no-libglx-indirect --no-install-libglvnd --x-prefix=/tmp/null \
       --x-module-path=/tmp/null --x-library-path=/tmp/null --x-sysconfig-path=/tmp/null \
    && mkdir -p /usr/src/nvidia-$DRIVER_VERSION \
    && mv LICENSE mkprecompiled kernel /usr/src/nvidia-$DRIVER_VERSION \
    && sed '9,${/^\(kernel\|LICENSE\)/!d}' .manifest > /usr/src/nvidia-$DRIVER_VERSION/.manifest \
    && rm -rf /tmp/* \
    # Required to build on specific RHCOS kernel version (not RHEL kernel version)
    && yum config-manager --set-enabled rhel-8-for-x86_64-baseos-eus-rpms \
    # Required to build on specific RHCOS kernel version (not RHEL kernel version)
    && dnf download -y kernel-core-${KERNEL_VERSION} --downloaddir=/tmp/ --releasever=8.2 \
    && rm -rf /var/cache/yum

WORKDIR /usr/src/nvidia-$DRIVER_VERSION

COPY ${PUBLIC_KEY} kernel/pubkey.x509

RUN mkdir -p /run/nvidia \
 && touch /run/nvidia/nvidia-driver.pid

# This will really run the disconnected version
ENTRYPOINT ["nvidia-driver, "init"]

