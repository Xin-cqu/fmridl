# =================================
# cuda          10.0
# cudnn         v7
# ---------------------------------
# python        3.6
# anaconda      5.2.0
# Jupyter       5.1 @:8888
# tensorboard   latest (pip) @:6006
# tensorboardx  latest (pip)
# pytorch       latest (pip)
# torchvision   latest (pip)
# Nilearn       latest (pip)
# ---------------------------------

FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04 as base
LABEL maintainer="nclxwen@gmail.com"
# =================================================================
# set evn
# -----------------------------------------------------------------
RUN apt-get update
ARG PYTHON_VERSION=3.7
ARG PYTORCH_VERSION=1.6

SHELL ["/bin/bash", "-c"]
# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Prague

ENV PATH="$PATH:/root/.local/bin"
ENV CUDA_TOOLKIT_ROOT_DIR="/usr/local/cuda"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        cmake \
        git \
        wget \
        ca-certificates \
        software-properties-common \
    && \

# Install python
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-distutils \
        python${PYTHON_VERSION}-dev \
    && \

    update-alternatives --install /usr/bin/python${PYTHON_VERSION%%.*} python${PYTHON_VERSION%%.*} /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 && \

# Cleaning
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /root/.cache && \
    rm -rf /var/lib/apt/lists/*

ENV HOROVOD_GPU_OPERATIONS=NCCL
ENV HOROVOD_WITH_PYTORCH=1
ENV HOROVOD_WITHOUT_TENSORFLOW=1
ENV HOROVOD_WITHOUT_MXNET=1
ENV HOROVOD_WITH_GLOO=1
ENV HOROVOD_WITHOUT_MPI=1
#ENV MAKEFLAGS="-j$(nproc)"
ENV MAKEFLAGS="-j1"
ENV TORCH_CUDA_ARCH_LIST="3.7;5.0;6.0;7.0;7.5"

COPY ./requirements.txt requirements.txt
COPY ./requirements/ ./requirements/

# conda init
RUN \
    wget https://bootstrap.pypa.io/get-pip.py --progress=bar:force:noscroll --no-check-certificate && \
    python${PYTHON_VERSION} get-pip.py && \
    rm get-pip.py && \

    # Disable cache
    pip config set global.cache-dir false && \
    # eventualy use pre-release
    #pip install "torch==${PYTORCH_VERSION}.*" --pre && \
    # set particular PyTorch version
    python -c "import re ; fname = 'requirements.txt' ; req = re.sub(r'torch[>=]+[\d\.]+', 'torch==${PYTORCH_VERSION}.*', open(fname).read()) ; open(fname, 'w').write(req)" && \

    # Install all requirements
    pip install -r requirements/devel.txt --upgrade-strategy only-if-needed --use-feature=2020-resolver && \
    rm -rf requirements*

RUN \
    # install NVIDIA AMP
    git clone https://github.com/NVIDIA/apex && \
    pip install --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./apex && \
    rm -rf apex

RUN \
    # Show what we have
    pip --version && \
    pip list && \
    python -c "import sys; assert sys.version[:3] == '$PYTHON_VERSION', sys.version" && \
    python -c "import torch; assert torch.__version__[:3] == '$PYTORCH_VERSION', torch.__version__"

RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --depth 10" && \
    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && \
# ==================================================================
# jupyter
# ------------------------------------------------------------------
  $PIP_INSTALL \
        jupyter \
        && \
# some tools I used
# ------------------------------------------------------------------
    $PIP_INSTALL \
        nilearn\
        mne\
        numba\
        &&\
# ==================================================================
# tensorboradx 
# ------------------------------------------------------------------      
    $PIP_INSTALL \
        tensorboardx\
	    && \
# ==================================================================
# Autogluon 
# ------------------------------------------------------------------      
    $PIP_INSTALL \
        mxnet-cu110\
        autogluon\
        && \
# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
# =================================
# tini
# =================================
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean
# =================================
# tornado version=5.1.1
# =================================
RUN pip install --upgrade tornado==5.1.1
# =================================
# settings
# =================================
# set up jupyter notebook
COPY jupyter_notebook_config.py /root/.jupyter/
EXPOSE 8888 6006
RUN mkdir /notebook
ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD ["jupyter", "notebook", "--no-browser", "--allow-root"]
WORKDIR /notebook
