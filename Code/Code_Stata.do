*******************************************************
* DESCRIPTIVE T-TESTS
*******************************************************

* North vs South
ttest employment, by(state)
ttest age, by(state)
ttest leverage, by(state)

* North Treated vs North Untreated
ttest employment if state==1, by(treated2020)
ttest age if state==1, by(treated2020)
ttest leverage if state==1, by(treated2020)

* North Treated vs North & South Untreated
ttest employment, by(treated2020)
ttest age, by(treated2020)
ttest leverage, by(treated2020)


*******************************************************
* DESCRIPTIVE T-TESTS BY YEAR
*******************************************************

* North vs South
ttest employment if year==2018, by(state)
ttest employment if year==2019, by(state)
ttest employment if year==2020, by(state)

* North Treated vs North Untreated
ttest employment if year==2018 & state==1, by(treated2020)
ttest employment if year==2019 & state==1, by(treated2020)
ttest employment if year==2020 & state==1, by(treated2020)

* North Treated vs North & South Untreated
ttest employment if year==2018, by(treated2020)
ttest employment if year==2019, by(treated2020)
ttest employment if year==2020, by(treated2020)


*******************************************************
* LPM, LOGIT AND PROBIT
*******************************************************

sort id year
by id: gen employment_2019 = employment[_n-1] if year == 2020 & year[_n-1] == 2019
keep if state == 1 & year == 2020

* MPL
regress loan leverage employment_2019 age i.industry, robust

* Logit
logit loan leverage employment_2019 age i.industry, nolog
margins, dydx(*)

* Probit
probit loan leverage employment_2019 age i.industry, nolog
margins, dydx(*)


*******************************************************
* PREDICTIONS
*******************************************************

quietly regress loan leverage employment_2019 age i.industry
predict xb_lpm, xb
predict pr_lpm

quietly logit loan leverage employment_2019 age i.industry
predict xb_logit, xb
predict pr_logit, pr

quietly probit loan leverage employment_2019 age i.industry
predict xb_probit, xb
predict pr_probit, pr

summarize loan pr_lpm xb_logit pr_logit xb_probit pr_probit, sep(2)


*******************************************************
* MARGINAL EFFECTS AT THE MEAN
*******************************************************

quietly logit loan leverage employment_2019 age i.industry
margins, predict(pr) dydx(*) atmean

quietly probit loan leverage employment_2019 age i.industry
margins, predict(pr) dydx(*) atmean


*******************************************************
* AVERAGE MARGINAL EFFECTS
*******************************************************

quietly logit loan leverage employment_2019 age i.industry
margins, predict(pr) dydx(*)

quietly probit loan leverage employment_2019 age i.industry
margins, predict(pr) dydx(*)


*******************************************************
* RELOAD FULL DATA BEFORE PANEL ANALYSIS
*******************************************************

use "\\homeblue02\qclm20\DUDE\Desktop\Micro codes\Data.dta", clear


*******************************************************
* PANEL
*******************************************************

xtset id year

* POLS
reg employment loan leverage age i.industry i.year

* FE
xtreg employment loan leverage age i.year, fe

* FD
reg D.employment D.loan D.leverage i.year


*******************************************************
* PARALLEL TRENDS BEFORE MATCHING
*******************************************************

preserve

capture drop treated2020
bysort id: egen treated2020 = max(year == 2020 & loan == 1)

tempfile base tn un au
save `base', replace


* Treated North
use `base', clear
keep if state == 1 & treated2020 == 1
collapse (mean) treated_north = employment, by(year)
save `tn', replace


* Untreated North
use `base', clear
keep if state == 1 & treated2020 == 0
collapse (mean) untreated_north = employment, by(year)
save `un', replace


* All untreated
use `base', clear
keep if treated2020 == 0
collapse (mean) all_untreated = employment, by(year)
save `au', replace


* Merge trend series
use `tn', clear
merge 1:1 year using `un', nogen
merge 1:1 year using `au', nogen

list year treated_north untreated_north all_untreated, clean noobs


* Treated North vs Untreated North
twoway ///
    (connected treated_north year, sort msymbol(o)) ///
    (connected untreated_north year, sort msymbol(triangle)), ///
    title("treated north vs untreated north") ///
    xtitle("period") ///
    ytitle("mean employment") ///
    xlabel(2018 "end 2018" ///
           2019 "end 2019" ///
           2020 "end 2020") ///
    xline(2019, lpattern(dash) lcolor(red)) ///
    legend(order(1 "treated north" ///
                 2 "untreated north")) ///
    name(g_north, replace)


* Treated North vs All Untreated
twoway ///
    (connected treated_north year, sort msymbol(o)) ///
    (connected all_untreated year, sort msymbol(square)), ///
    title("treated north vs all untreated") ///
    xtitle("period") ///
    ytitle("mean employment") ///
    xlabel(2018 "end 2018" ///
           2019 "end 2019" ///
           2020 "fin 2020") ///
    xline(2019, lpattern(dash) lcolor(red)) ///
    legend(order(1 "treated north" ///
                 2 "all untreated")) ///
    name(g_alluntreated, replace)


* Combine graphs
graph combine g_north g_alluntreated, ///
    title("parallel trends inspection")

restore


*******************************************************
* MATCHING IN ALL UNTREATED SAMPLE
*******************************************************

preserve

sort id year

capture drop employment_2019 emp19 employment_2020 ///
    lev20 age20 ind20 treated_north matchid* ps*

gen employment_2019 = employment if year == 2019
by id: egen emp19 = max(employment_2019)

keep if year == 2020

* Outcome in 2020
gen employment_2020 = employment

* Covariates
gen lev20 = leverage
gen age20 = age
gen ind20 = industry

* Treatment
gen treated_north = (state == 1 & loan == 1)

keep id state loan treated_north ///
    employment_2020 emp19 lev20 age20 ind20

drop if missing(employment_2020, emp19, lev20, age20, ind20)


* Nearest-neighbour Mahalanobis matching
teffects nnmatch ///
    (employment_2020 emp19 lev20 age20 i.ind20) ///
    (treated_north), ///
    metric(mahalanobis) ///
    generate(matchid) ///
    nneighbor(1) ///
    atet


* Balance before matching
ttest emp19, by(treated_north)
ttest lev20, by(treated_north)
ttest age20, by(treated_north)

tab ind20 treated_north, chi2


* Balance diagnostics
tebalance summarize emp19, baseline

tebalance density emp19
tebalance density lev20
tebalance density age20


*******************************************************
* PROPENSITY SCORE MATCHING - ALL UNTREATED
*******************************************************

logit loan lev20 emp19 age20 i.ind20, nolog

teffects psmatch ///
    (employment_2020) ///
    (treated_north emp19 lev20 age20 i.ind20, logit), ///
    nneighbor(1) ///
    generate(ps) ///
    atet

restore


*******************************************************
* MATCHING IN NORTH ONLY
*******************************************************

preserve

sort id year

capture drop employment_2019 emp19 employment_2020 ///
    lev20 age20 ind20 treated_north matchid* ps*

keep if state == 1

gen employment_2019 = employment if year == 2019
by id: egen emp19 = max(employment_2019)

keep if year == 2020

* Outcome in 2020
gen employment_2020 = employment

* Covariates
gen lev20 = leverage
gen age20 = age
gen ind20 = industry

* Treatment
gen treated_north = (state == 1 & loan == 1)

keep id state loan treated_north ///
    employment_2020 emp19 lev20 age20 ind20

drop if missing(employment_2020, emp19, lev20, age20, ind20)


* Nearest-neighbour Mahalanobis matching
teffects nnmatch ///
    (employment_2020 emp19 lev20 age20 i.ind20) ///
    (treated_north), ///
    metric(mahalanobis) ///
    generate(matchid) ///
    nneighbor(1) ///
    atet


* Balance before matching
ttest emp19, by(treated_north)
ttest lev20, by(treated_north)
ttest age20, by(treated_north)

tab ind20 treated_north, chi2


* Balance diagnostics
tebalance summarize emp19, baseline

tebalance density emp19
tebalance density lev20
tebalance density age20


*******************************************************
* PROPENSITY SCORE MATCHING - NORTH ONLY
*******************************************************

logit loan lev20 emp19 age20 i.ind20, nolog

teffects psmatch ///
    (employment_2020) ///
    (treated_north emp19 lev20 age20 i.ind20, logit), ///
    nneighbor(1) ///
    generate(ps) ///
    atet

restore


*******************************************************
* DIFFERENCE-IN-DIFFERENCES
*******************************************************

xtset id year

* Basic DiD
regress D.employment D.loan if year == 2020

* DiD with leverage
regress D.employment D.loan D.leverage if year == 2020


*******************************************************
* MATCHING + DID IN 2020
*******************************************************

preserve

sort id year

capture drop employment_2019 emp19 change_employment ///
    lev20 age20 ind20 treated_north obs2020 ///
    matchid* matched_treated matched_control matched_sample

gen employment_2019 = employment if year == 2019
by id: egen emp19 = max(employment_2019)

keep if year == 2020

gen change_employment = employment - emp19

gen lev20 = leverage
gen age20 = age
gen ind20 = industry

gen treated_north = (state == 1 & loan == 1)

keep id treated_north change_employment ///
    emp19 lev20 age20 ind20

drop if missing(change_employment, emp19, lev20, age20, ind20)

gen obs2020 = _n


* Mahalanobis matching on employment change
teffects nnmatch ///
    (change_employment emp19 lev20 age20 i.ind20) ///
    (treated_north), ///
    metric(mahalanobis) ///
    nneighbor(1) ///
    atet ///
    generate(matchid)


*******************************************************
* IDENTIFY MATCHED TREATED AND MATCHED CONTROLS
*******************************************************

tempfile matchbase treatedids controlids

save `matchbase', replace


* Treated firms
use `matchbase', clear
keep if treated_north == 1
keep id
duplicates drop

gen matched_treated = 1

save `treatedids', replace


* Matched control firms
use `matchbase', clear
keep if treated_north == 1

keep matchid1
rename matchid1 obs2020

drop if missing(obs2020)

duplicates drop

merge m:1 obs2020 using `matchbase', ///
    nogen keep(match) keepusing(id)

keep id
duplicates drop

gen matched_control = 1

save `controlids', replace


*******************************************************
* RETURN TO FULL PANEL
*******************************************************

restore


*******************************************************
* MERGE MATCHED SAMPLE WITH FULL PANEL
*******************************************************

merge m:1 id using `treatedids', ///
    nogen keep(master match)

replace matched_treated = 0 ///
    if missing(matched_treated)


merge m:1 id using `controlids', ///
    nogen keep(master match)

replace matched_control = 0 ///
    if missing(matched_control)


gen matched_sample = .

replace matched_sample = 1 ///
    if matched_treated == 1

replace matched_sample = 0 ///
    if matched_control == 1


label define ms ///
    1 "matched treated" ///
    0 "matched controls", replace

label values matched_sample ms


*******************************************************
* KEEP MATCHED SAMPLE
*******************************************************

keep id year employment matched_sample state

keep if matched_sample < .


*******************************************************
* COUNT MATCHED FIRMS
*******************************************************

preserve

keep id matched_sample

duplicates drop

contract matched_sample

label values matched_sample ms

list matched_sample _freq, noobs

restore


*******************************************************
* PARALLEL TRENDS AFTER MATCHING
*******************************************************

preserve

collapse (mean) mean_emp = employment, ///
    by(year matched_sample)


twoway ///
    (connected mean_emp year ///
        if matched_sample == 1, ///
        sort msymbol(o)) ///
    (connected mean_emp year ///
        if matched_sample == 0, ///
        sort msymbol(square)), ///
    title("matched treated vs matched controls") ///
    xtitle("period") ///
    ytitle("mean employment") ///
    xlabel(2018 "end 2018" ///
           2019 "start 2020" ///
           2020 "end 2020", ///
           labsize(small)) ///
    xline(2019, ///
          lpattern(dash) ///
          lcolor(red)) ///
    xscale(range(2018 2020)) ///
    legend(order(1 "matched treated" ///
                 2 "matched controls")) ///
    name(g_match_did, replace)


graph display g_match_did

restore


*******************************************************
* DISPLAY ALL FIGURES USED IN THE PDF
*******************************************************

* Figure 1
graph display fig_match_employment

* Figure 2
graph display fig_match_leverage

* Figure 3
graph display fig_parallel_before

* Figure 4
graph display fig_parallel_after

* Figure 5
graph display fig_match_age