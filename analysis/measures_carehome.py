###################################################
# This script creates monthly counts/rates of opioid
# prescribing for opioid prescribing to people in care homes 
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################

from ehrql import case, when, months, INTERVAL, Measures
from ehrql.tables.tpp import (
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

dataset = make_dataset_opioids(index_date=index_date, end_date=INTERVAL.end_date)

##########

## Define relevant variables 

# In care home based on primis codes/TPP address match
carehome_primis = clinical_events.where(
        clinical_events.snomedct_code.is_in(codelists.carehome_primis_codes)
    ).where(
        clinical_events.date.is_on_or_before(index_date)
    ).exists_for_patient() 

carehome_tpp = addresses.for_patient_on(index_date).care_home_is_potential_match 

carehome = case(
    when(carehome_primis).then(True),
    when(carehome_tpp).then(True),
    otherwise=False
)

age = patients.age_on(index_date)
age_group = case(
        when(age < 30).then("18-29"),
        when(age < 40).then("30-39"),
        when(age < 50).then("40-49"),
        when(age < 60).then("50-59"),
        when(age < 70).then("60-69"),
        when(age < 80).then("70-79"),
        when(age < 90).then("80-89"),
        when(age >= 90).then("90+"),
        otherwise="missing",
)

######

measures = Measures()
measures.configure_disclosure_control(enabled=False)

## Opioid prescribing to people in care homes
# Total denominator - people in care home
denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
        & carehome
    )

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

# By care home status
measures.define_measure(
    name="opioid_any",
    numerator=dataset.opioid_any,
    denominator=denominator,
    )

measures.define_measure(
    name="hi_opioid_any",
    numerator=dataset.hi_opioid_any,
    denominator=denominator,
    )

measures.define_measure(
    name="opioid_new",
    numerator=dataset.opioid_new,
    denominator=denominator & dataset.opioid_naive,
    )

# By admin route
measures.define_measure(
    name="oral_opioid", 
    numerator=dataset.oral_opioid_any,
    denominator=denominator,
    )

measures.define_measure(
    name="trans_opioid", 
    numerator=dataset.trans_opioid_any,
    denominator=denominator,
    )

measures.define_measure(
    name="par_opioid", 
    numerator=dataset.par_opioid_any,
    denominator=denominator,
    )

## Sensitivity analysis by care home residence
# Total denominator - restrict to >=65 years
denominator_sens = (
        (patients.age_on(index_date) >= 60) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
    )

measures.define_measure(
    name="opioid_any_carehome_age", 
    numerator=dataset.opioid_any,
    denominator=denominator_sens,
    group_by={
        "age_group": age_group,
        "carehome": carehome}
    )
