FROM ubuntu

RUN apt update && \
	apt install -y wget unzip gdal-bin

CMD ["bash"]

