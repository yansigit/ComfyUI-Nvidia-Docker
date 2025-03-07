#!/bin/bash

echo "Cloning SageAttention and building wheel..."
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention || exit
python3 -m venv venv
. venv/bin/activate
pip3 install setuptools wheel packaging

if [ "$PYTORCH_VERSION" = "nightly" ]; then
  echo "Installing nightly PyTorch..."
  pip3 install --upgrade --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
else
  echo "Installing PyTorch version from ComfyUI Manager repo..."
  pytorch_line=$(curl -s https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/scripts/install-comfyui-venv-linux.sh | grep 'torch torchvision torchaudio')
  eval "$pytorch_line"
fi

pip3 install -e .
python setup.py bdist_wheel
cp dist/*.whl /builds/

echo "Cloning SpargeAttn and building wheel..."
git clone https://github.com/thu-ml/SpargeAttn.git
cd SpargeAttn || exit
python3 -m venv venv
. venv/bin/activate
pip3 install setuptools wheel packaging

# pip3 install --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
pytorch_line=$(curl -s https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/scripts/install-comfyui-venv-linux.sh | grep 'torch torchvision torchaudio')
eval "$pytorch_line"

pip3 install -e .
python setup.py bdist_wheel
cp dist/*.whl /builds/

chown -R ubuntu:ubuntu /builds