echo "== Activating virtua lenv"
source /comfy/mnt/venv/bin/activate

sudo apt install -y git sudo curl wget

if [ "$PYTORCH_VERSION" = "nightly" ]; then
  echo "Installing nightly PyTorch..."
  # pip3 install --upgrade --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
  pip3 install --upgrade --pre torch torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
elif [ -n "$PYTORCH_VERSION" ]; then
# elif [ -n "$PYTORCH_VERSION" ]; then
  echo "== Installing torch version $PYTORCH_VERSION"
  pip3 install --force-reinstall torch==$PYTORCH_VERSION torchaudio==$PYTORCH_VERSION torchvision==$PYTORCH_VERSION --index-url https://download.pytorch.org/whl/nightly/cu128
else
  echo "Installing PyTorch version from ComfyUI Manager repo..."
  pytorch_line=$(curl -s https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/scripts/install-comfyui-venv-linux.sh | grep 'torch torchvision torchaudio')
  eval "$pytorch_line"
fi

sudo chown -R ${WANTED_UID}:${WANTED_GID} /comfy/mnt
sudo chown -R ${WANTED_UID}:${WANTED_GID} /basedir

# Install whl files under /builds directory
echo "== Installing whl files under /builds directory"
pip3 install /builds/*.whl