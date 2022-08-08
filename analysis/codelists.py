######################################

# Some covariates used in the study are created from codelists of clinical conditions or 
# numerical values available on a patient's records.
# This script fetches all of the codelists identified in codelists.txt from OpenCodelists.

######################################


# --- IMPORT STATEMENTS ---

## Import code building blocks from cohort extractor package
from cohortextractor import (codelist, codelist_from_csv, combine_codelists)

 
# --- CODELISTS ---

## Care home - use primis based on Schultze et al report (10.12688/wellcomeopenres.16737.1)
carehome_primis_codes = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-longres.csv", 
  system = "snomed", 
  column = "code",
)

## Cancer 

###  Cancer - excluding lung/haem
oth_ca_codes = codelist_from_csv(
  "codelists/opensafely-cancer-excluding-lung-and-haematological-snomed.csv",
  system = "snomed",
  column = "id"
)

### Cancer - lung
lung_ca_codes = codelist_from_csv(
  "codelists/opensafely-lung-cancer-snomed.csv",
  system = "snomed",
  column = "id"
)

### Cancer - haematological
haem_ca_codes = codelist_from_csv(
  "codelists/opensafely-haematological-cancer-snomed.csv",
  system = "snomed",
  column = "id"
)

### All cancer combined
cancer_codes = combine_codelists(
  oth_ca_codes,
  lung_ca_codes,
  haem_ca_codes
)

## Medication DM&D

### Any opioid (note - using SSRIs as a stand in until opioid codelist is finalised)
opioid_codes = codelist_from_csv(
  "codelists/opensafely-selective-serotonin-reuptake-inhibitors-dmd.csv",
  system = "snomed",
  column = "dmd_id",
)

### High dose opioids (note - using antipsychotics as a stand in until opioid codelist is finalised)
hi_opioid_codes = codelist_from_csv(
  "codelists/opensafely-first-generation-antipsychotics-excluding-long-acting-depots-dmd.csv",
  system = "snomed",
  column = "dmd_id",
)


## Ethnicity
ethnicity_codes_6 = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    system="snomed",
    column="snomedcode",
    category_column="Grouping_6",
)
