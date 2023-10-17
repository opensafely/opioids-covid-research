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

par_rx_in_interval = (
    medications.where(medications.dmd_code.is_in(codelists.par_opioid_codes))
    .where(medications.date.is_on_or_between(index_date, INTERVAL.end_date))
)

any_par_rx = par_rx_in_interval.exists_for_patient()
first_par_rx = par_rx_in_interval.sort_by(medications.date).last_for_patient().dmd_code
    


##########

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
    name="count", 
    numerator=any_par_rx,
    denominator=denominator,
    group_by={"dmd_code": first_par_rx}
    )
