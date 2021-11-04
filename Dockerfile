# Teile des Dockerfiles entstammen dem Dockerfile der Enmap-Box
ARG QGIS_VERSION=latest

FROM qgis/qgis:${QGIS_VERSION}

LABEL version="0.0.1"
LABEL description="EnMAP-Box in Docker"

# Checkout funktioniert nicht, weil da mein "requirements_docker.txt" noch nicht exitierte
ARG ENMAP_VERSION='v3.9'
#ARG ENMAP_BRANCH='master'
ARG XRD='/tmp/runtime-root'

ENV DEBIANFRONTEND=noninteractive
ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=$XRD

RUN git clone https://bitbucket.org/hu-geomatics/enmap-box.git

COPY external/custom-requirements.txt /enmap-box/

RUN # git checkout v3.9 && \
    # h5py is build against serial interface of HDF5-1.10.4. For parallel processing or newer versions see \
    # https://docs.h5py.org/en/latest/faq.html#building-from-git \
    # https://www.hdfgroup.org/downloads/hdf5/source-code/ \
    # and to an extent https://stackoverflow.com/questions/34119670/hdf5-library-and-header-mismatch-error
    HDF5_LIBDIR=/usr/lib/x86_64-linux-gnu/hdf5/serial HDF5_INCLUDEDIR=/usr/include/hdf5/serial \
      pip install --no-binary=h5py h5py>=3.5.0

RUN mkdir $XRD && \
    mkdir -p ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins

RUN cd enmap-box && \
    python3 -m pip install -r custom-requirements.txt && \
    python3 scripts/setup_repository.py && \
    python3 scripts/create_plugin.py && \
    cp -r deploy/enmapboxplugin ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins

RUN qgis_process plugins enable enmapboxplugin

RUN rm -rf /enmap-box

CMD ["qgis_process"]
