#! /bin/sh

# pull latest container image and run nextflow workflow
# only needed during "development" phase

if [ "$#" -gt 0 ]; then
    docker pull floriankaterndahl/geoflow:latest
fi

nextflow run -resume main.nf --input_dirP='/data/Dagobah/dc/deu/ard/X0061_Y0048/*{BOA,QAI}.tif' --output_dir_indices=/data/Dagobah/fonda/shk/test_out

