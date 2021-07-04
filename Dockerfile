FROM ubuntu:devel

RUN apt-get update \
  && apt-get install -y wget bzip2 make git \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | \
  tar -xvj bin/micromamba \
  && mkdir /micromamba \
  && micromamba shell init -s bash -p /micromamba

COPY build-environment.yml /root/build-environment.yml

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba create -n xplot -f /root/build-environment.yml

COPY xplot /root/xplot

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba activate xplot \
  && mkdir /root/xplot/build \
  && cd /root/xplot/build \
  && env \
  && cmake \
    -D CMAKE_INSTALL_PREFIX=/micromamba/envs/xplot \
    -D DOWNLOAD_GTEST=ON \
    -D CMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld" \
    -D CMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
    -D CMAKE_CXX_FLAGS="--sysroot=/micromamba/envs/xplot/x86_64-conda-linux-gnu/sysroot/" \
    -D CMAKE_C_FLAGS="--sysroot=/micromamba/envs/xplot/x86_64-conda-linux-gnu/sysroot/" \
    .. \
  && make VERBOSE=1 -j4 install \
  && make test_xplot \
  && cd test \
  && ./test_xplot

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba activate xplot \
  && micromamba install jupyter -c conda-forge

EXPOSE 8889

RUN mkdir /notebooks

COPY start.sh /root/start.sh
CMD /root/start.sh
