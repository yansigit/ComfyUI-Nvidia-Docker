FROM nvidia/cuda:12.5.1-devel-ubuntu24.04

# Extended from https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.6.3/ubuntu2404/runtime/cudnn/Dockerfile
ENV NV_CUDNN_VERSION=9.5.1.17-1
ENV NV_CUDNN_PACKAGE_NAME="libcudnn9-cuda-12"
ENV NV_CUDNN_PACKAGE="${NV_CUDNN_PACKAGE_NAME}=${NV_CUDNN_VERSION}"

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