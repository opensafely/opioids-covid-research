#####################################################################

# Reusable demographic variables

# Can be imported into a study definition to apply to any population

####################################################################

from cohortextractor import patients
from codelists import , carehome_codes

demographic_variables = dict(
    # Age
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
            "incidence": 0.001,
        },
    ),
     # Age
    age_cat=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """age >=18 AND age<30""",
            "2": """age >=30 AND age<40""",
            "3": """age >=40 AND age<50""",
            "4": """age >=50 AND age<60""",
            "5": """age >=60 AND age<70""",
            "6": """age >=70 AND age<80""",
            "7": """age >=80 AND age<90""",
            "8": """age >=90 AND age<110""",

        },
        age=patients.address_as_of(
            "index_date",
            returning="age",
            round_to_nearest=1,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.01,
                    "1": 0.18,
                    "2": 0.17,
                    "3": 0.16,
                    "4": 0.17,
                    "5": 0.14,
                    "3": 0.11,
                    "4": 0.05,
                    "5": 0.01,
                }
            },
        },
    # Sex
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # Index of multiple deprivation
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 """,
        },
        index_of_multiple_deprivation=patients.address_as_of(
            "index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.01,
                    "1": 0.20,
                    "2": 0.20,
                    "3": 0.20,
                    "4": 0.20,
                    "5": 0.19,
                }
            },
        },
    ),
    # Region
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.1,
                    "South West": 0.1,
                },
            },
        },
    ),
    # Care home
    carehome=patients.categorised_as(
        {
            "Unknown": "DEFAULT",
            "Not in carehome": "ch='0'",
            "Carehome": "ch='1'",
        },
        ch=patients.with_these_clinical_events(
            carehome_codes,
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.2},
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "Unknown": 0.1,
                    "Not in carehome": 0.8,
                    "Carehome": 0.1,
                }
            },
        },
    ),
    # Cancer
    cancer=patients.categorised_as(
        {
            "Unknown": "DEFAULT",
            "No cancer": "ca='0'",
            "Cancer": "ca='1'",
        },
        ca=patients.with_these_clinical_events(
            cancer_codes,
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.2},
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "Unknown": 0.1,
                    "No cancer": 0.8,
                    "Cancer": 0.1,
                }
            },
        },
    ),
)
