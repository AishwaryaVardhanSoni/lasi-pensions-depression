* =============================================================
* 01_sample.do
* Loads the LASI household and individual files, keeps only the
* variables I use, and keeps respondents aged 60 and above.
* =============================================================

* --- Household file: ration card questions (CO301, CO302) ---
* The household file has too many variables to open in full,
* so I load only the three I need.
use hhid co301 co302 using "$raw/2_LASI_W1_Household_data.dta", clear
isid hhid                        // check: one row per household
save "$work/household.dta", replace

* --- Individual file ---
use prim_key hhid stateid residence living_arrangements mpce_quintile ///
    indiaindividualweight dm003 dm005 dm006 dm007 dm010 dm013 dm021  ///
    we412 sw202a sw202b sw202d sw202e                                 ///
    mh201 mh204 mh205 mh206 mh207 mh208 mh209 mh210 mh211             ///
    mh214 mh217 mh218 mh219 mh220 mh221 mh222                         ///
    using "$raw/3_LASI_W1_Individual_data.dta", clear

* Keep respondents aged 60+ (the age group asked about social pensions).
* Stata treats missing as a very large number, so I also drop missing age.
keep if dm005 >= 60 & !missing(dm005)
assert _N == 31464               // same number as in the LASI user guide

* Add the ration card questions from the household file
merge m:1 hhid using "$work/household.dta", keep(master match)
tab _merge                       // a few respondents have no household interview
drop _merge

save "$work/sample60.dta", replace
