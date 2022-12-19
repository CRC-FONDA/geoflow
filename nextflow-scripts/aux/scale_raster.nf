nextflow.enable.dsl = 2

process scale_files {
	label 'small_memory'

	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path(masked_reflectance), path(mask_raster)

	output:
	// TODO here, an input gets overwritten!
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path("${identifier}_BOA.tif"), path(qai)

	script:
	"""
	scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
	original_nodata=\$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print \$2}')
	band_names=\$(gdalinfo ${reflectance} | grep 'Description' | awk 'BEGIN{FS=" = "} {print NR"="\$2}')

	geoflow_calc.py \
	    --input-file ${masked_reflectance} \
	    --output-file ${identifier}_BOA.tif \
	    --eType Int16 \
	    --scale-factor 1 \
	    --offset 0 \
	    --mask-band global \
	    --no-data \$original_nodata

	set_description.py --input_file ${identifier}_BOA.tif --names \$band_names
	"""
}

