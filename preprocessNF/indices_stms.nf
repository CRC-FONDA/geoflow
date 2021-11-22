nextflow.enable.dsl = 2

process calc_ndvi {
    echo true
    input:
    tuple path(reflectance), path(qai)

    output:
    tuple path(reflectance), path(qai), path('ndvi.tif'), emit: ch_ndvi

    script:
    /*"""
    qgis_process run enmapbox:RasterMath -- \
    code="2.5 * ((R1@4 - R1@3) / (R1@4 + 6 * R1@3 - 7.5 * R1@1 + 1))" \
    R1=$reflectace \
    outputRaster=ndvi.tif
    """*/
    """
    echo '$reflectance with respective $qai'
    """
}