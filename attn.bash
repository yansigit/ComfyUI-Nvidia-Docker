echo "== Activating virtua lenv"
source /comfy/mnt/venv/bin/activate

if [ "$PYTORCH_VERSION" = "nightly" ]; then
  echo "== Installing nightly torch from https://download.pytorch.org/whl/nightly/cu128"
  pip3 install --upgrade --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
elif [ -n "$PYTORCH_VERSION" ]; then
  echo "== Installing torch version $PYTORCH_VERSION"
  pip3 install --force-reinstall torch==$PYTORCH_VERSION torchaudio==$PYTORCH_VERSION torchvision==$PYTORCH_VERSION --index-url https://download.pytorch.org/whl/nightly/cu128
fi

# Install whl files under /builds directory
echo "== Installing whl files under /builds directory"
pip3 install /builds/*.whl