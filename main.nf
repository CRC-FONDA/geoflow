nextflow.enable.dsl = 2

include { calc_indices } from './preprocessNF/indicesWF.nf'
include { build_vrt_stack } from './preprocessNF/stackWF.nf'
include { explode_base_files } from './preprocessNF/explodeWF.nf'
include { calc_stms_landsat; calc_stms_sentinel } from './stmsNF/stmsWF.nf'

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

// expects FORCE nomenclature
def get_scene_id = input -> {
	last_chunk = input.toString().split('/')[-1]
	last_chunk_list = last_chunk.split('_')[0..<-1]
	
	return last_chunk_list.join('_')
}

def get_platform = input -> {
    input.split('_')[-1]
}

// Extract Tile Id, and create a list containing:
//  [tile id, scene identifier, FORCE platform abbreviation, path to BOA, path to QAI]
def sorta_flat = input -> {
	[get_tile(input[1][0]), input[0], get_platform(input[0]), input[1][0], input[1][1]]
}

// Extract Tile Id, and create a list containing:
//  [tile id, scene identifier, FORCE platform abbreviation, path to BOA, path to QAI]
def add_tile_id = input -> {
	[get_tile(input[1][0]), input[0], get_platform(input[0]), input[1][0], input[1][1]]
}

def get_year_month_etc = input -> {
	String year_month = input[1].split('_')[0] // split scene ID
	String year = year_month[0..3]
	Integer month = year_month[4..5] as Double
	Integer quarter = Math.ceil(month as Double / 3) as Integer
	// TODO: DOY, week? -> If so, how the fuck do dates work in groovy?

	return [input[0], input[1], input[2], year, month as String, quarter as String, input[3], input[4]]
}

def get_abstract_sensor = input -> {
	return [input[0], input[1], input[2][0], input[2], input[3], input[4], input[5], input[6], input[7]]


workflow {
    Channel
        .fromFilePairs(params.input_dirP)
        .take(70)
        .filter( { single_tileP(it) } )
        .map( { sorta_flat(it) } )
        .set( { ch_dataP } )

    // TODO: remove subset
    calc_indices(ch_dataP)

    Channel
        .fromFilePairs(params.input_dirP)
        .take(70)
        .filter( { single_tileP(it) } )
        .map( { sorta_flat(it) } )
        .set( { ch_base_files } )

    explode_base_files(ch_base_files)


    // The group size should be set, so that a "package"/"bundle" can be released as soon as everything needed is processed and not
    // we don't have to wait until everything is processed. In theory, there is a function for doing so (grouKey, see https://github.com/nextflow-io/nextflow/issues/796#issuecomment-407108667),
    // but this doesn't work here. Fabian might come up with a solution. Until then, this issue is postponed.
    Channel
        .empty()
        .mix(calc_indices.out, explode_base_files.out)
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

    build_vrt_stack
    .out
    // [Tile ID, Scene ID, Sensor type, Year, Month, Quarter, [BOA, exploded bands and indices], ordered band stack vrt]
    .map( { get_year_month_etc(it) } )
    // [Tile ID, Scene ID, abstract Sensor, Sensor type, Year, Month, Quarter, [BOA, exploded bands and indices], ordered band stack vrt]
    .map( { get_abstract_sensor(it) } )
    .tap( { ch_stacked_raster } ) // likely needed later on because stms discard sensor/scene specific stack
    .map( { it[0..<-1] } ) // drop vrt stack for next step (calculating stms); I couldn't figure out if it's possible to pass an array to a NF process marked as path -> I don't think so TODO
    .groupTuple(by: [0, 2, 5]) // group by TID, Landsat/Sentinel and month
    .map( { [it[0], it[1], it[2], it[3], it[4], it[5], it[6], it[7].flatten()] } )
    .branch ( {
	sentinel: it[2] == 'S'
	landsat: it[2] == 'L'
	other: true
    	} )
    .set( { ch_group_stacked_raster } )

    // TODO Workaround until enmapbox is capable of producing multi band rasters as output
    calc_stms_landsat(ch_group_stacked_raster.landsat)
    calc_stms_sentinel(ch_group_stacked_raster.sentinel)

}

