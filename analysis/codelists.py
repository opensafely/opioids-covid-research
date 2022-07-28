######################################

# Some covariates used in the study are created from codelists of clinical conditions or
# numerical values available on a patient's records.
# This script fetches all of the codelists identified in codelists.txt from OpenCodelists.

######################################


# --- IMPORT STATEMENTS ---

## Import code building blocks from cohort extractor package
from cohortextractor import codelist, codelist_from_csv


# --- CODELISTS ---


## Medication DM&D

### Selective serotonin reputake inhibitors
opioid_codes = codelist_from_csv(
    "codelists/opensafely-selective-serotonin-reuptake-inhibitors-dmd.csv",
    system="snomed",
    column="dmd_id",
)
highdose_codes = codelist_from_csv(
    "codelists/opensafely-tricyclic-and-related-antidepressants-dmd.csv",
    system="snomed",
    column="dmd_id",
)


## Groups

### Care homes
carehome_codes = codelist_from_csv(
    "opensafely-nhs-england-care-homes-residential-status-3712ef13.csv",
    system="snomed",
    column="code",
)

### Cancer
cancer_codes = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-depr_cod.csv",
    system="snomed",
    column="code",
)


## Variables

### Ethnicity
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed-2e641f61.csv",
    system="ctv3",
    column="snomedcode",
    category_column="Grouping_6",
)
