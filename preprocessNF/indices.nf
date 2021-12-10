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
    String code_str = platform_ndvi(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_NDVI-temp.tif

    adjust_indices.py ${identifier}_NDVI-temp.tif ${identifier}_NDVI.tif
    """
}

String platform_evi(String platform_f) {
    String code_snippet = "2.5 * ((R1@NIR - R1@RED) / (R1@NIR + 6 * R1@RED - 7.5 * R1@BLUE + 1))"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    }
    return ""
}

process evi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_EVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_EVI.tif"), emit: evi_out

    script:
    String code_str = platform_evi(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_EVI-temp.tif

    adjust_indices.py ${identifier}_EVI-temp.tif ${identifier}_EVI.tif
    """
}

String platform_nbr(String platform_f) {
    String code_snippet = "(R1@NIR - R1@SWIR2) / (R1@NIR + R1@SWIR2)"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/SWIR2/, "6")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/SWIR2/, "10")
    }
    return ""
}

process nbr {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_NBR.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_NBR.tif"), emit: nbr_out

    script:
    String code_str = platform_nbr(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_NBR-temp.tif

    adjust_indices.py ${identifier}_NBR-temp.tif ${identifier}_NBR.tif
    """
}

String platform_ndti(String platform_f) {
    String code_snippet = "(R1@SWIR1 - R1@SWIR2) / (R1@SWIR1 + R1@SWIR2)"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/SWIR1/, "5").replaceAll(/SWIR2/, "6")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/SWIR1/, "9").replaceAll(/SWIR2/, "10")
    }
    return ""
}

process ndti {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_NDTI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_NDTI.tif"), emit: ndti_out

    script:
    String code_str = platform_ndti(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_NDTI-temp.tif

    adjust_indices.py ${identifier}_NDTI-temp.tif ${identifier}_NDTI.tif
    """
}

String platform_arvi(String platform_f) {
    String code_snippet = "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)))"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    }
    return ""
}

process arvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_ARVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_ARVI.tif"), emit: arvi_out

    script:
    String code_str = platform_arvi(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_ARVI-temp.tif

    adjust_indices.py ${identifier}_ARVI-temp.tif ${identifier}_ARVI.tif
    """
}

String platform_savi(String platform_f) {
    String code_snippet = "(R1@NIR - R1@RED) / (R1@NIR + R1@RED + 0.5) * (1 + 0.5)"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/RED/, "3")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/RED/, "3")
    }
    return ""
}

process savi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_SAVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_SAVI.tif"), emit: savi_out

    script:
    String code_str = platform_savi(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_SAVI-temp.tif

    adjust_indices.py ${identifier}_SAVI-temp.tif ${identifier}_SAVI.tif
    """
}

String platform_sarvi(String platform_f) {
    String code_snippet = "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)) + 0.5) * (1 + 0.5)"
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        return code_snippet.replaceAll(/NIR/, "4").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        return code_snippet.replaceAll(/NIR/, "8").replaceAll(/RED/, "3").replaceAll(/BLUE/, "1")
    }
    return ""
}

process sarvi {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_SARVI.tif', overwrite: true

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_SARVI.tif"), emit: sarvi_out

    script:
    String code_str = platform_sarvi(platform)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_SARVI-temp.tif

    adjust_indices.py ${identifier}_SARVI-temp.tif ${identifier}_SARVI.tif
    """
}




