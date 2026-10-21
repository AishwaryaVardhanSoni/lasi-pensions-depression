*******************************************************
* lasi_pensions_depression.do -- pension receipt & depression among older adults in India
* LASI wave 1 (2017-18)
* Aishwarya Vardhan Soni
*
* this one file does everything, top to bottom:
*   part 1 - load the LASI files and keep people aged 60+
*   part 2 - depression outcome, pension variables, controls and the final sample
*   part 3 - table 1 (characteristics by pension status)
*   part 4 - regressions: tables 2-5 and figure 1
*
* before running:
*  - change the 3 paths below
*  - you need estout and coefplot (only once):
*      ssc install estout
*      ssc install coefplot
*******************************************************

clear all
set more off
version 17

* paths
global root "D:/Predoc_files/lasi-pensions-depression"   // project folder
global raw "D:/Predoc_files/data/LASI" // raw LASI files, never edit these
global work "D:/Predoc_files/data/work"  // cleaned data goes here

* make the output folders if they aren't there yet
cap mkdir "$work"
cap mkdir "$root/output"
cap mkdir "$root/output/tables"
cap mkdir "$root/output/figures"
cap mkdir "$root/output/logs"

cap log close
log using "$root/output/logs/lasi_pensions_depression.log", replace text


******** PART 1 - load the data, keep 60+ ********

* household file - only need the ration card questions (CO301, CO302)
* (the file has way too many variables to open in full)
use hhid co301 co302 using "$raw/2_LASI_W1_Household_data.dta", clear
isid hhid  // one row per hh
save "$work/household.dta", replace

* individual file
use prim_key hhid stateid residence living_arrangements mpce_quintile indiaindividualweight ///
    dm003 dm005 dm006 dm007 dm010 dm013 dm021 we412 sw202a sw202b sw202d sw202e ///
    mh201 mh204 mh205 mh206 mh207 mh208 mh209 mh210 mh211 mh214 mh217 mh218 mh219 mh220 mh221 mh222 ///
    using "$raw/3_LASI_W1_Individual_data.dta", clear
*des

* 60+ only, since the social pension questions are only asked to them.
* stata treats missing age as a very large number so dropping missing too
keep if dm005 >= 60 & !missing(dm005)
assert _N == 31464 // same as the LASI user guide

* merge in the ration card questions
merge m:1 hhid using "$work/household.dta", keep(master match)
tab _merge // a few people have no household interview
drop _merge


******** PART 2 - depression, pensions, controls ********

**** depression (CIDI-SF) ****
* LASI asks about depression in 2 parts:
*   sad mood (MH201). if yes and it lasted most of the day nearly every day, 7 symptoms are asked (MH204-MH211)
*   loss of interest (MH214). same idea, 6 symptoms (MH217-MH222)
* depressed = 3+ symptoms in either part. symptoms that weren't asked count as no

* anycount = how many of these vars are equal to 1
egen n_mood = anycount(mh204 mh205 mh208 mh209 mh210 mh211), values(1)
replace n_mood = n_mood + 1 if mh206 == 1 | mh207 == 1 // appetite loss or gain = 1 symptom
egen n_interest = anycount(mh217 mh218 mh219 mh220 mh221 mh222), values(1)
*tab n_mood n_interest

gen depressed = 0
replace depressed = 1 if n_mood>=3 | n_interest>=3

* people who were never asked the depression questions (probably proxy interviews)
* -> missing, not "not depressed"
replace depressed = . if missing(mh201) & missing(mh214)

count if missing(depressed)
assert r(N) == 818
count if depressed == 1
assert r(N) == 2317

* x100 so the regression coefficients are in percentage points
gen dep100 = 100*depressed

**** pensions ****
* work pension, WE412: 1 = getting it now, 2 = expects one later, 3 = neither
* only asked to people who worked in the organised sector, everyone else gets 0
gen work_pen = (we412==1)
gen work_pen_future = (we412==2)

* social pensions, SW202 ("are you availing this scheme?", 1 = yes)
*   a = national old age pension (needs a BPL card), b = widow pension, d and e = other schemes
* c is Annapurna which gives food grains not cash, so leaving it out
gen oldage_pen = (sw202a == 1)
gen widow_pen = (sw202b == 1)
gen other_pen = (sw202d == 1 | sw202e == 1)
gen social_pen = (oldage_pen == 1 | widow_pen == 1 | other_pen == 1)

* main variable - currently receives any pension
gen any_pen = (work_pen == 1 | social_pen == 1)

* broader one for a robustness check (also counts expected work pensions)
gen any_pen_broad = (any_pen == 1 | work_pen_future == 1)
*tab any_pen any_pen_broad

**** controls ****
gen age = dm005
gen female = (dm003 == 2)
gen urban = (residence == 2)

* years of schooling, 0 for people who never went to school (DM006 = 2)
gen schooling = dm007
replace schooling = 0 if dm006 == 2

* household structure = marital status (DM021) combined with who they live with.
* combining them because no widowed person lives with a spouse, so the two can't be separated
*  DM021: 1 married, 2 widowed, 3-7 divorced/separated/never married etc
*  living_arrangements: 1 alone, 2 spouse only, 3 spouse and children, 4 children only, 5 others
gen hhstruct = .
replace hhstruct = 1 if dm021 == 1 & living_arrangements == 2
replace hhstruct = 2 if dm021 == 1 & living_arrangements == 3
replace hhstruct = 3 if dm021 == 1 & inlist(living_arrangements, 1, 4, 5)
replace hhstruct = 4 if dm021 == 2 & living_arrangements == 1
replace hhstruct = 5 if dm021 == 2 & living_arrangements == 4
replace hhstruct = 6 if dm021 == 2 & living_arrangements == 5
replace hhstruct = 7 if dm021 >= 3 & dm021 <= 7
*tab hhstruct, m

label define hhstruct_lbl 1 "Married, spouse only" 2 "Married, spouse and children" 3 "Married, spouse away" ///
    4 "Widowed, alone" 5 "Widowed, with children" 6 "Widowed, with others" 7 "Other unmarried"
label values hhstruct hhstruct_lbl

* religion: hindu, muslim, christian, sikh, other (the small groups put together)
gen religion = 5
replace religion = 1 if dm010 == 2
replace religion = 2 if dm010 == 3
replace religion = 3 if dm010 == 4
replace religion = 4 if dm010 == 5
replace religion = . if missing(dm010)

* caste = DM013 as it is (1 SC, 2 ST, 3 OBC, 4 none of these)

* BPL or Antyodaya ration card, from the household file
* CO301 = has a ration card (1 yes, 2 no), CO302 = card type (1 BPL, 2 Antyodaya, 3 APL, 4 other)
gen bpl = .
replace bpl = 1 if co301 == 1 & (co302 == 1 | co302 == 2)
replace bpl = 0 if co301 == 2 | (co301 == 1 & (co302 == 3 | co302 == 4))

* 0/1 variables for table 1
gen widowed = (dm021 == 2)
gen alone = (living_arrangements == 1)
gen sc = (dm013 == 1) if !missing(dm013)
gen st = (dm013 == 2) if !missing(dm013)
gen poor_mpce = (mpce_quintile <= 2)

* village/urban ward for clustering = first 7 digits of hhid (wave, state, village/ward)
gen village = substr(hhid, 1, 7)

**** final sample: drop anyone missing the outcome or a control ****
drop if missing(depressed, age, female, hhstruct, urban, schooling, dm013, religion, mpce_quintile, stateid)
assert _N == 29627

* labels (these end up as the row names in the tables)
label var depressed "Depressed (CIDI-SF)"
label var any_pen "Receives any pension"
label var work_pen "Work-related pension"
label var social_pen "Social pension"
label var oldage_pen "National old-age pension"
label var widow_pen "Widow pension"
label var other_pen "Other social pension"
label var bpl "BPL or Antyodaya card"
label var age "Age (years)"
label var female "Female"
label var widowed "Widowed"
label var alone "Lives alone"
label var urban "Urban"
label var schooling "Years of schooling"
label var sc "Scheduled Caste"
label var st "Scheduled Tribe"
label var poor_mpce "Bottom two MPCE quintiles"

* saving the clean data, part 4 starts from this
save "$work/analysis.dta", replace


******** PART 3 - table 1, characteristics by pension status (means use the LASI survey weights) ********

global tab1vars depressed any_pen work_pen social_pen age female widowed alone urban schooling sc st bpl poor_mpce

* one column per group
eststo clear
eststo: estpost summarize $tab1vars [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if any_pen == 0 [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if work_pen == 1 [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if social_pen == 1 [aw = indiaindividualweight]

esttab using "$root/output/tables/table1_descriptives.tex", replace booktabs label nonumbers cells("mean(fmt(3))") collabels(none) ///
    mtitles("All" "No pension" "Work pension" "Social pension") stats(N, fmt(%9.0fc) labels("Observations")) ///
    title("Characteristics of respondents aged 60+ by pension status\label{tab:desc}") ///
    addnotes("Means weighted by LASI national individual weights; observations unweighted." ///
    "Work- and social-pension columns overlap for respondents receiving both.")

* depression rate for the text, unweighted and then weighted
sum depressed
sum depressed [aw = indiaindividualweight]


******** PART 4 - regressions ********
* LPMs of depression on pension receipt. outcome = depressed x 100 so coefficients are in pp
* several people per household get interviewed -> SEs clustered by household (hhid)

* reload the clean data before the regressions
use "$work/analysis.dta", clear

* controls
* c. = continuous, i. = categorical, ib2. = category 2 is the base. c.age##c.age gives age and age squared
global demo "c.age##c.age i.female ib2.hhstruct"  // base: married, spouse and children
global ses "i.urban c.schooling ib3.dm013 i.religion" // base: rural, OBC, hindu
global mpce "i.mpce_quintile" // base = poorest quintile
global state "i.stateid"
global all "$demo $ses $mpce $state"

********** TABLE 2 - adding the controls one group at a time **********
eststo clear
eststo m1: reg dep100 any_pen, vce(cluster hhid)
eststo m2: reg dep100 any_pen $demo, vce(cluster hhid)
eststo m3: reg dep100 any_pen $demo $ses, vce(cluster hhid)
eststo m4: reg dep100 any_pen $demo $ses $mpce, vce(cluster hhid)
eststo m5: reg dep100 any_pen $all, vce(cluster hhid)

* yes/no rows for which controls are in each column
estadd local demo "No" : m1
estadd local demo "Yes" : m2 m3 m4 m5
estadd local ses "No" : m1 m2
estadd local ses "Yes" : m3 m4 m5
estadd local mpce "No" : m1 m2 m3
estadd local mpce "Yes" : m4 m5
estadd local state "No" : m1 m2 m3 m4
estadd local state "Yes" : m5
estadd ysumm : m1 m2 m3 m4 m5 // mean of the outcome

esttab m1 m2 m3 m4 m5 using "$root/output/tables/table2_main.tex", replace booktabs label nomtitles keep(any_pen) b(2) se(2) ///
    star(* 0.10 ** 0.05 *** 0.01) stats(demo ses mpce state ymean N r2, fmt(0 0 0 0 2 %9.0fc 3) ///
    labels("Age, sex, household structure" "Urban, schooling, caste, religion" "MPCE quintiles" "State fixed effects" ///
    "Mean of outcome" "Observations" "R-squared")) ///
    title("Pension receipt and depression\label{tab:main}") ///
    addnotes("Linear probability models. The outcome is depressed (CIDI-SF) x 100," ///
    "so coefficients are in percentage points. Standard errors clustered by household.")

********** TABLE 3 - work vs social pensions + the BPL card **********
eststo t1: reg dep100 work_pen social_pen $all, vce(cluster hhid)
eststo t2: reg dep100 work_pen oldage_pen widow_pen other_pen $all, vce(cluster hhid)
eststo t3: reg dep100 work_pen social_pen bpl $all, vce(cluster hhid)
eststo t4: reg dep100 work_pen social_pen $all if bpl == 1, vce(cluster hhid)
estadd ysumm : t1 t2 t3 t4

esttab t1 t2 t3 t4 using "$root/output/tables/table3_pension_type.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) keep(work_pen social_pen oldage_pen widow_pen other_pen bpl) ///
    order(work_pen social_pen oldage_pen widow_pen other_pen bpl) ///
    mtitles("By type" "By scheme" "BPL control" "BPL households") ///
    stats(ymean N r2, fmt(2 %9.0fc 3) labels("Mean of outcome" "Observations" "R-squared")) ///
    title("Work-related and social pensions\label{tab:type}") ///
    addnotes("All columns include the controls and state fixed effects of Table 2, column 5." ///
    "Outcome x 100. Standard errors clustered by household.")

********** TABLE 4 (appendix) - robustness of the main estimate **********
* col 2: with the LASI survey weights
eststo r2: reg dep100 any_pen $all [pw = indiaindividualweight], vce(cluster hhid)
* col 3: SEs clustered by village/ward instead of household
eststo r3: reg dep100 any_pen $all, vce(cluster village)
* col 4: broader pension definition (+ expected work pensions)
eststo r4: reg dep100 any_pen_broad $all, vce(cluster hhid)
* col 5: no MPCE and no household structure, since pensions might affect those
eststo r5: reg dep100 any_pen c.age##c.age i.female $ses $state, vce(cluster hhid)
* col 6: probit instead of OLS. margins gives the average effect of a pension, x100 to match the other cols
probit depressed i.any_pen $all, vce(cluster hhid)
eststo r6: margins, dydx(any_pen) expression(100*predict(pr)) post

* rename() puts all 6 estimates on the same row
esttab m5 r2 r3 r4 r5 r6 using "$root/output/tables/table4_robustness.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) rename(any_pen_broad any_pen 1.any_pen any_pen) keep(any_pen) ///
    mtitles("Preferred" "Weighted" "Village SE" "Broad" "Lean" "Probit") stats(N, fmt(%9.0fc) labels("Observations")) ///
    title("Robustness of the pension coefficient\label{tab:robust}") ///
    addnotes("(1) Table 2, column 5. (2) LASI national weights. (3) Clustered by village/ward." ///
    "(4) Adds expected work-related pensions. (5) Drops MPCE and household structure." ///
    "(6) Probit average marginal effect. Coefficients in percentage points.")

********** TABLE 5 (appendix) - does the pension estimate differ by group? **********
* pen_x_group = pension x group. its coefficient is the extra difference for that group,
* and its p value tests whether the groups are different
gen pen_x_group = any_pen * female
eststo h1: reg dep100 any_pen pen_x_group $all, vce(cluster hhid)

replace pen_x_group = any_pen * urban
eststo h2: reg dep100 any_pen pen_x_group $all, vce(cluster hhid)

gen old70 = (age >= 70)
replace pen_x_group = any_pen * old70
eststo h3: reg dep100 any_pen pen_x_group old70 $all, vce(cluster hhid)

replace pen_x_group = any_pen * bpl
eststo h4: reg dep100 any_pen pen_x_group bpl $all, vce(cluster hhid)
*sum pen_x_group

label var pen_x_group "Pension x group"

esttab h1 h2 h3 h4 using "$root/output/tables/table5_heterogeneity.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) keep(any_pen pen_x_group) ///
    mtitles("Women" "Urban" "Aged 70+" "BPL card") stats(N, fmt(%9.0fc) labels("Observations")) ///
    title("Heterogeneity in the pension coefficient\label{tab:het}") ///
    addnotes("Group in column heading interacted with pension receipt; full controls as in Table 2, column 5.")

********** FIGURE 1 - pension estimates with 95% CIs **********
coefplot (m5, keep(any_pen)) (t2, keep(work_pen oldage_pen widow_pen other_pen)), ///
    xline(0, lpattern(dash) lcolor(gs8)) nooffsets legend(off) mcolor(black) ciopts(lcolor(black)) ///
    coeflabels(any_pen = "Any pension" work_pen = "Work-related pension" oldage_pen = "National old-age pension" ///
    widow_pen = "Widow pension" other_pen = "Other social pension") ///
    xtitle("Difference in depression prevalence (percentage points)") graphregion(color(white))
graph export "$root/output/figures/figure1_coefplot.pdf", replace

* numbers quoted in the paper (estimates + 95% CIs)
est restore m5
lincom any_pen
est restore t1
lincom work_pen
lincom social_pen
lincom work_pen - social_pen // are the 2 pension types different?

log close
