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

# New opioid prescribing
measures = Measures()

denominator = (
        (patients.age_on("2022-03-01") >= 18) 
        & (patients.age_on("2022-03-01") < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after("2022-03-01") | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on("2022-03-01").exists_for_patient())
        & dataset.opioid_naive
    )

measures.define_defaults(
    numerator=dataset.opioid_new,
    denominator=denominator,
    intervals=months(51).starting_on("2018-01-01"),
)

measures.define_measure(name="opioid_new_age", group_by={"age_group": dataset.age_group})
measures.define_measure(name="opioid_new_sex", group_by={"sex": dataset.sex})
measures.define_measure(name="opioid_new_region", group_by={"region": dataset.region})
# measures.define_measure(name="opioid_new_imd", group_by={"imd": dataset.imd5})
measures.define_measure(name="opioid_new_eth6", group_by={"ethnicity6": dataset.ethnicity6})
measures.define_measure(name="opioid_new_carehome", group_by={"carehome": dataset.carehome})