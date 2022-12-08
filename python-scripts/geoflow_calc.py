#! /usr/bin/python3

import argparse
from argparse import RawTextHelpFormatter
import gdal
import numpy as np
from typing import Dict, Union
from python_modules import cio

parser = argparse.ArgumentParser(
    description="This script acts like sort of a cheap knock-off of 'gdal_calc.py', or does it?\n"
                "Anyhow, it is used to appy a scaling factor to all bands of a multilayer raster image, "
                "choosing the output data type and burn in a mask band.\n"
                "When specified, a global mask band is used, otherwise each raster layer is assumed to carry its own mask band.\n"
                "If no scale factor is provided via the '--scale-factor' argument, the program applies the scale "
                "factor set on the band level similar to the '-unscale' option of gdal_translate.\n"
                "The resulting raster doesn't have a scale factor or offset set."
                "Otherwise, it is assumed, that the given scale factor is valid for all raster bands and it is "
                "preferred over the band-wise scale factor.\n\n"
                "IMPORTANT NOTE: It is assumed, that a value of zero does not represent valid data!",
    formatter_class=RawTextHelpFormatter
)
parser.add_argument("-if", "--input-file", required=True, type=str, dest="input_file", nargs=1,
                    help="File path to the input file.")
parser.add_argument("-of", "--output-file", required=True, type=str, dest="output_file", nargs=1,
                    help="File path to the output file.")
parser.add_argument("--eType", required=False, type=str, dest="e_type", nargs=1, default="Float32",
                    choices=["Byte", "Int8", "Int16", "UInt16", "UInt32", "Int32",
                             "Float32", "Float64", "CFloat64"],
                    help="Datatype used for storing potentially scaled and/or masked data in the output file. If not specified,"
                         "defaults to 'Float32'. Note that the types 'Int64', 'UInt64', 'CInt16', 'CInt32' and 'CFloat32' are not supported.")
parser.add_argument("-sf", "--scale-factor", required=False, type=float, dest="scale_factor", nargs=1, default=None,
                    help="Global scale factor.")
parser.add_argument("--offset", required=False, type=float, dest="offset", nargs=1, default=None,
                    help="Global offset value.")
parser.add_argument("--mask-band", required=False, type=str, dest="mask_band", nargs=1, default="global",
                    choices=["global", "band_wise"],
                    help="Specify whether the provided mask band applies to all bands or if each band has its own mask band."
                         "The mask needs to be a binary mask with 0 representing no data and 1 valid data.")
parser.add_argument("--no-data", required=True, type=int, dest="no_data", nargs=1, default=None,
                    help="No data value in the output file.")

args: Dict[str, str] = {key: value[0] for key, value in vars(parser.parse_args()).items()}

input_raster: gdal.Dataset = cio.read_raster(args.get("input_file"))
input_raster_n_layer: int = input_raster.RasterCount
global_mask_band: Union[np.ndarray, None] = None

output_driver: gdal.Driver = gdal.GetDriverByName("GTiff")
output_raster: gdal.Dataset = output_driver.Create(
    args.get("output_file"),
    xsize=input_raster.RasterXSize,
    ysize=input_raster.RasterYSize,
    bands=input_raster_n_layer,
    eType=cio.string_to_gdal_type(args.get("e_type")),
    options=[
        "COMPRESS=LZW",
        "PREDICTOR=3" if "Float" in args.get("e_type") else ""
    ]
)
output_raster.SetGeoTransform(input_raster.GetGeoTransform())
output_raster.SetProjection(input_raster.GetSpatialRef().ExportToWkt())

if args.get("mask_band") == "global":
    global_mask_band: np.ndarray = input_raster.GetRasterBand(1).GetMaskBand().ReadAsArray()

for layer_index in range(1, input_raster_n_layer + 1):
    # 0) Read Rasterband as numpy array
    input_raster_layer: gdal.Band = input_raster.GetRasterBand(layer_index)
    input_raster_array: np.ndarray = input_raster_layer.ReadAsArray()
    # 1) Multiply by mask
    mask_band: np.ndarray = global_mask_band if isinstance(global_mask_band, np.ndarray) else input_raster_layer.GetMaskBand().ReadAsArray()
    output_raster_array: np.ndarray = np.multiply(input_raster_array,
                                                  mask_band,
                                                  dtype=cio.string_to_numpy_type(args.get("e_type"))
                                                  )
    # 2) Set zeros to np.nan
    output_raster_array = np.ma.masked_array(
        np.where(output_raster_array == 0, np.nan, output_raster_array)
    )
    # 3) apply offset and scale
    output_raster_array = np.add(
        np.multiply(output_raster_array,
                    args.get("scale_factor") or input_raster_layer.GetScale()
                    ),
        args.get("offset") or input_raster_layer.GetOffset()
    )
    output_raster_array = output_raster_array.filled(args.get("no_data"))
    # 4) set no data value and color interpretation
    output_raster_band: gdal.Band = output_raster.GetRasterBand(layer_index)
    output_raster_band.SetNoDataValue(args.get("no_data"))
    # 5) convert numpy array to chosen output data type
    output_raster_array = np.asarray(output_raster_array, dtype=cio.string_to_numpy_type(args.get("e_type")))
    # 6) write Array
    output_raster_band.WriteArray(output_raster_array)

input_raster = None
output_raster = None
