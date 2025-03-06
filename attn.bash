echo "== Activating virtua lenv"
source /comfy/mnt/venv/bin/activate

# Install whl files under /builds directory
echo "== Installing whl files under /builds directory"
pip3 install /builds/*.whl