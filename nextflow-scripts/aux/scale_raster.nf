nextflow.enable.dsl = 2

process set_raster_scale {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)
	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	script:
	// this assumes, that every band is scaled by the same factor and the scaling value is given by FORCE; FORCE does not set an offset to my knowledge
	"""
	if [ \$(gdalinfo ${reflectance} | grep 'NoData' | awk 'BEGIN{FS="="} {if (NR==1) print \$2}') -eq -9999 ]; then
		scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
		scaled_nodata=\$(printf '%.4f' \$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print "scale=4;"\$2" * "sf}' | bc))
		gdal_edit.py -scale \$scale_factor -a_nodata \$scaled_nodata ${reflectance}
	fi
	"""
}

process scale_base_files {
	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	script:
	"""
	scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
	original_nodata=\$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print \$2}')
	gdal_calc.py \
		-A ${reflectance} \
		--outfile=${reflectance} \
		--overwrite \
		--allBands=A \
		--type=Float32 \
		--calc="A*\$scale_factor" \
		--NoDataValue="\$original_nodata" \
		--creation-option="COMPRESS=LZW" \
		--creation-option="PREDICTOR=3"
	"""
}

