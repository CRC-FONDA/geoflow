#! /bin/sh

if [ "$#" -gt 0 ]; then
	while getopts 'dgnv' opt; do
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
		n)
			nextflow run -resume main.nf --input_dirP='/data/Dagobah/dc/deu/ard/X0061_Y0048/*{BOA,QAI}.tif' --output_dir_indices=/data/Dagobah/fonda/shk/test_out
			;;
		v)
			rm -f img/dag.dot && \
			nextflow run -resume main.nf --input_dirP='/data/Dagobah/dc/deu/ard/X0061_Y0048/*{BOA,QAI}.tif' --output_dir_indices=/data/Dagobah/fonda/shk/test_out -with-dag img/dag.dot
			;;
		*)
			echo "Invalid argument provided"
			exit 1
		esac;
	done
fi
