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
    tuple val(TID), path(reflectance), path(bands), path(slVRTs), path(full_stack), path(cat_vec)

    output:
    tuple val(TID), path("${TID}_training.pkl")

    script:
	// qgis_process moves output to /tmp/processing when given a relative file path or just the file name
    """
    qgis_process run enmapbox:CreateClassificationDatasetFromCategorizedVectorLayerAndFeatureRaster -- \
    categorizedVector=${cat_vec} \
    featureRaster=${full_stack} \
    categoryField='lc1' \
    outputClassificationDataset=\$PWD/${TID}_training.pkl
    """
}

process merge_classification_datasets {
    input:
    tuple val(TID), path(training_datasets)

    output:
    tuple val(TID), path("merged_training_dataset.pkl")

    script:
	// qgis_process moves output to /tmp/processing when given a relative file path or just the file name
    String merged_arguments = ""
    training_datasets.each({ val -> merged_arguments += "datasets=$val "})
    
    """
    qgis_process run enmapbox:MergeClassificationDatasets -- ${merged_arguments} outputClassificationDataset=\$PWD/merged_training_dataset.pkl
    """
}

process train_rf_classifier {
    input:
    tuple val(TID), path(merged_training_dataset)

    output:
    tuple val(TID), path("estimator.pkl")

    script:
	// qgis_process moves output to /tmp/processing when given a relative file path or just the file name
    """
    qgis_process run enmapbox:FitRandomforestclassifier -- \
    classifier='from sklearn.ensemble import RandomForestClassifier;classifier = RandomForestClassifier(n_estimators=100, oob_score=True)' \
    dataset=${merged_training_dataset} \
    outputClassifier=\$PWD/estimator.pkl
    """
}

// TODO: This needs to take 2 arguments, basically. (1) Trained Classifier and (2) data cube to classify.
//       The data cube needs to be constructed before any of the sampling/training is done, tapped into and brought up here again.
// TODO publish results
process predict_classifier {
    input:
    tuple val(TID), path(prediction_stack), path(estimator)

    output:
    path("${TID}_prediction.tif")

    script:
    """
    qgis_process run  enmapbox:PredictClassificationLayer -- \
    raster=${prediction_stack} \
    classifier=${estimator} \
    outputClassification=${TID}_prediction.tif
    """
}

