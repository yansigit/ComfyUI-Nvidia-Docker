#!/bin/bash

min_sageattention_version="2.1"

set -e

error_exit() {
  echo -n "!! ERROR: "
  echo $*
  echo "!! Exiting script (ID: $$)"
  exit 1
}

source /comfy/mnt/venv/bin/activate || error_exit "Failed to activate virtualenv"

## requires: 00-nvidiaDev,sh
echo "Checking if nvcc is available"
if ! command -v nvcc &> /dev/null; then
    error_exit " !! nvcc not found, canceling run"
fi

## requires: 10-pip3Dev.sh
if pip3 show setuptools &>/dev/null; then
  echo " ++ setuptools installed"
else
  error_exit " !! setuptools not installed, canceling run"
fi
if pip3 show ninja &>/dev/null; then
  echo " ++ ninja installed"
else
  error_exit " !! ninja not installed, canceling run"
fi

# Adapted from https://github.com/eddiehavila/ComfyUI-Nvidia-Docker/blob/main/user_script.bash
compile_flag=true
if pip3 show sageattention &>/dev/null; then
  # Extract the installed version of sageattention
  sageattention_version=$(pip3 show sageattention | grep '^Version:' | awk '{print $2}')
  echo "SageAttention is installed with version $sageattention_version"

  # Use version sort to check if sageattention_version is below the minimal version
  # This command prints the lowest version of the two.
  # If the lowest isn't the minimal version, then sageattention_version is below the minimal version.
  if [ "$(printf '%s\n' "$sageattention_version" "$min_sageattention_version" | sort -V | head -n1)" != "$min_sageattention_version" ]; then
    echo "SageAttention version $sageattention_version is below minimum version $min_sageattention_version, need to compile"
  else
    compile_flag=false
  fi
fi

if [ "A$compile_flag" = "Afalse" ]; then
  echo "SageAttention is already up to date (version $sageattention_version), skipping compilation"
  exit 0
fi

echo "Compiling SageAttention"

cd /comfy/mnt
bb="venv/.build_base.txt"
if [ ! -f $bb ]; then error_exit "${bb} not found"; fi
BUILD_BASE=$(cat $bb)


if [ ! -d src ]; then mkdir src; fi
cd src

mkdir -p ${BUILD_BASE}
if [ ! -d ${BUILD_BASE} ]; then error_exit "${BUILD_BASE} not found"; fi
cd ${BUILD_BASE}

dd="/comfy/mnt/src/${BUILD_BASE}/SageAttention"
if [ -d $dd ]; then
  echo "SageAttention source already present, deleting $dd to force reinstallation"
  rm -rf $dd
fi
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
pip3 install -e . || error_exit "Failed to install SageAttention"

exit 0
