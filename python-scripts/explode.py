#! /usr/bin/python3

from osgeo import gdal
import re
import argparse
from pathlib import Path
from typing import Dict, Optional, List, AnyStr
from python_modules import cio as io

parser = argparse.ArgumentParser(
    description="This script generates as many single band virtual raster files as there are \
                    bands in the input file. The '.vrt' files will be generated in the same directory as the input \
                    file. This is because of the way Nextflow (at least to me) seems to function.")
parser.add_argument("multi_band", nargs=1, type=str,
                    help="File Path to Multi-band reflectance raster (i.e. FORCE Level2-ARD)")

args: Dict[str, str] = {key: (value[0] if isinstance(value, List) else value) for key, value in vars(parser.parse_args()).items()}

def get_tid(path: AnyStr) -> Optional[str]:
    return re.search(r"(?<=/)X[0-9]{4}_Y[0-9]{4}(?=/)", path).group()


def get_identifier(path: AnyStr) -> str:
    return path.split('/')[-1].split('.')[0]


def create_single_band_vrt(multi_raster: gdal.Dataset, multi_raster_path: str) -> None:
    """
    Create CRT-Datasets of each band in multi_raster as a side effect and return Dictionary with file paths and band
    descriptions of written files.
    @param multi_raster: open gdal.Dataset of multi_raster_path
    @param multi_raster_path: file path to raster file with > 1 bands
    """

    n_bands: int = multi_raster.RasterCount
    file_name: str = str(Path(multi_raster_path).name)

    for i in range(1, n_bands + 1):
        vrt_out: str = f"./{file_name.replace('.tif', '')}-{str(i).rjust(2, '0')}.vrt"
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

    src_raster: Optional[gdal.Dataset] = io.read_raster(args.get("multi_band"))

    create_single_band_vrt(src_raster, args.get("multi_band"))

    src_raster = None


if __name__ == "__main__":
    main()
