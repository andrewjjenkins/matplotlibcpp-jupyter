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
  && micromamba create -n matplotlibcpp-jupyter -f /root/environment.yml

COPY matplotlib-cpp/matplotlibcpp.h /micromamba/envs/matplotlibcpp-jupyter/include/
COPY matplotlibcpp-jupyter.h /micromamba/envs/matplotlibcpp-jupyter/include/
COPY kernels /micromamba/envs/matplotlibcpp-jupyter/share/jupyter/kernels

EXPOSE 8889

RUN mkdir /notebooks

COPY start.sh /root/start.sh
CMD /root/start.sh
