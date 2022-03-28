nextflow.enable.dsl = 2

process mask_layer_stack {
    input:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

    output:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

    script:
    """
    QAI2bit_mask.py -qf ${qai} -of mask_raster.tif -qb ${params.quality_cat}
    mv ${reflectance} BOA.tif
    qgis_process run enmapbox:ApplyMaskLayerToRasterLayer -- raster=BOA.tif mask=mask_raster.tif outputRaster=${reflectance}
    """
}