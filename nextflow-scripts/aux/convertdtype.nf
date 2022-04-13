nextflow.enable.dsl = 2

process raster_dtype_i2f {
	input:
	tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)
	output:
	tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	script:
	"""
	# set correct scaling factor
	gdal_translate -of GTiff -a_scale 0.0001 ${reflectance} temp_reflectance.tif

	# unscale image
	gdal_translate -ot Float32 -strict -of GTiff -unscale -a_nodata -3.402823e+38 -co "COMPRESS=DEFLATE" -co "PREDICTOR=3" temp_reflectance.tif ${reflectance}
	"""
}

