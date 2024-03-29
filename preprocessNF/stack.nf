nextflow.enable.dsl = 2

process stack {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_stacked.vrt', overwrite: true

    input:
	tuple val(TID), val(ID), val(platform), path(BOA), path(QAI), path(INDICES)

    output:
	tuple val(TID), val(ID), val(platform), path(BOA), path(QAI), path(INDICES), path("${ID}_stacked.vrt")
    
    script:
    """
    FileArray=(${BOA} ${INDICES})
    for vrtFile in \${FileArray[*]};
    do
	# previously: echo....
	readlink -f \$vrtFile >> vrt_files.txt;
    done
    gdalbuildvrt -input_file_list vrt_files.txt "${ID}_stacked.vrt"
    """
}

process build_vrt_stack_process {
    label 'debug'

    cpus params.n_cpus_indices

    publishDir "${params.output_dir_indices}/${TID}", mode: 'copy', pattern: '*_STACK.vrt', overwrite: true

    input:
	tuple val(TID), val(identifier), val(platform), path(bands)

    output:
	tuple val(TID), val(identifier), val(platform), path("${identifier}_STACK.vrt")

    script:
    """
    mkdir tmp
    build_vrt-stack.py tmp ${bands}
    mv ./tmp/* .
    """
}

