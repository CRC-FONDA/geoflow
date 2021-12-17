#! /usr/bin/python3

from osgeo import gdal
import re
import argparse
from pathlib import Path
from typing import Dict, Optional, List

parser = argparse.ArgumentParser(
    description="This script accepts a list of file paths to datasets that can be read by GDAL and creates a multi band VRT file in the current "
                "working directory.")
parser.add_argument("vrt-dir", nargs=1,
                    help="directory where files reside which are to be stacked")
parser.add_argument("output-file", nargs=1, help="Name of output file to be created")


def read_raster(path: str) -> gdal.Dataset:
    """
    Wrapper function around gdal.Open.
    @param path: Path to file, which should be opened
    @return: gdal.Dataset object
    """
    if raster := gdal.Open(str(Path(path).absolute()), gdal.GA_ReadOnly):
        return raster
    raise OSError(f"Failed to open dataset {path}")


def generate_band_description_list(path: List[str]) -> List[str]:
    return_list: List[str] = []
    for file in path:
        if src_dataset := read_raster(file):
            src_band = src_dataset.GetRasterBand(1)
            return_list.append(src_band.GetDescription())
            src_band = None
            src_dataset = None
        else:
            raise ValueError(f"Could not open dataset {file}")

    return return_list


def resolve_fpaths(paths: List[str]) -> List[str]:
    return_list = []
    for path in paths:
        return_list.append(str(Path(path).absolute()))

    return return_list


def create_multi_stack_vrt(output_file: str, files_to_stack: List[str], description: List[str]) -> None:
    """
    Create multi-band VRT-stack from list of single-band files.
    if it does not already exist.
    @param output_file:
    @param files_to_stack: Name of multi-band raster (or really any raster) which is solely used for an output name.
    @param description:
    """
    vrt_out: str = re.sub(
        r"(?<=(?:LND04|LND05|LND07|LND08|SEN2A|SEN2B|sen2a|sen2b|S1AIA|S1BIA|S1AID|S1BID|LNDLG|SEN2L|SEN2H|R-G-B|VVVHP)_).*?(?=.tif|.vrt)",
        "STACK",
        output_file)

    vrt_out = re.sub(r"(?<=STACK.).*$", "vrt", vrt_out)

    # insert subdirectory to force relative path
    # vrt_out = args_dict.get("temp-subdir").pop() + "/" + vrt_out

    #files_to_stack = resolve_fpaths(files_to_stack)

    if multi_vrt := gdal.BuildVRT(vrt_out, files_to_stack, separate=True):
        for band_index in range(1, len(files_to_stack) + 1):
            vrt_band = multi_vrt.GetRasterBand(band_index)
            vrt_band.SetDescription(description[band_index - 1])
            vrt_band = None
        multi_vrt = None
    else:
        raise OSError(f"Failed to create output virtual raster file {vrt_out}")


def main():
    args: Dict[str, List[str]] = vars(parser.parse_args())

    list_of_files: List[str] = [str(file) for file in Path(args.get("vrt-dir")).glob("*.[vrt][tif]")]

    band_descriptors: List[str] = generate_band_description_list(list_of_files)

    create_multi_stack_vrt(args.get("output-file")[0], list_of_files, band_descriptors)

    src_raster = None


main()
