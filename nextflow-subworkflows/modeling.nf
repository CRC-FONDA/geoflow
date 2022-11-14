nextflow.enable.dsl = 2

include { create_classification_dataset; merge_and_fit; predict_classifier } from './../nextflow-scripts/hl/classification_processes.nf'

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

        merge_and_fit(
            create_classification_dataset
			.out
			.collect()
        )

		predict_classifier(
			classification_data
			.combine(merge_and_fit.out)
		)

	emit:
		predict_classifier.out
}
