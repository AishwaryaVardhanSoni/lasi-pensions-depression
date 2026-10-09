* =============================================================
* 04_regressions.do
* Linear probability models of depression on pension receipt.
* Outcome is depressed x 100, so coefficients are percentage points.
* Several people are interviewed per household, so standard errors
* are clustered by household (hhid).
* =============================================================

use "$work/analysis.dta", clear

* --- Control variables ---
* c. = continuous, i. = categories, ib2. = category 2 is the base group
* c.age##c.age = age and age squared
global demo  "c.age##c.age i.female ib2.hhstruct"         // base: married, spouse and children
global ses   "i.urban c.schooling ib3.dm013 i.religion"   // base: rural, OBC, Hindu
global mpce  "i.mpce_quintile"                             // base: poorest quintile
global state "i.stateid"
global all   "$demo $ses $mpce $state"

* -------------------------------------------------------------
* Table 2: adding controls step by step
* -------------------------------------------------------------
eststo clear
eststo m1: reg dep100 any_pen, vce(cluster hhid)
eststo m2: reg dep100 any_pen $demo, vce(cluster hhid)
eststo m3: reg dep100 any_pen $demo $ses, vce(cluster hhid)
eststo m4: reg dep100 any_pen $demo $ses $mpce, vce(cluster hhid)
eststo m5: reg dep100 any_pen $all, vce(cluster hhid)

* Yes/No rows showing which controls each column has
estadd local demo  "No"  : m1
estadd local demo  "Yes" : m2 m3 m4 m5
estadd local ses   "No"  : m1 m2
estadd local ses   "Yes" : m3 m4 m5
estadd local mpce  "No"  : m1 m2 m3
estadd local mpce  "Yes" : m4 m5
estadd local state "No"  : m1 m2 m3 m4
estadd local state "Yes" : m5
estadd ysumm : m1 m2 m3 m4 m5       // adds the mean of the outcome

esttab m1 m2 m3 m4 m5 using "$root/output/tables/table2_main.tex", replace ///
    booktabs label nomtitles keep(any_pen) b(2) se(2)                     ///
    star(* 0.10 ** 0.05 *** 0.01)                                         ///
    stats(demo ses mpce state ymean N r2, fmt(0 0 0 0 2 %9.0fc 3)         ///
          labels("Age, sex, household structure" "Urban, schooling, caste, religion" ///
                 "MPCE quintiles" "State fixed effects"                   ///
                 "Mean of outcome" "Observations" "R-squared"))           ///
    title("Pension receipt and depression\label{tab:main}")              ///
    addnotes("Linear probability models. The outcome is depressed (CIDI-SF) x 100," ///
             "so coefficients are in percentage points. Standard errors clustered by household.")

* -------------------------------------------------------------
* Table 3: work vs. social pensions, and the BPL card
* -------------------------------------------------------------
eststo t1: reg dep100 work_pen social_pen $all, vce(cluster hhid)
eststo t2: reg dep100 work_pen oldage_pen widow_pen other_pen $all, vce(cluster hhid)
eststo t3: reg dep100 work_pen social_pen bpl $all, vce(cluster hhid)
eststo t4: reg dep100 work_pen social_pen $all if bpl == 1, vce(cluster hhid)
estadd ysumm : t1 t2 t3 t4

esttab t1 t2 t3 t4 using "$root/output/tables/table3_pension_type.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)                    ///
    keep(work_pen social_pen oldage_pen widow_pen other_pen bpl)              ///
    order(work_pen social_pen oldage_pen widow_pen other_pen bpl)             ///
    mtitles("By type" "By scheme" "BPL control" "BPL households")             ///
    stats(ymean N r2, fmt(2 %9.0fc 3) labels("Mean of outcome" "Observations" "R-squared")) ///
    title("Work-related and social pensions\label{tab:type}")                ///
    addnotes("All columns include the controls and state fixed effects of Table 2, column 5." ///
             "Outcome x 100. Standard errors clustered by household.")

* -------------------------------------------------------------
* Table 4 (appendix): robustness checks on the main estimate
* -------------------------------------------------------------
* (2) with LASI survey weights
eststo r2: reg dep100 any_pen $all [pw = indiaindividualweight], vce(cluster hhid)
* (3) standard errors clustered by village/ward instead of household
eststo r3: reg dep100 any_pen $all, vce(cluster village)
* (4) broader pension definition (adds expected work pensions)
eststo r4: reg dep100 any_pen_broad $all, vce(cluster hhid)
* (5) without MPCE and household structure, which pensions might affect
eststo r5: reg dep100 any_pen c.age##c.age i.female $ses $state, vce(cluster hhid)
* (6) probit instead of OLS; margins gives the average effect of a pension,
*     multiplied by 100 to match the other columns
probit depressed i.any_pen $all, vce(cluster hhid)
eststo r6: margins, dydx(any_pen) expression(100*predict(pr)) post

* rename() puts all six estimates on one row
esttab m5 r2 r3 r4 r5 r6 using "$root/output/tables/table4_robustness.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)        ///
    rename(any_pen_broad any_pen 1.any_pen any_pen) keep(any_pen)   ///
    mtitles("Preferred" "Weighted" "Village SE" "Broad" "Lean" "Probit") ///
    stats(N, fmt(%9.0fc) labels("Observations"))                    ///
    title("Robustness of the pension coefficient\label{tab:robust}") ///
    addnotes("(1) Table 2, column 5. (2) LASI national weights. (3) Clustered by village/ward." ///
             "(4) Adds expected work-related pensions. (5) Drops MPCE and household structure." ///
             "(6) Probit average marginal effect. Coefficients in percentage points.")

* -------------------------------------------------------------
* Table 5 (appendix): does the pension estimate differ by group?
* -------------------------------------------------------------
* pen_x_group = pension x group. Its coefficient is the extra
* difference for that group; its p-value tests whether groups differ.
gen pen_x_group = any_pen * female
eststo h1: reg dep100 any_pen pen_x_group $all, vce(cluster hhid)

replace pen_x_group = any_pen * urban
eststo h2: reg dep100 any_pen pen_x_group $all, vce(cluster hhid)

gen old70 = (age >= 70)
replace pen_x_group = any_pen * old70
eststo h3: reg dep100 any_pen pen_x_group old70 $all, vce(cluster hhid)

replace pen_x_group = any_pen * bpl
eststo h4: reg dep100 any_pen pen_x_group bpl $all, vce(cluster hhid)

label var pen_x_group "Pension x group"

esttab h1 h2 h3 h4 using "$root/output/tables/table5_heterogeneity.tex", replace ///
    booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)       ///
    keep(any_pen pen_x_group)                                      ///
    mtitles("Women" "Urban" "Aged 70+" "BPL card")                 ///
    stats(N, fmt(%9.0fc) labels("Observations"))                   ///
    title("Heterogeneity in the pension coefficient\label{tab:het}") ///
    addnotes("Group in column heading interacted with pension receipt; full controls as in Table 2, column 5.")

* -------------------------------------------------------------
* Figure 1: pension estimates with 95% confidence intervals
* -------------------------------------------------------------
coefplot (m5, keep(any_pen)) (t2, keep(work_pen oldage_pen widow_pen other_pen)), ///
    xline(0, lpattern(dash) lcolor(gs8)) nooffsets legend(off)        ///
    mcolor(black) ciopts(lcolor(black))                                ///
    coeflabels(any_pen = "Any pension" work_pen = "Work-related pension" ///
               oldage_pen = "National old-age pension"                ///
               widow_pen = "Widow pension" other_pen = "Other social pension") ///
    xtitle("Difference in depression prevalence (percentage points)") ///
    graphregion(color(white))
graph export "$root/output/figures/figure1_coefplot.pdf", replace

* -------------------------------------------------------------
* Numbers quoted in the paper (estimates and 95% confidence intervals)
* -------------------------------------------------------------
est restore m5
lincom any_pen
est restore t1
lincom work_pen
lincom social_pen
lincom work_pen - social_pen     // are the two pension types different?
