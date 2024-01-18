##################################################
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


number_diamorph_rx = medications.where(
        medications.dmd_code.is_in(codelists.diamorph_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

number_par_rx = medications.where(
        medications.dmd_code.is_in(codelists.par_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

diamorph_opioid_any = medications.where(
        medications.dmd_code.is_in(codelists.diamorph_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).exists_for_patient()

par_opioid_any = medications.where(
        medications.dmd_code.is_in(codelists.par_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).exists_for_patient()





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


measures.define_measure(
    name="par_opioid", 
    numerator=number_par_rx,
    denominator=denominator
    )

measures.define_measure(
    name="diamorph_opioid",
    numerator=number_diamorph_rx,
    denominator=denominator
)
measures.define_measure(
    name="par_opioid_any",
    numerator=par_opioid_any,
    denominator=denominator
)
measures.define_measure(
    name="diamorph_opioid_any",
    numerator=diamorph_opioid_any,
    denominator=denominator
)