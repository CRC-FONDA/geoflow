nextflow.enable.dsl = 2

process stack {
    input:
    tuple val(TID), path(bands)

    output:
    tuple val(TID), path(bands), path("*_slVRT.vrt"), path("${TID}_full_stack.vrt")

    script:
    """
    full_stack_explode.py --input_files ${bands.flatten().join(' ')} --out_name ${TID}_full_stack.vrt
    """
}

