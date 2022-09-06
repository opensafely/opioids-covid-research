from cohortextractor import (
  StudyDefinition,
  patients,
  codelist,
  codelist_from_csv,
  Measure,
)

from datetime import date

from codelists import *
  
study = StudyDefinition(
    default_expectations={
      "date": {"earliest": "1900-01-01", "latest": "today"},
      "rate": "uniform",
    },
    
    index_date= "2022-03-01",
    
    population = patients.all(),
    
     # Ethnicity
    ethnicity=patients.categorised_as(
        {
            "Unknown": "DEFAULT",
            "White - British": "eth='1'",
            "White - Irish": "eth='2'",
            "White - Other": "eth='3'",
            "Mixed - White/Black Caribbean": "eth='4'",
            "Mixed - White/Black African": "eth='5'",
            "Mixed - White/Asian": "eth='6'",
            "Mixed - Other": "eth='7'",
            "Asian or Asian British - Indian": "eth='8'",
            "Asian or Asian British - Pakistani": "eth='9'",
            "Asian or Asian British - Bangladeshi": "eth='10'",
            "Asian or Asian British - Other": "eth='11'",
            "Black or Black British - Caribbean": "eth='12'",
            "Black or Black British - African": "eth='13'",
            "Black or Black British - Other": "eth='14'",
            "Other - Chinese": "eth='15'",
            "Other": "eth='16'",
        },

        eth=patients.with_these_clinical_events(
            ethnicity_codes_16,
            returning="category",
            find_last_match_in_period=True,
            include_date_of_match=False,
            return_expectations={
                "incidence": 0.75,
                "category": {
                    "ratios": {
                        "1": 0.0625,
                        "2": 0.0625,
                        "3": 0.0625,
                        "4": 0.0625,
                        "5": 0.0625,
                        "6": 0.0625,
                        "7": 0.0625,
                        "8": 0.0625,
                        "9": 0.0625,
                        "10": 0.0625,
                        "11": 0.0625,
                        "12": 0.0625,
                        "13": 0.0625,
                        "14": 0.0625,
                        "15": 0.0625,
                        "16": 0.0625,
                    },
                },
            },
        ),

        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "White - British": 0.0625,
                    "White - Irish": 0.0625,
                    "White - Other": 0.0625,
                    "Mixed - White/Black Caribbean": 0.0625,
                    "Mixed - White/Black African": 0.0625,
                    "Mixed - White/Asian": 0.0625,
                    "Mixed - Other": 0.0625,
                    "Asian or Asian British - Indian": 0.0625,
                    "Asian or Asian British - Pakistani": 0.0625,
                    "Asian or Asian British - Bangladeshi": 0.0625,
                    "Asian or Asian British - Other": 0.0625,
                    "Black or Black British - Caribbean": 0.0625,
                    "Black or Black British - African": 0.05,
                    "Black or Black British - Other": 0.05,
                    "Other - Chinese": 0.05,
                    "Other": 0.05,
                    "Unknown": 0.05,
                },
            },
        },
    ),
)
