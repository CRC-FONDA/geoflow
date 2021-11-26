nextflow.enable.dsl = 2

// TODOOO: These prcocesses currently only work with Sentinel-2. However, they should be compatible with all inputs. Or different processes/sub-workflows for different sensors
// courtesy to David Frantz for an overview of indices (https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html)

process ndvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NDVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NDVI.tif"), emit: ndvi_out

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

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_EVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_EVI.tif"), emit: evi_out

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

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NBR.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NBR.tif"), emit: nbr_out

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

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_NDTI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_NDTI.tif"), emit: ndti_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@9 - R1@10) / (R1@9 + R1@10)" \
    R1=$reflectance \
    outputRaster=${identifier}_NDTI.tif
    """
}

process arvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_ARVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_ARVI.tif"), emit: arvi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - (R1@3 - (R1@1 - R1@3))) / (R1@8 + (R1@3 - (R1@1 - R1@3)))" \
    R1=$reflectance \
    outputRaster=${identifier}_ARVI.tif
    """
}

process savi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_SAVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_SAVI.tif"), emit: savi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - R1@3) / (R1@8 + R1@3 + 0.5) * (1 + 0.5)" \
    R1=$reflectance \
    outputRaster=${identifier}_SAVI.tif
    """
}

process sarvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir params.output_dir_indices, mode: 'copy', pattern: '*_SARVI.tif', overwrite: true

    input:
    tuple val(identifier), path(reflectance), path(qai)

    output:
    tuple val(identifier), path(reflectance), path(qai), path("${identifier}_SARVI.tif"), emit: sarvi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - (R1@3 - (R1@1 - R1@3))) / (R1@8 + (R1@3 - (R1@1 - R1@3)) + 0.5) * (1 + 0.5)" \
    R1=$reflectance \
    outputRaster=${identifier}_SARVI.tif
    """
}
