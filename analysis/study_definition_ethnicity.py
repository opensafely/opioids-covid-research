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
    eth2001 = patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning = "category",
        find_last_match_in_period = True,
        include_date_of_match = False,
        return_expectations = {
            "category": {
                "ratios": {
                    "1": 0.1,
                    "2": 0.1,
                    "3": 0.1,
                    "4": 0.06,
                    "5": 0.06,                   
                    "6": 0.06,
                    "7": 0.06,
                    "8": 0.06,
                    "9": 0.05,
                    "10": 0.05,                   
                    "11": 0.05,
                    "12": 0.05,
                    "13": 0.05,
                    "14": 0.05,
                    "15": 0.05,
                    "16": 0.05,
                }
            },
            "incidence": 0.75,
        },
    ),
)
