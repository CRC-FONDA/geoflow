nextflow.enable.dsl = 2

process set_raster_scale {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)
	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	script:
	// this assumes, that every band is scaled by the same factor; FORCE does not set an offset to my knowledge
	"""
	scale_factor=\$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR ==1) print 1/\$2}')
	scaled_nodata_expr=\$(gdalinfo ${reflectance} | grep 'NoData' | awk 'BEGIN{FS="="} {if (NR ==1) print 1/\$2}')
	scaled_nodata_expr+="* \${scale_factor}"
	scaled_nodata=\$(echo \$scaled_nodata_expr | bc)
	gdal_edit.py -scale \$scale_factor -a_nodata \$scaled_nodata ${reflectance}
	"""
}

