#!/bin/bash --login

export MAMBA_EXE=/usr/bin/micromamba
export MAMBA_ROOT_PREFIX=/micromamba
. /micromamba/etc/profile.d/mamba.sh

micromamba activate clingmpl

jupyter notebook --port 8889 --ip=0.0.0.0 --allow-root --notebook-dir=/notebooks
