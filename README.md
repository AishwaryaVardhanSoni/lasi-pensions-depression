# Pension Receipt and Depression among Older Adults in India

Replication code for *Pension Receipt and Depression among Older Adults in India* (Aishwarya Vardhan Soni, 2026). The paper uses Wave 1 of the Longitudinal Ageing Study in India (LASI, 2017–18) to ask whether adults aged 60 and above who receive a pension are less likely to be depressed, and how selection into work-related and social pensions shapes that comparison.

## Data

The analysis uses two LASI Wave 1 files released by the International Institute for Population Sciences (IIPS), Mumbai:

- `3_LASI_W1_Individual_data.dta`: individual respondents (demographics, pensions, CIDI-SF depression module)
- `2_LASI_W1_Household_data.dta`: household questionnaire (ration-card type, questions CO301–CO302)

Access requires a data request to IIPS (https://iipsindia.ac.in/content/data-request), so no data are included in this repository. Place both files in one folder and point `$raw` in `master.do` to it.

## Software

- Stata 17 or later
- `estout` and `coefplot` from SSC (`master.do` installs them if missing)

## Running the code

1. Edit the paths in Section 1 of `master.do`: this repository, the folder holding the raw LASI files, and a folder for intermediate datasets (kept outside the repository).
2. Run `master.do`. It runs every script in order, writes all tables and figures to `output/`, and logs the full run to `output/logs/master.log`. Runtime is a few minutes on a laptop.

The scripts `assert` known counts at each step (for example, 31,464 respondents aged 60+ and 29,627 in the estimation sample), so a run that finishes has reproduced the paper's sample exactly.

## Contents

| Script | Purpose | Output |
|---|---|---|
| `master.do` | Sets paths, installs packages, runs the pipeline | `output/logs/master.log` |
| `code/01_sample.do` | Loads the individual file; keeps respondents aged 60+ | `01_sample.dta` (intermediate) |
| `code/02_variables.do` | Builds the depression indicator, pension measures and controls; merges ration-card type; defines the estimation sample | `02_analysis.dta` (intermediate) |
| `code/03_descriptives.do` | Characteristics by pension status | Table 1 |
| `code/04_regressions.do` | Main estimates, pension types, robustness, heterogeneity | Tables 2–5, Figure 1 |

## Key construction choices

- **Depression.** Probable major depression from the CIDI-SF: three or more symptoms on either the depressed-mood pathway (MH204–MH211) or the loss-of-interest pathway (MH217–MH222). Respondents never administered the module are coded missing, not zero.
- **Pension receipt.** Current receipt of a work-related pension (WE412 = 1) or of a cash social pension (SW202, schemes a, b, d and e). Expected future pensions enter only as a robustness check.
- **Household structure.** Marital status and living arrangements are combined into one seven-category variable, since no widowed respondent lives with a spouse.
- **Inference.** Standard errors are clustered by household, with village/ward clustering as a robustness check. Main estimates are unweighted; survey-weighted estimates are in Table 4.

## Acknowledgment

The first version of this code was drafted with the help of an AI assistant (Claude, Anthropic). I ran and checked every step, and I am responsible for all choices and any errors.
