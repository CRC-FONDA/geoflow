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

LUT = pd.DataFrame({'LC1': {0: 'A10', 1: 'A11', 2: 'A12', 3: 'A13', 4: 'A20', 5: 'A21', 6: 'A22', 7: 'A30', 8: 'B34', 9: 'B35', 10: 'B36', 11: 'B37', 12: 'B40',
                            13: 'B41', 14: 'B42', 15: 'B43', 16: 'B51', 17: 'B45', 18: 'B50', 19: 'B33', 20: 'B52', 21: 'B53', 22: 'B54', 23: 'B55', 24: 'B44',
                            25: 'B32', 26: 'B30', 27: 'B13', 28: 'B10', 29: 'B11', 30: 'B12', 31: 'B31', 32: 'B14', 33: 'B15', 34: 'BX1', 35: 'B16', 36: 'B18',
                            37: 'B19', 38: 'B20', 39: 'B21', 40: 'B22', 41: 'B23', 42: 'B17', 43: 'B80', 44: 'B81', 45: 'B77', 46: 'B83', 47: 'B84', 48: 'B82',
                            49: 'B76', 50: 'B71', 51: 'B74', 52: 'B73', 53: 'B72', 54: 'B75', 55: 'B70', 56: 'BX2', 57: 'C10', 58: 'C23', 59: 'C22', 60: 'C21',
                            61: 'C20', 62: 'C30', 63: 'C31', 64: 'C32', 65: 'C33', 66: 'D10', 67: 'D20', 68: 'E20', 69: 'E30', 70: 'E10', 71: 'F00', 72: 'F10',
                            73: 'F20', 74: 'F30', 75: 'F40', 76: 'G30', 77: 'G21', 78: 'G22', 79: 'G12', 80: 'G11', 81: 'G10', 82: 'G20', 83: 'H10', 84: 'H11',
                            85: 'H12', 86: 'H20', 87: 'H21', 88: 'H22', 89: 'H23', 90: 'G50'},
                    'LC1_INFO': {0: 'built-up areas', 1: 'buildings with one to three floors ', 2: 'buildings with more than three floors', 3: 'greenhouses',
                                 4: 'artificial non-built up areas', 5: 'non built-up area features', 6: 'non built-up linear features',
                                 7: 'other artificial areas', 8: 'cotton', 9: 'other fibre and oleaginous crops', 10: 'tobacco',
                                 11: 'other non-permanent industrial crops', 12: 'dry pulses_ vegetables and flowers', 13: 'dry pulses', 14: 'tomatoes',
                                 15: 'other fresh vegetables', 16: 'clovers', 17: 'strawberries', 18: 'fodder crops (mainly leguminous)', 19: 'soya',
                                 20: 'lucerne', 21: 'other leguminous and mixtures for fodder', 22: 'mix of cereals', 23: 'temporary grassland',
                                 24: 'floriculture and ornamental plants', 25: 'rape and turnip rape', 26: 'non-permanent industrial crops', 27: 'barley',
                                 28: 'cereals', 29: 'common wheat', 30: 'durum wheat', 31: 'sunflower', 32: 'rye', 33: 'oats', 34: 'temporary crops',
                                 35: 'maize', 36: 'triticale', 37: 'other cereals', 38: 'root crops', 39: 'potatoes', 40: 'sugar beet', 41: 'other root crops',
                                 42: 'rice', 43: 'other permanent crops', 44: 'olive groves', 45: 'other citrus fruit', 46: 'nurseries',
                                 47: 'permanent industrial crops', 48: 'vineyards', 49: 'oranges', 50: 'apple fruit', 51: 'nuts trees', 52: 'cherry fruit',
                                 53: 'pear fruit', 54: 'other fruit trees and berries', 55: 'permanent crops: fruit trees', 56: 'permanent crops',
                                 57: 'broadleaved woodland', 58: 'other coniferous woodland', 59: 'pine dominated coniferous woodland',
                                 60: 'spruce dominated coniferous woodland', 61: 'coniferous woodland', 62: 'mixed woodland',
                                 63: 'spruce dominated mixed woodland', 64: 'pine dominated mixed woodland', 65: 'other mixed woodland',
                                 66: 'shrubland with sparse tree cover', 67: 'shrubland without tree cover', 68: 'grassland without tree_shrub cover',
                                 69: 'spontaneously re-vegetated surfaces', 70: 'grassland with sparse tree_shrub cover', 71: 'bare land',
                                 72: 'rocks and stones', 73: 'sand', 74: 'lichens and moss', 75: 'other bare soil', 76: 'coastal water bodies',
                                 77: 'Inland fresh running water', 78: 'Inland salty running water', 79: 'Inland salty water bodies',
                                 80: 'Inland fresh water bodies', 81: 'inland water bodies', 82: 'inland running water', 83: 'inland wetlands',
                                 84: 'inland marshes', 85: 'peatbogs', 86: 'coastal wetlands', 87: 'salt marshes', 88: 'salines', 89: 'intertidal flats',
                                 90: 'glaciers_ permanent snow'},
                    'LC3_ID': {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2, 16: 2, 17: 2, 18: 2, 19: 2,
                               20: 2, 21: 2, 22: 2, 23: 2, 24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 33: 2, 34: 2, 35: 2, 36: 2, 37: 2,
                               38: 2, 39: 2, 40: 2, 41: 2, 42: 2, 43: 3, 44: 3, 45: 3, 46: 3, 47: 3, 48: 3, 49: 3, 50: 3, 51: 3, 52: 3, 53: 3, 54: 3, 55: 3,
                               56: 3, 57: 4, 58: 5, 59: 5, 60: 5, 61: 5, 62: 6, 63: 6, 64: 6, 65: 6, 66: 7, 67: 7, 68: 8, 69: 8, 70: 8, 71: 9, 72: 9, 73: 9,
                               74: 9, 75: 9, 76: 10, 77: 10, 78: 10, 79: 10, 80: 10, 81: 10, 82: 10, 83: 11, 84: 11, 85: 11, 86: 11, 87: 11, 88: 11, 89: 11,
                               90: 12},
                    'LC3_INFO': {0: 'artificial land', 1: 'artificial land', 2: 'artificial land', 3: 'artificial land', 4: 'artificial land',
                                 5: 'artificial land', 6: 'artificial land', 7: 'artificial land', 8: 'cropland seasonal', 9: 'cropland seasonal',
                                 10: 'cropland seasonal', 11: 'cropland seasonal', 12: 'cropland seasonal', 13: 'cropland seasonal', 14: 'cropland seasonal',
                                 15: 'cropland seasonal', 16: 'cropland seasonal', 17: 'cropland seasonal', 18: 'cropland seasonal', 19: 'cropland seasonal',
                                 20: 'cropland seasonal', 21: 'cropland seasonal', 22: 'cropland seasonal', 23: 'cropland seasonal', 24: 'cropland seasonal',
                                 25: 'cropland seasonal', 26: 'cropland seasonal', 27: 'cropland seasonal', 28: 'cropland seasonal', 29: 'cropland seasonal',
                                 30: 'cropland seasonal', 31: 'cropland seasonal', 32: 'cropland seasonal', 33: 'cropland seasonal', 34: 'cropland seasonal',
                                 35: 'cropland seasonal', 36: 'cropland seasonal', 37: 'cropland seasonal', 38: 'cropland seasonal', 39: 'cropland seasonal',
                                 40: 'cropland seasonal', 41: 'cropland seasonal', 42: 'cropland seasonal', 43: 'cropland perennial', 44: 'cropland perennial',
                                 45: 'cropland perennial', 46: 'cropland perennial', 47: 'cropland perennial', 48: 'cropland perennial',
                                 49: 'cropland perennial', 50: 'cropland perennial', 51: 'cropland perennial', 52: 'cropland perennial',
                                 53: 'cropland perennial', 54: 'cropland perennial', 55: 'cropland perennial', 56: 'cropland perennial',
                                 57: 'forest broadleaved', 58: 'forest coniferous', 59: 'forest coniferous', 60: 'forest coniferous', 61: 'forest coniferous',
                                 62: 'forest mixed', 63: 'forest mixed', 64: 'forest mixed', 65: 'forest mixed', 66: 'shrubland', 67: 'shrubland',
                                 68: 'grassland', 69: 'grassland', 70: 'grassland', 71: 'bare land', 72: 'bare land', 73: 'bare land', 74: 'bare land',
                                 75: 'bare land', 76: 'water', 77: 'water', 78: 'water', 79: 'water', 80: 'water', 81: 'water', 82: 'water', 83: 'wetland',
                                 84: 'wetland', 85: 'wetland', 86: 'wetland', 87: 'wetland', 88: 'wetland', 89: 'wetland', 90: 'snow ice'}})


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
