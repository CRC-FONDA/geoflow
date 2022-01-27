nextflow.enable.dsl = 2

String generate_stm_script(String band_name, String band_id, String tile, String sensor_abbreviation, List<String> base_input) {
	stm_script_body = """mkdir vrt
			     |mv ${base_input.join(' ')} vrt
			     |ls -1 vrt/* | grep ${band_id} > ${band_name}_files.txt
			     |gdalbuildvrt -q -separate -input_file_list ${band_name}_files.txt ${band_name}_stack.vrt
			     |for stm in 0 1 2 3 4 5 6 7 8 9 10 11 12; do
			     |qgis_process run enmapbox:AggregateRasterBands -- raster=${band_name}_stack.vrt function=\$stm outraster=${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm-temp.tif;
//			     contrary to my custom script, gdal_translate rrounds values when converting from float to int. At least, as far as I could tell
//			     additionally, gdal_translate does not set band names!
			     |gdal_translate -ot Int16 GTiff -of GTiff -strict -of COMPRESS=LZW PREDICTOR=2 ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm-temp.tif  ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm.tif;
//			     |adjust_indices.py -STM -src ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm-temp.tif -of ${tile}_${sensor_abbreviation}_${band_name}_STMS-\$stm.tif;
			     |done
			     |gdal_merge.py -separate -o ${tile}_${sensor_abbreviation}_${band_name}_STMS.tif *${band_name}_STMS-*.tif""".stripMargin()

        return stm_script_body
}
process stm_BLUE_pr {
	label 'debug'

	input:
	tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

	output:
	tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_BLUE_STMS.tif")

	script:
	generate_stm_script("BLUE", "BOA-01", TID, sensor_abbr, base_files)
}

process stm_GREEN_pr {
        label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_GREEN_STMS.tif")

        script:
	generate_stm_script("GREEN", "BOA-02", TID, sensor_abbr, base_files)
}

process stm_RED_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_RED_STMS.tif")

        script:
	generate_stm_script("RED", "BOA-03", TID, sensor_abbr, base_files)
}

process stm_RE1_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_RE1_STMS.tif")

        script:
	generate_stm_script("RE1", "BOA-04", TID, sensor_abbr, base_files)
}

process stm_RE2_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_RE2_STMS.tif")

        script:
	generate_stm_script("RE2", "BOA-05", TID, sensor_abbr, base_files)
}

process stm_RE3_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_RE3_STMS.tif")

        script:
	generate_stm_script("RE3", "BOA-06", TID, sensor_abbr, base_files)
}

process stm_BNIR_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_BNIR_STMS.tif")

        script:
	generate_stm_script("BNIR", "BOA-07", TID, sensor_abbr, base_files)
}

process stm_NIR_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_NIR_STMS.tif")

        script:
	String band_index = sensor_abbr == 'S' ? 'BOA-08' : 'BOA-04'
	generate_stm_script("NIR", band_index, TID, sensor_abbr, base_files)
}

process stm_SWIR1_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_SWIR1_STMS.tif")

        script:
	String band_index = sensor_abbr == 'S' ? 'BOA-09' : 'BOA-05'
	generate_stm_script("SWIR1", band_index, TID, sensor_abbr, base_files)
}

process stm_SWIR2_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_SWIR2_STMS.tif")

        script:
	String band_index = sensor_abbr == 'S' ? 'BOA-10' : 'BOA-06'
	generate_stm_script("SWIR2", band_index, TID, sensor_abbr, base_files)
}

process stm_NDVI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_NDVI_STMS.tif")

        script:
	generate_stm_script("NDVI", "NDVI", TID, sensor_abbr, base_files)
}

process stm_NBR_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_NBR_STMS.tif")

        script:
	generate_stm_script("NBR", "NBR", TID, sensor_abbr, base_files)
}

process stm_NDTI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_NDTI_STMS.tif")

        script:
	generate_stm_script("NDTI", "NDTI", TID, sensor_abbr, base_files)
}

process stm_SAVI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_SAVI_STMS.tif")

        script:
	generate_stm_script("SAVI", "SAVI", TID, sensor_abbr, base_files)
}

process stm_SARVI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_SARVI_STMS.tif")

        script:
	generate_stm_script("SARVI", "SARVI", TID, sensor_abbr, base_files)
}

process stm_EVI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_EVI_STMS.tif")

        script:
	generate_stm_script("EVI", "EVI", TID, sensor_abbr, base_files)
}

process stm_ARVI_pr {
	label 'debug'

        input:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path(base_files)

        output:
        tuple val(TID), val(identifier), val(sensor_abbr), val(sensor), val(year), val(month), val(quarter), path("${TID}_${sensor_abbr}_ARVI_STMS.tif")

        script:
	generate_stm_script("ARVI", "ARVI", TID, sensor_abbr, base_files)
}

