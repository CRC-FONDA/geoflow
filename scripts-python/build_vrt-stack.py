#! /usr/bin/python3

from osgeo import gdal
import re
import argparse
from pathlib import Path
from typing import Dict, Optional, List

parser = argparse.ArgumentParser()
parser.add_argument("paths", action='extend', nargs='+',
                    help="Files to stack")


def read_raster(path: str) -> gdal.Dataset:
    """
    Wrapper function around gdal.Open.
    :param path: Path to file, which should be opened
    :return: gdal.Dataset object
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
        else:
            raise ValueError(f"Could not open dataset {file}")
        src_band = None
        src_dataset = None

    return return_list


def create_multi_stack_vrt(multi_raster_path: List[str], description: List[str]) -> None:
    """
    Create multi-band VRT-stack from list of single-band files.
    if it does not already exist.
    :param multi_raster_path: Name of multi-band raster (or really any raster) which is solely used for an output name.
    :param description:
    :return:
    """

    vrt_out: str = re.sub(
        r"(?<=(?:LND04|LND05|LND07|LND08|SEN2A|SEN2B|sen2a|sen2b|S1AIA|S1BIA|S1AID|S1BID|LNDLG|SEN2L|SEN2H|R-G-B|VVVHP)_).*?(?=.tif|.vrt)",
        "STACK",
        multi_raster_path)

    if multi_vrt := gdal.BuildVRT(vrt_out, multi_raster_path, separate=True):
        for band_index in range(1, len(multi_raster_path) + 1):
            vrt_band = multi_vrt.GetRasterBand(band_index)
            vrt_band.SetDescription(description[band_index - 1])
            vrt_band = None
        multi_vrt = None
    else:
        raise OSError(f"Failed to create output virtual raster file {vrt_out}")


def main():
    args: Dict[str, List[str]] = vars(parser.parse_args())

    band_descriptors: List[str] = generate_band_description_list(args.get("paths"))

    create_multi_stack_vrt(args.get("paths"), band_descriptors)

    src_raster = None


main()
