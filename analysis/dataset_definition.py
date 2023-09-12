###################################################
# This script defines a function that 
#   creates opioid prescribing variables,
#   and whether someone had a history of cancer
#   for use in downstream code
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
def make_dataset_opioids(index_date, end_date):
    
    dataset = Dataset()

    ## Define relevant variables

    # Cancer diagnosis in past 5 years (for sensivity analyses)
    dataset.cancer = clinical_events.where(
            clinical_events.snomedct_code.is_in(codelists.cancer_codes)
        ).where(
            clinical_events.date.is_on_or_between(index_date - years(5), index_date)
        ).exists_for_patient()

    # Function to define no. people with opioid prescription 
    def has_med_event(codelist, where=True):
        med_event_exists = medications.where(medications.dmd_code.is_in(codelist)
            ).where(
                medications.date.is_on_or_between(index_date, end_date)
            ).exists_for_patient()
        return (
            case(
                when(med_event_exists).then(True),
                when(~med_event_exists).then(False)
                )
        )

    # Overall
    dataset.opioid_any = has_med_event(codelists.opioid_codes) # Any opioid

    # By admin route
    dataset.oral_opioid_any = has_med_event(codelists.oral_opioid_codes)  # Oral opioid
    dataset.buc_opioid_any = has_med_event(codelists.buc_opioid_codes)  # Buccal opioid
    dataset.inh_opioid_any = has_med_event(codelists.inh_opioid_codes)  # Inhaled opioid
    dataset.rec_opioid_any = has_med_event(codelists.rec_opioid_codes)  # Rectal opioid
    dataset.par_opioid_any = has_med_event(codelists.par_opioid_codes)  # Parenteral opioid
    dataset.trans_opioid_any = has_med_event(codelists.trans_opioid_codes)  # Transdermal opioid
    dataset.oth_opioid_any = has_med_event(codelists.oth_opioid_codes)  # Other admin route opioid

    # By strength/type
    dataset.hi_opioid_any = has_med_event(codelists.hi_opioid_codes)  # High dose / long-acting opioid
    dataset.long_opioid_any = has_med_event(codelists.long_opioid_codes)  # Long-acting opioid


    # No. people with a new opioid prescription (2 year lookback) 
    # Note: for any opioids only 

    # Date of last prescription before index date
    last_rx = medications.where(
        medications.dmd_code.is_in(codelists.opioid_codes)
        ).where(
            medications.date.is_before(index_date)
        ).sort_by(
            medications.date
        ).last_for_patient().date

    # Is opioid naive using one year lookback (for denominator)
    dataset.opioid_naive = case(
        when(last_rx.is_before(index_date - years(1))).then(True),
        when(last_rx.is_null()).then(True),
        default=False
    )

    # Number of people with new prescriptions (among naive only)
    dataset.opioid_new = case(
        when(medications.where(medications.dmd_code.is_in(codelists.opioid_codes)
            ).where(
                medications.date.is_on_or_between(index_date, end_date)
            ).where(dataset.opioid_naive).exists_for_patient()
        ).then(True),
        default=False
    )

    return dataset

def registrations(start_date, end_date):
    return practice_registrations.where(
        practice_registrations.start_date.is_on_or_before(start_date)
        & (practice_registrations.end_date.is_after(end_date) | practice_registrations.end_date.is_null())
    )

##############################################

