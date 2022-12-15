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

  ### Any prescribing - num of people
  opioid_any = patients.with_these_medications(
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

  ### Any prescribing - num of items
  opioid_itm = patients.with_these_medications(
    opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    }
  ),

  ## Parenteral opioid - num of people
  par_opioid_any = patients.with_these_medications(
    par_opioid_codes,
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

  ## Parenteral opioid - num of items
  par_opioid_itm = patients.with_these_medications(
    par_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    }
  ),
)


# --- DEFINE MEASURES ---

measures = [

  ####  Monthly rates #####

  ### Full population ###

  ## Any opioid 
  Measure(
    id = "opioid_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["population"],
  ),

   Measure(
    id = "opioid_itm",
    numerator = "opioid_itm",
    denominator = "population",
    group_by = ["population"],
  ),

  ## Parenteral opioid 
  Measure(
    id = "par_opioid_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["population"],
  ),

  ## Parenteral opioid 
  Measure(
    id = "par_opioid_itm",
    numerator = "par_opioid_itm",
    denominator = "population",
    group_by = ["population"],
  ),
]