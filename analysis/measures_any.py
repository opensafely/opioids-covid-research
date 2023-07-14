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

# Any opioid prescribing
measures = Measures()

measures.define_defaults(
    numerator=dataset.opioid_any,
    denominator=dataset.population,
    intervals=months(51).starting_on("2018-01-01"),
)

measures.define_measure(name="opioid_any", group_by={"age_group": dataset.age_group})
measures.define_measure(name="opioid_any", group_by={"sex": dataset.sex})
measures.define_measure(name="opioid_any", group_by={"region": dataset.region})
# measures.define_measure(name="opioid_any", group_by={"imd": dataset.imd5})
measures.define_measure(name="opioid_any", group_by={"ethnicity6": dataset.ethnicity6})
measures.define_measure(name="opioid_any", group_by={"carehome": dataset.carehome})
