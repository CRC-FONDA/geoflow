nextflow.enable.dsl = 2

process scale_files {
	label 'small_memory'

	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path("${identifier}_BOA.tif"), path(qai)

	script:
	"""
	scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
	original_nodata=\$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print \$2}')
	#scaled_nodata=\$(printf '%.4f' \$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print "scale=4;"\$2" * "sf}' | bc))
	band_names=\$(gdalinfo ${reflectance} | grep 'Description' | awk 'BEGIN{FS=" = "} {print NR"="\$2}')

	gdal_calc.py \
		-A ${reflectance} \
		--outfile=${identifier}_BOA.tif \
		--overwrite \
		--allBands=A \
		--type=Float32 \
		--calc="A*\$scale_factor" \
		--NoDataValue="\$original_nodata" \
		--creation-option="COMPRESS=LZW" \
		--creation-option="PREDICTOR=3"

	set_description.py --input_file ${identifier}_BOA.tif --names \$band_names
	"""
}

