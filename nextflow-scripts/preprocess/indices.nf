nextflow.enable.dsl = 2

// courtesy to David Frantz for an overview of indices (https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html)

Map <String, String> SEN2_bands = [
        "BLUE":     "1",
        "GREEN":    "2",
        "RED":      "3",
        "RE1":      "4",
        "RE2":      "5",
        "RE3":      "6",
        "BNIR":     "7",
        "NIR":      "8",
        "SWIR1":    "9",
        "SWIR2":    "10"
]

Map <String, String> LND_bands = [
        "BLUE":     "1",
        "GREEN":    "2",
        "RED":      "3",
        "NIR":      "4",
        "SWIR1":    "5",
        "SWIR2":    "6"
]

Map <String, String> Indices = [
        "NDVI":     "(R1@NIR - R1@RED) / (R1@NIR + R1@RED)",
        "EVI":      "2.5 * ((R1@NIR - R1@RED) / (R1@NIR + 6 * R1@RED - 7.5 * R1@BLUE + 1))",
        "NBR":      "(R1@NIR - R1@SWIR2) / (R1@NIR + R1@SWIR2)",
        "NDTI":     "(R1@SWIR1 - R1@SWIR2) / (R1@SWIR1 + R1@SWIR2)",
        "ARVI":     "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)))",
        "SAVI":     "(R1@NIR - R1@RED) / (R1@NIR + R1@RED + 0.5) * (1 + 0.5)",
        "SARVI":    "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)) + 0.5) * (1 + 0.5)",
]

String platform_spectral_index(String platform_f, String code_snippet, Map <String, String> S_bands, Map <String, String> L_bands) {
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        for (band in L_bands)
            code_snippet = code_snippet.replaceAll(band.key, band.value)
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        for (band in S_bands)
            code_snippet = code_snippet.replaceAll(band.key, band.value)
    }
    return code_snippet
}

String cli_band_maps(String platform_short) {
	if (platform_short =~ /L/) {
		code_snippet = "B=1 G=2 R=3 N=4 S1=5 S2=6"
	} else if (platform_short =~ /S/) {
		code_snippet = "B=1 G=2 R=3 RE1=4 RE2=5 RE3=6 RE4=7 N=8 S1=9 S2=10"
	}
	return code_snippet
}


process calculate_spectral_indices {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), val(index_choice)

	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path("${identifier}_${index_choice*.key[0]}.tif")

	script:
	"""
	qgis_process run enmapbox:RasterMath -- \
		code=\"outputRaster=${platform_spectral_index(sensor, Indices[index_choice*.key[0]], SEN2_bands, LND_bands)};outputRaster.setBandName('${index_choice*.key[0]}', 1);outputRaster.setNoDataValue(R1.noDataValue())\" \
		floatInput=False \
		R1=$reflectance outputRaster=${identifier}_${index_choice*.key[0]}.tif

	#qgis_process run enmapbox:CreateSpectralIndices -- \
		raster=$reflectance \
		indices=${index_choice*.key[0]} \
		${cli_band_maps(sensor_abbr)} \
		outputVrt=${identifier}_${index_choice*.key[0]}.vrt

	#GDAL_VRT_ENABLE_PYTHON=YES gdal_translate ${identifier}_${index_choice*.key[0]}.vrt ${identifier}_${index_choice*.key[0]}.tif
	"""
}

