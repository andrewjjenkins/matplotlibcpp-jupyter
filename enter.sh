#!/bin/bash --login

export MAMBA_EXE=/usr/bin/micromamba
export MAMBA_ROOT_PREFIX=/micromamba
. /micromamba/etc/profile.d/mamba.sh
micromamba activate xplot

if [ "$#" -ne 0 ]; then
  exec $@
else
  exec /bin/bash
fi
