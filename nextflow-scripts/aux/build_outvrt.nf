nextflow.enable.dsl = 2

process build_class_vrt {
	label 'small_memory'

	publishDir "${params.final_outDir}", mode: 'copy', pattern: "*.vrt", overwrite: true

	input:
	path(predicted_tiles)

	output:
	path("mosaiced_classification.vrt")

	script:
	"""
	gdalbuildvrt -q mosaiced_classification.vrt ${predicted_tiles.join(' ')}
	"""
}

