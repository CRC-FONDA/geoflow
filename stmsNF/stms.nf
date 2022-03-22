nextflow.enable.dsl = 2

def generate_stm_stack = user_selection -> {
	String out_string = ""
	for (fun in user_selection) {
		out_string += "function=$fun.value "
	}

	return out_string
}

process calc_stms_pr {
	label 'debug'

	input:
	tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files), val(band_choice), val(stm_function)

	output:
	tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_${band_choice*.key[0]}_STMS.tif")

	script:
	// contrary to my custom script, gdal_translate rrounds values when converting from float to int. At least, as far as I could tell
        // additionally, gdal_translate does not set band names!
        // |adjust_indices.py -STM -src ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm-temp.tif -of ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm.tif;

	// TODO even though the Raster is converted to Int, the No-Data value is still the old one -> need to check if its possible to reclassify with gdal?
	"""
	shopt -s extglob

	mkdir vrt
	mv ${base_files.join(' ')} vrt
	ls -1 vrt/* | grep ${band_choice*.value[0]} > ${band_choice*.key[0]}_files.txt
	gdalbuildvrt -q -separate -input_file_list ${band_choice*.key[0]}_files.txt ${band_choice*.key[0]}.vrt
	qgis_process run enmapbox:AggregateRasterLayerBands -- raster=${band_choice*.key[0]}.vrt ${generate_stm_stack(stm_function)} outputRaster=${TID}_${sensor_abbr}_${band_choice*.key[0]}_STMS-temp.tif
	gdal_translate -ot Int16 -of GTiff -strict -co COMPRESS=LZW -co PREDICTOR=2 ${TID}_${sensor_abbr}_${band_choice*.key[0]}_STMS-temp.tif ${TID}_${sensor_abbr}_${band_choice*.key[0]}_STMS.tif
	"""
}

