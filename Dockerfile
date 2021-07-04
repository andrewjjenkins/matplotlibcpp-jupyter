FROM ubuntu:devel

RUN apt-get update \
  && apt-get install -y wget bzip2 make git \
  && rm -rf /var/lib/apt/lists/*

RUN wget -q "http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O miniconda.sh \
  && bash miniconda.sh -b -p $HOME/miniconda

RUN export PATH="$HOME/miniconda/bin:$PATH" \
  && hash -r \
  && conda config --set always_yes yes --set changeps1 no \
  && conda update -q conda \
  && conda install clang clang-12 clang-tools clangdev clangxx libclang libclang-cpp libclang-cpp12 python-clang cmake -c conda-forge \
  && conda install xeus=0.23.3 cppzmq=4.3.0 xproperty=0.10.1 xwidgets=0.20.0 -c conda-forge \
  && conda install clang clangdev libcxx -c conda-forge
#  && conda install gxx_linux-64=7.3.0 -c conda-forge

SHELL [ "/root/miniconda/bin/conda", "run", "--no-capture-output", "-n", "root", "/bin/bash", "-c" ]

COPY xplot /root/xplot

RUN mkdir /root/xplot/build \
  && cd /root/xplot/build \
  && env \
  && cmake -D CMAKE_INSTALL_PREFIX=$HOME/miniconda/ -D DOWNLOAD_GTEST=ON .. \
  && make install \
  && make test_xplot

EXPOSE 8889

RUN mkdir /notebooks

COPY start.sh /root/start.sh
CMD /root/start.sh
