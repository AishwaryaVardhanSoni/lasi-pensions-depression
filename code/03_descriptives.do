*==============================================================================
* 03_descriptives.do
*
* Table 1: characteristics of the estimation sample by pension status.
* Means are weighted by LASI national individual weights; observation counts
* are unweighted. The work- and social-pension columns overlap for the few
* respondents who receive both.
*
* Input : $work/02_analysis.dta
* Output: $tables/table1_descriptives.tex
*==============================================================================

use "$work/02_analysis.dta", clear

local rows depressed any_pen work_pen social_pen age female widowed         ///
           living_alone urban schooling sc st bpl_card mpce_bottom2

eststo clear
eststo d_all:    estpost summarize `rows' [aw = indiaindividualweight]
eststo d_nopen:  estpost summarize `rows' if any_pen == 0    [aw = indiaindividualweight]
eststo d_work:   estpost summarize `rows' if work_pen == 1   [aw = indiaindividualweight]
eststo d_social: estpost summarize `rows' if social_pen == 1 [aw = indiaindividualweight]

esttab d_all d_nopen d_work d_social using "$tables/table1_descriptives.tex", ///
    replace booktabs label nonumbers                                       ///
    cells("mean(fmt(3))") collabels(none)                                  ///
    mtitles("All" "No pension" "Work pension" "Social pension")           ///
    stats(N, fmt(%9.0fc) labels("Observations"))                          ///
    title("Characteristics of respondents aged 60+ by pension status\label{tab:desc}") ///
    addnotes("Means weighted by LASI national individual weights; observations unweighted." ///
             "Work- and social-pension columns overlap for respondents receiving both.")

* Depression prevalence quoted in the text: unweighted, then weighted
summarize depressed
summarize depressed [aw = indiaindividualweight]
