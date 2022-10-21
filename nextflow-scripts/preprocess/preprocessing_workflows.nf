nextflow.enable.dsl = 2

process spat_lucas {
	label 'small_memory'

	publishDir "${params.lucas_subset_dir}", pattern: "queried_lucas.gpkg", mode: 'copy', overwrite: true, enabled: params.publish_lucas_subset

        input:
        tuple path(survey), path(geometries), val(query), val(epsg)

        output:
        path("queried_lucas.gpkg")

        script:
        """
        spatLUCAS.py --survey ${survey} --geom ${geometries} --query "${query}" --epsg ${epsg} -of queried_lucas.gpkg
        """
}

