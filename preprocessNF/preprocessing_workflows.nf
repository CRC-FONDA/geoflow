nextflow.enable.dsl = 2

include { mask_pr } from './mask.nf'
include { ndvi; evi; nbr; ndti; arvi; savi; sarvi } from './indices.nf'
include { explode_pr } from './explode.nf'
include { build_vrt_stack_process } from './stack.nf'

workflow mask_BOA {
    take:
        data
    main:
        mask_pr(data)
    emit:
        mask_pr.out
}

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

workflow explode_base_files {
	take:
		data
	main:
		explode_pr(data)
	emit:
		explode_pr.out
}

workflow build_vrt_stack {
    take:
        data
    main:
        build_vrt_stack_process(data)
    emit:
        build_vrt_stack_process.out
}
