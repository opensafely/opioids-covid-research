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
      (age >=18 AND age < 110)
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

  ## Groups
  
  ### Care home - using combination of primis codes and address linkage (based on Schultze report)
  carehome = patients.satisfying(
    """
    carehome_codes
    OR
    tpp_care_home_type
    """,

    ### Care home from codelists
    carehome_codes = patients.with_these_clinical_events(
      carehome_primis_codes,
      on_or_before = "index_date",
      returning = "binary_flag",
      return_expectations = {"incidence": 0.1}
    ),

    # COPIED CODE FROM SCHULTZE REPORT
    # tpp_care_home_type=patients.care_home_status_as_of(
    #  "index_date",
    #  categorised_as={
    #    "PC": """
    #      IsPotentialCareHome
    #      AND LocationDoesNotRequireNursing='Y'
    #      AND LocationRequiresNursing='N'
    #      """,
    #    "PN": """
    #      IsPotentialCareHome
    #      AND LocationDoesNotRequireNursing='N'
    #      AND LocationRequiresNursing='Y'
    #      """,
    #    "PS": "IsPotentialCareHome",
    #    "U": "DEFAULT",
    #    },
    #  return_expectations={
    #    "rate": "universal",
    #    "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "U": 0.85,},},
    #    },
    #),

    ## Care home from TPP address list (as binary variable)
    tpp_care_home_type=patients.care_home_status_as_of(
      "index_date",
      categorised_as={
        1: """
          IsPotentialCareHome
          """,
        0: "DEFAULT",
        },
    ),

     return_expectations = {
      "incidence": 0.05,
    },

  ),

  ### Cancer in past year
  cancer = patients.with_these_clinical_events(
    cancer_codes,
    between = ["first_day_of_month(index_date) - 5 year", "last_day_of_month(index_date)"],
    returning = "binary_flag",
    return_expectations = {"incidence": 0.15}
  ),

  ### Sickle cell disease
  scd = patients.with_these_clinical_events(
    scd_codes,
    on_or_before = "last_day_of_month(index_date)",
    returning = "binary_flag",
    return_expectations = {"incidence": .01}
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

  ### High dose prescribing
  hi_opioid_any = patients.with_these_medications(
    hi_opioid_codes,
    between = ["first_day_of_month(index_date)", "last_day_of_month(index_date)"],
    returning = "binary_flag",
    find_first_match_in_period = True,
    include_date_of_match = True,
    date_format = "YYYY-MM-DD",
    return_expectations= {
      "date": {
        "earliest": "first_day_of_month(index_date)",
        "latest": "last_day_of_month(index_date)",
        },
      "incidence": 0.05
      },
  ),

  ### Any new prescribing (2-year washout)
  ### TODO: should patients be registered for 2+ years for defining new use?? 
  opioid_new = patients.satisfying(
    """
    opioid_any
    AND 
    NOT opioid_last
    """, 

    return_expectations = {
      "incidence": 0.1,
    },

    opioid_last = patients.with_these_medications(
      opioid_codes,
      returning = "binary_flag",
      between = ["opioid_any_date - 2 year", "opioid_any_date - 1 day"],
      find_first_match_in_period = True,
      return_expectations = {
        "date": {
          "earliest": "first_day_of_month(index_date) - 2 year",
          "latest": "last_day_of_month(index_date)- 1 day",
        },
        "incidence": 0.1
        }
    ),
  ),

  ### New high dose opioid prescribing
  hi_opioid_new = patients.satisfying(
    
    """
    hi_opioid_any
    AND 
    NOT hi_opioid_last
    """, 
    
    return_expectations = {
      "incidence": 0.05,
    },
    
    hi_opioid_last = patients.with_these_medications(
      hi_opioid_codes,
      returning = "date",
      find_first_match_in_period = True,
      between = ["hi_opioid_any_date - 2 year", "hi_opioid_any_date - 1 day"],
      date_format = "YYYY-MM-DD",
      return_expectations = {
        "date": {
          "earliest": "first_day_of_month(index_date) - 2 year",
          "latest": "last_day_of_month(index_date)- 1 day",
        },
        "incidence": 0.1}
    ),
  ),

  # Opioid naive in past 2 years (for denominator for new use)
  opioid_naive = patients.satisfying(
    """
    NOT opioid_last
    """, 
    return_expectations = {
      "incidence": 0.2,
    },
    ),

  # High dose opioid naive in past 2 years (for denominator for new use)
  hi_opioid_naive = patients.satisfying(
    """
    NOT hi_opioid_last
    """, 
    return_expectations = {
      "incidence": 0.1,
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
    group_by = ["cancer"],
  ),

  ## High dose opioid 
  Measure(
    id = "hi_opioid_all_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
    
  ),
  
  # Age and sex ####
  ## Any opioid - age and sex 
  Measure(
    id = "opioid_agesex_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
    
  ),

  ## High dose opioid - age and sex 
  Measure(
    id = "hi_opioid_agesex_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
    
  ),

    
  # Age and sex ####
  ## Any opioid - age and sex 
  Measure(
    id = "opioid_age_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat","cancer"],
    
  ),

  ## High dose opioid - age and sex 
  Measure(
    id = "hi_opioid_age_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["age_cat","cancer"],
    
  ),

    
  # Age and sex ####
  ## Any opioid - age and sex 
  Measure(
    id = "opioid_sex_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["sex","cancer"],
    
  ),

  ## High dose opioid - age and sex 
  Measure(
    id = "hi_opioid_sex_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer"],
    
  ),

  # Carehomes ####
  ## ANy opioid - carehomes 
  Measure(
    id = "opioid_care_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["carehome","cancer"],
    
  ),

  ## High dose opioid - carehomes 
  Measure(
    id = "hi_opioid_care_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["carehome","cancer"],
    
  ),
  
  # Sickle cell ####
  ## Any opioid - sickle cell 
  Measure(
    id = "opioid_scd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["scd","cancer"],
    
  ),

  ## High dose opioid - sickle cell 
  Measure(
    id = "hi_opioid_scd_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["scd","cancer"],
    
  ),

  # Ethnicity ####
  ## Any opioid - ethnicity16 
  Measure(
    id = "opioid_eth16_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity16","cancer"],
    
  ),

  ## High dose opioid - ethnicity16 
  Measure(
    id = "hi_opioid_eth16_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["ethnicity16","cancer"],
    
  ),

    ## Any opioid - ethnicity6
  Measure(
    id = "opioid_eth6_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer"],
    
  ),

  ## High dose opioid - ethnicity6 
  Measure(
    id = "hi_opioid_eth6_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer"],
    
  ),

  # Region ####
  ## Any opioid - region
  Measure(
    id = "opioid_reg_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["region","cancer"],
    
  ),

  ## High dose opioid - region 
  Measure(
    id = "hi_opioid_reg_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["region","cancer"],
    
  ),

  # IMD deciles
  ## Any opioid - imd
  Measure(
    id = "opioid_imd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer"],
    
  ),

  ## High dose opioid - imd
  Measure(
    id = "hi_opioid_imd_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer"],
    
  ),

  #  Monthly rates - initiation #
  ## Any opioid 
  Measure(
    id = "opioid_all_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["cancer"],
    
  ),
  
  # Age and sex #
  ## new opioid
  Measure(
    id = "opioid_agesex_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["age_cat","sex","cancer"],
  ),

    # Age and sex #
  ## new opioid
  Measure(
    id = "opioid_age_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["age_cat","cancer"],
  ),

    # Age and sex #
  ## new opioid
  Measure(
    id = "opioid_sex_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["sex","cancer"],
  ),
  
  # Carehomes #
  ## new opioid - carehomes
  Measure(
    id = "opioid_care_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["carehome","cancer"],
  ),
  
  # Sickle cell #
  ## new opioid - sickle cell
  Measure(
    id = "opioid_scd_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["scd","cancer"],
  ),

  #
  #  Ethnicity #
  ## new opioid - ethnicity16
  Measure(
    id = "opioid_eth16_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["ethnicity16","cancer"],
  ),

    #  Ethnicity #
  ## new opioid - ethnicity6
  Measure(
    id = "opioid_eth6_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["ethnicity6","cancer"],
  ),

  # Region #
  ## new opioid - region
  Measure(
    id = "opioid_reg_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["region","cancer"],
  ),
  
  # IMD decile #
  ## new opioid - imd
  Measure(
    id = "opioid_imd_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["imdq10","cancer"],
  ),


]