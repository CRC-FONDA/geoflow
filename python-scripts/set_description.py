#! /usr/bin/python3

import argparse
from python_modules import cio
from osgeo import gdal
from typing import Dict, List

parser = argparse.ArgumentParser(
    description="This program opens a raster file and updates the band descriptions for all layers specified.\
    Inspiration from https://gis.stackexchange.com/a/290806"
)
parser.add_argument("-i", "--input_file", nargs=1, type=str, required=True, dest="input_file",
                    help="File path to input dataset.")
parser.add_argument("--names", nargs="+", type=str, required=True,
                    help="Map of old and new names in the form of BAND-INDEX=NEW-NAME")

args: Dict[str, List[str]] = vars(parser.parse_args())

temporary_names = {'names': cio.dict_from_string_list(args.get('names'))}
args.update(temporary_names)
del temporary_names

raster_file = cio.read_raster(args.get("input_file")[0], gdal.GA_Update)

for band_index, description in args.get("names").items():
    band = raster_file.GetRasterBand(band_index)
    band.SetDescription(description)
    del band

del raster_file
