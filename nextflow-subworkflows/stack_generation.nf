nextflow.enable.dsl = 2

include { stack } from '../nextflow-scripts/aux/final_cube.nf'

workflow stack_generation {
	take:
		spectral_temporal_metrics_stack, spectral_temporal_metrics_periods, spectral_bands_array, spectral_indices_array 
	main:
		stack(
			spectral_temporal_metrics_stack
			.out
			// group by tile; assumes that no empty STM periods exist (i.e. a period for which there is no observation)
			.groupTuple(
				by: 0,
				size: spectral_temporal_metrics_periods.size() * (spectral_bands_array.size() + spectral_indices_array.size()),
				remainder: false
			)
		)
	emit:
		stack.out
}
