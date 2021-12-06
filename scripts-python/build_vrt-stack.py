#! /usr/bin/python3

from osgeo import gdal
# import numpy as np
import argparse
from pathlib import Path
from typing import Dict, Optional, List

parser = argparse.ArgumentParser()
parser.add_argument("output_dir_temp", nargs=1, type=str,
                    help="Path to output directory where intermediate and final VRTs will be stored.\
                     To guarantee absolute file paths in the VRT, a sub-folder containing the final output file will \
                     be created.")
parser.add_argument("multi_band", nargs=1, help="File Path to Multi-band reflectance raster (i.e. FORCE Level2-ARD")
parser.add_argument("single_bands", action='extend', nargs='+',
                    help="File Paths to Single-band spectral indices raster")


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


def create_single_band_vrt(out_dir: str, multi_raster: gdal.Dataset, multi_raster_path: str) -> Dict[str, List[str]]:
    """
    Create CRT-Datasets of each band in multi_raster as a side effect and return Dictionary with file paths and band
    descriptions of written files.
    :param out_dir: Directory oft created VRT-files.
    :param multi_raster: opened gdal.Dataset of multi_raster_path
    :param multi_raster_path: file path to raster file with > 1 bands
    :return: Dictionary containing both paths (to newly created VRT-files) and content of description field
    """
    if not Path(out_dir).absolute().exists():
        raise OSError(f"Directory {out_dir} does not exist")

    n_bands: int = multi_raster.RasterCount
    file_name: str = str(Path(multi_raster_path).name)
    return_dict: Dict[str, List[str]] = {"path_list": [],
                                         "band_description": []}

    for i in range(1, n_bands + 1):
        vrt_out: str = out_dir + f"/{extract_basename(file_name, '.tif', '')}_{str(i).rjust(2, '0')}.vrt"
        return_dict.get("path_list").append(vrt_out)
        if single_vrt := gdal.BuildVRT(vrt_out, multi_raster, bandList=[i]):
            band_name = multi_raster.GetRasterBand(i).GetDescription()
            return_dict.get("band_description").append(band_name)

            single_vrt_band = single_vrt.GetRasterBand(1)
            single_vrt_band.SetColorInterpretation(gdal.GCI_GrayIndex)
            single_vrt_band.SetDescription(band_name)

            single_vrt_band = None
            single_vrt = None
        else:
            raise OSError(f"Failed to create output virtual raster file {vrt_out}")

    return return_dict


def append_path_dict(dst_dict: Dict[str, List[str]], single_band_raster: List[str]) -> Dict[str, List[str]]:
    """
    Iterate over paths in single_band_raster and get the Band description from the files.
    :param dst_dict: Dictionary containing both the file paths, as well as the respective band description.
    :param single_band_raster: List containing the file paths of single band raster which should get added to dst_dict.
    :return: dst_dict appended with file paths and descriptions from single_band_raster
    """
    for file in single_band_raster:
        if temporary_dataset := gdal.Open(file, gdal.GA_ReadOnly):
            dst_dict.get("path_list").append(file)
            dst_dict.get("band_description").append(temporary_dataset.GetRasterBand(1).GetDescription())
        else:
            raise ValueError(f"Failed to open Dataset {file}")

    return dst_dict


def create_multi_stack_vrt(out_dir: str, multi_raster_path: str, single_band_vrt: Dict[str, List[str]]) -> None:
    """
    Create multi-band VRT-stack from list of single-band files.
    :param out_dir: Directory, where VRT-file should be created. A subdirectory named 'vrt' will be created
    if it does not already exist.
    :param multi_raster_path: Name of multi-band raster (or really any raster) which is solely used for an output name.
    :param single_band_vrt: Dictionary containing all file paths and respective band descriptions for the VRT-file.
    :return:
    """
    if not Path(out_dir).absolute().exists():
        raise OSError(f"Directory {out_dir} does not exist")

    if not (base_out_path := Path(out_dir).absolute() / Path("vrt")).exists():
        base_out_path.mkdir()

    vrt_out = str(base_out_path / extract_basename(multi_raster_path, "BOA.tif", "STACK.vrt"))

    if multi_vrt := gdal.BuildVRT(vrt_out, single_band_vrt.get("path_list"), separate=True):
        for band_index in range(1, len(single_band_vrt.get("path_list")) + 1):
            vrt_band = multi_vrt.GetRasterBand(band_index)
            vrt_band.SetDescription(single_band_vrt.get("band_description")[band_index - 1])
            vrt_band = None
        multi_vrt = None
    else:
        raise OSError(f"Failed to create output virtual raster file {vrt_out}")


def main():
    args: Dict[str, List[str]] = vars(parser.parse_args())

    src_raster: Optional[gdal.Dataset] = read_raster(args.get("multi_band")[0])

    single_band_vrt_paths: Dict[str, List[str]] = create_single_band_vrt(args.get("output_dir_temp")[0], src_raster,
                                                                         args.get("multi_band")[0])

    single_band_vrt_paths = append_path_dict(single_band_vrt_paths, args.get("single_bands"))

    create_multi_stack_vrt(args.get("output_dir_temp")[0], args.get("multi_band")[0], single_band_vrt_paths)

    src_raster = None


main()
