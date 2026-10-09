* =============================================================
* 03_descriptives.do
* Table 1: average characteristics by pension status.
* Means use the LASI survey weights.
* =============================================================

use "$work/analysis.dta", clear

global tab1vars depressed any_pen work_pen social_pen age female widowed ///
                alone urban schooling sc st bpl poor_mpce

* One column per group
eststo clear
eststo: estpost summarize $tab1vars [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if any_pen == 0    [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if work_pen == 1   [aw = indiaindividualweight]
eststo: estpost summarize $tab1vars if social_pen == 1 [aw = indiaindividualweight]

esttab using "$root/output/tables/table1_descriptives.tex", replace ///
    booktabs label nonumbers cells("mean(fmt(3))") collabels(none)   ///
    mtitles("All" "No pension" "Work pension" "Social pension")     ///
    stats(N, fmt(%9.0fc) labels("Observations"))                    ///
    title("Characteristics of respondents aged 60+ by pension status\label{tab:desc}") ///
    addnotes("Means weighted by LASI national individual weights; observations unweighted." ///
             "Work- and social-pension columns overlap for respondents receiving both.")

* Depression rate for the text: unweighted, then weighted
sum depressed
sum depressed [aw = indiaindividualweight]
