nextflow.enable.dsl = 2

def generate_stm_stack = user_selection -> {
	String out_string = ""
	for (fun in user_selection) {
		out_string += "function=$fun.value "
	}

	return out_string
}

process calc_stms_pr {
	input:
	tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor),/* val(sensor_abbr)*/ path(reflectance)/*,  path(qai)*/, path(base_files), /*path(vrt), */val(band_choice), val(stm_function)

	output:
	tuple val(TID), /*val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path(base_files), path(vrt), */
            path("${TID}_${sensor}_${date}_${stm_uid}_${band_choice*.key[0]}_STMS.tif")

	script:
	"""
	shopt -s extglob

	mkdir vrt
	mv ${base_files.join(' ')} vrt
	ls -1 vrt/* | grep ${band_choice*.value[0]} > ${band_choice*.key[0]}_files.txt
	gdalbuildvrt -q -separate -input_file_list ${band_choice*.key[0]}_files.txt ${band_choice*.key[0]}.vrt
	qgis_process run enmapbox:AggregateRasterLayerBands -- raster=${band_choice*.key[0]}.vrt ${generate_stm_stack(stm_function)} \
		outputRaster=${TID}_${sensor}_${date}_${stm_uid}_${band_choice*.key[0]}_STMS.tif
	mv vrt/* .
	"""
}

