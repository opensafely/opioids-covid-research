#########################################################
# This script extracts relevant demographics and
#   opioid prescribing data for people from Apr-Jun 2022
#   for inclusion in Table 1
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################


from ehrql import case, when
from ehrql.tables.tpp import (
    patients, 
    addresses,
    practice_registrations,
    clinical_events)

import codelists

from dataset_definition import make_dataset_opioids

dataset = make_dataset_opioids(index_date="2022-04-01", end_date="2022-06-30")

# Define population #
dataset.define_population(
    (patients.age_on("2022-04-01") >= 18) 
    & (patients.age_on("2022-04-01") < 110)
    & ((patients.sex == "male") | (patients.sex == "female"))
    & (patients.date_of_death.is_after("2022-04-01") | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on("2022-04-01").exists_for_patient())
)

# Demographics #

# Age
age = patients.age_on("2022-04-01")
dataset.age_group = case(
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
        otherwise="missing",
)

# Sex
dataset.sex = patients.sex 

# IMD decile
imd = addresses.for_patient_on("2022-04-01").imd_rounded
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
        otherwise="unknown"
)

# Ethnicity 16 categories
ethnicity16 = clinical_events.where(clinical_events.snomedct_code.is_in(codelists.ethnicity_codes_16)
    ).where(
        clinical_events.date.is_on_or_before("2022-04-01")
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
    otherwise="Unknown"
)

# Ethnicity 6 categories
ethnicity6 = clinical_events.where(
        clinical_events.snomedct_code.is_in(codelists.ethnicity_codes_6)
    ).where(
        clinical_events.date.is_on_or_before("2022-04-01")
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
    otherwise="Unknown"
)

# Practice region
dataset.region = practice_registrations.for_patient_on("2022-04-01").practice_nuts1_region_name

# In care home based on primis codes/TPP address match
carehome_primis = clinical_events.where(
        clinical_events.snomedct_code.is_in(codelists.carehome_primis_codes)
    ).where(
        clinical_events.date.is_on_or_before("2022-04-01")
    ).exists_for_patient() 

carehome_tpp = addresses.for_patient_on("2022-04-01").care_home_is_potential_match 

dataset.carehome = case(
    when(carehome_primis).then(True),
    when(carehome_tpp).then(True),
    otherwise=False
)


##############################################
