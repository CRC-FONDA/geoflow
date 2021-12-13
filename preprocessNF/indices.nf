nextflow.enable.dsl = 2

// courtesy to David Frantz for an overview of indices (https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html)

Map <String, String> SEN2_bands = [
        "BLUE": "1",
        "GREEN": "2",
        "RED": "3",
        "RE1": "4",
        "RE2": "5",
        "RE3": "6",
        "BNIR": "7",
        "NIR": "8",
        "SWIR1": "9",
        "SWIR2": "10"
]

Map <String, String> LND_bands = [
        "BLUE": "1",
        "GREEN": "2",
        "RED": "3",
        "NIR": "4",
        "SWIR1": "5",
        "SWIR2": "6"
]

Map <String, String> Indices = [
        "NDVI": "(R1@NIR - R1@RED) / (R1@NIR + R1@RED)",
        "EVI": "2.5 * ((R1@NIR - R1@RED) / (R1@NIR + 6 * R1@RED - 7.5 * R1@BLUE + 1))",
        "NBR": "(R1@NIR - R1@SWIR2) / (R1@NIR + R1@SWIR2)",
        "NDTI": "(R1@SWIR1 - R1@SWIR2) / (R1@SWIR1 + R1@SWIR2)",
        "ARVI": "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)))",
        "SAVI": "(R1@NIR - R1@RED) / (R1@NIR + R1@RED + 0.5) * (1 + 0.5)",
        "SARVI": "(R1@NIR - (R1@RED - (R1@BLUE - R1@RED))) / (R1@NIR + (R1@RED - (R1@BLUE - R1@RED)) + 0.5) * (1 + 0.5)",
]

String platform_spectral_index(String platform_f, String code_snippet, Map <String, String> S_bands, Map <String, String> L_bands) {
    if (platform_f =~ /LND04|LND05|LND07|LND08|LNDLG/) {
        for (band in L_bands)
            code_snippet = code_snippet.replaceAll(band.key, band.value)
    } else if (platform_f =~ /SEN2A|SEN2B|SEN2L/) {
        for (band in S_bands)
            code_snippet = code_snippet.replaceAll(band.key, band.value)
    }
    return code_snippet
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
    String code_str = platform_spectral_index(platform, Indices["NDVI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_EVI.tif"), emit: evi_out

    script:
    String code_str = platform_spectral_index(platform, Indices["EVI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_NBR.tif"), emit: nbr_out

    script:
    String code_str = platform_spectral_index(platform, Indices["NBR"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_NDTI.tif"), emit: ndti_out

    script:
    String code_str = platform_spectral_index(platform, Indices["NDTI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_ARVI.tif"), emit: arvi_out

    script:
    String code_str = platform_spectral_index(platform, Indices["ARVI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_SAVI.tif"), emit: savi_out

    script:
    String code_str = platform_spectral_index(platform, Indices["SAVI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
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
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform), path("${identifier}_SARVI.tif"), emit: sarvi_out

    script:
    String code_str = platform_spectral_index(platform, Indices["SARVI"], SEN2_bands, LND_bands)

    """
    qgis_process run enmapbox:RasterMath -- \
    code=\"${code_str}\" \
    R1=$reflectance \
    outputRaster=${identifier}_SARVI-temp.tif

    adjust_indices.py ${identifier}_SARVI-temp.tif ${identifier}_SARVI.tif
    """
}
