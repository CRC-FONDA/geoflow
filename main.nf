nextflow.enable.dsl = 2

include { calc_ndvi } from './preprocessNF/indices_stms.nf'

workflow {

    ch_data = Channel.fromFilePairs("/data/ard/*{BOA,QAI}.tif")
    ch_data.view { file -> "path: $file" }
}
