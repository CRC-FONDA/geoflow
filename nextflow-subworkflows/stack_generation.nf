nextflow.enable.dsl = 2

include { stack } from './../nextflow-scripts/aux/final_cube.nf'

workflow stack_generation {
	take:
		spectral_temporal_metrics_stack

	main:
		stack(
			spectral_temporal_metrics_stack
			.out
			// group by tile; assumes that no empty STM periods exist (i.e. a period for which there is no observation)
			.groupTuple(
				by: 0,
				size: params.stm_timeframes.size() * (params.stm_band_mapping_landsat.size() + params.spectral_indices_mapping.size()),
				remainder: false
			)
		)

	emit:
		stack.out
}
