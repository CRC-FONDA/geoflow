nextflow.enable.dsl = 2

include { calc_indices } from './preprocessNF/indicesWF.nf'
include { build_vrt_stack } from './preprocessNF/stackWF.nf'
include { explode_base_files } from './preprocessNF/explodeWF.nf'

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

workflow {
    Channel
        .fromFilePairs(params.input_dirP)
        .take(20)
        .filter( { single_tileP(it) } )
        .map( { sorta_flat(it) } )
        .set( { ch_dataP } )

    // TODO: remove subset
    calc_indices(ch_dataP)

    Channel
        .fromFilePairs(params.input_dirP)
        .take(20)
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
        .groupTuple(by: [0, 1]) // TODO: set size?
        // [Tile ID, Scene ID, Sensor type, BOA, [exploded bands and indices]]
        .map( { [it[0], it[1], it[2][0], it[3][0], it[4].flatten() } )
        .set( { ch_grouped_bands } )

    build_vrt_stack(ch_grouped_bands)

    build_vrt_stack.out.view()
}

