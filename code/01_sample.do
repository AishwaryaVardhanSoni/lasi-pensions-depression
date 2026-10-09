*==============================================================================
* 01_sample.do
*
* Loads the variables used in the analysis from the LASI Wave 1 individual
* file and restricts the data to respondents aged 60 and above, the population
* covered by LASI's social-pension module (SW201-SW213).
*
* Input : $indfile
* Output: $work/01_sample.dta
*==============================================================================

*------------------------------------------------------------------------------
* 1. Load only the variables used in the analysis
*------------------------------------------------------------------------------
use prim_key hhid stateid residence living_arrangements mpce_quintile       ///
    indiaindividualweight                                                  ///
    dm003 dm005 dm006 dm007 dm010 dm013 dm021                              ///
    we412                                                                  ///
    sw202a sw202b sw202d sw202e                                            ///
    mh201 mh202 mh203 mh204 mh205 mh206 mh207 mh208 mh209 mh210 mh211      ///
    mh214 mh215 mh216 mh217 mh218 mh219 mh220 mh221 mh222                  ///
    using "$indfile", clear

assert _N == 72250                       // all Wave 1 respondents
isid prim_key                            // one row per respondent

*------------------------------------------------------------------------------
* 2. Restrict to respondents aged 60+
*    Stata treats missing values as larger than any number, so the explicit
*    !missing() condition is required.
*------------------------------------------------------------------------------
keep if dm005 >= 60 & !missing(dm005)
assert _N == 31464                       // matches the LASI Data User Guide

* Every respondent aged 60+ has a national individual weight
assert !missing(indiaindividualweight)

compress
save "$work/01_sample.dta", replace
