#!/bin/bash -xe

# See the README file for a description of these variables
# Tesla based card:
# BASE_URL='https://us.download.nvidia.com/tesla'

# Quadro card:
BASE_URL='https://us.download.nvidia.com/XFree86/Linux-x86_64'

KERNEL_VERSION='4.18.0-193.29.1.el8_2.x86_64'
DRIVER_VERSION='450.80.02'
RHCOS_VERSION='4.6.6'
REGISTRY='quay.io'
REPO='rhcsdel'

KERNEL_VERSION=$(grep ${RHCOS_VERSION} README.md | awk -F\| '{print $3}' | tr -d ' ')

sudo podman build --no-cache \
     --tag ${REGISTRY}/${REPO}/nvidia-driver:${DRIVER_VERSION}-1.0.0-custom-rhcos-${KERNEL_VERSION}-${RHCOS_VERSION} \
     --build-arg=DRIVER_VERSION=${DRIVER_VERSION} \
     --build-arg=BASE_URL=https://us.download.nvidia.com/tesla \
     --build-arg=PUBLIC_KEY=empty \
     --build-arg=KERNEL_VERSION=${KERNEL_VERSION} \
     --build-arg=BASE_URL=${BASE_URL} \
     --file Dockerfile .

exit 0
