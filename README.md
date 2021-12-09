# New B5 Workflow

As per our proposal submitted to LPS22, the goals set are:
(1) to map annual land cover between 2000 and 2020 across Germany using integrated Landsat and 
Sentinel-2 times series and the harmonized European-wide Land Use and Coverage Area frame Survey (LUCAS) (d’Andrimont et al. 2020)
(2) to develop Nextflow workflows that leverage a broad range of existing, already widely used open source tools and programs and
(3) to evaluate the execution performance of Nextflow workflows.

This Readme serves a reference as to what has been accomplished, but also as a place to gather ideas/thoughts
that occurred throughout the work on this project. 

## Ready, Set, Go!

```bash
git clone https://github.com/CRC-FONDA/geoflow.git
cd geoflow
```

## Docker

We are making use of Docker containers to keep all dependencies (apart from Nextflow) together. And run the
workflow containerized.

### General

- `docker build` does not complete without warnings. However, as far as I know, these are things 
regarding the (recommended) way of installing dependencies such as the [EnMap-Box](https://bitbucket.org/hu-geomatics/enmap-box/src/develop/)
and thus, cannot be fixed on our side. 
- The container is based on the official QGIS container with the EnMap-Box added

```bash
docker build -t geoflow:latest -f Dockerfile .

docker run --rm geoflow:latest
#> QGIS Processing Executor - 3.23.0-Master 'Master' (3.23.0-Master)
#> Usage: qgis_process [--help] [--version] [--json] [--verbose] [command] [algorithm id or path to model file] [parameters]
#>
#> Options:
#>         --help or -h            Output the help
#>         --version or -v         Output all versions related to QGIS Process
#>         --json          Output results as JSON objects
#>         --verbose       Output verbose logs
# [...]
```

### Dockerhub and GitHub Actions

- I copied together a GitHub workflow which builds the container and pushes it to Dockerhub. If there's
no error, then the build and push should be relatively fast because it uses the GitHub build cache
- The image can be pulled via:

```bash
docker pull floriankaterndahl/geoflow:latest
```

## Running the Workflow

- Currently, the workflow expects two additional arguments: (1) the data source and (2) a directory
where the calculated indices should be stored (in addition to the working directory created by
Nextflow).
- To *"simplify"* the execution call and rather often occurring fetch for an updated docker image, run
the `run_nf.sh` script. Calling the script without any additional parameters, will simply execute
the workflow as defined in the script. Calling it with any number of arguments (no matter what
they actually are) additionally fetches the latest version of the docker image before running the
workflow.

```bash
bash ./run_nf.sh
# or
bash ./run_nf.sh update
```

## Further Notes

It's likely, that the docker image can be further optimised. A couple of ideas include:

- Create a "docker user" to not run the image as `root`, although I don't really see the point in doing
so for our use case
- optimize image size (~ 2,5 Gb on Dockerhub)
  - don't use the qgis base image, but compile QGIS ourselves. There's a guide on how to do this in
  the [QGIS GitHub repo](https://github.com/qgis/QGIS/blob/master/INSTALL.md)
  - use Alpine Linux as our Distro?
    - I fiddled around with that idea and there was at least one important dependency that was not readily
    available - I can't remember which one though
