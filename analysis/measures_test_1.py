###################################################
# This script is testing the most efficient way 
# to run measures
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

dataset = make_dataset_opioids(index_date=index_date, end_date=index_date + months(1) - days(1))

##########

## Define demographic variables

age = patients.age_on(index_date)
dataset.age_group = case(
        when(age < 30).then("18-29"),
        when(age < 40).then("30-39"),
        when(age < 50).then("40-49"),
        when(age < 60).then("50-59"),
        when(age < 70).then("60-69"),
        when(age < 80).then("70-79"),
        when(age < 90).then("80-89"),
        when(age >= 90).then("90+"),
        default="missing",
)

dataset.sex = patients.sex 



#########################

measures = Measures()

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

# Total denominator
denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & registrations(index_date, index_date).exists_for_patient()
    )


#########################

## Overall 
# By demographics - any prescribing
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

