#! /bin/sh

if [ "$#" -gt 0 ]; then
	while getopts 'dgnvc' opt; do
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
			nextflow run -resume main.nf
			;;
		v)
			rm -f img/dag.dot && \
			nextflow run -resume main.nf -with-dag img/dag.dot
			;;
		c)
			echo "Run Workflow without caching"
			echo ""
			nextflow run main.nf
			;;
		*)
			echo "Invalid argument provided"
			exit 1
		esac;
	done
fi
