#! /usr/bin/python3

import argparse
from typing import Dict
import gdal
from python_modules import cio
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(
    description="This script is used to combine a unmasked raster file with a binary mask file into a VRT dataset."
)
parser.add_argument("-in", "--input-file", required=True, nargs=1, type=str, help="Path to unmasked raster.", dest="input_file")
parser.add_argument("--mask", required=True, nargs=1, type=str,
                    help="Path to binary mask layer. It is expected that this file is either a binary mask with "
                         "zeros representing no data and ones valid data or a alpha mask with zeros representing "
                         "no data and a value of 255 valid data",
                    dest="mask_file")
parser.add_argument("-of", "--output-file", required=True, nargs=1, type=str, help="Path to output file.", dest="output_file")

args: Dict[str, str] = {key: value[0] for key, value in vars(parser.parse_args()).items()}

unmasked_raster: gdal.Dataset = cio.read_raster_shared(args.get("input_file"))
mask_raster: gdal.Dataset = cio.read_raster(args.get("mask_file"))
vrt_driver: gdal.Driver = gdal.GetDriverByName("VRT")
output_raster: gdal.Dataset = vrt_driver.CreateCopy(args.get("output_file"), unmasked_raster, strict=False)

xSize, ySize = mask_raster.RasterXSize, mask_raster.RasterYSize

for layer in range(1, unmasked_raster.RasterCount + 1):
    slayer = output_raster.GetRasterBand(layer)
    slayer.SetMetadataItem("HideNoDataValue", "1")
    slayer.DeleteNoDataValue() # See RFC 58

output_raster = None # Why do I need to set this to None (i.e. close it) here instead of passing it to another function like the following two lines?
# More importantly, why does this only come up, when setting a metadata item in the loop above?
cio.close_gdal(unmasked_raster)
cio.close_gdal(mask_raster)

# output_raster.CreateMaskBand(gdal.GMF_ALPHA) adds the MaskBand as well, but seemingly doesn't allow any editing of it (or I didn't find it).
# This however feels very hacky and there should be a better/more straightforward solution!
tree = ET.parse(args.get("output_file"))
root = tree.getroot()
mask_band = ET.SubElement(root, "MaskBand")
mask_band_rasterband = ET.SubElement(mask_band, "VRTRasterBand", {"dataType": "Byte"})
mask_band_rasterband_source = ET.SubElement(mask_band_rasterband, "SimpleSource")
mask_band_source_definition = ET.SubElement(mask_band_rasterband_source, "SourceFilename", {"relativeToVRT": "1"})
mask_band_source_definition.text = args.get("mask_file")
mask_band_source_band = ET.SubElement(mask_band_rasterband_source, "SourceBand")
mask_band_source_band.text = "1"
mask_band_srcRect = ET.SubElement(mask_band_rasterband_source, "SrcRect", {"xOff": "0", "yOff": "0", "xSize": f"{xSize}", "ySize": f"{ySize}"})
mask_band_dstRect = ET.SubElement(mask_band_rasterband_source, "DstRect", {"xOff": "0", "yOff": "0", "xSize": f"{xSize}", "ySize": f"{ySize}"})
tree.write(args.get("output_file"))
