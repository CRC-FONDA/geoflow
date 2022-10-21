nextflow.enable.dsl = 2

process mask_layer_stack {
	label 'small_memory'

    input:
    tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

    output:
    tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path("${identifier}_BOA_masked.tif"), path(qai)

    script:
    """
    QAI2bit_mask.py -qf ${qai} -of mask_raster.tif -qb ${params.quality_cat}
    qgis_process run enmapbox:ApplyMaskLayerToRasterLayer -- raster=${reflectance} mask=mask_raster.tif outputRaster=${identifier}_BOA_masked.tif
    """
}
