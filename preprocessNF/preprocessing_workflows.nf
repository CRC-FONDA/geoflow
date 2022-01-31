nextflow.enable.dsl = 2

include { mask_pr } from './mask.nf'
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
