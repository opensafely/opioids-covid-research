from cohortextractor import (
  StudyDefinition,
  patients,
  codelist,
  codelist_from_csv,
  Measure,
)

from datetime import date

end_date = "2022-03-01"

from codelists import *
  
study = StudyDefinition(
    default_expectations={
      "date": {"earliest": "1900-01-01", "latest": "today"},
      "rate": "uniform",
    },
    
    index_date=end_date,
    
    population = patients.all(),
    
    # Ethnicity
    eth2001 = patients.with_these_clinical_events(
        ethnicity_codes_6,
        returning = "category",
        find_last_match_in_period = True,
        include_date_of_match = False,
        return_expectations = {
            "category": {
                "ratios": {
                    "1": 0.2,
                    "2": 0.2,
                    "3": 0.2,
                    "4": 0.2,
                    "5": 0.2,
                }
            },
            "incidence": 0.75,
        },
    ),
)
