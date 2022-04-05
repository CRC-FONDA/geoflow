nextflow.enable.dsl = 2

process stack {
    input:
    tuple val(TID), /*val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array),*/ path(reflectance), path(bands)

    output:
    // TODO newly created vrt files also need to get carried over!
    tuple val(TID), /*val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array),*/ path(reflectance), path(bands), path("${TID}_full_stack.vrt")

    script:
    """
    full_stack_explode.py --input_files ${bands.flatten().join(' ')} --out_name ${TID}_full_stack.vrt
    """
}

