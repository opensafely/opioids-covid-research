#########################################################
# This script extracts relevant demographics and
#   opioid prescribing data for people from Apr-Jun 2022
#   for inclusion in Table 1
#########################################################


from ehrql import Dataset

from ehrql.tables.tpp import (
    patients, 
    practice_registrations)

dataset = Dataset()

dataset.sex = patients.sex

# Define population #
dataset.define_population(
    (patients.age_on("2022-04-01") >= 18) 
    & (patients.age_on("2022-04-01") < 110)
    & (patients.date_of_death.is_after("2022-04-01") | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on("2022-04-01").exists_for_patient())
)


##############################################
