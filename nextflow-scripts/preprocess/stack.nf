nextflow.enable.dsl = 2

process build_vrt_stack {
	label 'small_memory'
//    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_STACK.vrt', overwrite: true

    input:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path(bands)

    output:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path(bands), path("${identifier}_STACK.vrt")

    script:
    """
    mkdir vrt
    mv ${bands} vrt
    build_vrt-stack.py vrt ${identifier}_STACK.vrt
    mv vrt/* .
    """
}

