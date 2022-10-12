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
    ethnicity16=patients.categorised_as(
        {
            "Unknown": "DEFAULT",
            "White - British": "eth16='1'",
            "White - Irish": "eth16='2'",
            "White - Other": "eth16='3'",
            "Mixed - White/Black Caribbean": "eth16='4'",
            "Mixed - White/Black African": "eth16='5'",
            "Mixed - White/Asian": "eth16='6'",
            "Mixed - Other": "eth16='7'",
            "Asian or Asian British - Indian": "eth16='8'",
            "Asian or Asian British - Pakistani": "eth16='9'",
            "Asian or Asian British - Bangladeshi": "eth16='10'",
            "Asian or Asian British - Other": "eth16='11'",
            "Black or Black British - Caribbean": "eth16='12'",
            "Black or Black British - African": "eth16='13'",
            "Black or Black British - Other": "eth16='14'",
            "Other - Chinese": "eth16='15'",
            "Other": "eth16='16'",
        },

        eth16=patients.with_these_clinical_events(
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

    ethnicity6=patients.categorised_as(
        {
            "Unknown": "DEFAULT",
            "White": "eth6='1'",
            "Mixed": "eth6='2'",
            "Asian or Asian British": "eth6='3'",
            "Black or Black British": "eth6='4'",
            "Other": "eth6='5'",
        },

        eth6=patients.with_these_clinical_events(
            ethnicity_codes_6,
            returning="category",
            find_last_match_in_period=True,
            include_date_of_match=False,
            return_expectations={
                "incidence": 0.75,
                "category": {
                    "ratios": {
                        "1": 0.30,
                        "2": 0.20,
                        "3": 0.20,
                        "4": 0.20,
                        "5": 0.05,
                        "6": 0.05,
                    },
                },
            },
        ),

        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "White": 0.30,
                    "Mixed": 0.20,
                    "Asian or Asian British": 0.20,
                    "Black or Black British": 0.20,
                    "Other": 0.05,
                    "Unknown": 0.05,
                },
            },
        },
    ),
)
