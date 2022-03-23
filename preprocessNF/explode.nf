nextflow.enable.dsl = 2

process explode_pr {
    input:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

    output:
    tuple val(TID), val(stm_uid), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path("*.vrt")

    script:
    """
    explode.py ${reflectance}
    """
}

