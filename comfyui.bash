if [ "$1" == "build" ]; then
  if ! docker images -q "attn-builder" 1>/dev/null; then
    docker build -f Dockerfile/attn/ubuntu24_cuda12.8-attn-builder.Dockerfile -t attn-builder .
  fi
  docker run --rm -v ./builds:/builds attn-builder
fi

if [ "$1" == "run" ]; then
  if ! docker images -q "comfyui-attn-runtime" 1>/dev/null; then
    docker build -f Dockerfile/attn/ubuntu24_cuda12.8-attn.Dockerfile -t comfyui-attn-runtime .
  fi
  docker run --rm -it \
    --gpus all \
    -v /opt/comfyui/run:/comfy/mnt \
    -v /opt/comfyui/basedir:/basedir \
    -v /mnt/d/Images/:/mnt/d/Images/ \
    -e WANTED_UID=$(id -u) \
    -e WANTED_GID=$(id -g) \
    -e BASE_DIRECTORY=/basedir \
    -e SECURITY_LEVEL=normal \
    -e COMFY_CMDLINE_EXTRA="--output-directory /mnt/d/Images/output --input-directory /mnt/d/Images/input" \
    -p 8188:8188 \
    --name comfyui-attn-runtime \
    comfyui-attn-runtime:latest
fi
