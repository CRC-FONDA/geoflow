library(tmap)
library(sf)
library(terra)

classified_map <- rast("/data/Dagobah/fonda/shk/geoflow/output/classification/mosaiced_classification.vrt")

t1 <- tm_shape(classified_map, raster.downsample = FALSE) +
	tm_raster(style = "cat",
			  palette = c("1" = "#c90616", "2" = "#f0de6c", "3" = "#ffe528","4" = "#33a02c", 
						  "5" = "#0d5d28", "6" = "#7fa718", "7" = "#ff7f00", 
						  "8" = "#b3de69", "9" = "#8f6031", "10" = "#1f78b4", "11" = "#9acbe1", "12" = "#2ad6ff"),
			  labels = c("1" = "Articificial Land", "2" = "Cropland Seasonal", "3" = "Cropland Perennial", 
			  		   "4" = "Forest Broadleaved", "5" = "Forest Coniferous", "6" = "Forest Mixed", 
			  		   "7" = "Shrubland", "8" = "Grassland", "9" = "Bare Land", "10" = "Water", "11" = "Wetland",
			  		   "12" = "Snow/Ice"),
			  title = "Classes",
			  drop.levels = TRUE) +
	tm_legend(legend.outside = FALSE) +
	tm_layout(main.title = "LUCAS based LULC classification",
			  frame = FALSE,
			  legend.position = c("left", "bottom")
	)

tmap_save(t1, "/data/Dagobah/fonda/shk/geoflow/output/classification.png")
