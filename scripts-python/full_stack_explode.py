#! /usr/bin/python3
from osgeo import gdal
import argparse
from pathlib import Path
from typing import Dict, List, Any
from python_modules import io

parser = argparse.ArgumentParser(
	description="While similar/almost identical to 'explode.py' in functionality, this is script is used for the creation on the 'final' data cube and will "
				"likely be merged into 'explode.py' once I (re-)figured out how to solve the problem at hand.\n"
				"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
				"Before extracting features and any training/prediction can be done, a 'final' data cube needs to be created in which all inputs (i.e. "
				"reflectance, spectral indices, spectral temporal metrics) are combined. This cube should be exported as a virtual dataset (VRT) and only "
				"consist of relative paths. Due to this requirement, either this script or the user needs to do move files around/organise the input files "
				"and folders accordingly (which one of the both is not decided yet)."
)
parser.add_argument("--input_dir", nargs=1, type=Path, required=True,
					help="Path to input directory, where files to cube are located. This script detects Geo-TIFFS and VRT files.")
parser.add_argument("--out_name", nargs=1, type=str, required=True,
					help="Name of output VRT-cube")

args: Dict[str, Any] = {key: (value[0] if isinstance(value, List) else value) for key, value in vars(parser.parse_args()).items()}
final_cube_inputs: List[Path] = list()

files: List[Path] = args.get("input_dir").glob("*.[tif][vrt]")

# drop BOA.tif files as they are not needed in further stacking
files = list(filter(lambda x: "BOA.tif" not in x.name, files))

# BOA vrt files don't need to be re-processed
filtered_files: List[Path] = list(filter(lambda x: "BOA" not in x.name, files))

# while BOA files don't need to be processed again, they're needed in the final cube
final_cube_inputs.extend(list(set(files) - set(filtered_files)))

# iterate over all rasters, if a raster file only contains 1 band, simply append said file to "final_cube_input".
# Otherwise, create multiple single band vrt files and extend "final_cube_input" with them.
for raster_file in filtered_files:
	raster: gdal.Dataset = io.read_raster(str(raster_file))
	if raster.RasterCount == 1:
		final_cube_inputs.append(raster_file)
	else:
		final_cube_inputs.extend(io.explode_multi_raster_to_vrt(raster, raster_file))

	io.close_gdal(raster)

io.create_big_cube(final_cube_inputs, args.get("out_name"))