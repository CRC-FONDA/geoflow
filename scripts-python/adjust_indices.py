#! /usr/bin/python3

import numpy as np
from osgeo import gdal
from typing import Optional, List, Dict
import argparse

parser = argparse.ArgumentParser(
    description="This script converts floating point raster to integer ones following the convention set by FORCE (scaling by "
                "10.000 and truncating.")
parser.add_argument("source_dst", nargs=1, type=str, required=True, help="File path to input dataset.")
parser.add_argument("destination_dst", nargs=1, type=str, required=True, help="File path to output dataset.")

args: Dict[str, List[str]] = vars(parser.parse_args())

raster_dataset: Optional[gdal.Dataset] = gdal.Open(
    args.get("source_dst")[0],
    gdal.GA_ReadOnly)

if not raster_dataset:
    raise FileNotFoundError("Failed to open source_dst")

if raster_dataset.RasterCount != 1:
    raster_dataset = None
    raise AssertionError("Number of bands in raster file is not equal to 1")

file_format: str = "GTiff"

driver: gdal.Driver = gdal.GetDriverByName(file_format)

dst_ds = driver.Create(args.get("destination_dst")[0], xsize=raster_dataset.RasterXSize,
                       ysize=raster_dataset.RasterYSize, bands=1, eType=gdal.GDT_Int16,
                       options=["COMPRESS=LZW", "PREDICTOR=2",
                                f"BLOCKXSIZE={raster_dataset.RasterXSize}", f"BLOCKYSIZE={raster_dataset.RasterYSize / 10}"])

if not dst_ds:
    raise FileNotFoundError("Failed to open destination_dst")

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
# /data/Dagobah/fonda/shk/geoflow/work/66/c79afe3af3d2bd54c4a5705068a2ca/20190813_LEVEL2_SEN2B_NDTI-temp.tif
band_name: str = args.get("source_dst")[0].split('_')[-1].replace("-temp.tif", "")
output_band.SetDescription(band_name)
output_band.SetColorInterpretation(gdal.GCI_GrayIndex)
output_band.WriteArray(src_dst_values_scaled)

# close datasets
raster_dataset = None
dst_ds = None
