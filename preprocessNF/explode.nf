nextflow.enable.dsl = 2

process explode_pr {
    label 'debug'

    // TODO: different parameter or at least name it differently?
    cpus params.n_cpus_indices

    input:
    tuple val(TID), val(identifier), val(platform), path(reflectance), path(qai)

    output:
    tuple val(TID), val(identifier), val(platform),  path(reflectance), path("*.vrt")

    script:
    """
    explode.py ${reflectance}
    """
}

