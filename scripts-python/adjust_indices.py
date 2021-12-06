#! /usr/bin/python3

import numpy as np
from osgeo import gdal
from typing import Optional
from sys import argv

if len(argv) != 3:
    raise AssertionError(f"Program called with wrong number of arguments. Expected 2, got {len(argv) - 1}")

raster_dataset: Optional[gdal.Dataset] = gdal.Open(
    argv[1],
    gdal.GA_ReadOnly)

if not raster_dataset:
    raise FileNotFoundError("Failed to open input-dataset")

if raster_dataset.RasterCount != 1:
    raster_dataset = None
    raise AssertionError("Number of bands in raster file is not equal to 1")

file_format: str = "GTiff"

driver: gdal.Driver = gdal.GetDriverByName(file_format)

dst_ds = driver.Create(argv[2], xsize=raster_dataset.RasterXSize,
                       ysize=raster_dataset.RasterYSize, bands=1, eType=gdal.GDT_Int16,
                       options=["COMPRESS=LZW", "PREDICTOR=2"])

if not dst_ds:
    raise FileNotFoundError("Failed to open output-dataset")

# copy GeoTransform and SpatialRef to new dataset
dst_ds.SetGeoTransform(raster_dataset.GetGeoTransform())
dst_ds.SetProjection(raster_dataset.GetSpatialRef().ExportToWkt())

# set NoDataValue
dst_ds.GetRasterBand(1).SetNoDataValue(-9999)

src_dst_values = raster_dataset.GetRasterBand(1).ReadAsArray(0, 0, raster_dataset.RasterXSize,
                                                             raster_dataset.RasterYSize)

# check if any values are already marked as NA and if yes, set them to new NoDataValue
src_no_data: Optional[float] = raster_dataset.GetRasterBand(1).GetNoDataValue()
if src_no_data:
    for row in src_dst_values:
        for cell in row:
            if cell == src_no_data:
                cell = -9999

# scale, truncate and convert values according to FORCE format (FORCE truncates as well by casting float to short)
src_dst_values_scaled = np.int_(np.trunc(src_dst_values * 10_000))

# fetch band, set color interpretation (https://gis.stackexchange.com/a/414699) and write Band
output_band = dst_ds.GetRasterBand(1)

# Index name only exists in file name
# TODO while this does works, it looks ugly af
output_band.SetDescription(argv[1].split("/")[-1].split("_")[-1].split(".")[0])
output_band.SetColorInterpretation(gdal.GCI_GrayIndex)
output_band.WriteArray(src_dst_values_scaled)

# close datasets
raster_dataset = None
dst_ds = None
