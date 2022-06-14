nextflow.enable.dsl = 2

process build_class_vrt {
	publishDir "${params.final_outDir}", mode: 'copy', pattern: "mosaiced_classification.vrt", overwrite: true

	input:
	path(predicted_tiles)

	output:
	path("mosaiced_classification.vrt")

	script:
	"""
	gdalbuildvrt -q mosaiced_classification.vrt ${predicted_tiles.join(' ')}
	"""
}

