# =================================
# cuda          10.0
# cudnn         v7
# ---------------------------------
# python        3.9
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
    $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        cmake \
        curl \
        wget \
        git \
        vim \
        python \
        && \
# ==================================================================
# python
# ------------------------------------------------------------------
    $PIP_INSTALL \
        setuptools \
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
        torch==1.7.0+cu110 torchvision==0.8.1+cu110 torchaudio===0.7.0 -f https://download.pytorch.org/whl/torch_stable.html \
	torchtext \
        && \
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
