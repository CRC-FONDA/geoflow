nextflow.enable.dsl = 2

process explode_base_files {
	label 'small_memory'

    input:
    tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai)

    output:
    tuple val(TID), val(date), val(identifier), val(sensor), val(sensor_abbr), path(reflectance), path(qai), path("*.vrt")

    script:
    """
    explode.py ${reflectance}
    """
}

