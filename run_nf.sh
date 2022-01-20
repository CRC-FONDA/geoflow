#! /bin/sh

if [ "$#" -gt 0 ]; then
	while getopts 'dgr' opt; do
		case "$opt" in
		d)
			echo "Pulling latest docker image from dockerhub:"
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			echo ""
			docker pull floriankaterndahl/geoflow:latest
			;;
		g)
			echo "Pulling changes from GitHub"
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			echo ""
			git pull
			;;
		r)
			nextflow run -resume main.nf --input_dirP='/data/Dagobah/dc/deu/ard/X0061_Y0048/*{BOA,QAI}.tif' --output_dir_indices=/data/Dagobah/fonda/shk/test_out
			;;
		*)
			echo "Invalid argument provided"
			exit 1
		esac;
	done
fi
