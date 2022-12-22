if [[ $# -eq 1 ]]; then
  CONTAINER_NAME=$1
else
  CONTAINER_NAME="k8s_management"
fi

# Line 10: Paths can be the same
docker run --privileged -it -d \
  --name ${CONTAINER_NAME} \
  -v path/to/datacube/local:/path/to/datacube/inside/docker \
  -v /local/path/to/geoflow/:/murmel/ \
  -v /path/to/kubernetes/config/files/:/murmel/setup/ \
  -v /path/to/.kubernetes/:/murmel/.kubernetes/ \
  floriankaterndahl/k8s_management

docker exec ${CONTAINER_NAME} openvpn --config setup/openvpn-config-file.ovpn  --daemon

docker exec --privileged -it ${CONTAINER_NAME} bash

docker stop ${CONTAINER_NAME}

docker rm ${CONTAINER_NAME}
