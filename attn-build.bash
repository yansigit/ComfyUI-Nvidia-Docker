#!/bin/bash

sudo chown -R $(id -u):$(id -g) /builds

echo "Cloning SageAttention and building wheel..."
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention || exit
python3 -m venv venv
. venv/bin/activate
pip3 install setuptools wheel packaging
pip3 install --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
pip3 install -e .
python setup.py bdist_wheel
cp dist/*.whl /builds/

echo "Cloning SpargeAttn and building wheel..."
git clone https://github.com/thu-ml/SpargeAttn.git
cd SpargeAttn || exit
python3 -m venv venv
. venv/bin/activate
pip3 install setuptools wheel packaging
pip3 install --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128
pip3 install -e .
python setup.py bdist_wheel
cp dist/*.whl /builds/