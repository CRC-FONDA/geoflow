nextflow.enable.dsl = 2

include { explode_pr } from './explode.nf'

workflow explode_base_files {
	take:
		data
	main:
		explode_pr(data)
	emit:
		explode_pr.out		
}

