###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing by mode of administration
###################################################

from ehrql import Dataset, case, when, months, days, years, INTERVAL, Measures
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

from dataset_definition import make_dataset_opioids, registrations

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

dataset = make_dataset_opioids(index_date=index_date, end_date=INTERVAL.end_date)

##########

measures = Measures()

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & registrations(index_date, index_date).exists_for_patient()
    )

#########################

## Overall
measures.define_measure(
    name="oral_opioid", 
    numerator=dataset.oral_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="trans_opioid", 
    numerator=dataset.trans_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="par_opioid", 
    numerator=dataset.par_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="rec_opioid", 
    numerator=dataset.rec_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="inh_opioid", 
    numerator=dataset.inh_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="buc_opioid", 
    numerator=dataset.buc_opioid_any,
    denominator=denominator
    )

measures.define_measure(
    name="oth_opioid", 
    numerator=dataset.oth_opioid_any,
    denominator=denominator
    )
