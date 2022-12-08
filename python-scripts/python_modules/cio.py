# TODO give this file a more fitting name
import re
from typing import List, Dict, Tuple
from osgeo import gdal
import numpy as np
import numpy.typing as npt


def remove_filetype(file_name: str) -> str:
	pattern: re.Pattern = re.compile(r"\..*$")

	return pattern.sub("", file_name)


def read_raster(path: str, mode=gdal.GA_ReadOnly) -> gdal.Dataset:
	"""
	Wrapper function around gdal.Open
	:param path: Path to file, which should be opened
	:param mode: GDAL Open mode
	:return: gdal.Dataset object
	"""
	if raster := gdal.Open(path, mode):
		return raster
	else:
		raise FileNotFoundError(f"{path} not found")


def read_raster_shared(path: str, mode=gdal.GA_ReadOnly) -> gdal.Dataset:
	"""
	Wrapper around gdal.OpenShared
	:param path: Path to file, which should be opened
	:param mode: GDAL Open mode
	:return: gdal.Dataset object
	"""
	if raster := gdal.OpenShared(path, mode):
		return raster
	else:
		raise FileNotFoundError(f"{path} not found")


def explode_multi_raster_to_vrt(multi_raster: gdal.Dataset, file_path: str) -> List[str]:
	"""
	Explode multi-layer raster files into multiple virtual datasets (VRTs) which only consist of a single layer.
	Each separate output file is named after 'base_name' and has its respective layer description appended
	to create a unique name.
	Additionally, the description is also set in the single-layer VRT.
	:param multi_raster: opened gdal.Dataset of multi-layer raster
	:param file_path: file path to 'multi_raster'
	:return: List of files which are later combined into a final stack
	"""
	n_bands: int = multi_raster.RasterCount
	splitted_base_name: List[str] = remove_filetype(file_path).split('_')[2:]
	base_name: str = '_'.join(splitted_base_name)
	return_list: List[str] = list()

	for layer in range(1, n_bands + 1):
		layer_description: str = base_name + "_" + multi_raster.GetRasterBand(layer).GetDescription().replace(" ", "-")
		# layer_description: str = multi_raster.GetRasterBand(layer).GetDescription().replace(" ", "-")
		vrt_out_name: str = layer_description + "_slVRT.vrt"
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
	# TODO I don't like how I treat single layer files!
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


def dict_from_string_list(base: List[str]) -> Dict[int, str]:
	"""
	Given a list of key value pairs as strings, return a dictionary.
	@param base: list of key value pairs in the form of ["key1=val1", "key2=val2", ...]
	@return: {key1: val1, key2: val2, ...}
	"""
	list_of_kv: List[Tuple[int, str]] = list()

	for value_pair in base:
		k, v = value_pair.split("=")
		list_of_kv.append((int(k), v))

	return dict(list_of_kv)


def string_to_gdal_type(string_data_type: str) -> gdal.gdalconst:
	if string_data_type == "Byte":
		return gdal.GDT_Byte
	elif string_data_type == "Int8":
		return gdal.GDT_Byte
	elif string_data_type == "Int16":
		return gdal.GDT_Int16
	elif string_data_type == "UInt16":
		return gdal.GDT_UInt16
	elif string_data_type == "UInt32":
		return gdal.GDT_UInt32
	elif string_data_type == "Int32":
		return gdal.GDT_Int32
	elif string_data_type == "Float32":
		return gdal.GDT_Float32
	elif string_data_type == "Float64":
		return gdal.GDT_Float64
	elif string_data_type == "CFloat64":
		return gdal.GDT_CFloat64


def string_to_numpy_type(string_data_type: str) -> npt.DTypeLike:
	if string_data_type == "Byte":
		return np.byte
	elif string_data_type == "Int8":
		return np.int8
	elif string_data_type == "Int16":
		return np.int16
	elif string_data_type == "UInt16":
		return np.uint16
	elif string_data_type == "UInt32":
		return np.uint32
	elif string_data_type == "Int32":
		return np.int32
	elif string_data_type == "Float32":
		return np.float32
	elif string_data_type == "Float64":
		return np.float64
	elif string_data_type == "CFloat64":
		return np.complex64