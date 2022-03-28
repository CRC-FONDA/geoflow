import re

from osgeo import gdal
from pathlib import Path
from typing import Dict, Any, List, Union

def read_raster(path: str) -> gdal.Dataset:
	"""
	Wrapper function around gdal.Open.
	@param path: Path to file, which should be opened
	@return: gdal.Dataset object
	"""
	if raster := gdal.Open(path, gdal.GA_ReadOnly):
		return raster
	else:
		raise FileNotFoundError(f"{path} not found")


def explode_multi_raster_to_vrt(multi_raster: gdal.Dataset, file_path: str) -> List[str]:
	"""
	Explode multi-layer raster files into multiple virtual datasets (VRTs) which only consist of a single layer.
	Each separate output file is named after 'base_name' and has its respective layer description appended to create a unique name.
	Additionally, the description is also set in the single-layer VRT.
	@param multi_raster: opened gdal.Dataset of multi-layer raster
	@param file_path: file path to 'multi_raster'
	"""
	n_bands: int = multi_raster.RasterCount
	base_name: str = re.sub(r"\..*$", "", file_path)
	return_list: List[str] = list()

	for layer in range(1, n_bands + 1):
		layer_description: str = multi_raster.GetRasterBand(layer).GetDescription()
		vrt_out_name: str = base_name + "_" + layer_description + ".vrt"
		return_list.append(vrt_out_name)

		if single_vrt := gdal.BuildVRT(vrt_out_name, multi_raster, bandlist=[layer]):
			vrt_layer = single_vrt.GetRasterBand(1)
			vrt_layer.setDescription(layer_description)
			vrt_layer.SetColorInterpretation(gdal.GCI_GrayIndex)

			vrt_layer = None
			single_vrt = None
		else:
			raise OSError(f"Failed to open dataset {vrt_out_name}")

	return return_list


def create_big_cube(in_files: List[str], out_name: str) -> None:
	if not (big_vrt := gdal.BuildVRT(out_name, in_files)):
		raise OSError(f"Failed to open dataset {out_name}")
	else:
		big_vrt = None


def close_gdal(gdal_dataset: gdal.Dataset) -> None:
	gdal_dataset = None
