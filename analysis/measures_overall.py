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

from dataset_definition import make_dataset_opioids


##########

from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--start-date", type=str)
parser.add_argument("--intervals", type=int)

args = parser.parse_args()

start_date = args.start_date
intervals = args.intervals

##########

index_date = INTERVAL.start_date

dataset = make_dataset_opioids(index_date=index_date, end_date=index_date + months(1) - days(1))

##########

measures = Measures()

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

## In full population
denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
    )

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

## People without cancer
measures.define_measure(
    name="opioid_any_nocancer",
    numerator=dataset.opioid_any,
    denominator=denominator & ~dataset.cancer,
    )

measures.define_measure(
    name="opioid_new_nocancer",
    numerator=dataset.opioid_new,
    denominator=denominator & ~dataset.cancer & dataset.opioid_naive,
    )

measures.define_measure(
    name="hi_opioid_any_nocancer",
    numerator=dataset.hi_opioid_any,
    denominator=denominator & ~dataset.cancer,
    )
