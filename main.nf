nextflow.enable.dsl = 2

include { build_vrt_stack; explode_base_files; spat_lucas } from './preprocessNF/preprocessing_workflows.nf'
include { mask_layer_stack } from './preprocessNF/mask.nf'
include { calculate_spectral_indices } from './preprocessNF/indices.nf'
include { calc_stms_pr as stms_ls; calc_stms_pr as stms_sen } from './stmsNF/stms.nf'
include { extract_features } from './hl/feature_extraction.nf'

def single_tileP = input -> {
	Boolean tile_x = (input[1][0] =~ /(?<=X00)${params.tx}(?=_Y)/)
	Boolean tile_y = (input[1][0] =~ /(?<=Y00)${params.ty}/)
	//Boolean sensor = (input[1][0] =~ /(?<=LEVEL2_)${params.s0}.*?(?=_)/)

	return tile_x && tile_y
}

// expects FORCE nomenclature
def get_tile = input -> {
    input.toString().split('/')[-2]
}

def get_platform = input -> {
    input.split('_')[-1]
}

// expects FORCE nomenclature
def get_scene_id = input -> {
	last_chunk = input.toString().split('/')[-1]
	last_chunk_list = last_chunk.split('_')[0..<-1]
	
	return last_chunk_list.join('_')
}

// Extract Tile Id, and create a list containing:
//  [tile id, scene identifier, FORCE platform abbreviation, path to BOA, path to QAI]
def spread_input = input -> {
	[get_tile(input[1][0]), input[0], get_platform(input[0]), input[1][0], input[1][1]]
}

// Extract Tile Id, and create a list containing:
//  [tile id, scene identifier, FORCE platform abbreviation, path to BOA, path to QAI]
def add_tile_id = input -> {
	[get_tile(input[1][0]), input[0], get_platform(input[0]), input[1][0], input[1][1]]
}

// [Tile ID, Scene ID, Sensor type, Year, Month, Quarter, [BOA, exploded bands and indices], ordered band stack vrt]
def get_year_month_etc = input -> {
	String year_month = input[1].split('_')[0] // split scene ID
	String year = year_month[0..3]
	Integer month = year_month[4..5] as Double
	Integer quarter = Math.ceil(month as Double / 3) as Integer
	// TODO: DOY, week? -> If so, how the fuck do dates work in groovy?

	return [input[0], input[1], input[2], year, month as String, quarter as String, input[3], input[4]]
}

// [Tile ID, Scene ID, short Sensor, Sensor type, Year, Month, Quarter, [BOA, exploded bands and indices], ordered band stack vrt]
def get_short_sensor = input -> {
	return [input[0], input[1], input[2][0], input[2], input[3], input[4], input[5], input[6], input[7]]
}

workflow {
    Channel
	.fromPath([params.lucas_survey, params.lucas_geom], type: 'file')
	.concat(Channel.of(params.lucas_query, params.lucas_epsg))
	.collect()
	.set( { lucas } )

    spat_lucas(lucas)

    Channel
	.of(params.spectral_indices_mapping)
	.set( { spectral_indices } )

    Channel
	.of(params.calculate_stms)
	.set( { stm_choices } )

    Channel
	.of(params.stm_band_mapping_sentinel)
	.mix( spectral_indices )
	.flatMap()
	.combine( stm_choices )
	.set( { stm_combination_sentinel } )

    Channel
	.of(params.stm_band_mapping_landsat)
	.mix( spectral_indices )
	.flatMap()
	.combine( stm_choices )
	.set( { stm_combination_landsat } )

    // TODO: remove subset
    Channel
        .fromFilePairs(params.input_dirP)
        .take(15)
        .filter( { single_tileP(it) } )
        .map( { spread_input(it) } )
        .set( { ch_dataP } )

    mask_layer_stack(ch_dataP)

    mask_layer_stack
        .out
        .tap( { ch_base_files } )
        .set( { ch_for_indices } )

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
      //  .mix(calc_indices.out, explode_base_files.out)
	// regardless of sensor type, the group size is (as long as all indices can be calculated for all platforms) always N-indices + 1 because explode_base_files returns nested lists
	// as soon as this is not the case anymore, the approach implemented by Fabian in his git pull request would be needed.
        .groupTuple(by: [0, 1], size: 8)
        // [Tile ID, Scene ID, Sensor type, [BOA, exploded bands and indices]]
        .map( { [it[0], it[1], it[2][0], [it[3][0], it[4].flatten()].flatten()] } )
        .set( { ch_grouped_bands } )

    build_vrt_stack(ch_grouped_bands)

    /*
    *   conceptually, new chunk as per proposed flow chart
    */

    // Rest siehe Notizen!
    Channel
	.of(params.stm_timeframes.flatten())
	.set( { stm_timeframes } )

    // TODO indicate (via filename??) what the grouping variable is/was -> this also needs to be communicated via NF channels
    build_vrt_stack
    .out
    .map( { get_year_month_etc(it) } )
    .map( { get_short_sensor(it) } )
    .tap( { ch_stacked_raster } ) // likely needed later on because stms discard sensor/scene specific stack
    .map( { it[0..<-1] } ) // drop vrt stack for next step (calculating stms); I couldn't figure out if it's possible to pass an array to a NF process marked as path -> I don't think so TODO
    .groupTuple(by: [0, 2, 5]) // group by TID, Landsat/Sentinel and month
    .map( { [it[0], it[1], it[2], it[3], it[4], it[5], it[6], it[7].flatten()] } )
    .branch ( {
	sentinel: it[2] == 'S'
	landsat: it[2] == 'L'
    	} )
    .set( { ch_group_stacked_raster } )

    stms_ls(
	ch_group_stacked_raster
		.landsat
		.combine(stm_combination_landsat)
    )

//    stms_sen(
//	ch_group_stacked_raster
//		.sentinel
//		.combine(stm_combination_sentinel)
//    )

    extract_features(
	stms_ls
	    .out
	    .combine( spat_lucas.out )
    )

    // TODO Extraction of Features after stacking rasters again
}

