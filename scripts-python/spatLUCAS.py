#! /usr/bin/python3

import pandas as pd
import geopandas as gpd
import argparse
from typing import Dict, List

# TODO implement Query
parser = argparse.ArgumentParser(
	description="Join theoretical LUCAS points together with LUCAS survey data and query observations."
)
parser.add_argument("--survey", required=True, type=str, nargs=1, help="Path to file containing LUCAS observations")
parser.add_argument("--geom", required=True, type=str, nargs=1, help="Path to file containing LUCAS point geometries")
parser.add_argument("--query", required=False, type=str, nargs=1, help="")
parser.add_argument("-epsg", required=False, type=int, default=3035, nargs=1, help="EPSG code for the projection fo FORCE generated files")
parser.add_argument("-of", "--output-file", required=True, dest="of", type=str, nargs=1, help="Path to output file.")

args: Dict[str, str] = {key: (value[0] if isinstance(value, List) else value) for key, value in vars(parser.parse_args()).items()}


def main():
	attributes = pd.read_csv(args.get("survey"), low_memory=False)

	geo_dataset = gpd.read_file(args.get("geom"))
	geo_dataset.to_crs(epsg=args.get("epsg"), inplace=True)

	try:
		attributes.query(args.get("query"), inplace=True)
	except ValueError:
		pass
	finally:
		geo_dataset.query(f"POINT_ID in {list(attributes.point_id)}")

	geo_dataset.to_file(args.get("of"), layer="lucas")

if __name__ == "__main__":
	main()
