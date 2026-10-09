# Pension Receipt and Depression among Older Adults in India

Replication code for *Pension Receipt and Depression among Older Adults in India* (Aishwarya Vardhan Soni, 2026). The paper uses Wave 1 of the Longitudinal Ageing Study in India (LASI, 2017–18) to ask whether adults aged 60 and above who receive a pension are less likely to be depressed, and how selection into work-related and social pensions shapes that comparison.

## Data

The code uses two LASI Wave 1 files from the International Institute for Population Sciences (IIPS), Mumbai:

- `3_LASI_W1_Individual_data.dta`: individual respondents (demographics, pensions, depression module)
- `2_LASI_W1_Household_data.dta`: household questionnaire (ration-card type, questions CO301–CO302)

The data are available on request from IIPS (https://iipsindia.ac.in/content/data-request), so they are not included here. Put both files in one folder and set `$raw` in `master.do` to that folder.

## Software

- Stata 17
- Two packages from SSC, installed once with `ssc install estout` and `ssc install coefplot`

## How to run

1. Open `master.do` and change the three folder paths at the top.
2. Run `master.do`. It runs the four scripts in `code/` in order, saves all tables and the figure in `output/`, and writes a log of the full run to `output/logs/master.log`.

The scripts check sample sizes as they go (31,464 respondents aged 60+, 29,627 in the final sample) and stop if a number doesn't match.

## Files

| Script | What it does | Output |
|---|---|---|
| `master.do` | Sets folder paths and runs everything | `output/logs/master.log` |
| `code/01_sample.do` | Loads the data, keeps respondents aged 60+, adds ration-card type | `sample60.dta` |
| `code/02_variables.do` | Makes the depression outcome, pension variables and controls | `analysis.dta` |
| `code/03_descriptives.do` | Characteristics by pension status | Table 1 |
| `code/04_regressions.do` | Main results, pension types, robustness, heterogeneity | Tables 2–5, Figure 1 |

## Main choices

- **Depression:** three or more symptoms on either part of the CIDI-SF depression module (sad mood, MH204–MH211, or loss of interest, MH217–MH222). People who were never asked the module are coded missing, not zero.
- **Pension receipt:** currently receiving a work-related pension (WE412 = 1) or a cash social pension (SW202, schemes a, b, d and e). Expected future pensions are used only in a robustness check.
- **Household structure:** marital status and living arrangements combined into one variable, because no widowed respondent lives with a spouse.
- **Standard errors:** clustered by household, with village/ward clustering as a check. Main estimates are unweighted; survey-weighted estimates are in Table 4.

## AI use

I wrote this code with help from an AI assistant (Claude, Anthropic). I ran and checked every step, and I am responsible for all choices and any errors.
