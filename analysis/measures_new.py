from ehrql import Dataset, case, when, months, days, years, INTERVAL, Measures
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

index_date = "2018-01-01"

from dataset_definition import make_dataset

import codelists

dataset = make_dataset(index_date=index_date)


# New opioid prescribing
measures = Measures()

measures.define_defaults(
    numerator=dataset.opioid_new,
    denominator=dataset.population & dataset.opioid_naive,
    intervals=months(51).starting_on("2018-01-01"),
)

measures.define_measure(name="opioid_new_age", group_by={"age_group": dataset.age_group})
measures.define_measure(name="opioid_new_sex", group_by={"sex": dataset.sex})
measures.define_measure(name="opioid_new_region", group_by={"region": dataset.region})
#measures.define_measure(name="opioid_new_imd", group_by={"imd": dataset.imd5})
measures.define_measure(name="opioid_new_eth6", group_by={"ethnicity6": dataset.ethnicity6})
measures.define_measure(name="opioid_new_carehome", group_by={"carehome": dataset.carehome})