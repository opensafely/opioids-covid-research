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
    "date": {"earliest": "2020-01-01", "latest": "2022-03-01"},
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


  #####################
  ## Medication DM&D ##
  
  ## Opioid prescribing

      ## Morphine subq opioid - num of people
  morph_opioid_any = patients.with_these_medications(
    morph_opioid_codes,
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

  ## Morphine subq opioid - num of items
  morph_opioid_itm = patients.with_these_medications(
    morph_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    },
  ),

  
## Morphine subq opioid - num of items
  morph10_opioid_itm = patients.with_these_medications(
    morph10_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    },
  ),

morph10_opioid_dmd=patients.with_these_medications(
   morph10_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "code",
    return_expectations={
      "category": {"ratios": {
        "36128211000001109":  .1,
        "4382711000001105": .1,
        "39146711000001105": .1,
        "4383611000001106": .1,
        "24403511000001100": .1,
        "40838611000001106": .1,
        "4383411000001108": .1,
        "4383011000001104": .1,
        "4383211000001109": .1,
        "10678011000001108": .1,
      }},
            "incidence": 1,
        },
  ),
)


# --- DEFINE MEASURES ---

measures = [

  ####  Monthly rates #####

  ### Full population ###


  ## Morphine opioid 
  Measure(
    id = "morph_opioid_any",
    numerator = "morph_opioid_any",
    denominator = "population",
    group_by = ["population"],
  ),

  ## MOrphine opioid 
  Measure(
    id = "morph_opioid_itm",
    numerator = "morph_opioid_itm",
    denominator = "population",
    group_by = ["population"],
  ),
  
  ## MOrphine opioid 
  Measure(
    id = "morph10_opioid_itm",
    numerator = "morph10_opioid_itm",
    denominator = "population",
    group_by = ["population"],
  ),

  ## MOrphine opioid 
  Measure(
    id = "morph10_opioid_dmd",
    numerator = "morph10_opioid_itm",
    denominator = "population",
    group_by = ["morph10_opioid_dmd"],
  ),
]