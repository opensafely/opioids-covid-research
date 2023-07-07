from ehrql import Dataset, case, when, months, days, years, weeks
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

dataset = Dataset()

index_date = "2020-03-01"

### Define population ##########################
dataset.define_population(
    (patients.age_on(index_date) >= 18) & (patients.age_on(index_date) < 110) \
    & (patients.sex.contains("male") | patients.sex.contains("female")) \
    & (patients.date_of_death >= index_date) 
    & (practice_registrations.for_patient_on(index_date).practice_pseudo_id.is_not_null())
)

### Demographics ###############################

# Age
dataset.age = patients.age_on(index_date)
dataset.age_band = case(
        when(dataset.age < 30).then("18-29"),
        when(dataset.age < 40).then("20-39"),
        when(dataset.age < 50).then("40-49"),
        when(dataset.age < 60).then("50-59"),
        when(dataset.age < 70).then("60-69"),
        when(dataset.age < 80).then("70-79"),
        when(dataset.age < 90).then("80-89"),
        when(dataset.age >= 90).then("90+"),
        default="missing",
)

# Sex
dataset.sex = patients.sex 

# IMD decile
# imd = addresses.for_patient_on(index_date).imd_rounded
# dataset.imd_band = case(
#         when(imd < 32844 * 1 / 10).then("1 (most deprived)"),
#         when(imd < 32844 * 2 / 10).then("2"),
#         when(imd < 32844 * 3 / 10).then("3"),
#         when(imd < 32844 * 4 / 10).then("4"),        
#         when(imd < 32844 * 5 / 10).then("5"),
#         when(imd < 32844 * 6 / 10).then("6"),
#         when(imd < 32844 * 7 / 10).then("7"),
#         when(imd < 32844 * 8 / 10).then("8"),
#         when(imd < 32844 * 9 / 10).then("9"),
#         when(imd >= 32844 * 9 / 10).then("10 (least deprived)"),
#         default="unknown"
# )

# Practice region
dataset.region = practice_registrations.for_patient_on(index_date).practice_nuts1_region_name

# In care home based on primis codes/TPP address match
dataset.carehome_primis = clinical_events.where(
        clinical_events.snomedct_code.is_in(codelists.carehome_primis_codes)) \
            .where(clinical_events.date.is_on_or_before(index_date)) \
            .exists_for_patient() 
dataset.carehome_tpp = addresses.for_patient_on(index_date).care_home_is_potential_match 

dataset.carehome = case(
    when(dataset.carehome_primis).then(1),
    when(dataset.carehome_tpp).then(1),
    default=0
)

# Cancer diagnosis in past 5 years
dataset.cancer = case(
    when(clinical_events.where(clinical_events.snomedct_code.is_in(codelists.cancer_codes)) \
        .where(clinical_events.date.is_between(index_date, index_date - years(5))) \
        .exists_for_patient()) \
        .then(1),
        default=0
)

### No. people with opioid prescription ##########################################
def has_med_event(codelist, where=True):
    med_event_exists = medications.where(medications.dmd_code.is_in(codelist))\
        .where(medications.date.is_on_or_between(index_date, index_date + months(1) - days(1))) \
        .exists_for_patient()
    return (
        case(
            when(med_event_exists).then(1),
            when(~med_event_exists).then(0)
            )
    )

dataset.opioid_any = has_med_event(codelists.opioid_codes) # Any opioid

# By admin route
dataset.oral_opioid_any = has_med_event(codelists.opioid_codes) # Oral opioid
dataset.buc_opioid_any = has_med_event(codelists.opioid_codes) # Buccal opioid
dataset.inh_opioid_any = has_med_event(codelists.opioid_codes) # Inhaled opioid
dataset.rec_opioid_any = has_med_event(codelists.opioid_codes) # Rectal opioid
dataset.par_opioid_any = has_med_event(codelists.opioid_codes) # Parenteral opioid
dataset.trans_opioid_any = has_med_event(codelists.opioid_codes) # Transdermal opioid
dataset.oth_opioid_any = has_med_event(codelists.opioid_codes) # Other admin route opioid

# By strength/type
dataset.hi_opioid_any = has_med_event(codelists.hi_opioid_codes) # High dose opioid
dataset.long_opioid_any = has_med_event(codelists.long_opioid_codes) # Long-acting opioid


### No. people with a new opioid prescription (2 year lookback) ######################

# Date of last prescription
last_rx = medications.where(
    medications.dmd_code.is_in(codelists.opioid_codes)) \
        .where(medications.date.is_before(index_date)) \
        .sort_by(medications.date) \
        .last_for_patient().date

# Is opioid naive (two year lookback) (for denominator)
dataset.opioid_naive = case(
    when(last_rx.is_before(index_date - years(2))).then(1),
    when(last_rx.is_null()).then(1),
    default=0
)

# Number of people with new prescriptions
dataset.opioid_new = case(
    when(medications.where(medications.dmd_code.is_in(codelists.opioid_codes)) \
        .where(medications.date.is_on_or_between(index_date, index_date + months(1) - days(1))) \
        .where(dataset.opioid_naive == 1) \
        .exists_for_patient()) \
        .then(1),
        default=0
)
