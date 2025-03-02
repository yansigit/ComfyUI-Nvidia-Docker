FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# CUDNN9 "runtime" package
# Adapted from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.4.1/ubuntu2204/runtime/cudnn/Dockerfile
ENV NV_CUDNN_VERSION=9.1.0.70-1
ENV NV_CUDNN_PACKAGE_NAME=libcudnn9-cuda-12
ENV NV_CUDNN_PACKAGE="libcudnn9-cuda-12=${NV_CUDNN_VERSION}"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NV_CUDNN_PACKAGE} \
    && apt-mark hold ${NV_CUDNN_PACKAGE_NAME} \
    && rm -rf /var/lib/apt/lists/*

ARG BASE_DOCKER_FROM=nvidia/cuda:12.4.1-runtime-ubuntu22.04

##### Base

# Install system packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y --fix-missing\
  && apt-get install -y \
    apt-utils \
    locales \
    ca-certificates \
    && apt-get upgrade -y \
    && apt-get clean

# UTF-8
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8
ENV LC_ALL=C

# Install needed packages
RUN apt-get update -y --fix-missing \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    python3-dev \
    unzip \
    wget \
    zip \
    zlib1g \
    zlib1g-dev \
    gnupg \
    rsync \
    python3-pip \
    python3-venv \
    git \
    sudo \
    # Adding libGL (used by a few common nodes)
    libgl1 \
    libglib2.0-0 \
    # Adding FFMPEG (for video generation workflow)
    ffmpeg \
  && apt-get clean

ENV BUILD_FILE="/etc/image_base.txt"
ARG BASE_DOCKER_FROM
RUN echo "DOCKER_FROM: ${BASE_DOCKER_FROM}" | tee ${BUILD_FILE}
RUN echo "CUDNN: ${NV_CUDNN_PACKAGE_NAME} (${NV_CUDNN_VERSION})" | tee -a ${BUILD_FILE}

ARG BUILD_BASE="unknown"
LABEL comfyui-nvidia-docker-build-from=${BUILD_BASE}
RUN it="/etc/build_base.txt"; echo ${BUILD_BASE} > $it && chmod 555 $it

# Place the init script in / so it can be found by the entrypoint
COPY --chmod=555 init.bash /comfyui-nvidia_init.bash

##### ComfyUI preparation
# Every sudo group user does not need a password
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create a new group for the comfy and comfytoo users
RUN groupadd -g 1024 comfy \ 
    && groupadd -g 1025 comfytoo

# The comfy (resp. comfytoo) user will have UID 1024 (resp. 1025), 
# be part of the comfy (resp. comfytoo) and users groups and be sudo capable (passwordless) 
RUN useradd -u 1024 -d /home/comfy -g comfy -s /bin/bash -m comfy \
    && usermod -G users comfy \
    && adduser comfy sudo
RUN useradd -u 1025 -d /home/comfytoo -g comfytoo -s /bin/bash -m comfytoo \
    && usermod -G users comfytoo \
    && adduser comfytoo sudo

ENV COMFYUSER_DIR="/comfy"
RUN mkdir -p ${COMFYUSER_DIR}
RUN it="/etc/comfyuser_dir"; echo ${COMFYUSER_DIR} > $it && chmod 555 $it

ENV NVIDIA_VISIBLE_DEVICES=all

EXPOSE 8188

ARG COMFYUI_NVIDIA_DOCKER_VERSION="unknown"
LABEL comfyui-nvidia-docker-build=${COMFYUI_NVIDIA_DOCKER_VERSION}
RUN echo "COMFYUI_NVIDIA_DOCKER_VERSION: ${COMFYUI_NVIDIA_DOCKER_VERSION}" | tee -a ${BUILD_FILE}

# We start as comfytoo and will switch to the comfy user AFTER the container is up
# and after having altered the comfy details to match the requested UID/GID
USER comfytoo

CMD [ "/comfyui-nvidia_init.bash" ]