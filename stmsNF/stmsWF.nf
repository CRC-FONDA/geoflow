nextflow.enable.dsl = 2

include { stm_BLUE_pr; stm_GREEN_pr; stm_RED_pr; stm_RE1_pr; stm_RE2_pr; stm_RE3_pr; stm_BNIR_pr; stm_NIR_pr; stm_SWIR1_pr; stm_SWIR2_pr; stm_NDVI_pr; stm_NBR_pr; stm_NDTI_pr; stm_SAVI_pr; stm_SARVI_pr; stm_EVI_pr; stm_ARVI_pr } from './stms.nf'

workflow calc_stms_landsat {
	take:
		data
	 main:
                stm_BLUE_pr(data)
                stm_GREEN_pr(data)
                stm_RED_pr(data)
                stm_NIR_pr(data)
                stm_SWIR1_pr(data)
                stm_SWIR2_pr(data)
                stm_NDVI_pr(data)
                stm_NBR_pr(data)
                stm_NDTI_pr(data)
                stm_SAVI_pr(data)
                stm_SARVI_pr(data)
                stm_EVI_pr(data)
                stm_ARVI_pr(data)

        emit:
                stm_BLUE_pr.out
                stm_GREEN_pr.out
                stm_RED_pr.out
                stm_NIR_pr.out
                stm_SWIR1_pr.out
                stm_SWIR2_pr.out
                stm_NDVI_pr.out
                stm_NBR_pr.out
                stm_NDTI_pr.out
                stm_SAVI_pr.out
                stm_SARVI_pr.out
                stm_EVI_pr.out
                stm_ARVI_pr.out
}

workflow calc_stms_sentinel {
	take:
		data
	main:
		stm_BLUE_pr(data)
		stm_GREEN_pr(data)
		stm_RED_pr(data)
		stm_RE1_pr(data)
		stm_RE2_pr(data)
		stm_RE3_pr(data)
		stm_BNIR_pr(data)
		stm_NIR_pr(data)
		stm_SWIR1_pr(data)
		stm_SWIR2_pr(data)
		stm_NDVI_pr(data)
		stm_NBR_pr(data)
		stm_NDTI_pr(data)
		stm_SAVI_pr(data)
		stm_SARVI_pr(data)
		stm_EVI_pr(data)
		stm_ARVI_pr(data)

	emit:
		stm_BLUE_pr.out
                stm_GREEN_pr.out
                stm_RED_pr.out
                stm_RE1_pr.out
                stm_RE2_pr.out
                stm_RE3_pr.out
                stm_BNIR_pr.out
                stm_NIR_pr.out
                stm_SWIR1_pr.out
                stm_SWIR2_pr.out
                stm_NDVI_pr.out
                stm_NBR_pr.out
                stm_NDTI_pr.out
                stm_SAVI_pr.out
                stm_SARVI_pr.out
                stm_EVI_pr.out
                stm_ARVI_pr.out
}

