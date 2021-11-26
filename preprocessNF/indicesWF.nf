nextflow.enable.dsl = 2

include { ndvi; evi; nbr; ndti } from './indices_stms.nf'

workflow calc_indices {
    take:
        data
    main:
        ndvi(data)
        evi(data)
        nbr(data)
        ndti(data)
}

