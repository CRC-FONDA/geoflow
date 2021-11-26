nextflow.enable.dsl = 2

include { ndvi; evi; nbr; ndti; arvi; savi; sarvi } from './indices_stms.nf'

// TODO: some kind of "switch" to choose which indices to compute?

workflow calc_indices {
    take:
        data
    main:
        ndvi(data)
        evi(data)
        nbr(data)
        ndti(data)
        arvi(data)
        savi(data)
        sarvi(data)
}

