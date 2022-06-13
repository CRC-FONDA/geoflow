#! /usr/bin/python3

import pandas as pd
import geopandas as gpd
import argparse
from typing import Dict, List

parser = argparse.ArgumentParser(
	description="Join theoretical LUCAS points together with LUCAS survey data and query observations."
)
parser.add_argument("--survey", required=True, type=str, nargs=1, help="Path to file containing LUCAS observations")
parser.add_argument("--geom", required=True, type=str, nargs=1, help="Path to file containing LUCAS point geometries")
parser.add_argument("--query", required=False, type=str, nargs='?', default="", help="")
parser.add_argument("--epsg", required=False, type=int, default=3035, nargs=1, help="EPSG code for the projection fo FORCE generated files")
parser.add_argument("-of", "--output-file", required=True, dest="of", type=str, nargs=1, help="Path to output file.")

args: Dict[str, str] = {key: (value[0] if isinstance(value, List) else value) for key, value in vars(parser.parse_args()).items()}

LUT = pd.DataFrame({'LC1': {0: 'A10', 1: 'A11', 2: 'A12', 3: 'A13', 4: 'A20', 5: 'A21', 6: 'A22', 7: 'A30', 8: 'BX1', 9: 'BX2', 10: 'B10', 11: 'B11', 12: 'B12',
							13: 'B13', 14: 'B14', 15: 'B15', 16: 'B16', 17: 'B17', 18: 'B18', 19: 'B19', 20: 'B20', 21: 'B21', 22: 'B22', 23: 'B23', 24: 'B30',
							25: 'B31', 26: 'B32', 27: 'B33', 28: 'B34', 29: 'B35', 30: 'B36', 31: 'B37', 32: 'B40', 33: 'B41', 34: 'B42', 35: 'B43', 36: 'B44',
							37: 'B45', 38: 'B50', 39: 'B51', 40: 'B52', 41: 'B53', 42: 'B54', 43: 'B55', 44: 'B70', 45: 'B71', 46: 'B72', 47: 'B73', 48: 'B74',
							49: 'B75', 50: 'B76', 51: 'B77', 52: 'B80', 53: 'B81', 54: 'B82', 55: 'B83', 56: 'B84', 57: 'C10', 58: 'C20', 59: 'C21', 60: 'C22',
							61: 'C23', 62: 'C30', 63: 'C31', 64: 'C32', 65: 'C33', 66: 'D10', 67: 'D20', 68: 'E10', 69: 'E20', 70: 'E30', 71: 'F10', 72: 'F20',
							73: 'F30', 74: 'F40', 76: 'G10', 77: 'G11', 78: 'G12', 79: 'G20', 80: 'G21', 81: 'G22', 82: 'G30', 83: 'G50', 84: 'H10', 85: 'H11',
							86: 'H12', 87: 'H20', 88: 'H21', 89: 'H22', 90: 'H23'},
					'LC1_INFO': {0: 'built-up areas', 1: 'buildings with one to three floors ', 2: 'buildings with more than three floors', 3: 'greenhouses',
								 4: 'artificial non-built up areas', 5: 'non built-up area features', 6: 'non built-up linear features',
								 7: 'other artificial areas', 8: 'temporary crops', 9: 'permanent crops', 10: 'cereals', 11: 'common wheat', 12: 'durum wheat',
								 13: 'barley', 14: 'rye', 15: 'oats', 16: 'maize', 17: 'rice', 18: 'triticale', 19: 'other cereals', 20: 'root crops',
								 21: 'potatoes', 22: 'sugar beet', 23: 'other root crops', 24: 'non-permanent industrial crops', 25: 'sunflower',
								 26: 'rape and turnip rape', 27: 'soya', 28: 'cotton', 29: 'other fibre and oleaginous crops', 30: 'tobacco',
								 31: 'other non-permanent industrial crops', 32: 'dry pulses_ vegetables and flowers', 33: 'dry pulses', 34: 'tomatoes',
								 35: 'other fresh vegetables', 36: 'floriculture and ornamental plants', 37: 'strawberries',
								 38: 'fodder crops (mainly leguminous)', 39: 'clovers', 40: 'lucerne', 41: 'other leguminous and mixtures for fodder',
								 42: 'mix of cereals', 43: 'temporary grassland', 44: 'permanent crops: fruit trees', 45: 'apple fruit', 46: 'pear fruit',
								 47: 'cherry fruit', 48: 'nuts trees', 49: 'other fruit trees and berries', 50: 'oranges', 51: 'other citrus fruit',
								 52: 'other permanent crops', 53: 'olive groves', 54: 'vineyards', 55: 'nurseries', 56: 'permanent industrial crops',
								 57: 'broadleaved woodland', 58: 'coniferous woodland', 59: 'spruce dominated coniferous woodland',
								 60: 'pine dominated coniferous woodland', 61: 'other coniferous woodland', 62: 'mixed woodland',
								 63: 'spruce dominated mixed woodland', 64: 'pine dominated mixed woodland', 65: 'other mixed woodland',
								 66: 'shrubland with sparse tree cover', 67: 'shrubland without tree cover', 68: 'grassland with sparse tree_shrub cover',
								 69: 'grassland without tree_shrub cover', 70: 'spontaneously re-vegetated surfaces', 71: 'rocks and stones', 72: 'sand',
								 73: 'lichens and moss', 74: 'other bare soil', 76: 'inland water bodies', 77: 'Inland fresh water bodies',
								 78: 'Inland salty water bodies', 79: 'inland running water', 80: 'Inland fresh running water',
								 81: 'Inland salty running water', 82: 'coastal water bodies', 83: 'glaciers_ permanent snow', 84: 'inland wetlands',
								 85: 'inland marshes', 86: 'peatbogs', 87: 'coastal wetlands', 88: 'salt marshes', 89: 'salines', 90: 'intertidal flats'},
					'LC3_ID': {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 2, 9: 3, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2, 16: 2, 17: 2, 18: 2, 19: 2,
							   20: 2, 21: 2, 22: 2, 23: 2, 24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2,
							   38: 2, 39: 2, 40: 2, 41: 2, 42: 2, 43: 2, 44: 3, 45: 3, 46: 3, 47: 3, 48: 3, 49: 3, 50: 3, 51: 3, 52: 3, 53: 3, 54: 3, 55: 3,
							   56: 3, 57: 4, 58: 5, 59: 5, 60: 5, 61: 5, 62: 6, 63: 6, 64: 6, 65: 6, 66: 7, 67: 7, 68: 8, 69: 8, 70: 8, 71: 9, 72: 9, 73: 9,
							   74: 9, 76: 10, 77: 10, 78: 10, 79: 10, 80: 10, 81: 10, 82: 10, 83: 12, 84: 11, 85: 11, 86: 11, 87: 11, 88: 11, 89: 11, 90: 11},
					'LC3_INFO': {0: 'artificial land', 1: 'artificial land', 2: 'artificial land', 3: 'artificial land', 4: 'artificial land',
								 5: 'artificial land', 6: 'artificial land', 7: 'artificial land', 8: 'cropland seasonal', 9: 'cropland perennial',
								 10: 'cropland seasonal', 11: 'cropland seasonal', 12: 'cropland seasonal', 13: 'cropland seasonal', 14: 'cropland seasonal',
								 15: 'cropland seasonal', 16: 'cropland seasonal', 17: 'cropland seasonal', 18: 'cropland seasonal', 19: 'cropland seasonal',
								 20: 'cropland seasonal', 21: 'cropland seasonal', 22: 'cropland seasonal', 23: 'cropland seasonal', 24: 'cropland seasonal',
								 25: 'cropland seasonal', 26: 'cropland seasonal', 27: 'cropland seasonal', 28: 'cropland seasonal', 29: 'cropland seasonal',
								 30: 'cropland seasonal', 31: 'cropland seasonal', 32: 'cropland seasonal', 33: 'cropland seasonal', 34: 'cropland seasonal',
								 35: 'cropland seasonal', 36: 'cropland seasonal', 37: 'cropland seasonal', 38: 'cropland seasonal', 39: 'cropland seasonal',
								 40: 'cropland seasonal', 41: 'cropland seasonal', 42: 'cropland seasonal', 43: 'cropland seasonal', 44: 'cropland perennial',
								 45: 'cropland perennial', 46: 'cropland perennial', 47: 'cropland perennial', 48: 'cropland perennial',
								 49: 'cropland perennial', 50: 'cropland perennial', 51: 'cropland perennial', 52: 'cropland perennial',
								 53: 'cropland perennial', 54: 'cropland perennial', 55: 'cropland perennial', 56: 'cropland perennial',
								 57: 'forest broadleaved', 58: 'forest coniferous', 59: 'forest coniferous', 60: 'forest coniferous', 61: 'forest coniferous',
								 62: 'forest mixed', 63: 'forest mixed', 64: 'forest mixed', 65: 'forest mixed', 66: 'shrubland', 67: 'shrubland',
								 68: 'grassland', 69: 'grassland', 70: 'grassland', 71: 'bare land', 72: 'bare land', 73: 'bare land', 74: 'bare land',
								 76: 'water', 77: 'water', 78: 'water', 79: 'water', 80: 'water', 81: 'water', 82: 'water', 83: 'snow ice', 84: 'wetland',
								 85: 'wetland', 86: 'wetland', 87: 'wetland', 88: 'wetland', 89: 'wetland', 90: 'wetland'}})


def main():
	attributes = pd.read_csv(args.get("survey"), low_memory=False)

	geo_dataset = gpd.read_file(args.get("geom"))
	geo_dataset.to_crs(epsg=args.get("epsg"), inplace=True)
	geo_dataset.drop_duplicates("POINT_ID", inplace=True)

	try:
		attributes.query(args.get("query"), inplace=True)
	except ValueError:
		pass
	finally:
		geo_dataset.query(f"POINT_ID in {list(attributes.point_id)}", inplace=True)
		validation_subset = attributes.get(["point_id", "lc1"])
		geo_dataset = geo_dataset.merge(validation_subset, left_on="POINT_ID", right_on="point_id", how="left", validate="1:1")
		geo_dataset = geo_dataset.merge(LUT, left_on="lc1", right_on="LC1", how="left")
		geo_dataset = geo_dataset.loc[:, ['POINT_ID', 'LC3_ID', 'lc1', 'geometry']]
		geo_dataset['LC3_ID'] = geo_dataset['LC3_ID'].astype(int)

	geo_dataset.to_file(args.get("of"), layer="lucas")


if __name__ == "__main__":
	main()
