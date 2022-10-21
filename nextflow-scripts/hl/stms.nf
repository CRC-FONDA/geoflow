nextflow.enable.dsl = 2

process calc_stms_pr {
	label 'small_memory'

	input:
	tuple val(TID), val(stm_uid), path(reflectance), path(base_files), val(band_choice), val(stm_function)

	output:
	tuple val(TID), path("${TID}_${stm_uid}_${band_choice*.key[0]}_STMS.tif")

	script:
	"""
	shopt -s extglob

	mkdir vrt
	mv ${base_files.join(' ')} vrt
	ls -1 vrt/* | grep '_${band_choice*.value[0]}' > ${band_choice*.key[0]}_files.txt
	gdalbuildvrt -q -separate -input_file_list ${band_choice*.key[0]}_files.txt ${band_choice*.key[0]}.vrt
	qgis_process run enmapbox:AggregateRasterLayerBands -- raster=${band_choice*.key[0]}.vrt function=${stm_function*.value.join(",")} \
		outputRaster=${TID}_${stm_uid}_${band_choice*.key[0]}_STMS.tif
	"""
}

