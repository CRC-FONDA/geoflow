# Parts of this Dockerfile were taken from EnMap's Docker configuration file
ARG QGIS_VERSION=latest

FROM qgis/qgis:${QGIS_VERSION}

LABEL version="latest"
LABEL description="EnMAP-Box in Docker"

ARG ENMAP_VERSION='v3.9'
#ARG ENMAP_BRANCH='master'
ARG XRD='/var/tmp/runtime-root'

ENV DEBIANFRONTEND=noninteractive
ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=$XRD

WORKDIR /tmp/build

COPY external/custom-requirements.txt .

RUN mkdir -m=0700 $XRD && \
    mkdir -p ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins && \
    # h5py is build against serial interface of HDF5-1.10.4. For parallel processing or newer versions see \
    # https://docs.h5py.org/en/latest/faq.html#building-from-git \
    # https://www.hdfgroup.org/downloads/hdf5/source-code/ \
    # and to an extent https://stackoverflow.com/questions/34119670/hdf5-library-and-header-mismatch-error
    HDF5_LIBDIR=/usr/lib/x86_64-linux-gnu/hdf5/serial HDF5_INCLUDEDIR=/usr/include/hdf5/serial \
      pip3 install --no-cache-dir --no-binary=h5py h5py>=3.5.0 && \
    python3 -m pip install --no-cache-dir -r custom-requirements.txt

RUN git clone --recurse-submodules https://bitbucket.org/hu-geomatics/enmap-box.git && \
    cd enmap-box && \
    # until 3.10 gets released, I can't do a version checkout beacuse I want/need further STMs, which are already implemented
    # git checkout $ENMAP_VERSION && \
    python3 scripts/setup_repository.py && \
    python3 scripts/create_plugin.py && \
    cp -r deploy/enmapboxplugin ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins && \
    qgis_process plugins enable enmapboxplugin && \
    rm -rf /tmp/build

ADD scripts-python /root/scripts
RUN chmod +x /root/scripts/*.py
ENV PATH "$PATH:/root/scripts"

CMD ["qgis_process"]
