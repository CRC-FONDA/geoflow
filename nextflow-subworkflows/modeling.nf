nextflow.enable.dsl = 2

include { create_classification_dataset; merge_classification_datasets; train_rf_classifier; predict_classifier } from './../nextflow-scripts/hl/classification_processes.nf'

workflow ml_modeling {
	take: 
		training_data
		classification_data
		prepared_lucas

	main:
		create_classification_dataset(
			training_data
			.combine(prepared_lucas.out)
		)

		merge_classification_datasets(
			create_classification_dataset
			.out
			.collect()
		)

		train_rf_classifier(
			merge_classification_datasets
			.out
		)

		predict_classifier(
			classification_data
			.combine(train_rf_classifier.out)
		)

	emit:
		predict_classifier.out
}
