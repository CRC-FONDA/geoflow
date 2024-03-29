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
//  [tile id, scene identifier, FORCE platform abbreviation, [path to BOA, path to QAI]]
def add_tile_id = input -> {
	[get_tile(input[1][0]), input[0], get_platform(input[0]), input[1]]
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
        .map( { add_tile_id(it) } )
        .flatten()
        .set( { base_files } )

    explode_base_files(ch_dataP)


    // set group size might not be desirable here because it is affected by indices computed -> set via environment variable??
    // Can I use maps in channels?
    Channel
        .empty()
        .mix(calc_indices.out, explode_base_files.out)
        .groupTuple(by: [0, 1]) // TODO: set size?
        .map( { [it[0], it[1], it[2], it[3].flatten()] } )
        .set( { ch_grouped_bands } )

    build_vrt_stack(ch_grouped_bands)

    build_vrt_stack.out.view()
}

