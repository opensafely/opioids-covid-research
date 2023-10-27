###################################################
# This script creates monthly counts/rates of opioid
# prescribing for any opioid prescribing, new opioid prescribing,
# and high dose/long-acting prescribing by demographics categories
###################################################

from ehrql import case, when, months, INTERVAL, Measures
from ehrql.tables.beta.tpp import (
    patients, 
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

# number_morph_rx = medications.where(
#         medications.dmd_code.is_in(codelists.morph_par_codes)
#     ).where(
#         medications.date.is_on_or_between(index_date, INTERVAL.end_date)
#     ).count_for_patient()

# number_oxy_rx = medications.where(
#         medications.dmd_code.is_in(codelists.oxy_par_codes)
#     ).where(
#         medications.date.is_on_or_between(index_date, INTERVAL.end_date)
#     ).count_for_patient()

number_dia_rx = medications.where(
        medications.dmd_code.is_in(codelists.diamorph_opioid_codes)
    ).where(
        medications.date.is_on_or_between(index_date, INTERVAL.end_date)
    ).count_for_patient()

##########

region = practice_registrations.for_patient_on(index_date).practice_nuts1_region_name

#########################

measures = Measures()

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

# Total denominator
denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
    )

#########################

# measures.define_measure(
#     name="morph_opioid_region", 
#     numerator=number_morph_rx,
#     denominator=denominator,
#     group_by={"region": region}
#     )

# measures.define_measure(
#     name="oxy_opioid_region", 
#     numerator=number_oxy_rx,
#     denominator=denominator,
#     group_by={"region": region}
#     )

measures.define_measure(
    name="diamorph_opioid_region", 
    numerator=number_dia_rx
    denominator=denominator,
    group_by={"region": region}
    )

