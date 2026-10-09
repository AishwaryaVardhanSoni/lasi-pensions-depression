* =============================================================
* 02_variables.do
* Makes the depression outcome, the pension variables and the
* controls, then keeps the final sample.
* =============================================================

use "$work/sample60.dta", clear

* -------------------------------------------------------------
* 1. Depression (CIDI-SF)
* -------------------------------------------------------------
* LASI asks about depression in two parts:
*  - Sad mood (MH201). If the person says yes, and it lasted most of
*    the day nearly every day, 7 symptoms are asked (MH204-MH211).
*  - Loss of interest (MH214). Same idea, 6 symptoms (MH217-MH222).
* Someone is depressed if they report 3+ symptoms in either part.
* Symptoms that were not asked count as "no".

* Count the "yes" answers (anycount counts how many variables equal 1)
egen n_mood = anycount(mh204 mh205 mh208 mh209 mh210 mh211), values(1)
replace n_mood = n_mood + 1 if mh206 == 1 | mh207 == 1   // appetite loss or gain = 1 symptom
egen n_interest = anycount(mh217 mh218 mh219 mh220 mh221 mh222), values(1)

gen depressed = 0
replace depressed = 1 if n_mood >= 3 | n_interest >= 3

* People never asked the depression questions (probably proxy
* interviews) are set to missing rather than "not depressed"
replace depressed = . if missing(mh201) & missing(mh214)

count if missing(depressed)
assert r(N) == 818
count if depressed == 1
assert r(N) == 2317

* Outcome x 100, so regression coefficients are in percentage points
gen dep100 = 100 * depressed

* -------------------------------------------------------------
* 2. Pensions
* -------------------------------------------------------------
* Work pension, WE412: 1 = receiving now, 2 = expects one later, 3 = neither.
* Only asked of people who worked in the organised sector; everyone else gets 0.
gen work_pen = (we412 == 1)
gen work_pen_future = (we412 == 2)

* Social pensions, SW202 ("are you availing this scheme?", 1 = yes):
*   a = National Old Age Pension (needs a BPL card)
*   b = widow pension
*   d, e = other pension schemes
* (c = Annapurna gives food grains, not cash, so I leave it out)
gen oldage_pen = (sw202a == 1)
gen widow_pen  = (sw202b == 1)
gen other_pen  = (sw202d == 1 | sw202e == 1)
gen social_pen = (oldage_pen == 1 | widow_pen == 1 | other_pen == 1)

* Main variable: currently receives any pension
gen any_pen = (work_pen == 1 | social_pen == 1)

* Broader version for a robustness check: also counts expected work pensions
gen any_pen_broad = (any_pen == 1 | work_pen_future == 1)

* -------------------------------------------------------------
* 3. Controls
* -------------------------------------------------------------
gen age    = dm005
gen female = (dm003 == 2)
gen urban  = (residence == 2)

* Years of schooling (0 for people who never went to school, DM006 = 2)
gen schooling = dm007
replace schooling = 0 if dm006 == 2

* Household structure: marital status (DM021) combined with who the
* person lives with. I combine them because no widowed person lives
* with a spouse, so the two variables can't be separated.
*   DM021: 1 married, 2 widowed, 3-7 divorced/separated/never married etc.
*   living_arrangements: 1 alone, 2 spouse only, 3 spouse and children,
*                        4 children only, 5 others
gen hhstruct = .
replace hhstruct = 1 if dm021 == 1 & living_arrangements == 2
replace hhstruct = 2 if dm021 == 1 & living_arrangements == 3
replace hhstruct = 3 if dm021 == 1 & inlist(living_arrangements, 1, 4, 5)
replace hhstruct = 4 if dm021 == 2 & living_arrangements == 1
replace hhstruct = 5 if dm021 == 2 & living_arrangements == 4
replace hhstruct = 6 if dm021 == 2 & living_arrangements == 5
replace hhstruct = 7 if dm021 >= 3 & dm021 <= 7

label define hhstruct_lbl 1 "Married, spouse only" 2 "Married, spouse and children" ///
    3 "Married, spouse away" 4 "Widowed, alone" 5 "Widowed, with children"        ///
    6 "Widowed, with others" 7 "Other unmarried"
label values hhstruct hhstruct_lbl

* Religion: Hindu, Muslim, Christian, Sikh, Other (small groups combined)
gen religion = 5
replace religion = 1 if dm010 == 2
replace religion = 2 if dm010 == 3
replace religion = 3 if dm010 == 4
replace religion = 4 if dm010 == 5
replace religion = . if missing(dm010)

* Caste is DM013: 1 SC, 2 ST, 3 OBC, 4 none of these (used as is)

* BPL or Antyodaya ration card, from the household file
*   CO301: has a ration card (1 yes, 2 no)
*   CO302: card type (1 BPL, 2 Antyodaya, 3 APL, 4 other)
gen bpl = .
replace bpl = 1 if co301 == 1 & (co302 == 1 | co302 == 2)
replace bpl = 0 if co301 == 2 | (co301 == 1 & (co302 == 3 | co302 == 4))

* Simple yes/no variables for the descriptive table
gen widowed   = (dm021 == 2)
gen alone     = (living_arrangements == 1)
gen sc        = (dm013 == 1) if !missing(dm013)
gen st        = (dm013 == 2) if !missing(dm013)
gen poor_mpce = (mpce_quintile <= 2)

* Village or urban ward, for clustering: the first 7 digits of hhid
* (wave, state, village/ward)
gen village = substr(hhid, 1, 7)

* -------------------------------------------------------------
* 4. Final sample: drop anyone missing the outcome or a control
* -------------------------------------------------------------
drop if missing(depressed, age, female, hhstruct, urban, schooling, ///
                dm013, religion, mpce_quintile, stateid)
assert _N == 29627

* Labels (these become the row names in the tables)
label var depressed  "Depressed (CIDI-SF)"
label var any_pen    "Receives any pension"
label var work_pen   "Work-related pension"
label var social_pen "Social pension"
label var oldage_pen "National old-age pension"
label var widow_pen  "Widow pension"
label var other_pen  "Other social pension"
label var bpl        "BPL or Antyodaya card"
label var age        "Age (years)"
label var female     "Female"
label var widowed    "Widowed"
label var alone      "Lives alone"
label var urban      "Urban"
label var schooling  "Years of schooling"
label var sc         "Scheduled Caste"
label var st         "Scheduled Tribe"
label var poor_mpce  "Bottom two MPCE quintiles"

save "$work/analysis.dta", replace
