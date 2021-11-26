nextflow.enable.dsl = 2

// TODOOO: These prcocesses currently only work with Sentinel-2. However, they should be compatible with all inputs. Or different processes/sub-workflows for different sensors
// courtesy to David Frantz for an overview of indices (https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html)

process ndvi {
    label 'debug'

    cpus params.n_cpus_ndvi

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NDVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NDVI.tif")//, emit: ch_ndvi

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - R1@3) / (R1@8 + R1@3)" \
    R1=$reflectance \
    outputRaster=${identifier}_NDVI.tif
    """
}

process evi {
    label 'debug'

    cpus params.n_cpus_ndvi

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_EVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_EVI.tif")//, emit: ch_ndvi

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="2.5 * ((R1@8 - R1@3) / (R1@8 + 6 * R1@3 - 7.5 * R1@1 + 1))" \
    R1=$reflectance \
    outputRaster=${identifier}_EVI.tif
    """
}

process nbr {
    label 'debug'

    cpus params.n_cpus_ndvi

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NBR.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NBR.tif")//, emit: ch_ndvi

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - R1@10) / (R1@8 + R1@10)" \
    R1=$reflectance \
    outputRaster=${identifier}_NBR.tif
    """
}

process ndti {
    label 'debug'

    cpus params.n_cpus_ndvi

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NDTI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NDTI.tif")//, emit: ch_ndvi

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@9 - R1@10) / (R1@9 + R1@10)" \
    R1=$reflectance \
    outputRaster=${identifier}_NDTI.tif
    """
}


