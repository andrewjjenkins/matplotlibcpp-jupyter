FROM ubuntu:devel

SHELL [ "/bin/bash", "-c" ]

RUN apt-get update \
  && apt-get install -y wget bzip2 \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | \
  tar -xvj bin/micromamba \
  && mkdir /micromamba \
  && micromamba shell init -s bash -p /micromamba

COPY environment.yml /root/environment.yml

RUN export MAMBA_EXE=/usr/bin/micromamba \
  && export MAMBA_ROOT_PREFIX=/micromamba \
  && . /micromamba/etc/profile.d/mamba.sh \
  && micromamba create -n xplot -f /root/environment.yml

EXPOSE 8889

RUN mkdir /notebooks

COPY start.sh /root/start.sh
CMD /root/start.sh
