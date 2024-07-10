###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing by mode of administration
# (oral, parenteral, transdermal, other)
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################

from ehrql import  months, INTERVAL, Measures
from ehrql.tables.tpp import (
    patients, 
    practice_registrations)

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

dataset = make_dataset_opioids(index_date=index_date, end_date=INTERVAL.end_date)

##########

measures = Measures()
measures.configure_disclosure_control(enabled=False)

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
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
    name="oth_opioid", 
    numerator=dataset.oth_opioid_any,
    denominator=denominator
    )
