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

    ## Oxy subq opioid - num of people
  oxy_opioid_any = patients.with_these_medications(
    oxy_opioid_codes,
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

  ## Oxy subq opioid - num of items
  oxy_opioid_itm = patients.with_these_medications(
    oxy_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "number_of_matches_in_period",
    return_expectations = {
      "int": {"distribution": "normal", "mean": 6, "stddev": 3},
        "incidence": 0.6,
    }
  ),

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
    }
  ),


  morph_opioids_dmd=patients.with_these_medications(
    morph_opioid_codes,
    between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],    
    returning = "code",
    return_expectations={
      "category": {"ratios": {
        "12391711000001100": 0.014,
"12335511000001100": 0.024,
"12391311000001100": 0.024,
"12333211000001100": 0.014,
"22401911000001100": 0.014,
"22402211000001100": 0.014,
"30947711000001100": 0.014,
"12391411000001100": 0.014,
"12333611000001100": 0.014,
"12391611000001100": 0.014,
"12334711000001100": 0.014,
"12391211000001100": 0.014,
"12332111000001100": 0.014,
"36128211000001100": 0.014,
"4382711000001100": 0.014,
"4383611000001100": 0.014,
"24403511000001100": 0.014,
"4383411000001100": 0.014,
"4383011000001100": 0.014,
"4383211000001100": 0.014,
"10678011000001100": 0.014,
"38895511000001100": 0.014,
"4045011000001100": 0.014,
"4047511000001100": 0.014,
"4047011000001100": 0.014,
"4046311000001100": 0.014,
"4046711000001100": 0.014,
"36128711000001100": 0.014,
"4048411000001100": 0.014,
"4049611000001100": 0.014,
"24403711000001100": 0.014,
"4049411000001100": 0.014,
"4048911000001100": 0.014,
"4049211000001100": 0.014,
"12391011000001100": 0.014,
"12329811000001100": 0.014,
"36128511000001100": 0.014,
"4478411000001100": 0.014,
"8436411000001100": 0.014,
"4478911000001100": 0.014,
"36128911000001100": 0.014,
"4476211000001100": 0.014,
"21507711000001100": 0.014,
"4477511000001100": 0.014,
"4476511000001100": 0.014,
"4477011000001100": 0.014,
"12390811000001100": 0.014,
"12329211000001100": 0.014,
"12391111000001100": 0.014,
"12332811000001100": 0.014,
"10075511000001100": 0.014,
"10065911000001100": 0.014,
"10066311000001100": 0.014,
"9750511000001100": 0.014,
"19723011000001100": 0.014,
"19710611000001100": 0.014,
"20419411000001100": 0.014,
"20418211000001100": 0.014,
"21579811000001100": 0.014,
"21555311000001100": 0.014,
"21636011000001100": 0.014,
"21627711000001100": 0.014,
"12391811000001100": 0.014,
"12336111000001100": 0.014,
"30823211000001100": 0.014,
"21579911000001100": 0.014,
"21540711000001100": 0.014,
"30823411000001100": 0.014,
"30996711000001100": 0.014,
"9748311000001100": 0.014,
      }},

            "incidence": 1,
        },
  )
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
    id = "morph_opioid_dmd",
    numerator = "morph_opioid_itm",
    denominator = "population",
    group_by = ["morph_opioids_dmd"],
  ),
]