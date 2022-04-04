# TODO give this file a more fitting name
import re
from typing import List
from osgeo import gdal

def remove_filetype(file_name: str) -> str:
	pattern: re.Pattern = re.compile(r"\..*$")

	return pattern.sub("", file_name)


def read_raster(path: str) -> gdal.Dataset:
	"""
	Wrapper function around gdal.Open
	:param path: Path to file, which should be opened
	:return: gdal.Dataset object
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
	:param multi_raster: opened gdal.Dataset of multi-layer raster
	:param file_path: file path to 'multi_raster'
	"""
	n_bands: int = multi_raster.RasterCount
	base_name: str = remove_filetype(file_path)
	return_list: List[str] = list()

	for layer in range(1, n_bands + 1):
		layer_description: str = multi_raster.GetRasterBand(layer).GetDescription()
		vrt_out_name: str = base_name + "_" + layer_description + ".vrt"
		return_list.append(vrt_out_name)

		if single_vrt := gdal.BuildVRT(vrt_out_name, multi_raster, bandList=[layer]):
			vrt_layer = single_vrt.GetRasterBand(1)
			vrt_layer.SetDescription(layer_description)
			vrt_layer.SetColorInterpretation(gdal.GCI_GrayIndex)

			vrt_layer = None
			single_vrt = None
		else:
			raise OSError(f"Failed to open dataset {vrt_out_name}")

	return return_list


def generate_layer_names_list(in_files: List[str]) -> List[str]:
	"""
	Given a list of file paths, open them and get the gdal Description entry.
	It is assumed, that all files given in `in_files` only have a single layer
	:param in_files: List of Input paths as string objects
	:return: List of layer descriptions
	"""
	return_list: List[str] = list()
	for single_layer_vrt in in_files:
		temp_layer: gdal.Dataset = read_raster(single_layer_vrt)
		single_layer_vrt_description: str = temp_layer.GetRasterBand(1).GetDescription()
		return_list.append(single_layer_vrt_description)

	return return_list

def create_big_cube(in_files: List[str], out_name: str) -> None:
	"""
	Generate virtual dataset which combines previously spread out layers
	:param in_files: List of (VRT) files which are to be combined
	:param out_name: File name/path for output
	"""
	if not (big_vrt := gdal.BuildVRT(out_name, in_files, separate=True)):
		raise OSError(f"Failed to open dataset {out_name}")
	else:
		# set respective layer names
		# TODO file names as Description -> hopefully unique (more or less)
		original_layer_descriptions: List[str] = generate_layer_names_list(in_files)
		for layer_index, layer_description in zip(range(1, len(in_files) + 1), original_layer_descriptions):
			big_vrt_layer = big_vrt.GetRasterBand(layer_index)
			big_vrt_layer.SetDescription(layer_description)
			big_vrt_layer.SetColorInterpretation(gdal.GCI_GrayIndex)
			big_vrt_layer = None
		big_vrt = None


def close_gdal(gdal_dataset: gdal.Dataset) -> None:
	gdal_dataset = None
