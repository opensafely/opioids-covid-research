###################################################
# This script defines all necessary variables
# including demographics and opioid prescribing
###################################################


from ehrql import Dataset, case, when, months, days, years, weeks, Measures, INTERVAL
from ehrql.tables.beta.tpp import (
    patients, 
    medications, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

# Function to define dataset #
def make_dataset(index_date):
    
    dataset = Dataset()

    # Demographics #

    # Age
    age = patients.age_on(index_date)
    dataset.age_group = case(
            when(age < 30).then("18-29"),
            when(age < 40).then("30-39"),
            when(age < 50).then("40-49"),
            when(age < 60).then("50-59"),
            when(age < 70).then("60-69"),
            when(age < 80).then("70-79"),
            when(age < 90).then("80-89"),
            when(age >= 90).then("90+"),
            default="missing",
    )

    # Age for standardisation
    dataset.age_stand = case(
            when(age < 25).then("18-24"),
            when(age < 30).then("25-29"),
            when(age < 35).then("30-34"),
            when(age < 40).then("35-39"),
            when(age < 45).then("40-44"),
            when(age < 50).then("45-49"),
            when(age < 55).then("50-54"),
            when(age < 60).then("55-59"),
            when(age < 65).then("60-64"),
            when(age < 70).then("65-69"),
            when(age < 75).then("70-74"),
            when(age < 80).then("75-79"),
            when(age < 85).then("80-84"),
            when(age < 90).then("85-89"),
            when(age >= 90).then("90+"),
            default="missing",
    )

    # Sex
    dataset.sex = patients.sex 

    # IMD decile
    imd = addresses.for_patient_on(index_date).imd_rounded
    dataset.imd10 = case(
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
            default="unknown"
    )

    # Ethnicity 16 categories
    ethnicity16 = clinical_events.where(clinical_events.snomedct_code.is_in(codelists.ethnicity_codes_16)
        ).sort_by(
            clinical_events.date
        ).last_for_patient().snomedct_code.to_category(codelists.ethnicity_codes_16)

    dataset.ethnicity16 = case(
        when(ethnicity16 == "1").then("White - British"),
        when(ethnicity16 == "2").then("White - Irish"),
        when(ethnicity16 == "3").then("White - Other"),
        when(ethnicity16 == "4").then("Mixed - White/Black Caribbean"),
        when(ethnicity16 == "5").then("Mixed - White/Black African"),
        when(ethnicity16 == "6").then("Mixed - White/Asian"),
        when(ethnicity16 == "7").then("Mixed - Other"),
        when(ethnicity16 == "8").then("Asian or Asian British - Indian"),
        when(ethnicity16 == "9").then("Asian or Asian British - Pakistani"),
        when(ethnicity16 == "10").then("Asian or Asian British - Bangladeshi"),
        when(ethnicity16 == "11").then("Asian or Asian British - Other"),
        when(ethnicity16 == "12").then("Black - Caribbean"),    
        when(ethnicity16 == "13").then("Black - African"),
        when(ethnicity16 == "14").then("Black - Other"),
        when(ethnicity16 == "15").then("Other - Chinese"),
        when(ethnicity16 == "16").then("Other - Other"),
        default="Unknown"
    )

    # Ethnicity 6 categories
    ethnicity6 = clinical_events.where(
            clinical_events.snomedct_code.is_in(codelists.ethnicity_codes_6)
        ).sort_by(
            clinical_events.date
        ).last_for_patient().snomedct_code.to_category(codelists.ethnicity_codes_6)

    dataset.ethnicity6 = case(
        when(ethnicity6 == "1").then("White"),
        when(ethnicity6 == "2").then("Mixed"),
        when(ethnicity6 == "3").then("South Asian"),
        when(ethnicity6 == "4").then("Black"),
        when(ethnicity6 == "5").then("Other"),
        when(ethnicity6 == "6").then("Not stated"),
        default="Unknown"
    )

    # Practice region
    dataset.region = practice_registrations.for_patient_on(index_date).practice_nuts1_region_name

    # In care home based on primis codes/TPP address match
    carehome_primis = clinical_events.where(
            clinical_events.snomedct_code.is_in(codelists.carehome_primis_codes)
        ).exists_for_patient() 

    carehome_tpp = addresses.for_patient_on(index_date).care_home_is_potential_match

    dataset.carehome = case(
        when(carehome_primis).then(True),
        when(carehome_tpp).then(True),
        default=False
    )

    # Cancer diagnosis in past 5 years
    dataset.cancer = case(
        when(clinical_events.where(clinical_events.snomedct_code.is_in(codelists.cancer_codes)
            ).where(
                clinical_events.date.is_on_or_between(index_date - years(5), index_date)
            ).exists_for_patient()
        ).then(True),
        default=False
    )

    # No. people with opioid prescription #

    def has_med_event(codelist, where=True):
        med_event_exists = medications.where(medications.dmd_code.is_in(codelist)
            ).where(
                medications.date.is_on_or_between(index_date, index_date + months(1) - days(1))
            ).exists_for_patient()
        return (
            case(
                when(med_event_exists).then(True),
                when(~med_event_exists).then(False)
                )
        )

    dataset.opioid_any = has_med_event(codelists.opioid_codes) # Any opioid

    # By admin route
    dataset.oral_opioid_any = has_med_event(codelists.opioid_codes)  # Oral opioid
    dataset.buc_opioid_any = has_med_event(codelists.opioid_codes)  # Buccal opioid
    dataset.inh_opioid_any = has_med_event(codelists.opioid_codes)  # Inhaled opioid
    dataset.rec_opioid_any = has_med_event(codelists.opioid_codes)  # Rectal opioid
    dataset.par_opioid_any = has_med_event(codelists.opioid_codes)  # Parenteral opioid
    dataset.trans_opioid_any = has_med_event(codelists.opioid_codes)  # Transdermal opioid
    dataset.oth_opioid_any = has_med_event(codelists.opioid_codes)  # Other admin route opioid

    # By strength/type
    dataset.hi_opioid_any = has_med_event(codelists.hi_opioid_codes)  # High dose opioid
    dataset.long_opioid_any = has_med_event(codelists.long_opioid_codes)  # Long-acting opioid


    # No. people with a new opioid prescription (2 year lookback) #
    # Note: for all opioids only 

    # Date of last prescription before index date
    last_rx = medications.where(
        medications.dmd_code.is_in(codelists.opioid_codes)
        ).where(
            medications.date.is_before(index_date)
        ).sort_by(
            medications.date).last_for_patient().date

    # Is opioid naive (using two year lookback) (for denominator)
    dataset.opioid_naive = case(
        when(last_rx.is_before(index_date - years(2))).then(True),
        when(last_rx.is_null()).then(True),
        default=False
    )

    # Number of people with new prescriptions (among naive only)
    dataset.opioid_new = case(
        when(medications.where(medications.dmd_code.is_in(codelists.opioid_codes)
            ).where(
                medications.date.is_on_or_between(index_date, index_date + months(1) - days(1))
            ).where(dataset.opioid_naive).exists_for_patient()
        ).then(True),
        default=False
    )

    return dataset


##############################################
