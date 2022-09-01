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
  # TODO: for TPP studies, do we need to specify TPP registered?
  population = patients.satisfying(
      """
      NOT has_died
      AND
      registered
      AND 
      (sex = "M" OR sex = "F")
      AND
      (age >=5 AND age < 110)
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
      "1": """age >= 5 AND age < 18""",
      "2": """age >= 18 AND age < 30""",
      "3": """age >= 30 AND age < 40""",
      "4": """age >= 40 AND age < 50""",
      "5": """age >= 50 AND age < 60""",
      "6": """age >= 60 AND age < 70""",
      "7": """age >= 70 AND age < 80""",
      "8": """age >= 80 AND age < 90""",
      "9": """age >= 90""",
    },

    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0.01,
          "1": 0.12,
          "2": 0.12,
          "3": 0.12,
          "4": 0.12,
          "5": 0.12,          
          "6": 0.11,
          "7": 0.11,
          "8": 0.11,
          "9": 0.06
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

    return_expectations = {
      "incidence": 0.05,
    },

    ### Care home from codelists
    carehome_codes = patients.with_these_clinical_events(
      carehome_primis_codes,
      on_or_before = "index_date",
      returning = "binary_flag",
      return_expectations = {
        "date": {
          "earliest": "2017-01-01", 
          "latest": "index_date",
          },
        "incidence": 0.1}
    ),

    # COPIED CODE  
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
        "1": """
          IsPotentialCareHome
          """,
        "0": "DEFAULT",
        },
      return_expectations={
        "rate": "universal",
        "category": {"ratios": {"1": .15, "0": 0.85,},},
      },
    ),
  ),

  ### Cancer in past year
  cancer = patients.with_these_clinical_events(
    cancer_codes,
    between = ["first_day_of_month(index_date) - 1 year","last_day_of_month(index_date)"],
    returning = "binary_flag",
    return_expectations = {
      "date": {
        "earliest": "first_day_of_month(index_date) - 1 year",
        "latest": "last_day_of_month(index_date)",
        },
      "incidence": 0.15}
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
  
  #  Monthly rates - whole population
  
  ## Any opioid
  Measure(
    id = "opioid_all_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["population"],
    small_number_suppression = True,
  ),

  ## High dose opioid
  Measure(
    id = "hi_opioid_all_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["population"],
    small_number_suppression = True,
  ),

  # Monthly rates - cancer
  ## Any opioid
  Measure(
    id = "opioid_ca_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - cancer
  Measure(
    id = "hi_opioid_ca_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - carehomes
  ## Any opioid
  Measure(
    id = "opioid_care_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["carehome"],
    small_number_suppression = True,
  ),

  ## High dose opioid - carehomes
  Measure(
    id = "hi_opioid_care_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["carehome"],
    small_number_suppression = True,
  ),
  
  # Monthly rates - sickle cell
  ## Any opioid
  Measure(
    id = "opioid_scd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["scd"],
    small_number_suppression = True,
  ),

  ## High dose opioid - sickle cell
  Measure(
    id = "hi_opioid_scd_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["scd"],
    small_number_suppression = True,
  ),

  # Monthly rates - age and sex
  ## Any opioid
  Measure(
    id = "opioid_age_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - age and sex
  Measure(
    id = "hi_opioid_age_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - ethnicity
  ## Any opioid
  Measure(
    id = "opioid_eth_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - ethnicity
  Measure(
    id = "hi_opioid_eth_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["ethnicity","cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - region
  ## Any opioid
  Measure(
    id = "opioid_reg_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["region","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - region
  Measure(
    id = "hi_opioid_reg_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["region","cancer"],
    small_number_suppression = True,
  ),
  
  # Monthly rates - imd
  ## Any opioid
  Measure(
    id = "opioid_imd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - imd
  Measure(
    id = "hi_opioid_imd_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer"],
    small_number_suppression = True,
  ),

  ####

  #  Monthly rates - initiation

  ## Any opioid initiation
  Measure(
    id = "opioid_all_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["population"],
    small_number_suppression = True,
  ),

  ## High dose opioid
  Measure(
    id = "hi_opioid_all_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["population"],
    small_number_suppression = True,
  ),

  # Monthly rates - cancer
  ## new opioid
  Measure(
    id = "opioid_ca_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - cancer
  Measure(
    id = "hi_opioid_ca_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - carehomes
  ## new opioid
  Measure(
    id = "opioid_care_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["carehome"],
    small_number_suppression = True,
  ),

  ## High dose opioid - carehomes
  Measure(
    id = "hi_opioid_care_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["carehome"],
    small_number_suppression = True,
  ),
  
  # Monthly rates - sickle cell
  ## new opioid
  Measure(
    id = "opioid_scd_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["scd"],
    small_number_suppression = True,
  ),

  ## High dose opioid - sickle cell
  Measure(
    id = "hi_opioid_scd_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["scd"],
    small_number_suppression = True,
  ),

  # Monthly rates - age and sex
  ## new opioid
  Measure(
    id = "opioid_age_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["age_cat","sex","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - age and sex
  Measure(
    id = "hi_opioid_age_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["age_cat","sex","cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - ethnicity
  ## new opioid
  Measure(
    id = "opioid_eth_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["ethnicity","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - ethnicity
  Measure(
    id = "hi_opioid_eth_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["ethnicity","cancer"],
    small_number_suppression = True,
  ),

  # Monthly rates - region
  ## new opioid
  Measure(
    id = "opioid_reg_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["region","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - region
  Measure(
    id = "hi_opioid_reg_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["region","cancer"],
    small_number_suppression = True,
  ),
  
  # Monthly rates - imd
  ## new opioid
  Measure(
    id = "opioid_imd_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["imdq10","cancer"],
    small_number_suppression = True,
  ),

  ## High dose opioid - imd
  Measure(
    id = "hi_opioid_imd_new",
    numerator = "hi_opioid_new",
    denominator = "hi_opioid_naive",
    group_by = ["imdq10","cancer"],
    small_number_suppression = True,
  ),

]