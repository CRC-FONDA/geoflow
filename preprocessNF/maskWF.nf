nextflow.enable.dsl = 2

include { mask_pr } from './mask.nf'

workflow mask_BOA {
    take:
        data
    main:
        mask_pr(data)
    emit:
        mask_pr.out
}
