echo "== Activating virtua lenv"
source /comfy/mnt/venv/bin/activate

if [ "$PYTORCH_VERSION" = "nightly" ]; then
  echo "== Installing nightly torch from https://download.pytorch.org/whl/nightly/cu128"
  pip3 install --upgrade --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
fi

# Install whl files under /builds directory
echo "== Installing whl files under /builds directory"
pip3 install /builds/*.whl