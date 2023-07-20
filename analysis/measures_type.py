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

from dataset_definition import make_dataset

index_date = INTERVAL.start_date

dataset = make_dataset(index_date=index_date)

measures = Measures()

denominator = (
        (patients.age_on(index_date) >= 18) 
        & (patients.age_on(index_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(index_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(index_date).exists_for_patient())
    )

measures.define_defaults(
    denominator=denominator,
    intervals=months(54).starting_on("2018-01-01"),
)

# Overall
measures.define_measure(
    name="oral_opioid", 
    numerator=dataset.oral_opioid_any
    )

measures.define_measure(
    name="trans_opioid", 
    numerator=dataset.trans_opioid_any
    )

measures.define_measure(
    name="par_opioid", 
    numerator=dataset.par_opioid_any
    )

measures.define_measure(
    name="rec_opioid", 
    numerator=dataset.rec_opioid_any
    )

measures.define_measure(
    name="inh_opioid", 
    numerator=dataset.inh_opioid_any
    )

measures.define_measure(
    name="buc_opioid", 
    numerator=dataset.buc_opioid_any
    )

measures.define_measure(
    name="oth_opioid", 
    numerator=dataset.oth_opioid_any
    )

# By care home
measures.define_measure(
    name="oral_opioid_carehome", 
    numerator=dataset.oral_opioid_any,
    group_by={"carehome": dataset.carehome}
    )

measures.define_measure(
    name="trans_opioid_carehome", 
    numerator=dataset.trans_opioid_any,
    group_by={"carehome": dataset.carehome}
    )

measures.define_measure(
    name="par_opioid_carehome", 
    numerator=dataset.par_opioid_any,
    group_by={"carehome": dataset.carehome}
    )

