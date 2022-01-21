nextflow.enable.dsl = 2

process mask_pr {
    label 'debug'

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path(reflectance)

    script:
    """
    QAI2bit_mask.py -qf ${qai} -of mask_raster.tif -qb ${params.quality_cat}
    mv ${reflectance} BOA.tif
    qgis_process run enmapbox:ApplyMaskLayerToRasterLayer -- raster=BOA.tif mask=mask_raster.tif outputRaster=${reflectance}
    """
}
