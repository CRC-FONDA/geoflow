nextflow.enable.dsl = 2

process extract_features {
	input:
	tuple val(TID), val(SID), val(sensor_abbr), val(sensor), val(years), val(month), val(quarter), path(stm), path(vector)

	output:
	path("sample_${TID}-${stm.toString().split('_')[-2]}.gpkg")

	script:
	"""
	qgis_process run enmapbox:SampleRasterLayerValues -- raster=${stm} vector=${vector} outputPointsData=sample_${TID}-${stm.toString().split('_')[-2]}.gpkg
	"""
}

process create_classification_dataset {
	input:

	output:

	script:
	"""
	"""
}

process merge_classification_datasets {
	input:

	output:

	script:
	"""
	"""
}

process train_rf_classifier {
	input:

	output:

	script:
	"""
	"""
}

// TODO: This needs to take 2 arguments, basically. (1) Trained Classifier and (2) data cube to classify.
//       The data cube needs to be constructed before any of the sampling/training is done, tapped into and brought up here again.
process predict_classifier {
	input:

	output:

	script:
	"""
	"""
}
