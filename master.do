*==============================================================================
* master.do
*
* Project : Pension Receipt and Depression among Older Adults in India
* Data    : Longitudinal Ageing Study in India (LASI), Wave 1 (2017-18)
* Author  : Aishwarya Vardhan Soni
*
* Runs the full pipeline, from the raw LASI files to every table and figure
* in the paper. To replicate, edit the paths in Section 1 and run this file.
* Data access and software requirements are described in README.md.
*==============================================================================

clear all
set more off
set varabbrev off
version 17

*------------------------------------------------------------------------------
* 1. Paths (the only lines a new user needs to edit)
*------------------------------------------------------------------------------
global root "D:/Predoc_files/lasi-pensions-depression"    // this repository
global raw  "D:/Predoc_files/data/LASI"                   // raw LASI files (read-only)
global work "D:/Predoc_files/data/work"                   // intermediate data (not in repo)

global indfile "$raw/3_LASI_W1_Individual_data.dta"
global hhfile  "$raw/2_LASI_W1_Household_data.dta"

*------------------------------------------------------------------------------
* 2. Output folders
*------------------------------------------------------------------------------
global code   "$root/code"
global tables "$root/output/tables"
global figs   "$root/output/figures"
global logs   "$root/output/logs"

foreach folder in "$work" "$root/output" "$tables" "$figs" "$logs" {
    capture mkdir "`folder'"
}

*------------------------------------------------------------------------------
* 3. User-written packages (installed only if missing)
*------------------------------------------------------------------------------
foreach pkg in estout coefplot {
    capture which `pkg'
    if _rc {
        ssc install `pkg', replace
    }
}

*------------------------------------------------------------------------------
* 4. Pipeline
*------------------------------------------------------------------------------
capture log close
log using "$logs/master.log", replace text

do "$code/01_sample.do"         // raw individual file -> respondents aged 60+
do "$code/02_variables.do"      // outcome, pensions, controls, estimation sample
do "$code/03_descriptives.do"   // Table 1
do "$code/04_regressions.do"    // Tables 2-5 and Figure 1

log close
