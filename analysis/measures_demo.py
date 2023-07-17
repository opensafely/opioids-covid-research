###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing, new opioid prescribing,
# and high dose/long-acting prescribing by demographics categories
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

# Opioid naive denominator
denominator_naive = (
       denominator 
       & dataset.opioid_naive
    )

measures.define_defaults(intervals=months(51).starting_on("2018-01-01"))


# By demographics - overall prescribing
measures.define_measure(
    name="opioid_any_age", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={"age_group": dataset.age_group}
    )

measures.define_measure(
    name="opioid_any_sex", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={"sex": dataset.sex}
    )

measures.define_measure(
    name="opioid_any_region", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={"region": dataset.region}
    )

measures.define_measure(
    name="opioid_any_imd", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={"imd": dataset.imd10}
    )

measures.define_measure(
    name="opioid_any_eth6",
    numerator=dataset.opioid_any,
    denominator=denominator, 
    group_by={"ethnicity6": dataset.ethnicity6}
    )

measures.define_measure(
    name="opioid_any_carehome", 
    numerator=dataset.opioid_any,
    denominator=denominator,
    group_by={"carehome": dataset.carehome}
    )

# By demograhpics - new prescribing
measures.define_measure(
    name="opioid_new_age", 
    numerator=dataset.opioid_any,
    denominator=denominator_naive,
    group_by={"age_group": dataset.age_group}
    )

measures.define_measure(
    name="opioid_new_sex", 
    numerator=dataset.opioid_any,
    denominator=denominator_naive,
    group_by={"sex": dataset.sex}
    )

measures.define_measure(
    name="opioid_new_region", 
    numerator=dataset.opioid_any,
    denominator=denominator_naive,
    group_by={"region": dataset.region}
    )

measures.define_measure(
    name="opioid_new_imd", 
    numerator=dataset.opioid_any,
    denominator=denominator_naive,
    group_by={"imd": dataset.imd10}
    )

measures.define_measure(
    name="opioid_new_eth6", 
    numerator=dataset.opioid_any,
    denominator=denominator_naive,
    group_by={"ethnicity6": dataset.ethnicity6}
    )

measures.define_measure(
    name="opioid_new_carehome",
    numerator=dataset.opioid_any,
    denominator=denominator_naive, 
    group_by={"carehome": dataset.carehome}
    )

# By demograhpics - high dose/long acting
measures.define_measure(
    name="hi_opioid_new_age", 
    numerator=opioid.hi_opioid_any,
    denominator=denominator,
    group_by={"age_group": dataset.age_group}
    )

measures.define_measure(
    name="hopioid_new_sex", 
    numerator=opioid.hi_opioid_any,
    denominator=denominator,
    group_by={"sex": dataset.sex}
    )

measures.define_measure(
    name="opioid_new_region", 
    numerator=opioid.hi_opioid_any,
    denominator=denominator,
    group_by={"region": dataset.region}
    )

measures.define_measure(
    name="opioid_new_imd", 
    numerator=opioid.hi_opioid_any,
    denominator=denominator,
    group_by={"imd": dataset.imd10}
    )

measures.define_measure(
    name="opioid_new_eth6", 
    numerator=opioid.hi_opioid_any,
    denominator=denominator,
    group_by={"ethnicity6": dataset.ethnicity6}
    )

measures.define_measure(
    name="opioid_new_carehome",
    numerator=opioid.hi_opioid_any,
    denominator=denominator, 
    group_by={"carehome": dataset.carehome}
    )