nextflow.enable.dsl = 2

include { ndvi; evi; nbr; ndti; arvi; savi; sarvi } from './indices.nf'

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
    emit:
        ndvi.out.ndvi_out
        evi.out.evi_out
        nbr.out.nbr_out
	    ndti.out.ndti_out
        arvi.out.arvi_out
        savi.out.savi_out
	    sarvi.out.sarvi_out
}

