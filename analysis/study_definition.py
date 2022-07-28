######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

######################################


# IMPORT STATEMENTS ----

# Import code building blocks from cohort extractor package
from cohortextractor import (
    StudyDefinition,
    patients,
    Measure,
)

# Import codelists from codelist.py (which pulls them from the codelist folder)
from codelists import (
   opioid_codes,
   high_dose_codes,
   care_home_codes,
)

from config import start_date, end_date, codelist_path, demographics

from demographic_variables import demographic_variables


# Define study population and variables
study = StudyDefinition(
    index_date=start_date,
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "uniform",
        "incidence": 0.15,
    },
    # Define the study population
    population=patients.satisfying(
        """
        NOT has_died
        AND
        registered
        AND
        (sex = "M" OR sex = "F")
        AND
        (age >= 18 AND age < 110)
        """,
        has_died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
        ),
        registered=patients.satisfying(
            "registered_at_start",
            registered_at_start=patients.registered_as_of("index_date"),
        ),
    ),
    # Common demographic variables
    **demographic_variables,
    # Opioids
    any_opioid=patients.satisfying(
        """
        opioid_date
        """,
        opioid_date=patients.with_these_medications(
            codelist=opioid_codes,
            returning="date",
            date_format="YYYY-MM-DD",
            find_last_match_in_period=True,
            between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],
            return_expectations={
                "date": {
                    "earliest": "first_day_of_month(index_date)",
                    "latest": "last_day_of_month(index_date)",
                },
            },
        ),
    ),
    new_opioid=patients.satisfying(
        """
        any_opioid AND
        NOT previous_opioid
        """,
        previous_opioid=patients.with_these_medications(
            codelist=opioid_codes,
            returning="binary_flag",
            find_last_match_in_period=True,
            between=[
                "opioid_date - 2 years",
                "opioid_date - 1 day",
            ],
            return_expectations={"incidence": 0.01},
        ),
        return_expectations={"incidence": 0.01},
    ),
    # High dose
    antidepressant_tricyclic=patients.satisfying(
        """
        antidepressant_tricyclic_date
        """,
        antidepressant_tricyclic_date=patients.with_these_medications(
            codelist=tricyclic_codes,
            returning="date",
            date_format="YYYY-MM-DD",
            find_last_match_in_period=True,
            between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],
            return_expectations={
                "date": {
                    "earliest": "first_day_of_month(index_date)",
                    "latest": "last_day_of_month(index_date)",
                },
            },
        ),
    ),
    new_antidepressant_tricyclic=patients.satisfying(
        """
        antidepressant_tricyclic AND
        NOT previous_tricyclic
        """,
        previous_tricyclic=patients.with_these_medications(
            codelist=tricyclic_codes,
            returning="binary_flag",
            find_last_match_in_period=True,
            between=[
                "antidepressant_ssri_date - 2 years",
                "antidepressant_ssri_date - 1 day",
            ],
            return_expectations={"incidence": 0.01},
        ),
        return_expectations={"incidence": 0.01},
    ),
    # MAOI
    antidepressant_maoi=patients.satisfying(
        """
        antidepressant_maoi_date
        """,
        antidepressant_maoi_date=patients.with_these_medications(
            codelist=maoi_codes,
            returning="date",
            date_format="YYYY-MM-DD",
            find_last_match_in_period=True,
            between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],
            return_expectations={
                "date": {
                    "earliest": "first_day_of_month(index_date)",
                    "latest": "last_day_of_month(index_date)",
                },
            },
        ),
    ),
    new_antidepressant_maoi=patients.satisfying(
        """
        antidepressant_maoi AND
        NOT previous_maoi
        """,
        previous_maoi=patients.with_these_medications(
            codelist=maoi_codes,
            returning="binary_flag",
            find_last_match_in_period=True,
            between=[
                "antidepressant_maoi_date - 2 years",
                "antidepressant_maoi_date - 1 day",
            ],
            return_expectations={"incidence": 0.01},
        ),
        return_expectations={"incidence": 0.01},
    ),
    # Other antidepressant
    antidepressant_other=patients.satisfying(
        """
        antidepressant_other_date
        """,
        antidepressant_other_date=patients.with_these_medications(
            codelist=other_antidepressant_codes,
            returning="date",
            date_format="YYYY-MM-DD",
            find_last_match_in_period=True,
            between=["first_day_of_month(index_date)", "last_day_of_month(index_date)"],
            return_expectations={
                "date": {
                    "earliest": "first_day_of_month(index_date)",
                    "latest": "last_day_of_month(index_date)",
                },
            },
        ),
    ),
    new_antidepressant_other=patients.satisfying(
        """
        antidepressant_other AND
        NOT previous_other
        """,
        previous_other=patients.with_these_medications(
            codelist=other_antidepressant_codes,
            returning="binary_flag",
            find_last_match_in_period=True,
            between=[
                "antidepressant_other_date - 2 years",
                "antidepressant_other_date - 1 day",
            ],
            return_expectations={"incidence": 0.01},
        ),
        return_expectations={"incidence": 0.01},
    ),
    antidepressant_any=patients.satisfying(
        """
        antidepressant_ssri OR
        antidepressant_tricyclic OR
        antidepressant_maoi OR
        antidepressant_other
        """
    ),
    new_antidepressant_any=patients.satisfying(
        """
        new_antidepressant_ssri OR
        new_antidepressant_tricyclic OR
        new_antidepressant_maoi OR
        new_antidepressant_other
        """,
    ),
)

