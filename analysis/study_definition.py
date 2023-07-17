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

  ### Age categories for standardisation
  age_stand = patients.categorised_as(
    {"0": "DEFAULT",
      "1": """age >= 18 AND age < 25""",
      "2": """age >= 25 AND age < 30""",
      "3": """age >= 30 AND age < 35""",
      "4": """age >= 35 AND age < 40""",
      "5": """age >= 40 AND age < 45""",
      "6": """age >= 45 AND age < 50""",
      "7": """age >= 50 AND age < 55""",
      "8": """age >= 55 AND age < 60""",      
      "9": """age >= 60 AND age < 65""",
      "10": """age >= 65 AND age < 70""",
      "11": """age >= 70 AND age < 75""",
      "12": """age >= 75 AND age < 80""",
      "13": """age >= 80 AND age < 85""",
      "14": """age >= 85 AND age < 90""",
      "15": """age >= 90""",
    },

    return_expectations = {
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0.01,
          "1": 0.06,
          "2": 0.06,
          "3": 0.06,
          "4": 0.06,
          "5": 0.06,          
          "6": 0.07,
          "7": 0.07,
          "8": 0.07,
          "9": 0.07,
          "10": 0.07,
          "11": 0.07,
          "12": 0.07,
          "13": 0.07,          
          "14": 0.07,
          "15": 0.06,
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
     return_expectations = {
      "incidence": 0.05,
    },
  ),
  ),

  ### Cancer in past 5 year
  cancer = patients.with_these_clinical_events(
    cancer_codes,
    between = ["first_day_of_month(index_date) - 5 year", "last_day_of_month(index_date)"],
    returning = "binary_flag",
    return_expectations = {"incidence": 0.15}
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

  ## Oral opioid
  oral_opioid_any = patients.with_these_medications(
    oral_opioid_codes,
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

  ## Buccal opioid
  buc_opioid_any = patients.with_these_medications(
    buc_opioid_codes,
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
  
  ## inhaled opioid
  inh_opioid_any = patients.with_these_medications(
    inh_opioid_codes,
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

  ## Parenteral opioid
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

  ## rectal opioid
  rec_opioid_any = patients.with_these_medications(
    rec_opioid_codes,
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

  ## transdermal opioid
  trans_opioid_any = patients.with_these_medications(
    trans_opioid_codes,
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

  ## Other opioid
  oth_opioid_any = patients.with_these_medications(
    oth_opioid_codes,
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

  
  ### Long acting prescribing
  long_opioid_any = patients.with_these_medications(
    long_opioid_codes,
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
      between = ["first_day_of_month(index_date) - 2 years", "first_day_of_month(index_date) - 1 day"],
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

  # Opioid naive in past 2 years (for denominator for new use)
  opioid_naive = patients.satisfying(
    """
    NOT opioid_last
    """, 
    return_expectations = {
      "incidence": 0.2,
    },
    ),
)


# --- DEFINE MEASURES ---

measures = [

  ####  Monthly rates #####

  ### Full population ###

  ## Any opioid 
  Measure(
    id = "opioid_all_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

  ## Oral opioid 
  Measure(
    id = "oral_opioid_all_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

  ## Transdermal opioid 
  Measure(
    id = "trans_opioid_all_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

  ## Parenteral opioid 
  Measure(
    id = "par_opioid_all_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

  ## Inhaled opioid 
  Measure(
    id = "inh_opioid_all_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

    ## Buccal opioid 
  Measure(
    id = "buc_opioid_all_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

    ## Rectal opioid 
  Measure(
    id = "rec_opioid_all_any",
    numerator = "rec_opioid_any",
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
  
  ## Long-acting opioid 
  Measure(
    id = "long_opioid_all_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["cancer"],
  ),

  ### Age ### 
  ## Any opioid - age 
  Measure(
    id = "opioid_age_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
  ),

  ## High dose opioid - age 
  Measure(
    id = "hi_opioid_age_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
  ),  
  
  ## Long acting opioid - age 
  Measure(
    id = "long_opioid_age_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
  ),

  ## Oral opioid - age 
  Measure(
    id = "oral_opioid_age_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["age_cat",  "sex","cancer"],
  ),

  ## Buccal opioid - age 
  Measure(
    id = "buc_opioid_age_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["age_cat", "sex", "cancer"],
  ),

  ## Rectal opioid  - age 
  Measure(
    id = "rec_opioid_age_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["age_cat", "sex","cancer"],
  ),

  ## Transdermal opioid  - age 
  Measure(
    id = "trans_opioid_age_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["age_cat",  "sex","cancer"],
  ),

  ## Parenteral opioid  - age 
  Measure(
    id = "par_opioid_age_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["age_cat", "sex", "cancer"],
  ),

  ## Inhaled opioid  - age 
  Measure(
    id = "inh_opioid_age_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["age_cat","sex","cancer"],
  ),

  ### Sex ###

  ## Any opioid -  sex 
  Measure(
    id = "opioid_sex_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["sex","age_stand","cancer"],
  ),

  ## High dose opioid - sex
  Measure(
    id = "hi_opioid_sex_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),  
  
  ## Long acting opioid - sex 
  Measure(
    id = "long_opioid_sex_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

## Oral opioid -  sex 
  Measure(
    id = "oral_opioid_sex_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ## Buccal opioid -  sex 
  Measure(
    id = "buc_opioid_sex_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ## Rectal opioid -  sex 
  Measure(
    id = "rec_opioid_sex_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ## Transdermal opioid -  sex 
  Measure(
    id = "trans_opioid_sex_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ## Parenteral opioid -  sex 
  Measure(
    id = "par_opioid_sex_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ## Inhaled opioid -  sex 
  Measure(
    id = "inh_opioid_sex_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["sex","cancer", "age_stand"],
  ),

  ### Carehomes ###
  ## ANy opioid - carehomes 
  Measure(
    id = "opioid_care_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["carehome","cancer", "age_stand", "sex"],
    
  ),

  ## High dose opioid - carehomes 
  Measure(
    id = "hi_opioid_care_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["carehome","cancer", "age_stand", "sex"],
  ),  
  
  ## Long acting  opioid - carehomes 
  Measure(
    id = "long_opioid_care_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["carehome","cancer", "age_stand", "sex"],
  ),

    ## Oral opioid - carehomes 
  Measure(
    id = "oral_opioid_care_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["cancer", "carehome", "age_stand", "sex"],
  ),

  ## Buccal opioid - carehomes 
  Measure(
    id = "buc_opioid_care_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["cancer", "carehome", "age_stand", "sex"],
  ),

  ## Rectal opioid - carehomes 
  Measure(
    id = "rec_opioid_care_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["cancer", "carehome", "age_stand", "sex"],
  ),

  ## Transdermal opioid - carehomes 
  Measure(
    id = "trans_opioid_care_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["cancer", "carehome", "age_stand", "sex"],
  ),

  ## Parenteral opioid - carehomes 
  Measure(
    id = "par_opioid_care_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["cancer" , "carehome", "age_stand", "sex"],
  ),

  ## Inhaled opioid - carehomes 
  Measure(
    id = "inh_opioid_care_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["cancer", "carehome", "age_stand", "sex"],
  ),

  ### Ethnicity ####
  ## Any opioid - ethnicity16 
  Measure(
    id = "opioid_eth16_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity16","cancer", "age_stand", "sex"],
  ),

  ## Any opioid - ethnicity6
  Measure(
    id = "opioid_eth6_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## High dose opioid - ethnicity6 
  Measure(
    id = "hi_opioid_eth6_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Long acting opioid - ethnicity6 
  Measure(
    id = "long_opioid_eth6_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Oral opioid -  eth6 
  Measure(
    id = "oral_opioid_eth6_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Buccal opioid -  eth6 
  Measure(
    id = "buc_opioid_eth6_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Rectal opioid -  eth6 
  Measure(
    id = "rec_opioid_eth6_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Transdermal opioid -  eth6 
  Measure(
    id = "trans_opioid_eth6_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Parenteral opioid -  eth6 
  Measure(
    id = "par_opioid_eth6_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ## Inhaled opioid -  eth6 
  Measure(
    id = "inh_opioid_eth6_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["ethnicity6","cancer", "age_stand", "sex"],
  ),

  ### Region ####
  ## Any opioid - region
  Measure(
    id = "opioid_reg_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## High dose opioid - region 
  Measure(
    id = "hi_opioid_reg_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),
  
  ## Long acting opioid - region 
  Measure(
    id = "long_opioid_reg_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),
  
  ## Oral opioid -  region 
  Measure(
    id = "oral_opioid_reg_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## Buccal opioid -  region 
  Measure(
    id = "buc_opioid_reg_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## Rectal opioid -  region 
  Measure(
    id = "rec_opioid_reg_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## Transdermal opioid -  region 
  Measure(
    id = "trans_opioid_reg_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## Parenteral opioid -  region 
  Measure(
    id = "par_opioid_reg_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ## Inhaled opioid -  region 
  Measure(
    id = "inh_opioid_reg_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),

  ### IMD deciles ###
  ## Any opioid - imd
  Measure(
    id = "opioid_imd_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## High dose opioid - imd
  Measure(
    id = "hi_opioid_imd_any",
    numerator = "hi_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),
  
  ## High dose opioid - imd
  Measure(
    id = "long_opioid_imd_any",
    numerator = "long_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],

  ), 
  
  ## Oral opioid -  imd 
  Measure(
    id = "oral_opioid_imd_any",
    numerator = "oral_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## Buccal opioid -  imd 
  Measure(
    id = "buc_opioid_imd_any",
    numerator = "buc_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## Rectal opioid -  imd 
  Measure(
    id = "rec_opioid_imd_any",
    numerator = "rec_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## Transdermal opioid -  imd 
  Measure(
    id = "trans_opioid_imd_any",
    numerator = "trans_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## Parenteral opioid -  imd 
  Measure(
    id = "par_opioid_imd_any",
    numerator = "par_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ## Inhaled opioid -  imd 
  Measure(
    id = "inh_opioid_imd_any",
    numerator = "inh_opioid_any",
    denominator = "population",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ###  NEW PRESCRIBING ###
  ## Any new opioid
  Measure(
    id = "opioid_all_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["cancer"],
  ),
  
  ### Age ###
  Measure(
    id = "opioid_age_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["age_cat", "cancer", "sex"],
  ),

  ### Sex ###
  Measure(
    id = "opioid_sex_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["sex", "cancer", "age_stand"],
  ),
  
  ### Carehomes ###
  Measure(
    id = "opioid_care_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["carehome","cancer", "age_stand", "sex"],
  ),
  
  ### Ethnicity ###
  Measure(
    id = "opioid_eth6_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["ethnicity6", "cancer", "age_stand", "sex"],
  ),

  ### Region ###
  Measure(
    id = "opioid_reg_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["region","cancer", "age_stand", "sex"],
  ),
  
  ### IMD decile ###
  Measure(
    id = "opioid_imd_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["imdq10","cancer", "age_stand", "sex"],
  ),

  ### Sensitivity - by age, not in care home
  # Any opioid prescribing
    Measure(
    id = "opioid_age_care_any",
    numerator = "opioid_any",
    denominator = "population",
    group_by = ["age_cat","carehome", "sex"],
  ),
  
  # New opioid prescribing
    Measure(
    id = "opioid_age_care_new",
    numerator = "opioid_new",
    denominator = "opioid_naive",
    group_by = ["age_cat","carehome", "sex"],
  ),
]