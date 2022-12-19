nextflow.enable.dsl = 2

process mask_and_scale {
	label 'small_memory'

	input:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

	output:
	tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance)

	script:
	"""
    scale_factor=\$(printf '%.4f' \$(gdalinfo -mdd force ${reflectance} | grep 'Scale=' | awk 'BEGIN{FS="="} {if (NR==1) print "scale=4;1/"\$2}' | bc))
	original_nodata=\$(gdalinfo ${reflectance} | grep 'NoData' | awk -v sf="\$scale_factor" 'BEGIN{FS="="} {if (NR==1) print \$2}')
	band_names=\$(gdalinfo ${reflectance} | grep 'Description' | awk 'BEGIN{FS=" = "} {print NR"="\$2}')

    QAI2bit_mask.py -qf ${qai} -of mask_raster.tif -qb ${params.quality_cat}
    vrt_add_mask.py --input-file ${reflectance} --mask mask_raster.tif --output-file masked_reflectance.vrt

	geoflow_calc.py \
	    --input-file masked_reflectance.vrt \
	    --output-file ${identifier}.tif \
	    --eType Int16 \
	    --scale-factor 1 \
	    --offset 0 \
	    --mask-band global \
	    --no-data \$original_nodata

	mv ${identifier}.tif ${reflectance}

	set_description.py --input_file ${reflectance} --names \$band_names
	"""
}
