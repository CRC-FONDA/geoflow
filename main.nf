nextflow.enable.dsl = 2

include { spat_lucas } from './nextflow-scripts/preprocess/preprocessing_workflows.nf'
include { explode_base_files } from './nextflow-scripts/preprocess/explode.nf'
include { build_vrt_stack } from './nextflow-scripts/preprocess/stack.nf'
include { mask_layer_stack } from './nextflow-scripts/preprocess/mask.nf'
include { set_raster_scale } from './nextflow-scripts/aux/scale_raster.nf'
include { calculate_spectral_indices } from './nextflow-scripts/preprocess/indices.nf'
include { calc_stms_pr as stms_ls; calc_stms_pr as stms_sen } from './nextflow-scripts/hl/stms.nf'
include { create_classification_dataset; merge_classification_datasets; train_rf_classifier; predict_classifier } from './nextflow-scripts/hl/classification_processes.nf'
include { stack } from './nextflow-scripts/aux/final_cube.nf'
include { build_class_vrt } from './nextflow-scripts/aux/build_outvrt.nf'

/* NOTE: This expects a cubed data provided or 'managed' by FORCE as input
 * - Flatten (partially) nested return from `Channel.fromFilePairs`
 * - Extract various information from the file path and file name, such as:
 *   - tile ID (generated by FORCE)
 *   - observation date
 *   - sensor name (long)
 *   - single letter sensor abbreviation
 *   - scene ID (i.e. file name of the input file, minus the product 'id'
 *     (such as 'BOA') and file type
 */
def prepare_channel = input -> {
	String reflectance_path = input[1][0]
	String quality_path = input[1][1]
	String tile = reflectance_path.split('/')[-2]
	String scene = input[0]
	String date = scene.split('_')[0]
	String sensor = scene.split('_')[-1]
	String sensor_abbreviation = sensor[0]

	return [tile, date, scene, sensor, sensor_abbreviation, reflectance_path, quality_path]
}

def insert_stm_frame = input -> {
	String stm_frame = input[-2] + '_' + input[-1]

	return [input[0], stm_frame, input[1], input[2], input[3], input[4], input[5], input[6], input[7]]
}

def is_landsat = input -> {
    return input[4] == 'L'
}

workflow {
	Channel
		.fromPath([params.lucas_survey, params.lucas_geom], type: 'file')
		.concat(Channel.of(params.lucas_query, params.lucas_epsg))
		.collect()
		.set({ lucas })

	spat_lucas(lucas)

	Channel
		.of(params.spectral_indices_mapping)
		.set({ spectral_indices })

	Channel
		.of(params.calculate_stms)
		.set({ stm_choices })

	Channel
		.of(params.stm_band_mapping_sentinel)
		.mix( spectral_indices )
		.flatMap()
		.combine( stm_choices )
		.set({ stm_combination_sentinel })

	Channel
		.of(params.stm_band_mapping_landsat)
		.mix( spectral_indices )
		.flatMap()
		.set({ stm_combination_landsat })

	Channel
		.fromFilePairs(params.input_cube)
		.map({ prepare_channel(it) })
		.filter({ is_landsat(it) })
		.filter({ it[1] >= params.processing_timeframe["START"] && it[1] <= params.processing_timeframe["END"] })
		.set({ ch_dataP })

	mask_layer_stack(ch_dataP)

	set_raster_scale(
		mask_layer_stack
			.out
	)

	set_raster_scale
		.out
		.tap({ ch_base_files })
		.set({ ch_for_indices })

	calculate_spectral_indices(
		ch_for_indices
			.combine(
				spectral_indices
				.flatMap()
			)
	)
	
	explode_base_files(ch_base_files)

	// The group size should be set, so that a "package"/"bundle" can be released as soon as everything needed is processed and not
	// we don't have to wait until everything is processed. In theory, there is a function for doing so (grouKey, see https://github.com/nextflow-io/nextflow/issues/796#issuecomment-407108667),
	// but this doesn't work here. Fabian might come up with a solution. Until then, this issue is postponed.
	Channel
		.empty()
		.mix(calculate_spectral_indices.out, explode_base_files.out)
		.combine(params.stm_timeframes) // inserts start and end time as flat elements on the end
		// -> tile, date, scene, sensor, sensor_abbr, BOA, QAI, IDX/SL-VRT, {STM_start, STM_end}
		.map({ insert_stm_frame(it) })
		.filter({ it[2] >= it[1].split('_')[0] && it[2] <= it[1].split('_')[1] }) // filters observations where capture date falls within STM timeframe TODO should be fine, check nonetheless!!
		.groupTuple(by: [0, 1]) // group by tile and STM period
		// [tile, stm period, unique BOA, [indices and flat BOAs]]
		.map({ [it[0], it[1], it[6].unique({ a, b -> a.name <=> b.name }), it[8].flatten()] })
		.set({ ch_grouped_bands })

	/* conceptually, new chunk as per proposed flow chart */
	ch_grouped_bands
		.tap({ ch_stacked_raster }) // likely needed later on because stms discard sensor/scene specific stack
		.set({ ch_group_stacked_raster })

	stms_ls(
	    ch_group_stacked_raster
	        .combine(stm_combination_landsat)
	        .combine(stm_choices)
	)

	stack(
		stms_ls.out.groupTuple(by: 0) // group by tile ID
	)

	stack
		.out
		.tap({ classification_stack })
		.set({ training_stack })

	create_classification_dataset(
		training_stack
			.combine(spat_lucas.out)
	)

	merge_classification_datasets(
		create_classification_dataset
			.out
			.collect()
	)

	train_rf_classifier(
		merge_classification_datasets
			.out
	)

	predict_classifier(
		classification_stack
			.combine(train_rf_classifier.out)
	)

	build_class_vrt(
		predict_classifier
			.out
			.collect()
	)

}

