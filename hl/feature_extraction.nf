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

process combine_samples {
	input:
	path(samples)

	output:
	tuple path("validation.gpkg"), path("features.gpkg")

	script:
	"""
	for i in ${samples.join(' ')}; do
		ogr2ogr -f "gpkg" -append -nln samples samples.gpkg \$i;
	done
	
	ogr2ogr -select 'lc1' validation.gpkg samples.gpkg -nln 'validation'
	ogr2ogr -sql "ALTER TABLE features DROP COLUMN PIXEL_X, PIXEL_Y" features.gpkg samples.gpkg
	"""
}

