#! /usr/bin/python3

from osgeo import gdal
import numpy as np
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
args: Dict[str, List[str]] = vars(parser.parse_args())


def extract_basename(path: str, old_str: str, new_str: str) -> Path:
    return Path(path.split('/').pop().replace(old_str, new_str))


def read_raster(path: str) -> gdal.Dataset:
    # TODO: Does it make sense to resolve to absolute?
    if raster := gdal.Open(str(Path(path).absolute()), gdal.GA_ReadOnly):
        return raster
    raise OSError(f"Failed to open dataset {path}")


def create_single_band_vrt(out_dir: str, multi_raster: gdal.Dataset, multi_raster_path: str) -> List[str]:
    if not Path(out_dir).absolute().exists():
        raise OSError(f"Directory {out_dir} does not exist")

    n_bands: int = multi_raster.RasterCount
    file_name: str = str(Path(multi_raster_path).name)
    path_list: List[str] = []

    for i in range(1, n_bands + 1):
        vrt_out: str = out_dir + f"/{extract_basename(file_name, '.tif', '')}_{str(i).rjust(2, '0')}.vrt"
        path_list.append(vrt_out)
        if single_vrt := gdal.BuildVRT(vrt_out, multi_raster, bandList=[i]):
            single_vrt_band = single_vrt.GetRasterBand(1)
            single_vrt_band.SetColorInterpretation(gdal.GCI_GrayIndex)
            single_vrt_band = None
            single_vrt = None
        else:
            raise OSError(f"Failed to create output virtual raster file {vrt_out}")

    return path_list


def create_multi_stack_vrt(out_dir: str, multi_raster_path: str, single_band_vrt: List[str],
                           single_band_raster: List[str]) -> None:
    if not Path(out_dir).absolute().exists():
        raise OSError(f"Directory {out_dir} does not exist")

    vrt_out = str(Path(out_dir).absolute() / Path("vrt") / extract_basename(multi_raster_path, "BOA.tif", "STACK.vrt"))
    # TODO: set band names? Right now, it is not possible to differentiate the raster bands afterwards.
    if multi_vrt := gdal.BuildVRT(vrt_out, single_band_vrt + single_band_raster, separate=True):
        multi_vrt = None
    else:
        raise OSError(f"Failed to create output virtual raster file {vrt_out}")


src_raster: Optional[gdal.Dataset] = read_raster(args.get("multi_band")[0])

single_band_vrt_paths: List[str] = create_single_band_vrt(args.get("output_dir")[0], src_raster,
                                                          args.get("multi_band")[0])

create_multi_stack_vrt(args.get("output_dir")[0], args.get("multi_band")[0], single_band_vrt_paths,
                       args.get("single_bands"))

src_raster = None
