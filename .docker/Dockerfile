# Parts of this Dockerfile were taken from EnMap's Docker configuration file
ARG QGIS_VERSION='latest'

FROM qgis/qgis:${QGIS_VERSION}

LABEL version="latest"
LABEL description="Dependencies of Geoflow, dockerized"

ENV DEBIANFRONTEND=noninteractive
ENV QT_QPA_PLATFORM=offscreen
#ENV XDG_RUNTIME_DIR=$XRD

ADD python-scripts /usr/scripts
RUN chmod +x /usr/scripts/*.py

RUN apt install -y bc wget

# courtesy of https://github.com/davidfrantz/base_image/blob/fab4748fe6d017788b7e5aa109266791838afb37/Dockerfile
RUN groupadd docker && \
	useradd -m docker -g docker -p docker && \
	chmod 0777 /home/docker && \
	chgrp docker /usr/local/bin && \
	mkdir -p /usr/scripts && \
	chown -R docker:docker /usr/scripts 

WORKDIR /home/docker

#USER docker
ENV HOME /home/docker

ENV PATH "$PATH:/usr/scripts:/home/docker/.local/bin"
ENV PYTHONPATH "${PYTHONPATH}:/usr/scripts:/home/docker/.local/bin"

COPY external/custom-requirements.txt .

RUN mkdir -p ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins && \
    # h5py is build against serial interface of HDF5-1.10.4. For parallel processing or newer versions see \
    # https://docs.h5py.org/en/latest/faq.html#building-from-git \
    # https://www.hdfgroup.org/downloads/hdf5/source-code/ \
    # and to an extent https://stackoverflow.com/questions/34119670/hdf5-library-and-header-mismatch-error
    HDF5_LIBDIR=/usr/lib/x86_64-linux-gnu/hdf5/serial HDF5_INCLUDEDIR=/usr/include/hdf5/serial \
      pip3 install --no-cache-dir --no-binary=h5py h5py>=3.5.0 && \
    python3 -m pip install --no-cache-dir -r custom-requirements.txt

RUN mkdir -p ~/.local/share/QGIS/QGIS3/profiles/default/processing/scripts && \
	mkdir -p  ~/.local/share/QGIS/QGIS3/profiles/default/processing/models

RUN git clone --recurse-submodules https://github.com/EnMAP-Box/enmap-box.git && \
    cd enmap-box && \
	git config --local include.path ../.gitconfig && \
    git checkout main && \
    python3 scripts/setup_repository.py && \
	python3 scripts/create_plugin.py && \
	cp -r deploy/enmapboxplugin ~/.local/share/QGIS/QGIS3/profiles/default/python/plugins && \
    chown -R docker:docker ~/.local && \
	chown -R docker:docker /usr/share/qgis

RUN qgis_process plugins enable grassprovider &&\
	qgis_process plugins enable enmapboxplugin

USER docker

CMD ["qgis_process"]
