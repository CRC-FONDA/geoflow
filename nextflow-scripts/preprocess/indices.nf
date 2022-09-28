nextflow.enable.dsl = 2

String cli_band_maps(String platform_short) {
	if (platform_short =~ /L/) {
		code_snippet = "B=1 G=2 R=3 N=4 S1=5 S2=6"
	} else if (platform_short =~ /S/) {
		code_snippet = "B=1 G=2 R=3 RE1=4 RE2=5 RE3=6 RE4=7 N=8 S1=9 S2=10"
	}
	return code_snippet
}

String GRASS_Sensors(String platform_short) {	
	switch(platform_short) {
		case 'LDN04':
			return 'landsat4_tm'
		case 'LND05':
			return 'landsat5_tm'
		case 'LND07':
			return 'landsat7_etm'
		case 'LND08':
			return 'landsat8_oli'
	}
}

process calculate_spectral_indices {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), val(index_choice)

	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path("${identifier}_${index_choice*.key[0]}.tif")

	script:
	Boolean is_TC = index_choice*.key[0] ==~ /^TC[GBR]$/

	if (!is_TC) {
		"""
		# EMB does (data * GDAL_scale) / EMB_scale
		qgis_process run enmapbox:CreateSpectralIndices -- \
			raster=$reflectance \
			scale=1 \
			indices=${index_choice*.key[0]} \
			${cli_band_maps(sensor_abbr)} \
			outputVrt=${identifier}_${index_choice*.key[0]}.vrt

		GDAL_VRT_ENABLE_PYTHON=YES gdal_translate ${identifier}_${index_choice*.key[0]}.vrt ${identifier}_${index_choice*.key[0]}.tif
		"""
	} else if (is_TC) {
		"""
		explode.py ${reflectance}

		qgis_process run grass7:i.tasscap -- \
			sensor=${GRASS_sensor(sensor_abbr)} \
			input=*BOA-01.vrt,*BOA-02.vrt,*BOA-03.vrt,*BOA-04.vrt,*BOA-05.vrt,*BOA-06.vrt \
			output=${identifier}_${index_choice*.key[0]}_total.tif
		"""
		Integer TC_band

		switch(index_choice*.key[0]) {
			case 'TCB':
				TC_band = 1
				break
			case 'TCG':
				TC_band = 2
				break
			case 'TCW':
				TC_band = 3
				break
		}
		"""
		gdal_translate -b ${TC_band} ${identifier}_${index_choice*.key[0]}_total.tif ${identifier}_${index_choice*.key[0]}.tif
		gdal_edit.py -mo DESCRIPTION=${index_choice*.key[0]} ${identifier}_${index_choice*.key[0]}.tif output=${identifier}_${index_choice*.key[0]}.tif
		"""
	}
}

