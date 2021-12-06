nextflow.enable.dsl = 2

include { calc_indices } from './preprocessNF/indicesWF.nf'
include { stack_bands; build_vrt_stack } from './preprocessNF/stackWF.nf'
include { explode_base_files } from './preprocessNF/explodeWF.nf'
//include { build_vrt_stack } from './preprocessNF/stackWF.nf

def single_tileP = input -> {
	Boolean tile_x = (input[1][0] =~ /(?<=X00)${params.tx}(?=_Y)/)
	Boolean tile_y = (input[1][0] =~ /(?<=Y00)${params.ty}/)
	Boolean sensor = (input[1][0] =~ /(?<=LEVEL2_)${params.s0}.*?(?=_)/)

	return tile_x && tile_y && sensor
}

def single_tile_flat  = input -> {
        Boolean tile_x = (input =~ /(?<=X00)${params.tx}(?=_Y)/)
        Boolean tile_y = (input =~ /(?<=Y00)${params.ty}/)
        Boolean sensor = (input =~ /(?<=LEVEL2_)${params.s0}.*?(?=_)/)

        return tile_x && tile_y && sensor
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

def sorta_flat = input -> {
	[get_tile(input[1][0]), input[0], input[1][0], input[1][1]]
}

// not used anymore
def remove_duplicates = input -> {
	[input[0], input[1], input[2][0], input[3][0], input[4]]
}

def extract_tile_and_identifier = input -> {
	[get_tile(input), get_scene_id(input), input]
}

def add_tile_id = input -> {
	[get_tile(input[1][0]), input[0], input[1]]
}

workflow {
    ch_dataP = Channel
	.fromFilePairs(params.input_dirP)
	.take(20)
	.filter( { single_tileP(it) } )
	.map( { sorta_flat(it) } )

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


    // TODO: Can I guarantee the order of [BOA, QAI, INDICES]? Can I name those?
    // set group size might not be desirable here becaus it is affected by indices computed -> set via environment variable??
    Channel
	.empty()
	.mix(calc_indices.out, explode_base_files.out)
	.groupTuple(by:[0, 1]) // TODO: set size?
	.map( { [it[0], it[1], it[2].flatten()] } )
	.set( { ch_grouped_bands } )

    build_vrt_stack(ch_grouped_bands)

    build_vrt_stack.out.view()

//    Channel
//	.fromPath("/data/Dagobah/fonda/shk/test_out/*/*.tif") // TODO: Don't hardcode this shit!
//	.map( { extract_tile_and_identifier(it) } )
//	.mix(base_files)
//	.groupTuple(by: [0, 1]) // TODO: set size?
//	.map( { [it[0], it[1], it[2].flatten()] } )
//	.map( { remove_duplicates(it) } )
//	.set( { test } )

//    test.view()

//    stack_bands(ch_grouped_bands)
}

