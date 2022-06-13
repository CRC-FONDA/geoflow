#! /usr/bin/python3
from osgeo import gdal
import argparse
from typing import Dict, List, Any
from python_modules import io

parser = argparse.ArgumentParser(
	description="While similar/almost identical to 'explode.py' in functionality, this is script is used for the creation on the 'final' data cube and will\n"
				"likely be merged into 'explode.py' once I (re-)figured out how to solve the problem at hand.\n"
				"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
				"Before extracting features and any training/prediction can be done, a 'final' data cube needs to be created in which all inputs (i.e. "
				"reflectance, spectral indices, spectral temporal metrics) are combined. This cube should be exported as a virtual dataset (VRT) and only "
				"consist of relative paths. Due to this requirement, either this script or the user needs to do move files around/organise the input files "
				"and folders accordingly (which one of the both is not decided yet)."
)
parser.add_argument("--input_files", nargs='+', type=str, required=True,
					help="Input files.")
parser.add_argument("--out_name", nargs=1, type=str, required=True,
					help="Name of output VRT-cube")

args: Dict[str, Any] = {key: (value[0] if key == "out_name" else value) for key, value in vars(parser.parse_args()).items()}
final_cube_inputs: List[str] = list()

# BOA vrt files don't need to be re-processed
filtered_files: List[str] = list(filter(lambda x: "BOA" not in x, args.get("input_files")))

# while BOA files don't need to be processed again, they're needed in the final cube
final_cube_inputs.extend(list(set(args.get("input_files")) - set(filtered_files)))

# iterate over all rasters, if a raster file only contains 1 band, simply append said file to "final_cube_input".
# Otherwise, create multiple single band vrt files and extend "final_cube_input" with them.
for raster_file in filtered_files:
	raster: gdal.Dataset = io.read_raster(raster_file)
	if raster.RasterCount == 1:
		final_cube_inputs.append(raster_file)
	else:
		final_cube_inputs.extend(io.explode_multi_raster_to_vrt(raster, raster_file))

	io.close_gdal(raster)

final_cube_inputs.sort() # TODO do I need to sort the stack? Method discussion needed from my side!

io.create_big_cube(final_cube_inputs, args.get("out_name"))

