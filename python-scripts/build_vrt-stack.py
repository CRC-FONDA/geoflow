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

# TODO remove hard coded Indices ?!
def guarantee_band_order(file: str) -> int:
    sentinel_order: Dict[str, int] = {
        "BOA-01": 0,
        "BOA-02": 1,
        "BOA-03": 2,
        "BOA-04": 3,
        "BOA-05": 4,
        "BOA-06": 5,
        "BOA-07": 6,
        "BOA-08": 7,
        "BOA-09": 8,
        "BOA-10": 9,
        "NDVI": 10,
        "NBR": 11,
        "NDTI": 12,
        "SAVI": 13,
        "SARVI": 14,
        "EVI": 15,
        "ARVI": 16
    }

    landsat_order: Dict[str, int] = {
        "BOA-01": 0,
        "BOA-02": 1,
        "BOA-03": 2,
        "BOA-04": 3,
        "BOA-05": 4,
        "BOA-06": 5,
        "NDVI": 6,
        "NBR": 7,
        "NDTI": 8,
        "SAVI": 9,
        "SARVI": 10,
        "EVI": 11,
        "ARVI": 12
    }

    band_name = file.split("_")[-1].split(".")[0]

    if re.search(r"LND04|LND05|LND07|LND08|LNDLG", file):
        return landsat_order[band_name]
    elif re.search(r"SEN2A|SEN2B|SEN2L", file):
        return sentinel_order[band_name]
    else:
        raise ValueError("Unknown or unsupported sensor")


def create_multi_stack_vrt(output_file: str, files_to_stack: List[str], description: List[str]) -> None:
    """
    Create multi-band VRT-stack from list of single-band files.
    @param output_file: string to output file
    @param files_to_stack: list of files to stack into "output_file"
    @param description: band descriptions for raster files iin "files_to_stack"
    """
    vrt_out: str = re.sub(
        r"(?<=(?:LND04|LND05|LND07|LND08|SEN2A|SEN2B|sen2a|sen2b|S1AIA|S1BIA|S1AID|S1BID|LNDLG|SEN2L|SEN2H|R-G-B|VVVHP)_).*?(?=.tif|.vrt)",
        "STACK",
        output_file)

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

    list_of_files: List[str] = sorted(filter(lambda x: not re.search(r"(?<=_)BOA(?=.tif)", x),
                                             [path.as_posix() for path in Path(args.get("vrt-dir")[0]).glob("*")]))

    list_of_files.sort(key=guarantee_band_order)

    band_descriptors: List[str] = generate_band_description_list(list_of_files)

    create_multi_stack_vrt(args.get("output-file")[0], list_of_files, band_descriptors)

    src_raster = None


main()
