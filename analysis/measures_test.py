###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing by mode of administration
###################################################

from ehrql import Dataset, months, INTERVAL, Measures
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    practice_registrations)

import codelists


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

dataset = Dataset()

dataset.number_par_rx = medications.where(
        medications.dmd_code.is_in(codelists.par_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

dataset.number_trans_rx = medications.where(
        medications.dmd_code.is_in(codelists.trans_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

dataset.number_opioid_rx = medications.where(
        medications.dmd_code.is_in(codelists.opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

measures = Measures()

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
    name="any_opioid", 
    numerator=dataset.number_opioid_rx,
    denominator=denominator
    )

measures.define_measure(
    name="par_opioid", 
    numerator=dataset.number_par_rx,
    denominator=denominator
    )

measures.define_measure(
    name="trans_opioid", 
    numerator=dataset.number_trans_rx,
    denominator=denominator
    )
