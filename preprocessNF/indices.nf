nextflow.enable.dsl = 2

// TODOOO: These prcocesses currently only work with Sentinel-2. However, they should be compatible with all inputs. Or different processes/sub-workflows for different sensors
// 	one solution could be to split paths/channels prior to calling individual processes

// courtesy to David Frantz for an overview of indices (https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html)

String platform_ndvi(String platform_f) {
    String code_snippet = "(R1@NIR - R1@RED) / (R1@NIR + R1@RED)"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/RED/, "3")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/RED/, "3")
    }
    return ""
}

process ndvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_NDVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_NDVI.tif"), emit: ndvi_out

    script:
    // code="(R1@8 - R1@3) / (R1@8 + R1@3)" \
    """
    qgis_process run enmapbox:RasterMath -- \
    ${platform_ndvi($platform)}
    R1=$reflectance \
    outputRaster=${identifier}_NDVI-temp.tif

    adjust_indices.py ${identifier}_NDVI-temp.tif ${identifier}_NDVI.tif
    """
}

process evi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_EVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_EVI.tif"), emit: evi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="2.5 * ((R1@8 - R1@3) / (R1@8 + 6 * R1@3 - 7.5 * R1@1 + 1))" \
    R1=$reflectance \
    outputRaster=${identifier}_EVI-temp.tif

    adjust_indices.py ${identifier}_EVI-temp.tif ${identifier}_EVI.tif
    """
}

process nbr {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_NBR.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_NBR.tif"), emit: nbr_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - R1@10) / (R1@8 + R1@10)" \
    R1=$reflectance \
    outputRaster=${identifier}_NBR-temp.tif

    adjust_indices.py ${identifier}_NBR-temp.tif ${identifier}_NBR.tif
    """
}

process ndti {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_NDTI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_NDTI.tif"), emit: ndti_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@9 - R1@10) / (R1@9 + R1@10)" \
    R1=$reflectance \
    outputRaster=${identifier}_NDTI-temp.tif

    adjust_indices.py ${identifier}_NDTI-temp.tif ${identifier}_NDTI.tif
    """
}

process arvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_ARVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_ARVI.tif"), emit: arvi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - (R1@3 - (R1@1 - R1@3))) / (R1@8 + (R1@3 - (R1@1 - R1@3)))" \
    R1=$reflectance \
    outputRaster=${identifier}_ARVI-temp.tif

    adjust_indices.py ${identifier}_ARVI-temp.tif ${identifier}_ARVI.tif
    """
}

process savi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_SAVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_SAVI.tif"), emit: savi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - R1@3) / (R1@8 + R1@3 + 0.5) * (1 + 0.5)" \
    R1=$reflectance \
    outputRaster=${identifier}_SAVI-temp.tif

    adjust_indices.py ${identifier}_SAVI-temp.tif ${identifier}_SAVI.tif
    """
}

process sarvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_SARVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), path("${identifier}_SARVI.tif"), emit: sarvi_out

    script:
    """
    qgis_process run enmapbox:RasterMath -- \
    code="(R1@8 - (R1@3 - (R1@1 - R1@3))) / (R1@8 + (R1@3 - (R1@1 - R1@3)) + 0.5) * (1 + 0.5)" \
    R1=$reflectance \
    outputRaster=${identifier}_SARVI-temp.tif

    adjust_indices.py ${identifier}_SARVI-temp.tif ${identifier}_SARVI.tif
    """
}




