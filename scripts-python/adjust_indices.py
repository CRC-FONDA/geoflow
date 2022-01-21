#! /usr/bin/python3

import numpy as np
from osgeo import gdal
from typing import Optional, List, Dict, Union
import argparse
import re

parser = argparse.ArgumentParser(
	description="This script converts floating point raster to integer ones following the convention set by FORCE (scaling by "
				"10.000 and truncating.")
parser.add_argument("-src", "--source_dst", nargs=1, type=str, required=True, help="File path to input dataset.")
parser.add_argument("-of", "--output_dst", nargs=1, type=str, required=True, help="File path to output dataset.")
parser.add_argument("-STM", action="store_true", type=bool, dest="is_stm", help="Flag indicating if raster is spectral index or spectral temporal metric. "
																				"Needed due to different naming conventions.")

args: Dict[str, Union[str, bool]] = {key: (value[0] if isinstance(value, List) else value) for key, value in vars(parser.parse_args()).items()}


def read_raster(path: str) -> gdal.Dataset:
	if raster := gdal.Open(path, gdal.GA_ReadOnly):
		return raster
	raise OSError(f"Failed to open dataset {path}")


def write_raster(path: str, data: np.ndarray, of: str, band_description: str, gdt: int, geo_trans: List[int], projection: str,
				 no_data_value: int = -9999, gci: int = gdal.GCI_GrayIndex) -> None:
	cols, rows = data.shape
	driver: gdal.Driver = gdal.GetDriverByName(of)
	dst: gdal.Dataset = driver.Create(path, xsize=cols, ysize=rows, bands=1, eType=gdt,
									  # TODO Block[X/Y]Size correctly set? Looks wrong
									  options=["COMPRESS=LZW", "PREDICTOR=2", f"BLOCKXSIZE={cols}", f"BLOCKYSIZE={int(rows / 10)}"])
	if not dst:
		raise FileNotFoundError("Failed to open output dataset.")

	dst.SetGeoTransform(geo_trans)
	dst.SetProjection(projection)
	dst_band: gdal.Band = dst.GetRasterBand(1)
	dst_band.SetNoDataValue(no_data_value)
	dst_band.SetColorInterpretation(gci)
	dst_band.SetDescription(band_description)
	dst_band.WriteArray(data, 0, 0)

	dst = None


def scale_array(data: np.ndarray, old_no_data: Optional[float], new_no_data: int = -9999) -> np.ndarray:
	scaled_array: np.ndarray = np.int_(np.trunc(data * 10_000))
	if old_no_data:
		scaled_old_na: int = int(old_no_data * 10_000)
		scaled_array = np.where(scaled_array == scaled_old_na, new_no_data, scaled_array)
	return scaled_array


def generate_band_description(name: str, type_flag: bool) -> str:
	band_description: str = ""
	if type_flag:
		stm_mapping: List[str] = [
			"MEAN",
			"STD",
			"MIN",
			"P5",
			"P25",
			"MEDIAN",
			"P75",
			"P95",
			"MAX",
			"SUM",
			"PRODUCT",
			"RANGE",
			"IQR"
		]
		stm_index: int = int(re.search(r"(?<=STMS-)[0-9]{1,2}(?=.tif)", name).group())
		band_description = stm_mapping[stm_index]
	else:
		band_description = re.search(r"(?<=_)[A-Za-z]{3,}(?=-temp.tif)", name).group()

	return band_description


def main() -> None:
	in_raster = read_raster(args.get("source_dst"))
	in_array: np.ndarray = in_raster.GetRasterBand(1).ReadAsArray(0, 0, in_raster.RasterXSize, in_raster.RasterYSize)

	out_array: np.ndarray = scale_array(in_array, in_raster.GetRasterBand(1).GetNoDataValue())
	out_description: str = generate_band_description(args.get("source_dst"), args.get("is_stm"))
	write_raster(args.get("destination_dst"), out_array, "GTiff", out_description, gdal.GDT_Int16, in_raster.GetGeoTransform(),
				 in_raster.GetSpatialRef().ExportToWKT())

	in_raster = None


if __name__ == "__main__":
	main()
