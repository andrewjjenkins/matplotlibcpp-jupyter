FROM ubuntu:devel as Builder

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
  && micromamba create -n clingmpl -f /root/build-environment.yml

COPY matplotlib-cpp /root/matplotlib-cpp

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba activate clingmpl \
  && mkdir /root/matplotlib-cpp/build \
  && cd /root/matplotlib-cpp/build \
  && env \
  && cmake \
    -D CMAKE_INSTALL_PREFIX=/root/matplotlib-cpp-install \
    -D CMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld" \
    -D CMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
    -D CMAKE_CXX_FLAGS="--sysroot=/micromamba/envs/clingmpl/x86_64-conda-linux-gnu/sysroot/" \
    -D CMAKE_C_FLAGS="--sysroot=/micromamba/envs/clingmpl/x86_64-conda-linux-gnu/sysroot/" \
    .. \
  && make \
  && make install \
  && make xkcd \
  && ./bin/xkcd

COPY enter.sh /root/enter.sh

FROM ubuntu:devel as Runner

RUN apt-get update \
  && apt-get install -y wget bzip2 make git \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | \
  tar -xvj bin/micromamba \
  && mkdir /micromamba \
  && micromamba shell init -s bash -p /micromamba

COPY environment.yml /root/environment.yml

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba create -n clingmpl -f /root/environment.yml

COPY --from=Builder /root/matplotlib-cpp-install/include /micromamba/envs/clingmpl/include/
COPY --from=Builder /root/matplotlib-cpp-install/lib /micromamba/envs/clingmpl/lib/
COPY kernels /micromamba/envs/clingmpl/share/jupyter/kernels

EXPOSE 8889

RUN mkdir /notebooks

COPY enter.sh /root/enter.sh
COPY start.sh /root/start.sh
CMD /root/start.sh
