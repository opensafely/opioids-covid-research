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
  index_date = "2018-01-01",
  
  # Configure the expectations framework
  default_expectations={
    "date": {"earliest": "2018-01-01", "latest": "2022-03-01"},
    "rate": "uniform",
    "incidence": 0.15,
  },
 
  # Define the study population
  population = patients.satisfying(
      """
      NOT has_died
      AND
      registered
      AND 
      (sex = "M" OR sex = "F")
      AND
      (age >=5 AND age < 18)
      """,
    
      has_died = patients.died_from_any_cause(
        on_or_before = "index_date",
        returning = "binary_flag",
      ),
    
      registered = patients.registered_as_of("index_date"),
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

  age_cat = patients.categorised_as(
    {"0": "DEFAULT",
      "1": """age < 12""",
      "2": """age >= 12""",
    },

    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0.01,
          "1": 0.49,
          "2": 0.50,
        }},
    },
  ),

  ### Index of multiple deprivation
  imdq10 = patients.categorised_as(
    {"0": "DEFAULT",
      "1": """index_of_multiple_deprivation >= 0 AND index_of_multiple_deprivation < 32844*1/10""",
      "2": """index_of_multiple_deprivation >= 32844*1/10 AND index_of_multiple_deprivation < 32844*2/10""",
      "3": """index_of_multiple_deprivation >= 32844*2/10 AND index_of_multiple_deprivation < 32844*3/10""",
      "4": """index_of_multiple_deprivation >= 32844*3/10 AND index_of_multiple_deprivation < 32844*4/10""",
      "5": """index_of_multiple_deprivation >= 32844*4/10 AND index_of_multiple_deprivation < 32844*5/10""",
      "6": """index_of_multiple_deprivation >= 32844*5/10 AND index_of_multiple_deprivation < 32844*6/10""",
      "7": """index_of_multiple_deprivation >= 32844*6/10 AND index_of_multiple_deprivation < 32844*7/10""",
      "8": """index_of_multiple_deprivation >= 32844*7/10 AND index_of_multiple_deprivation < 32844*8/10""",
      "9": """index_of_multiple_deprivation >= 32844*8/10 AND index_of_multiple_deprivation < 32844*9/10""",
      "10": """index_of_multiple_deprivation >= 32844*9/10""",
    },

    index_of_multiple_deprivation = patients.address_as_of(
      "index_date",
      returning = "index_of_multiple_deprivation",
      round_to_nearest = 100,
    ),

    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0.01,
          "1": 0.10,
          "2": 0.10,
          "3": 0.10,
          "4": 0.10,
          "5": 0.09,          
          "6": 0.10,
          "7": 0.10,
          "8": 0.10,
          "9": 0.10,
          "10": 0.10,
        },
      },
    },
  ),

  ### Region
  region = patients.registered_practice_as_of(
    "index_date",
    returning = "nuts1_region_name",
    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "North East": 0.1,
          "North West": 0.1,
          "Yorkshire and The Humber": 0.1,
          "East Midlands": 0.1,
          "West Midlands": 0.1,
          "East": 0.1,
          "London": 0.2,
          "South East": 0.1,
          "South West": 0.1,
        },
      },
    },
  ),

  #####################
  ## Medication DM&D ##
  
  ## Opioid prescribing

  ### Any prescribing
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

)

# --- DEFINE MEASURES ---

measures = [
  
  #  Monthly rates #
  # Full population ####
  ## Any opioid 
  Measure(
    id = "opioid_all_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["population"],
  ),

  # Sex ####
  ## Any opioid -  sex 
  Measure(
    id = "opioid_sex_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["sex"],
    
  ),

  Measure(
    id = "opioid_age_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat"],
    
  ),

  Measure(
    id = "opioid_agesex_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat", "sex"],
    
  ),

  # Ethnicity ####
  ## Any opioid - ethnicity 
  Measure(
    id = "opioid_eth_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity6"],
    
  ),

  # Region ####
  ## Any opioid - region 
  Measure(
    id = "opioid_reg_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["region"],
    
  ),

  # IMD deciles
  ## Any opioid - imd
  Measure(
    id = "opioid_imd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["imdq10"],
    
  ),
]