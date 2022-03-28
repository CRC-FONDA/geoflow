nextflow.enable.dsl = 2

process stack {
    echo true

    input:
    tuple val(TID), val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array), path(bands)

    output:
    tuple val(TID), val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array), path(bands), path("${TID}_full_stack.vrt")

    script:
    /* enmapbox:StackRasterLayers won't work, because temporary/in-between VRTs use absolute file paths which is not
     * beneficial/wanted in my case.
     */
    println bands
}

// take as input what stack process outputs
process rearrange_stack {
    input:
    tuple val(TID), val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array), path(bands), path(full_stack)

    output:
    tuple val(TID), val(stm_uid_array), val(date_array), val(scene_array), val(sensor_array), path(bands), path("${TID}_full_stack.vrt")

    script:
    """
    """
}

