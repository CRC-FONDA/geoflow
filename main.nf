nextflow.enable.dsl = 2

include { calc_indices } from './preprocessNF/indicesWF.nf'

def single_tile = input -> { 
    Boolean tile_x = (input =~ /(?<=X00)${params.tx}(?=_Y)/)
    Boolean tile_y = (input =~ /(?<=Y00)${params.ty}/)
    Boolean sensor = (input =~ /(?<=LEVEL2_)[${params.s0}].*?(?=_)/)

    return tile_x && tile_y && sensor
}

def single_tileP = input -> {
    Boolean tile_x = (input[1][0] =~ /(?<=X00)${params.tx}(?=_Y)/)
    Boolean tile_y = (input[1][0] =~ /(?<=Y00)${params.ty}/)
    // due to the bracket notation, this can (currently) only filter for the first letter
    Boolean sensor = (input[1][0] =~ /(?<=LEVEL2_)[${params.s0}].*?(?=_)/)

    return tile_x && tile_y && sensor
}

def sorta_flat = input -> {
	[input[0], input[1][0], input[1][1]]
}

workflow {
//    ch_data = Channel.fromPath(params.input_dir)
//    ch_data.filter( { single_tile(it) } ).view { file -> "path: $file" }

    ch_dataP = Channel.fromFilePairs(params.input_dirP)
    // TODO: remove subset
    // TODO: is the outpu of calc_ndvi actually what I want?
    calc_indices(ch_dataP.take(20).filter( { single_tileP(it) } ).map( { sorta_flat(it) } ))
}

