###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing, new opioid prescribing,
# and high dose/long-acting prescribing
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

# Total denominator
denominator = (
        (patients.age_on("2022-03-01") >= 18) 
        & (patients.age_on("2022-03-01") < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after("2022-03-01") | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on("2022-03-01").exists_for_patient())
    )

measures.define_defaults(intervals=months(51).starting_on("2018-01-01"),)

measures.define_measure(
    name="opioid_any",
    numerator=dataset.opioid_any,
    denominator=denominator,
    )

measures.define_measure(
    name="opioid_new",
    numerator=dataset.opioid_new,
    denominator=denominator & dataset.opioid_naive,
    )

measures.define_measure(
    name="hi_opioid_any",
    numerator=dataset.hi_opioid_any,
    denominator=denominator,
    )

# Without cancer
measures.define_measure(
    name="opioid_any_nocancer",
    numerator=dataset.opioid_any,
    denominator=denominator & ~dataset.cancer,
    )

measures.define_measure(
    name="opioid_new_nocancer",
    numerator=dataset.opioid_new,
    denominator=denominator & dataset.opioid_naive & ~dataset.cancer,
    )

measures.define_measure(
    name="hi_opioid_any_nocancer",
    numerator=dataset.hi_opioid_any,
    denominator=denominator & ~dataset.cancer,
    )
