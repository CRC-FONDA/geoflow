#! /usr/bin/python3

import pandas as pd
import geopandas as gpd
import argparse
from typing import Dict, List

parser = argparse.ArgumentParser(
	description="Save subset of extracted columns. Since not all are needed further on."
)


