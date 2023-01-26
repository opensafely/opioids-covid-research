######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

######################################


# IMPORT STATEMENTS ----

# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
    Measure,
    codelist,
)

# Import codelists from codelist.py (which pulls them from the codelist folder)
from codelists import *

## Define study population and variables
study = StudyDefinition(

  # Set index date
  index_date = "2020-01-01",
  
  # Configure the expectations framework
  default_expectations={
    "date": {"earliest": "2020-01-01", "latest": "2022-12-01"},
    "rate": "uniform",
    "incidence": 0.15,
  },
 
  # Define the study population
  population = patients.satisfying(
      """
      registered
      AND 
      NOT has_died
      AND
      (sex = "M" OR sex = "F")
      AND
      (age >=18 AND age < 110)
      """,
    
      registered = patients.registered_as_of("index_date"),
      ), 
      
      has_died = patients.died_from_any_cause(
            on_or_before = "index_date",
            returning = "binary_flag",
      ),

 ## Variables ##

  ### Sex
  sex = patients.sex(
    return_expectations = {
      "rate": "universal",
      "category": {"ratios": {"M": 0.49, "F": 0.51}},
    },
  ),

  ### Age
  age = patients.age_as_of(
    "index_date",
    return_expectations={
        "rate" : "universal",
        "int" : {"distribution" : "population_ages"}
    }
    ),

      ### Age categories
  age_cat = patients.categorised_as(
    {"0": "DEFAULT",
      "1": """age >= 18 AND age < 30""",
      "2": """age >= 30 AND age < 40""",
      "3": """age >= 40 AND age < 50""",
      "4": """age >= 50 AND age < 60""",
      "5": """age >= 60 AND age < 70""",
      "6": """age >= 70 AND age < 80""",
      "7": """age >= 80 AND age < 90""",
      "8": """age >= 90""",
    },

    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0.01,
          "1": 0.12,
          "2": 0.12,
          "3": 0.13,
          "4": 0.13,
          "5": 0.13,          
          "6": 0.12,
          "7": 0.12,
          "8": 0.12,
        }},
    },
  ),



  #####################
  ## Medication DM&D ##
  
  ## Opioid prescribing

  ## num of items
  morph10_itm = patients.with_these_medications(
    morph10_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    },
  ),

  ## Morphine subq 10mg/ml opioid - num of items
  opioid_itm = patients.with_these_medications(
    morph10_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    },
  ),

  ## num people
  morph10_ppl = patients.with_these_medications(
    morph10_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "binary_flag",
    find_first_match_in_period = True,
    include_date_of_match = True,
    date_format = "YYYY-MM-DD",
    return_expectations= {
      "date": {
        "earliest": "first_day_of_month(index_date)",
        "latest": "last_day_of_month(index_date)",
        },
      "incidence": 0.15
      },
  ),

  ## Morphine subq 10mg/ml opioid - num of items
  opioid_ppl = patients.with_these_medications(
    opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "binary_flag",
    find_first_match_in_period = True,
    include_date_of_match = True,
    date_format = "YYYY-MM-DD",
    return_expectations= {
      "date": {
        "earliest": "first_day_of_month(index_date)",
        "latest": "last_day_of_month(index_date)",
        },
      "incidence": 0.15
      },
  ),

)

# --- DEFINE MEASURES ---

measures = [

  ####  Monthly rates #####

  Measure(
    id = "morph10_itm",
    numerator = "morph10_itm",
    denominator = "population",
    group_by = ["age_cat"],
  ),

  Measure(
    id = "morph10_ppl",
    numerator = "morph10_ppl",
    denominator = "population",
    group_by = ["age_cat"],
  ),

  Measure(
    id = "opioid_itm",
    numerator = "opioid_itm",
    denominator = "population",
    group_by = ["age_cat"],
  ),

  Measure(
    id = "opioid_ppl",
    numerator = "opioid_ppl",
    denominator = "population",
    group_by = ["age_cat"],
  ),

  
  ]
