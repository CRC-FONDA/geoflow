# Geoflow - *New* B5 Workflow

As per our proposal submitted to LPS22, the goals set are:
(1) to map annual land cover between 2000 and 2020 across Germany using integrated Landsat and Sentinel-2 times series
and the harmonized European-wide Land Use and Coverage Area frame Survey (LUCAS) (d’Andrimont et al. 2020)
(2) to develop Nextflow workflows that leverage a broad range of existing, already widely used open source tools and
programs and
(3) to evaluate the execution performance of Nextflow workflows.

This Readme serves a reference as to what has been accomplished, but also as a place to gather ideas/thoughts that
occurred throughout the work on this project.

At the current point in time, the project is still in its early stages and work has mainly been funneled into the second
goal, as its serves as a basis for the others.

## Get The Code

To start working on this repository, clone the GitHub repository. E.g.:

```bash
git clone https://github.com/CRC-FONDA/geoflow.git
cd geoflow
```

## Docker

Docker serves as the execution environment for each Nextflow processes: All dependencies, be it binary executables like
the [EnMap-Box](https://github.com/EnMAP-Box/enmap-box) or custom scripts, are self-contained in a docker container and
thus portable across different execution environments and systems. Three dockerfiles currently exist which serve
different purposes:

1. `./docker/Dockerfile`: This is the current execution environment for the workflow. The docker image is also hosted on
   DockerHub (needed for execution on clusters)
2. `.docker/ubuntu_with_wget.dockerfile`: This docker image is used for setting up prerequisites of the workflow inside
   a cluster. Depending on the future structure of the workflow (e.g. generating the datacube inside the cluster/as part
   of Geoflow instead of uploading it) this may become obnsolete.
3. `.docker/k8s_management.dockerfile`: This docker image has `kubectl` and `openvpn` installed to connect to a
   Kubernetes cluster and mitigates the need to install either one of those on your local machine.

The *main* docker image which contains all other software the workflow is dependent on build upon the QGIS docker image
and adds the EnMap-Box as well as custom Python scripts. For local workflow development, I chose to build the docker
image locally to allow for faster testing-cycles. To do so, run the following command from inside the root project
directory:

```bash
docker build -f .docker/Dockerfile -t <some-docker-account>/geoflow:<version-tag> .
```

For the time being, the most up-to-date version of this container can be pulled from DockerHub via

```bash
docker pull floriankaterndahl/geoflow
```

Since the image gets cached on the Kubernetes cluster, it is advised to use *actual* version tags instead of relying
on the 'latest' tag! Keep in mind updating the version specification in all configuration files.

The Python dependencies for the EnMap-Box as well as the custom Python scripts are specified
inside `external/custom-requirements.txt`. To this day, there exists no *official* EnMap-Box Docker image and the
dependency list is kept in sync with the EnMap-Box dependencies

:exclamation::exclamation: Within Nextflow processes, you can assume to be inside a docker container given that you instructed
Nextflow to use Docker as an execution environment. You are not responsible for starting/stopping containers and
mounting files into a running docker container. Nextflow takes care of all of this for you!

### Dockerhub and GitHub Actions

A GitHub Actions workflow is triggered when changes to 1) the dockerfile, 2) the Action definition, 3)
the `.dockerignore`, 3) Python scripts folder or above-mentioned requirement definition is committed and pushed to the
repo. In order for this to work, certain secrets must be set in the GitHub-repo's section for managing secrets. As of
the time of writing, they are connected to my personal DockerHub-Account.

At the end of this document are more information regarding what needs to be set up in GitHub.

## "Land use and land cover survey" (LUCAS) Data

In its current implementation, the workflow relies
on [the harmonized LUCAS survey data](https://doi.org/10.1038/s41597-020-00675-z). Which can be
downloaded [here](https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/LUCAS). While in the development phase
(i.e. right now), only points sampled in 2018 and the theoretical LUCAS-points are considered. This likely changes in
the future. The respective files can be downloaded in a zipped format and processed as shown below:

```bash
wget --directory-prefix=lucas --content-disposition https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/LUCAS/LUCAS_harmonised/1_table/lucas_harmo_uf_2018.zip && \
  unzip lucas/lucas_harmo_uf_2018.zip -d lucas && \
  rm lucas/lucas_harmo_uf_2018.zip

wget --directory-prefix=lucas --content-disposition https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/LUCAS/LUCAS_harmonised/2_geometry/LUCAS_th_geom.zip && \
  unzip lucas/LUCAS_th_geom.zip -d lucas && \
  ogr2ogr -f "GPKG" lucas/lucas_geom.gpkg lucas/LUCAS_th_geom.shp && \
  rm lucas/LUCAS_th_geom*
```

## Running the Workflow

### General

Regardless on how you choose to execute this workflow, you need to install [Nextflow](https://www.nextflow.io/) on
your **local** machine and update your `PATH` environment variable to point to the executable. You may also want to
check out their [documentation](https://www.nextflow.io/docs/latest/index.html)
or [training material](https://training.seqera.io/).

TODO: Does the following paragraph, especially the last sentence, hold true?

In more recent development, I tried to consolidate some processes, which were previously separated, into one. For
example, the `mask` and `scale` processes are now combined into one. While these two processes are distinct
content-wise, it may be beneficial to keep them together since the steps are tightly coupled, and it could allow for
storage space savings when running the workflow on Kubernetes: Only the *final* output (i.e. the scaled raster images)
would be written to the `PersistentVolumeClaims` (only relevant if you execute the workflow on Kubernetes!).

The separate files are not deleted, yet. In the future, it may be desirable to let the user decide how they want these
two steps to be executed.

It's possible to configure which flags produced by FORCE should be used for a bit mask creation. For more information,
see [here](https://force-eo.readthedocs.io/en/latest/howto/qai.html#quality-bits-in-force).

:warning: When using cached results, unexpected results have been observed where files were processed more than
once and thus violate assumptions concerning metadata or errors in various python scripts occurred.

### Local Execution

To in invoke the workflow locally, run the following command form inside the cloned repository.

TODO: add download and *pre-processing* of LUCAS as well.

```bash
nextflow run -c nextflow.config -profile local main.nf
```

### Cluster Execution (Kubernetes)

:warning: Even if you intend to run this workflow (or an adapted version) on a kubernetes cluster, you need to have
Nextflow installed locally. It is assumed, that you are in the root directory of this repo.

#### Connecting To A Cluster 

In order to interact with a Kubernetes cluster, you need to install `kubectl` on your machine and possibly some way to
instantiate a VPN connection as well. If you are not able to install all prerequisites, e.g. because you're not
granted the appropriate *rights* on your machine, you can use the script `kubernetes-management.sh`. This script starts
a docker container with `kubectl` and `openvpn` installed and sets up a VPN connection.

For ease of use, this is best run inside a `tmux` or `screen`-session.

Keep in mind, that all paths inside the script are placeholders and need to be adopted to your specific setup.

#### Setup ServiceAccounts, Storage Claims, etc.

To run this workflow on a Kubernetes-Cluster, one or more "PersistentVolumeClaim"s, a *master* pod which mounts the
PVC (here: `ceph-pod.yml` or `geoflow-pod. yml`), as well as Nextflow roles on the cluster and a role binding need to be
created. Make sure to adjust the namespaces and storage sizes according to your setup and needs.

```bash
kubectl create -f kubernetes/ceph-input.yml
kubectl create -f kubernetes/ceph-workdir.yml
kubectl create -f kubernetes/ceph-output.yml

kubectl create -f kubernetes/ceph-pod.yml
kubectl create -f kubernetes/geoflow-pod.yml

kubectl create -f kubernetes/nextflow-service-account.yml
kubectl create -f kubernetes/nextflow-pod-role.yml
kubectl create -f kubernetes/nextflow-role-binding.yml
```

This workflow relies on an already existing FORCE datacube. To ingest to data, run the following command from the
machine on which the datacube is saved. First, create a subset of the datacube (if needed) on your local machine and then
upload a tarball to the Kubernetes cluster. The parent directory needs to exist on the cluster.

Alternatively, follow the instructions defined in
the [FORCE2NXF-Rangeland](https://github.com/CRC-FONDA/FORCE2NXF-Rangeland) workflow to build the datacube on the
Kubernetes cluster.

The following command is expected to be run locally on your machine which holds the datacube and needs to be adjusted
to your path/folder structure.

```bash
find /data/Dagobah/dc/deu/ard -type f \( -name "2020*_LEVEL2_LND*BOA.tif" -o  -name "2020*_LEVEL2_LND*QAI.tif" \) \
  -exec bash -c 'DIRNAME=$( dirname "$1");
  mkdir --parent /data/Dagobah/fonda/shk/geoflow/datacube/$( basename $DIRNAME );
  ln --symbolic "$1" /data/Dagobah/fonda/shk/geoflow/datacube/$( basename $DIRNAME )/$( basename "$1" )' bash {} \;
```

```bash
kubectl exec ceph-pod-geoflow -- bash -c "mkdir /input/datacube"

tar hcf - /data/Dagobah/fonda/shk/geoflow/datacube/ | kubectl exec -i ceph-pod-geoflow -- tar xf - -C /input/
```

Other prerequisites are the LUCAS-datasets which need to be available for Nextflow as workflow inputs.
To create them on the cluster, run the following commands.

```bash
kubectl exec geoflow-pod -- bash -c \
  "wget --directory-prefix=/input/lucas --content-disposition https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/LUCAS/LUCAS_harmonised/1_table/lucas_harmo_uf_2018.zip && \
  unzip /input/lucas/lucas_harmo_uf_2018.zip -d /input/lucas && \
  rm /input/lucas/lucas_harmo_uf_2018.zip"
  
kubectl exec geoflow-pod -- bash -c \
  "wget --directory-prefix=/input/lucas --content-disposition https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/LUCAS/LUCAS_harmonised/2_geometry/LUCAS_th_geom.zip && \
  unzip /input/lucas/LUCAS_th_geom.zip -d /input/lucas && \
  ogr2ogr -f "GPKG" /input/lucas/lucas_geom.gpkg /input/lucas/LUCAS_th_geom.shp && \
  rm /input/lucas/LUCAS_th_geom*"
```

#### Cloning the geoflow repository

The `ceph-pod-geoflow` does not have git installed. Thus, prior to cloning the repo, you have to install it.

TODO: This doesn't seem correct!
TODO: Not needed for execution, when following this README

```bash
kubectl exec ceph-pod-geoflow -- bash -c "apt update && apt install -y git"
kubectl exec ceph-pod-geoflow -- git clone https://github.com/CRC-FONDA/geoflow.git /data/geoflow-repo
```

#### Running the workflow

After either creating a datacube inside your cluster (i.e. in an PVC) or [copying one to it](./kubernetes/upload.sh),
adjust the options in the `nextflow. config` and select the suitable profile (i.e. the K8s one) and start the workflow
from a machine outside the Kubernetes cluster.

```bash
nextflow kuberun -c nextflow.config -profile kubernetes \
  -v ceph-input:/input \
  -v ceph-workdir:/workdir \
  -v ceph-output:/output \
  -r develop \
  https://github.com/CRC-FONDA/geoflow.git
```

:warning: I think with the current Kubernetes config (i.e. specifying volume and storage claims in the pod and `k8s`
scope), it should be possible to start the workflow via `nextflow kuberun` as well as from inside a dedicated
Nextflow-pod.

:warning: By default, the Nextflow-Pods which are spawned when executing the workflow on a kubernetes-cluster require
some nodes to be labeled with `geoflow=true`. This label can be either changed and updated
in `configurations/k8s.config`, alternatively the `nodeSelector`-property can be omitted to use all available nodes in a
cluster. To label certain nodes within a Kubernetes cluster, use `kubectl label`.

### Downloading the Results

After a successful workflow execution, the results can be downloaded from the Kubernetes cluster via

```bash
kubectl cp <your-namespace>/ceph-pod-geoflow:/output /where/you/want/to/save/the/folder/locally/
```

## DAG Visualization

The current workflow execution structure is depicted [here](img/dag.svg) and is generated on the basis of a local
execution.

![current DAG](img/dag.svg)

## GitHub Actions

Currently, there are two automated GitHub Actions set up. One is for automatically creating a new docker image and
pushing it to Dockerhub and one for updating the workflow execution visualization. The former can usually be done
quicker via the CLI from docker, but it seemed like a good idea to guarantee that all relevant changes to the codebase
are reflected in the docker image.

In order for these two automated workflows to run properly, some setup in the GitHub repository is required:
The *secrets* `DOCKER_HUB_ACCESS_TOKEN`, `DOCKER_HUB_USERNAME`, `EMAIL`, `NAME` and `PAT` all need to be set. The first
two are used for updating the docker image while the latter three are used for updating the workflow visualization.

## Further Notes And Ideas

- optimize image size (~ 2,5 Gb on Dockerhub)
    - don't use the qgis base image, but compile QGIS ourselves. There's a guide on how to do this in
      the [QGIS GitHub repo](https://github.com/qgis/QGIS/blob/master/INSTALL.md)
    - use another, smaller Linux distribution (e.g. AlpineLinux)?
- Generate the datacube as part of the workflow. This reduces dependencies (i.e. the local environment doesn't
  need to have FORCE installed and have sufficient disk space to hold the entire datacube) and mitigates data
  duplication. The [FORCE Rangeland Workflow](https://github.com/CRC-FONDA/FORCE2NXF-Rangeland) serves as a 
  blueprint/guideline on how to such integration could be managed.

