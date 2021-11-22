nextflow.enable.dsl = 2

include { calc_ndvi } from './preprocessNF/indices_stms.nf'

ch_data = Channel.fromFilePairs = "/data/ard/*{BOA,QAI}.tif"

workflow {
    take:
        ch_data
    main:
        calc_ndvi(
            ch_data
            .take( 10 )
        )
    emit:
        main_out = calc_ndvi.ch_ndv    
}

main_out.view()