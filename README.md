# Pension Receipt and Depression among Older Adults in India

Replication code for my paper "Pension Receipt and Depression among Older Adults in India" (Aishwarya Vardhan Soni, 2026). It uses wave 1 of the Longitudinal Ageing Study in India (LASI, 2017-18) to look at whether people aged 60+ who get a pension are less likely to be depressed, and how selection into work-related vs social pensions affects that comparison.

## Data

Two LASI wave 1 files from IIPS (International Institute for Population Sciences, Mumbai):

- `3_LASI_W1_Individual_data.dta` - individual respondents (demographics, pensions, the depression module)
- `2_LASI_W1_Household_data.dta` - household questionnaire, only used for the ration card type (CO301-CO302)

The data are available on request from IIPS (https://iipsindia.ac.in/content/data-request) so they're not included here. Put both files in one folder and set `$raw` at the top of the do-file to that folder.

## Running it

Everything is in one do-file, `lasi_pensions_depression.do`. You need Stata 17 and two packages from SSC (only once): `ssc install estout` and `ssc install coefplot`.

Change the 3 folder paths at the top and run it. It goes top to bottom in 4 parts (load the data and keep 60+, make the variables, Table 1, then the regressions for Tables 2-5 and Figure 1). The tables and the figure are saved in `output/`, and a log of the whole run goes to `output/logs/lasi_pensions_depression.log`. The cleaned data is also saved as `analysis.dta` in the `$work` folder.

The do-file checks the sample sizes as it goes (31,464 respondents aged 60+, 29,627 in the final sample) and stops if a number doesn't match.

## Main choices

Depression = 3 or more symptoms on either part of the CIDI-SF module (sad mood, MH204-MH211, or loss of interest, MH217-MH222). People who were never asked the module are coded missing, not 0.

Pension receipt = currently getting a work-related pension (WE412 = 1) or a cash social pension (SW202, schemes a, b, d and e). Expected future pensions are only used in a robustness check.

Marital status and living arrangements are combined into one household structure variable, because no widowed respondent lives with a spouse.

SEs are clustered by household, with village/ward clustering as a check. Main estimates are unweighted, the survey-weighted ones are in Table 4.


