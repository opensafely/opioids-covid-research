###################################################################
# This script extracts age and sex for FULL cohort (no exclusions)
#   for quantification of number of people with missing age/sex 
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################

from ehrql import Dataset

from ehrql.tables.tpp import (
    patients, 
    practice_registrations)

dataset = Dataset()

dataset.sex = patients.sex

dataset.age = patients.age_on("2022-04-01")

# Define population #
dataset.define_population(
    (patients.date_of_death.is_after("2022-04-01") | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on("2022-04-01").exists_for_patient())
)


##############################################
