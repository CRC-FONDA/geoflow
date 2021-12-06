nextflow.enable.dsl = 2

include { stack; build_vrt_stack_process } from './stack.nf'

workflow stack_bands {
    take:
	grouped_things
    main:
	stack(grouped_things)
}

workflow build_vrt_stack {
    take:
	data
    main:
	build_vrt_stack_process(data)
}

