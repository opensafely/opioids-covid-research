from dataset_definition import make_dataset
from ehrql import INTERVAL, Dataset, Measures, case, days, months, when, years
from ehrql.tables.beta.tpp import (addresses, clinical_events, medications,
                                   patients, practice_registrations)

import codelists

index_date = INTERVAL.start_date

dataset = make_dataset(index_date=index_date)

# Any opioid prescribing
measures = Measures()

measures.define_defaults(
    numerator=dataset.opioid_any,
    denominator=dataset.population,
    intervals=months(51).starting_on("2018-01-01"),
)

measures.define_measure(name="opioid_any_age", group_by={"age_group": dataset.age_group})
measures.define_measure(name="opioid_any_sex", group_by={"sex": dataset.sex})
measures.define_measure(name="opioid_any_region", group_by={"region": dataset.region})
#measures.define_measure(name="opioid_any", group_by={"imd": dataset.imd5})
measures.define_measure(name="opioid_any_eth6", group_by={"ethnicity6": dataset.ethnicity6})
measures.define_measure(name="opioid_any_carehome", group_by={"carehome": dataset.carehome})
