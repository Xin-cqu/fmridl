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

FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04 as base
LABEL maintainer="nclxwen@gmail.com"
# =================================================================
# set evn
# -----------------------------------------------------------------
RUN apt-get update
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    GIT_CLONE="git clone --depth 10" && \
    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && \
# ==================================================================
# tools
# ------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        cmake \
        curl \
        wget \
        git \
        vim \
        && \
# ==================================================================
# python
# ------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.6 \
        python3.6-dev \
        python3-distutils-extra \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3.6 ~/get-pip.py && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.6 /usr/local/bin/python && \
    $PIP_INSTALL \
        pip \
        setuptools \
        && \
    $PIP_INSTALL \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-learn \
        matplotlib \
        Cython \
        && \
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
# ------------------------------------------------------------------
# pytorch
# ------------------------------------------------------------------
    $PIP_INSTALL \
        future \
        numpy \
        protobuf \
        enum34 \
        pyyaml \
        typing \
        && \
    $PIP_INSTALL \
        torch===1.5.1 torchvision===0.6.1 -f https://download.pytorch.org/whl/torch_stable.html \
	torchtext \
        && \
# ==================================================================
# tensorboradx 
# ------------------------------------------------------------------      
    $PIP_INSTALL \
        tensorboardx\
	mxnet-cu100\
	autogluon\
	&& \
# ==================================================================
# Autogluon 
# ------------------------------------------------------------------      
    $PIP_INSTALL \
        mxnet-cu100\
        autoglun\
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
