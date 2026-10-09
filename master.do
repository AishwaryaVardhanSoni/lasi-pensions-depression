* =============================================================
* master.do
* Pension receipt and depression among older adults in India
* Data: LASI Wave 1 (2017-18)
* Author: Aishwarya Vardhan Soni
*
* Running this file runs the whole project: it cleans the raw
* data and makes every table and the figure in the paper.
*
* Before running:
*  1. Change the three folder paths below.
*  2. Install two packages (only needed once):
*       ssc install estout
*       ssc install coefplot
* =============================================================

clear all
set more off
version 17

* --- Folder paths ---
global root "D:/Predoc_files/lasi-pensions-depression"   // project folder
global raw  "D:/Predoc_files/data/LASI"                  // raw LASI data (never edited)
global work "D:/Predoc_files/data/work"                  // cleaned data

* Create the output folders if they don't exist yet
cap mkdir "$work"
cap mkdir "$root/output"
cap mkdir "$root/output/tables"
cap mkdir "$root/output/figures"
cap mkdir "$root/output/logs"

* --- Run the project ---
cap log close
log using "$root/output/logs/master.log", replace text

do "$root/code/01_sample.do"        // load data, keep people aged 60+
do "$root/code/02_variables.do"     // make outcome, pension and control variables
do "$root/code/03_descriptives.do"  // Table 1
do "$root/code/04_regressions.do"   // Tables 2-5 and Figure 1

log close
