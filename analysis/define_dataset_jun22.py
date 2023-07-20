###################################################
# This script defines creates a dataset for
# everyone in the cohort on 1 Mar 2023,
# for the purposes of creating Table 1
###################################################

from ehrql import Dataset, case, when, months, days, years, weeks, Measures, INTERVAL
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

from dataset_definition import make_dataset

# Save data for Jun 2022 (for tables)
dataset = make_dataset(index_date="2022-06-01")

# Define population #
dataset.define_population(
        (patients.age_on("2022-06-01") >= 18) 
        & (patients.age_on("2022-06-01") < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after("2022-06-01") | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on("2022-06-01").exists_for_patient())
    )

