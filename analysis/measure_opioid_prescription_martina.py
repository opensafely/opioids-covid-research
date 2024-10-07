# This script will
# To determine the rate of opioid prescribing in England, January 2019 to December 2022 by age group
# How many PEOPLE per 100,000 population are prescribed an opioid per month?
# How many OPIOIDS are prescribed per 100,000 population per month?
# How many PEOPLE per 100,000 population initiate a NEW OPIOID treatment episode per month?
# How do the above measures vary by AGE group (10-year intervals) and sex?

from ehrql import (
    case,
    INTERVAL,
    create_measures,
    months,
    when,
    codelist_from_csv,)


from ehrql.tables.tpp import (
    medications,
    patients,
    practice_registrations,
    )


# Every measure definitions file must include this line
measures = create_measures()

#index date
index_date = INTERVAL.start_date


# Disable disclosure control for demonstration purposes.
# Values will neither be suppressed nor rounded.
measures.configure_disclosure_control(enabled=False)


#Import codelist
opioid_analgesia_codelist = codelist_from_csv(
    "codelists/user-anschaf-opioids-for-analgesia-dmd.csv",
    column="code",
)


# Variables
## Sex
has_recorded_sex = patients.sex.is_in(["male", "female"])


## Age
age = patients.age_on(index_date)


age_band = case(
    when((age >= 0) & (age < 20)).then("0-19"),
    when((age >= 20) & (age < 40)).then("20-39"),
    when((age >= 40) & (age < 60)).then("40-59"),
    when((age >= 60) & (age < 80)).then("60-79"),
    when(age >= 80).then("80+"),
)


# Denominator: For all objectives, the denominator is
# adults (18-110 years)
was_adult = (age >= 18) & (
    patients.age_on(index_date) <= 110
)
# alive and
was_alive = (
    patients.date_of_death.is_after(index_date)
    | patients.date_of_death.is_null()
)
# registered with a TPP practice on the first of each  month.
was_registered = practice_registrations.for_patient_on(
    index_date
).exists_for_patient()


#opioid analgesia: people
opioid_prescription_people = medications.where(
        medications.dmd_code.is_in(opioid_analgesia_codelist)
).where(
        medications.date.is_during(INTERVAL)
).exists_for_patient()

#opioids prescripted
opioid_prescription_drugs = medications.where(
        medications.dmd_code.is_in(opioid_analgesia_codelist)
).where(
        medications.date.is_during(INTERVAL)
).count_for_patient()

#new patient
first_prescription = (
    medications.where(medications.dmd_code.is_in(opioid_analgesia_codelist))
    .sort_by(medications.date)
    .first_for_patient()
)

new_opioid_analgesia_people = medications.where(
        medications.dmd_code.is_in(opioid_analgesia_codelist)
).where(
        first_prescription.date.is_during(INTERVAL)
).exists_for_patient()

# interval =


#Measure definition
measures.define_measure(
    name = "opioid_analgesia_people",
    numerator= opioid_prescription_people,
    denominator= was_adult & was_alive & was_registered & has_recorded_sex,
    group_by={
        "sex": patients.sex,
        "age_band": age_band,
    },
    intervals=months(36).starting_on("2019-01-01"),
)

measures.define_measure(
    name = "opioid_analgesia_drugs",
    numerator= opioid_prescription_drugs,
    denominator= was_adult & was_alive & was_registered & has_recorded_sex,
    group_by={
        "sex": patients.sex,
        "age_band": age_band,
    },
    intervals=months(36).starting_on("2019-01-01"),
)

measures.define_measure(
    name = "new_opioid_analgesia_people",
    numerator= new_opioid_analgesia_people,
    denominator= was_adult & was_alive & was_registered & has_recorded_sex,
    group_by={
        "sex": patients.sex,
        "age_band": age_band,
    },
    intervals=months(36).starting_on("2019-01-01"),
)



measures.configure_dummy_data(population_size=1000)



