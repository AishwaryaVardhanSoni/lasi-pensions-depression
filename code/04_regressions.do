*==============================================================================
* 04_regressions.do
*
* Linear probability models of depression on pension receipt.
*   Table 2 : controls added step by step
*   Table 3 : work-related vs. social pensions, by scheme, and eligibility
*   Table 4 : robustness of the preferred specification (appendix)
*   Table 5 : heterogeneity by group (appendix)
*   Figure 1: pension coefficients from the preferred specification
*
* The outcome is scaled 0/100, so coefficients are in percentage points.
* Several respondents are interviewed per household, so standard errors are
* clustered by household; Table 4 also clusters by village/urban ward.
*
* Input : $work/02_analysis.dta
* Output: $tables/table2_main.tex ... table5_heterogeneity.tex,
*         $figs/figure1_coefplot.pdf
*==============================================================================

use "$work/02_analysis.dta", clear

*------------------------------------------------------------------------------
* Control sets (reference groups in comments)
*------------------------------------------------------------------------------
local c_demo  "c.age##c.age i.female ib2.hhstruct"   // married, spouse + children
local c_ses   "i.urban c.schooling ib3.caste i.religion" // rural, OBC, Hindu
local c_mpce  "i.mpce_quintile"                      // poorest quintile
local c_state "i.stateid"
local full    "`c_demo' `c_ses' `c_mpce' `c_state'"

*------------------------------------------------------------------------------
* Table 2: pension receipt and depression, adding controls step by step
*------------------------------------------------------------------------------
local spec1 ""
local spec2 "`c_demo'"
local spec3 "`c_demo' `c_ses'"
local spec4 "`c_demo' `c_ses' `c_mpce'"
local spec5 "`full'"

eststo clear
forvalues j = 1/5 {
    eststo m`j': regress dep_pp any_pen `spec`j'', vce(cluster hh_id)
}
assert e(N) == 29627                     // every column uses the same sample

estadd ysumm : m1 m2 m3 m4 m5            // adds the mean of the outcome
estadd local demo  "No"  : m1
estadd local demo  "Yes" : m2 m3 m4 m5
estadd local ses   "No"  : m1 m2
estadd local ses   "Yes" : m3 m4 m5
estadd local mpce  "No"  : m1 m2 m3
estadd local mpce  "Yes" : m4 m5
estadd local state "No"  : m1 m2 m3 m4
estadd local state "Yes" : m5

esttab m1 m2 m3 m4 m5 using "$tables/table2_main.tex",                     ///
    replace booktabs label nomtitles keep(any_pen) b(2) se(2)              ///
    star(* 0.10 ** 0.05 *** 0.01)                                          ///
    stats(demo ses mpce state ymean N r2,                                  ///
          fmt(0 0 0 0 2 %9.0fc 3)                                          ///
          labels("Age, sex, household structure"                           ///
                 "Urban, schooling, caste, religion"                       ///
                 "MPCE quintiles" "State fixed effects"                     ///
                 "Mean of outcome" "Observations" "R-squared"))            ///
    title("Pension receipt and depression\label{tab:main}")               ///
    addnotes("Linear probability models. The outcome is depressed (CIDI-SF) x 100,"   ///
             "so coefficients are in percentage points. Standard errors clustered by household.")

*------------------------------------------------------------------------------
* Table 3: work-related vs. social pensions, by scheme, and eligibility
*   (1) the two pension types as separate regressors
*   (2) social pensions split by scheme
*   (3) adds the BPL/Antyodaya card, the old-age pension's eligibility rule
*   (4) restricted to households holding a BPL/Antyodaya card
*------------------------------------------------------------------------------
eststo t1: regress dep_pp work_pen social_pen `full', vce(cluster hh_id)
eststo t2: regress dep_pp work_pen oldage_pen widow_pen other_social `full', ///
           vce(cluster hh_id)
eststo t3: regress dep_pp work_pen social_pen bpl_card `full', vce(cluster hh_id)
eststo t4: regress dep_pp work_pen social_pen `full' if bpl_card == 1,      ///
           vce(cluster hh_id)
estadd ysumm : t1 t2 t3 t4

esttab t1 t2 t3 t4 using "$tables/table3_pension_type.tex",                 ///
    replace booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)        ///
    keep(work_pen social_pen oldage_pen widow_pen other_social bpl_card)   ///
    order(work_pen social_pen oldage_pen widow_pen other_social bpl_card)  ///
    mtitles("By type" "By scheme" "BPL control" "BPL households")          ///
    stats(ymean N r2, fmt(2 %9.0fc 3)                                      ///
          labels("Mean of outcome" "Observations" "R-squared"))            ///
    title("Work-related and social pensions\label{tab:type}")             ///
    addnotes("All columns include the controls and state fixed effects of Table 2, column 5."  ///
             "Outcome x 100. Standard errors clustered by household.")

*------------------------------------------------------------------------------
* Table 4 (appendix): robustness of the preferred specification
*   (1) preferred specification (Table 2, column 5)
*   (2) LASI national survey weights
*   (3) standard errors clustered by village/urban ward
*   (4) broader treatment that adds expected work-related pensions
*   (5) drops MPCE and household structure, which pensions may affect
*   (6) probit; average marginal effect of pension receipt, x 100
*------------------------------------------------------------------------------
eststo r2: regress dep_pp any_pen `full' [pw = indiaindividualweight],      ///
           vce(cluster hh_id)
eststo r3: regress dep_pp any_pen `full', vce(cluster ssu_id)
eststo r4: regress dep_pp any_pen_broad `full', vce(cluster hh_id)
eststo r5: regress dep_pp any_pen c.age##c.age i.female `c_ses' `c_state',  ///
           vce(cluster hh_id)
probit depressed i.any_pen `full', vce(cluster hh_id)
eststo r6: margins, dydx(any_pen) expression(100*predict(pr)) post

esttab m5 r2 r3 r4 r5 r6 using "$tables/table4_robustness.tex",             ///
    replace booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)        ///
    rename(any_pen_broad any_pen 1.any_pen any_pen)                        ///
    keep(any_pen)                                                          ///
    mtitles("Preferred" "Weighted" "Village SE" "Broad" "Lean" "Probit")   ///
    stats(N, fmt(%9.0fc) labels("Observations"))                           ///
    title("Robustness of the pension coefficient\label{tab:robust}")      ///
    addnotes("(1) Table 2, column 5. (2) LASI national weights. (3) Clustered by village/ward." ///
             "(4) Adds expected work-related pensions. (5) Drops MPCE and household structure." ///
             "(6) Probit average marginal effect. Coefficients in percentage points.")

*------------------------------------------------------------------------------
* Table 5 (appendix): heterogeneity
*   Each column interacts pension receipt with one group indicator. The
*   pension row is the association outside the group; the interaction row is
*   the difference within it, and its t-test is the test of heterogeneity.
*   Female and urban main effects are already in `full'; the other two groups
*   need their own main effect.
*------------------------------------------------------------------------------
local main_female   ""
local main_urban    ""
local main_old70    "old70"
local main_bpl_card "bpl_card"

foreach g in female urban old70 bpl_card {
    capture drop pen_x_group
    gen byte pen_x_group = any_pen * `g'
    label variable pen_x_group "Pension x group"
    eststo h_`g': regress dep_pp any_pen pen_x_group `main_`g'' `full',    ///
                  vce(cluster hh_id)
}

esttab h_female h_urban h_old70 h_bpl_card                                  ///
    using "$tables/table5_heterogeneity.tex",                              ///
    replace booktabs label b(2) se(2) star(* 0.10 ** 0.05 *** 0.01)        ///
    keep(any_pen pen_x_group)                                              ///
    mtitles("Women" "Urban" "Aged 70+" "BPL card")                         ///
    stats(N, fmt(%9.0fc) labels("Observations"))                           ///
    title("Heterogeneity in the pension coefficient\label{tab:het}")      ///
    addnotes("Group in column heading interacted with pension receipt; full controls as in Table 2, column 5.")
drop pen_x_group                         // kept until here so esttab can use its label

*------------------------------------------------------------------------------
* Figure 1: pension coefficients from the preferred specification
*------------------------------------------------------------------------------
coefplot (m5, keep(any_pen))                                                ///
         (t2, keep(work_pen oldage_pen widow_pen other_social)),            ///
    xline(0, lpattern(dash) lcolor(gs8)) nooffsets legend(off)              ///
    mcolor(black) ciopts(lcolor(black))                                     ///
    coeflabels(any_pen      = "Any pension"                                 ///
               work_pen     = "Work-related pension"                        ///
               oldage_pen   = "National old-age pension"                    ///
               widow_pen    = "Widow pension"                               ///
               other_social = "Other social pension")                       ///
    xtitle("Difference in depression prevalence (percentage points)")       ///
    graphregion(color(white))
graph export "$figs/figure1_coefplot.pdf", replace

*------------------------------------------------------------------------------
* Numbers quoted in the text: estimates with 95% confidence intervals
*------------------------------------------------------------------------------
estimates restore m5
lincom any_pen                           // preferred estimate
estimates restore t1
lincom work_pen
lincom social_pen
lincom work_pen - social_pen             // do the two pension types differ?
