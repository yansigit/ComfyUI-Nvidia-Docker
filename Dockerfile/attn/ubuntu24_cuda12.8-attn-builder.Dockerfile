FROM nvidia/cuda:12.8.0-devel-ubuntu24.04 AS builder

# Adapted from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.8.0/ubuntu2404/devel/cudnn/Dockerfile
ENV NV_CUDNN_VERSION=9.7.0.66-1
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9-cuda-12"
ENV NV_CUDNN_PACKAGE="libcudnn9-cuda-12=${NV_CUDNN_VERSION}"

LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  git sudo curl wget python3-pip python3-dev python-is-python3 python3.12-venv \
  ${NV_CUDNN_PACKAGE} \
  && apt-mark hold ${NV_CUDNN_PACKAGE_NAME}

VOLUME /builds
WORKDIR /run

COPY --chown=ubuntu:ubuntu attn-build.bash /run/attn-build.bash
RUN chmod +x /run/attn-build.bash

CMD [ "/run/attn-build.bash" ]