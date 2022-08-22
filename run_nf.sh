#! /bin/bash

NEXTFLOW_ARGS=""

function print_help () {
	echo ""
	echo "run_nf.sh is a short auxillary script which can be used to perform various tasks related to Geoflow,"
	echo "such as pulling the latest docker image from dockerhub or setting various CLI flags for the Nextflow"
	echo "execution."
	echo ""
	echo "The following flags are currently accepted:"
	echo "	-p: print this help"
	echo "	-d: pull the latest docker image containing all dependencies Geoflow needs from Dockerhub"
	echo "	-g: pull the latest changes from the Geoflow GitHub repository for the currently checked out branch"
	echo "	-r: add the resume flag to the Nextflow execution call"
	echo "	-v: add the DAG visualization flag to the Nextflow execution call"
	echo "	-h: add the HTML report flag to the Nextflow execution call"
	echo "	-c: clear all prior flags (does not use cached results)"
	echo "	-e: execute the Workflow with the aforementioned flags"
	echo ""
	echo "Flags can be specified one-by-one or together, i.e. ./run_nf.sh -d -g -r -e is identical to ./run_nf.sh -dgre"
}

if [ "$#" -gt 0 ]; then
	while getopts 'pdgrvhce' opt; do
		case "$opt" in
		p)
			print_help
			exit 1
			;;
		d)
			echo "Pulling latest docker image from dockerhub"
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
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
			# add resume flag
			NEXTFLOW_ARGS+='-resume '
			;;
		v)
			# generate dag
			rm -f img/dag.dot && NEXTFLOW_ARGS+="-with-dag img/dag.dot "
			;;
		h)
			# generate HTML report
			rm -f report.html && NEXTFLOW_ARGS+="-with-report "
			;;
		c)
			# clear all prior flags and run bare workflow
			NEXTFLOW_ARGS=""
			;;
		e)
			# actually execute the workflow
			nextflow run main.nf ${NEXTFLOW_ARGS}
			;;
		*)
			print_help
			exit 1
		esac;
	done
fi
