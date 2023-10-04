###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing by mode of administration
###################################################

from ehrql import months, INTERVAL, Measures, case, when
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


number_morph_rx = medications.where(
        medications.dmd_code.is_in(codelists.morph_par_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

number_oxy_rx = medications.where(
        medications.dmd_code.is_in(codelists.oxy_par_codes)
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
    name="oxy_par_rx", 
    numerator=number_oxy_rx,
    denominator=denominator
    )

measures.define_measure(
    name="morph_par_rx", 
    numerator=number_morph_rx,
    denominator=denominator
    )
