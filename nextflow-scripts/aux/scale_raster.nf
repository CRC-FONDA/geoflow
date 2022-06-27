nextflow.enable.dsl = 2

process set_raster_scale {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)
	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	script:
	// this assumes, that every band is scaled by the same factor and the scaling value is given by FORCE; FORCE does not set an offset to my knowledge
	"""
	scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
	scaled_nodata=\$(printf '%.4f' \$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print "scale=4;"\$2" * "sf}' | bc))
	gdal_edit.py -scale \$scale_factor -a_nodata \$scaled_nodata ${reflectance}
	"""
}

