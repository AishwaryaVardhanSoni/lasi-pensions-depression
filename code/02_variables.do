*==============================================================================
* 02_variables.do
*
* Constructs the outcome (probable major depression, CIDI-SF), the pension
* measures and the controls; merges ration-card type from the household file;
* and defines the estimation sample.
*
* Input : $work/01_sample.dta, $hhfile
* Output: $work/02_analysis.dta
*==============================================================================

use "$work/01_sample.dta", clear

*------------------------------------------------------------------------------
* 1. Outcome: probable major depression (CIDI-SF)
*
* LASI administers the CIDI-SF through two screening pathways:
*   Depressed mood   - screen MH201. The seven symptom items MH204-MH211 are
*                      asked only if the episode lasted most of the day
*                      (MH202) nearly every day (MH203 = 1 or 2).
*   Loss of interest - screen MH214. The six symptom items MH217-MH222 are
*                      asked only under the analogous criteria (MH215-MH216).
* A respondent is classified as depressed if either pathway records three or
* more symptoms. A skipped symptom item counts as absent, because the skip
* means the screening criteria were not met. Respondents never administered
* the module (both screens missing, most likely proxy interviews) are coded
* missing rather than "not depressed".
*------------------------------------------------------------------------------

* The skip pattern described above holds in the data, with one exception:
* a single respondent answers MH217 although the MH216 screen was not met.
* That record is harmless (it would change the classification only if it
* alone lifted the respondent to three symptoms), so it is tolerated here.
count if !missing(mh204) & !inlist(mh203, 1, 2)
assert r(N) == 0
count if !missing(mh217) & !inlist(mh216, 1, 2)
assert r(N) <= 1

* Depressed-mood pathway: seven symptoms (appetite loss or gain counts once).
* (x == 1) equals 0 when x is missing, so skipped items count as absent.
foreach q in mh204 mh205 mh208 mh209 mh210 mh211 {
    gen byte sym_`q' = (`q' == 1)
}
gen byte sym_appetite = (mh206 == 1 | mh207 == 1)
egen byte n_mood = rowtotal(sym_mh204 sym_mh205 sym_appetite sym_mh208    ///
                            sym_mh209 sym_mh210 sym_mh211)

* Loss-of-interest pathway: six symptoms
foreach q in mh217 mh218 mh219 mh220 mh221 mh222 {
    gen byte sym_`q' = (`q' == 1)
}
egen byte n_interest = rowtotal(sym_mh217 sym_mh218 sym_mh219 sym_mh220   ///
                                sym_mh221 sym_mh222)

* The module was administered if at least one screening question was answered
gen byte cidi_module = !missing(mh201) | !missing(mh214)
count if cidi_module == 0
assert r(N) == 818

gen byte depressed = (max(n_mood, n_interest) >= 3) if cidi_module == 1
gen dep_pp = 100 * depressed             // outcome in percentage points

count if !missing(depressed)
assert r(N) == 30646
count if depressed == 1
assert r(N) == 2317

drop sym_*

*------------------------------------------------------------------------------
* 2. Pension receipt
*
* Work-related pensions (WE412) are asked only of respondents who work in, or
* retired from, the organized sector (WE004 = 1 or WE402 = 1); respondents not
* asked have no work-related pension.
*   WE412: 1 = currently receiving, 2 = expected in future, 3 = neither.
* Social pensions (SW202, "availing the benefits") are asked scheme by scheme
* of respondents aged 60+ who are aware of the scheme (SW201 = 1); respondents
* unaware of a scheme are not receiving it.
*   a = National Old Age Pension Scheme (requires a BPL household),
*   b = widow pension (asked of women only), d and e = other pension schemes.
*   Scheme c (Annapurna) provides food grains rather than cash and is excluded.
*------------------------------------------------------------------------------
gen byte work_pen     = (we412 == 1)
gen byte work_pen_exp = (we412 == 2)
gen byte oldage_pen   = (sw202a == 1)
gen byte widow_pen    = (sw202b == 1)
gen byte other_social = (sw202d == 1 | sw202e == 1)
gen byte social_pen   = (oldage_pen == 1 | widow_pen == 1 | other_social == 1)

* Main treatment: currently receives any pension
gen byte any_pen = (work_pen == 1 | social_pen == 1)

* Broader definition (robustness only): adds respondents expecting a
* work-related pension in future, who receive no pension income yet
gen byte any_pen_broad = (any_pen == 1 | work_pen_exp == 1)

count if work_pen == 1
assert r(N) == 2196
count if work_pen_exp == 1
assert r(N) == 365

*------------------------------------------------------------------------------
* 3. Controls
*------------------------------------------------------------------------------
gen age          = dm005
gen byte old70   = (age >= 70)
gen byte female  = (dm003 == 2)
gen byte urban   = (residence == 2)

* Years of schooling; respondents who never attended school (DM006 = 2) have 0
gen schooling = cond(dm006 == 2, 0, dm007)
assert !missing(schooling)

* Household structure. Marital status (DM021) and living arrangements are
* nearly collinear - no widowed respondent lives with a spouse - so they
* enter the regressions as one combined variable.
*   DM021: 1 = currently married, 2 = widowed, 3-7 = divorced, separated,
*          deserted, live-in relationship, never married.
*   living_arrangements: 1 = alone, 2 = spouse only, 3 = spouse and children,
*          4 = children only, 5 = others only.
gen byte hhstruct = .
replace  hhstruct = 1 if dm021 == 1 & living_arrangements == 2
replace  hhstruct = 2 if dm021 == 1 & living_arrangements == 3
replace  hhstruct = 3 if dm021 == 1 & inlist(living_arrangements, 1, 4, 5)
replace  hhstruct = 4 if dm021 == 2 & living_arrangements == 1
replace  hhstruct = 5 if dm021 == 2 & living_arrangements == 4
replace  hhstruct = 6 if dm021 == 2 & living_arrangements == 5
replace  hhstruct = 7 if inrange(dm021, 3, 7)
assert !missing(hhstruct)
label define hhstruct_lbl                                                 ///
    1 "Married, with spouse only"                                         ///
    2 "Married, with spouse and children"                                 ///
    3 "Married, spouse not co-resident"                                   ///
    4 "Widowed, alone"                                                    ///
    5 "Widowed, with children"                                            ///
    6 "Widowed, with others"                                              ///
    7 "Other unmarried"
label values hhstruct hhstruct_lbl

* Simple indicators for the descriptive table
gen byte widowed      = (dm021 == 2)
gen byte living_alone = (living_arrangements == 1)

* Caste (DM013); OBC is the reference group in the regressions
gen byte caste = dm013
label define caste_lbl 1 "Scheduled Caste" 2 "Scheduled Tribe" 3 "OBC"   ///
                       4 "None of these"
label values caste caste_lbl
gen byte sc = (caste == 1) if !missing(caste)
gen byte st = (caste == 2) if !missing(caste)

* Religion (DM010), collapsed. Categories with very few respondents (for
* example, two Jewish and two Parsi respondents aged 60+) are grouped as Other.
recode dm010 (2 = 1 "Hindu") (3 = 2 "Muslim") (4 = 3 "Christian")        ///
             (5 = 4 "Sikh") (1 6/10 = 5 "Other"), gen(religion)

* Consumption: bottom two MPCE quintiles (descriptive table only)
gen byte mpce_bottom2 = inlist(mpce_quintile, 1, 2)

*------------------------------------------------------------------------------
* 4. Identifiers for clustering
*    hhid has 15 digits: wave (1), state (2), secondary sampling unit, i.e.
*    village or urban ward (4), household structure (4), household (2), and
*    member (2, always 00 at the household level). It is stored as a string
*    so that it merges cleanly with the household file.
*------------------------------------------------------------------------------
capture confirm numeric variable hhid
if !_rc {
    tostring hhid, replace format(%15.0f)
}
assert strlen(hhid) == 15

egen long hh_id  = group(hhid)                  // household
gen str7 ssu     = substr(hhid, 1, 7)           // wave + state + village/ward
egen long ssu_id = group(ssu)

*------------------------------------------------------------------------------
* 5. Ration-card type from the household file (CO301-CO302)
*    The National Old Age Pension requires a below-poverty-line (BPL)
*    household; Antyodaya cards go to the poorest BPL households.
*------------------------------------------------------------------------------
preserve
    use hhid co301 co302 using "$hhfile", clear
    capture confirm numeric variable hhid
    if !_rc {
        tostring hhid, replace format(%15.0f)
    }
    isid hhid
    tempfile hh
    save `hh'
restore

merge m:1 hhid using `hh', keep(master match)
tab _merge
drop _merge

gen byte bpl_card = .
replace  bpl_card = 1 if co301 == 1 & inlist(co302, 1, 2)
replace  bpl_card = 0 if co301 == 2 | (co301 == 1 & inlist(co302, 3, 4))
tab bpl_card, missing

*------------------------------------------------------------------------------
* 6. Estimation sample: complete data on the outcome and all controls
*    31,464 aged 60+ -> less 818 without the depression module
*    -> less 1,018 with missing caste -> less 1 with missing religion
*    = 29,627 respondents
*------------------------------------------------------------------------------
keep if !missing(depressed, age, female, hhstruct, urban, schooling,      ///
                 caste, religion, mpce_quintile, stateid)
assert _N == 29627

*------------------------------------------------------------------------------
* 7. Labels (esttab uses them as table row names)
*------------------------------------------------------------------------------
label variable depressed     "Depressed (CIDI-SF)"
label variable dep_pp        "Depressed (CIDI-SF) x 100"
label variable any_pen       "Receives any pension"
label variable any_pen_broad "Receives or expects any pension"
label variable work_pen      "Work-related pension"
label variable work_pen_exp  "Expects work-related pension"
label variable social_pen    "Social pension"
label variable oldage_pen    "National old-age pension"
label variable widow_pen     "Widow pension"
label variable other_social  "Other social pension"
label variable age           "Age (years)"
label variable old70         "Aged 70+"
label variable female        "Female"
label variable widowed       "Widowed"
label variable living_alone  "Lives alone"
label variable urban         "Urban"
label variable schooling     "Years of schooling"
label variable sc            "Scheduled Caste"
label variable st            "Scheduled Tribe"
label variable bpl_card      "BPL or Antyodaya card"
label variable mpce_bottom2  "Bottom two MPCE quintiles"
label variable hhstruct      "Household structure"
label variable caste         "Caste"
label variable religion      "Religion"

compress
save "$work/02_analysis.dta", replace
