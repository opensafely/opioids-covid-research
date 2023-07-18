###################################################
# This script creates monthly counts/rates of opioid
# prescribing, this is a sensitivity analysis
# by age, in/not in a carehome
###################################################

from ehrql import Dataset, case, when, months, days, years, INTERVAL, Measures
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

from dataset_definition import make_dataset

index_date = INTERVAL.start_date

dataset = make_dataset(index_date=index_date)

measures = Measures()

# Total denominator - restrict to >=65 years
denominator = (
        (patients.age_on("2022-03-01") >= 65) 
        & (patients.age_on("2022-03-01") < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after("2022-03-01") | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on("2022-03-01").exists_for_patient())
    )

measures.define_defaults(intervals=months(51).starting_on("2018-01-01"))


# By demographics - overall prescribing
measures.define_measure(
    name="opioid_any_carehome_age", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={
        "age_group": dataset.age_group,
        "carehome": dataset.carehome}
    )
