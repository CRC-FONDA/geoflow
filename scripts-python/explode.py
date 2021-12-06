#! /usr/bin/python3

from osgeo import gdal
import re
import argparse
from pathlib import Path
from typing import Dict, Optional, List, AnyStr

parser = argparse.ArgumentParser()
parser.add_argument("output_dir_temp", nargs=1, type=str,
                    help="Path to output directory where intermediate and final VRTs will be stored.\
                     To guarantee absolute file paths in the VRT, a sub-folder containing the final output file will \
                     be created.")
parser.add_argument("multi_band", nargs=1, type=str,
                    help="File Path to Multi-band reflectance raster (i.e. FORCE Level2-ARD")


def get_tid(path: AnyStr) -> Optional[str]:
    return re.search(r"(?<=/)X[0-9]{4}_Y[0-9]{4}(?=/)", path).group()


def get_identifier(path: AnyStr) -> str:
    return path.split('/')[-1].split('.')[0]


def extract_basename(path: str, old_str: str, new_str: str) -> Path:
    """
    Create output name for VRT-file.
    """
    return Path(path.split('/').pop().replace(old_str, new_str))


def read_raster(path: str) -> gdal.Dataset:
    """
    Wrapper function around gdal.Open.
    :param path: Path to file, which should be opened
    :return: gdal.Dataset object
    """
    if raster := gdal.Open(str(Path(path).absolute()), gdal.GA_ReadOnly):
        return raster
    raise OSError(f"Failed to open dataset {path}")


def create_single_band_vrt(out_dir: str, multi_raster: gdal.Dataset, multi_raster_path: str) -> None:
    """
    Create CRT-Datasets of each band in multi_raster as a side effect and return Dictionary with file paths and band
    descriptions of written files.
    :param out_dir: Directory oft created VRT-files.
    :param multi_raster: opened gdal.Dataset of multi_raster_path
    :param multi_raster_path: file path to raster file with > 1 bands
    :return: Dictionary containing both paths (to newly created VRT-files) and content of description field
    """
    out_dir = Path(out_dir + "/" + get_tid(multi_raster_path) + "/" + get_identifier(multi_raster_path))
    out_dir.mkdir(exist_ok=True)

    n_bands: int = multi_raster.RasterCount
    file_name: str = str(Path(multi_raster_path).name)

    for i in range(1, n_bands + 1):
        vrt_out: str = str(out_dir) + f"/{extract_basename(file_name, '.tif', '')}_{str(i).rjust(2, '0')}.vrt"
        if single_vrt := gdal.BuildVRT(vrt_out, multi_raster, bandList=[i]):
            band_name = multi_raster.GetRasterBand(i).GetDescription()

            single_vrt_band = single_vrt.GetRasterBand(1)
            single_vrt_band.SetColorInterpretation(gdal.GCI_GrayIndex)
            single_vrt_band.SetDescription(band_name)

            single_vrt_band = None
            single_vrt = None
        else:
            raise OSError(f"Failed to create output virtual raster file {vrt_out}")


def main():
    args: Dict[str, List[str]] = vars(parser.parse_args())

    src_raster: Optional[gdal.Dataset] = read_raster(args.get("multi_band")[0])

    create_single_band_vrt(args.get("output_dir_temp")[0], src_raster,
                           args.get("multi_band")[0])

    src_raster = None


main()
