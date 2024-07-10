###################################################
# This script creates monthly counts/rates of opioid
# prescribing for new opioid prescribing by demographics categories
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

## Define demographic variables

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

sex = patients.sex

imd = addresses.for_patient_on(index_date).imd_rounded
imd10 = case(
        when((imd >= 0) & (imd < int(32844 * 1 / 10))).then("1 (most deprived)"),
        when(imd < int(32844 * 2 / 10)).then("2"),
        when(imd < int(32844 * 3 / 10)).then("3"),
        when(imd < int(32844 * 4 / 10)).then("4"),
        when(imd < int(32844 * 5 / 10)).then("5"),
        when(imd < int(32844 * 6 / 10)).then("6"),
        when(imd < int(32844 * 7 / 10)).then("7"),
        when(imd < int(32844 * 8 / 10)).then("8"),
        when(imd < int(32844 * 9 / 10)).then("9"),
        when(imd >= int(32844 * 9 / 10)).then("10 (least deprived)"),
        otherwise="unknown"
)

ethnicity = clinical_events.where(
        clinical_events.snomedct_code.is_in(codelists.ethnicity_codes_6)
    ).sort_by(
        clinical_events.date
    ).last_for_patient().snomedct_code.to_category(codelists.ethnicity_codes_6)

ethnicity6 = case(
    when(ethnicity == "1").then("White"),
    when(ethnicity == "2").then("Mixed"),
    when(ethnicity == "3").then("South Asian"),
    when(ethnicity == "4").then("Black"),
    when(ethnicity == "5").then("Other"),
    when(ethnicity == "6").then("Not stated"),
    otherwise="Unknown"
)

region = practice_registrations.for_patient_on(index_date).practice_nuts1_region_name


#########################

measures = Measures()
measures.configure_disclosure_control(enabled=False)

measures.define_defaults(intervals=months(intervals).starting_on(start_date))

# Total denominator
denominator_naive = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
        & dataset.opioid_naive
)

#########################

## Overall 
# By demographics - new prescribing
measures.define_measure(
    name="opioid_new_age", 
    numerator=dataset.opioid_new,
    denominator=denominator_naive,
    group_by={"age_group": age_group}
    )

measures.define_measure(
    name="opioid_new_sex", 
    numerator=dataset.opioid_new,
    denominator=denominator_naive,
    group_by={"sex": patients.sex}
    )

measures.define_measure(
    name="opioid_new_region", 
    numerator=dataset.opioid_new,
    denominator=denominator_naive,
    group_by={"region": region}
    )

measures.define_measure(
    name="opioid_new_imd", 
    numerator=dataset.opioid_new,
    denominator=denominator_naive,
    group_by={"imd": imd10}
    )

measures.define_measure(
    name="opioid_new_eth6", 
    numerator=dataset.opioid_new,
    denominator=denominator_naive,
    group_by={"ethnicity6": ethnicity6}
    )

