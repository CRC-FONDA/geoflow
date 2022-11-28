from typing import List, Union, Tuple, Literal, Optional

import geopandas as gp
import numpy as np
import pandas as pd


class Samples:
    @staticmethod
    def __open(path: str) -> pd.DataFrame:
        return gp.read_file(path, ignore_geometry=True)

    @staticmethod
    def __get_year__():
        pass

    def __init__(self, source: Union[str, pd.DataFrame]):
        self.Data: pd.DataFrame = Samples.__open(source) if isinstance(source, str) else source
        self.year: int = 0

    def __drop_empty(self):
        self.Data.dropna(axis=0, how='any', inplace=True)

    # def __convert_dtypes(self):
    #     object_columns: np.ndarray = np.flatnonzero(np.asarray((self.Data.dtypes == 'object')))
    #
    #     if object_columns.size > 0:
    #         self.Data.iloc[:, object_columns.tolist()] = self.Data.iloc[:, object_columns.tolist()].astype('string', copy=False)

    def clean_up(self):
        self.__drop_empty()
        # self.__convert_dtypes()

    def join(self, to_join: 'Samples') -> 'Samples':
        if np.any(self.Data.isna()) or np.any(to_join.Data.isna()):
            raise AssertionError("At least one instance contains missing data which is not allowed.")

        return Samples(self.Data.merge(right=to_join.Data, how="left", on="POINT_ID", validate="1:1"))

    def align_samples(self, to_align: 'Samples') -> Tuple['Samples', 'Samples']:
        left, right = self.Data.align(to_align.Data, join='outer', axis=0)

        return Samples(left), Samples(right)


class AASGContainer:
    def __init__(self, building_block: Samples, index_column: str, non_data_columns: List[str]):
        self.Index: pd.Series = building_block.Data[index_column]
        # TODO Check array dimensions!
        self.Data: np.ndarray = np.asarray(building_block.Data.drop(labels=non_data_columns, axis=1))

    def compute_pdf(self) -> None:
        pass

    def filter_stable_samples(self):
        pass

    def distance(self, distance_to: 'AASGContainer', distance_type: Literal["manhattan", "euclidian", "fractional"], pdf_cutoff: float,
                 fractional_power: Optional[float] = None) -> pd.Series:
        """
        Calculate distance between two observations based on feature variables. Returns a pandas Series of unique LUCAS
        point IDs which are below a specified threshold in the PDF.

        :param distance_to:
        :param distance_type:
        :param pdf_cutoff:
        :param fractional_power:
        """
        if distance_type == "manhattan":
            pass
        elif distance_type == "euclidian":
            pass
        elif distance_type == "fractional":
            if fractional_power is None or fractional_power < 0 or fractional_power > 1:
                raise ValueError("Argument 'fractional_power' cannot be None, smaller then zero or greater then one when computing fractional distances.")
            pass
        else:
            raise ValueError(f"Argument 'distance_type' must be one of 'manhattan', 'euclidian' or 'fractional'. Got {distance_type} instead.")


class AASGSolvedContainer:
    pass
