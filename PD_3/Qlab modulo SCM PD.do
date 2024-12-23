clear *
cd "/Users/ar8787/Dropbox/data_eco/diplomado/2024/aplicada/scm"

**# Setup
import delimited "df.csv", clear

//eliminando variables innecessarias
drop gini 
drop populationextremepoverty
drop yearsschooling

//declarando la base como panel
xtset code year

//cambiando nombres
gen pobreza = proportionextremepoverty

**# Pregunta 1
preserve
gen san_pablo =(abbreviation=="SP")
collapse (mean) homiciderates, by( san_pablo year)
reshape wide homiciderates, i(year) j(san_pablo)

#delimit ;
twoway 
(line homiciderates0 year, lcolor(gray) lpattern(dash) sort)
(line homiciderates1 year, lcolor(black) sort), 
ytitle("Homicide rates") 
xtitle("Year") xline(1999, lcolor(gray))
legend(label(1 "Brazil (Average)"))
scheme (s1color) legend(label(2 "Sao Paulo")) ;
#delimit cr
graph export "figura1.jpg", replace
restore

**# Pregunta 2
preserve
drop if inlist(code, 28, 29)

#delimit ;
synth homiciderates 
stategdpcapita stategdpgrowthpercent yearsschoolingimp populationprojectionln 
giniimp homiciderates pobreza, 
trunit(35) trperiod(1999) nested fig ;
#delimit cr
graph export "figura2.jpg", replace

ereturn list
matrix treated 		= e(Y_treated) 
matrix synth 		= e(Y_synthetic) 
keep year 
svmat treated 
svmat synth

#delimit ;
twoway 
(line treated year , lcolor(black) lpattern(solid) sort)
(line synth year , lcolor(black) lpattern(dash) sort), 
ytitle("Homicide rates treated and synth") 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009));
#delimit cr
restore

**# Pregunta 4
preserve
drop if inlist(code, 28, 29)

matrix gaps 		= e(Y_treated) - e(Y_synthetic)
keep year
svmat gaps

#delimit ;
twoway 
(line gaps year ,lcolor(black) lwidth(thick))
(connect gaps year , lcolor(black) lpattern(dash) sort), 
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009));
#delimit cr
graph export "figura4.jpg", replace
restore


**# Pregunta 5
preserve
drop if inlist(code, 28, 29)
keep if year <= 1998

#delimit;
synth homiciderates 
stategdpcapita stategdpgrowthpercent yearsschoolingimp populationprojectionln
giniimp homiciderates pobreza,
trunit(35) trperiod(1994) nested;
#delimit cr

matrix treated 	= e(Y_treated)
matrix synth 	= e(Y_synthetic)
matrix gaps 	= e(Y_treated) - e(Y_synthetic)
keep year
svmat treated 
svmat synth
svmat gaps

#delimit ;
twoway 
(line treated year, lcolor(black) lpattern(solid) sort)
(line synth year, lcolor(black) lpattern(dash) sort), 
ytitle("Homicide rates treated and synth")  ylabel(0(5)50) yscale(range(0 50)) 
xtitle("Year") xlabel(1990(1)1998) xline(1994) xscale(range(1990 1998));
#delimit cr
graph export "figura5_1.jpg", replace

#delimit ;
twoway 
(line gaps year ,lcolor(black) lwidth(thick))
(connect gaps year , lcolor(black) lpattern(dash) sort), 
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(1)1998) xline(1994) xscale(range(1990 1998));
#delimit cr
graph export "figura5_2.jpg", replace
restore


**# Pregunta 6
//Estimado inicial: fijémonos en los estados que componen el control sintético
import delimited "df.csv", clear

drop gini 
drop populationextremepoverty
drop yearsschooling
xtset code year
gen pobreza = proportionextremepoverty

drop if inlist(code, 28, 29)

#delimit;
synth homiciderates 
stategdpcapita stategdpgrowthpercent yearsschoolingimp  
populationprojectionln giniimp homiciderates pobreza, 
trunit(35) trperiod(1999) nested fig keep("original_estimate.dta", replace);
#delimit cr

//Ejecutamos el leave one out estimator dejando de lado cada vez 1 Estado
foreach j of numlist 14 32 33 42 50 53 {
	display _n(2) as result "Estado `j'"
	
	import delimited "df.csv", clear

	drop gini 
	drop populationextremepoverty
	drop yearsschooling
	xtset code year
	gen pobreza = proportionextremepoverty
	
	drop if inlist(code, 28, 29)
	drop if code==`j'
	#delimit;
	synth homiciderates 
	stategdpcapita stategdpgrowthpercent yearsschoolingimp  
	populationprojectionln giniimp homiciderates pobreza, 
	trunit(35) trperiod(1999) nested 
	keep("leaveoneout_without`j'.dta", replace);
	#delimit cr		
	
	use "leaveoneout_without`j'.dta", clear
	keep _Co_Number _time _Y_synthetic _Y_treated
	rename _Y_synthetic _Y_synthetic_`j'
	save "leaveoneout_without`j'.dta", replace
}

use _Co_Number _time _Y_treated	_Y_synthetic using "original_estimate.dta", clear
foreach j of numlist 14 32 33 42 50 53 {
	merge 1:1 _Co_Number _time using "leaveoneout_without`j'.dta", nogen
	erase "leaveoneout_without`j'.dta"
}

#delimit ;
twoway 
(line _Y_synthetic_14 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_32 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_33 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_42 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_50 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_53 _time, lcolor(gray) lpattern(solid))
(line _Y_treated _time, lcolor(black) lwidth(thick) lpattern(solid) )
(line _Y_synthetic _time, lcolor(black) lpattern(dash) ),
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
legend(
		order(7 "Observed Sao Paulo" 8 "Synthetic Sao Paulo" 1 "Sao Paulo leave-one-out Sao Paulo") pos(6) 
	);
#delimit cr
graph export "figura6.jpg", replace


**# Pregunta 7
import delimited "df.csv", clear

drop gini 
drop populationextremepoverty
drop yearsschooling
xtset code year
gen pobreza = proportionextremepoverty

drop if inlist(code, 28, 29)

//Generando los pseudo controles sintéticos
macro drop rmspe_names synth_names
local i=1
foreach state_code of numlist 11 12 13 14 15 16 17 21 /*22*/ 23 24 25 26 27 31 32 33 35 41 42 43 50 51 52 53 {
    display _n(1) as result "State `state_code' (iteration `i')"
	
	#delimit;
	synth homiciderates 
	stategdpcapita stategdpgrowthpercent yearsschoolingimp  
	populationprojectionln giniimp homiciderates pobreza, 
	trunit(`state_code') trperiod(1999) nested;
	#delimit cr		
    
	if `i'==1 	{	//for the first iteration, it just creates the vectors separately
		matrix rmspe 	= e(RMSPE)
		matrix y_synth 	= e(Y_synthetic)
		matrix y_obs   	= e(Y_treated)
	}
	else 	{		//for the next iterations, we put the vectors (separately) next to the previous ones
	    matrix rmspe 	= rmspe \ e(RMSPE)
		matrix y_synth 	= y_synth, e(Y_synthetic)	
		matrix y_obs 	= y_obs, e(Y_treated)	
	}
	global rmspe_names ${rmspe_names} `state_code'
	global synth_names ${synth_names} "synth_`state_code'"
	
	matrix list rmspe		//just to see how the accumulation process works, comment out once you actually understand it
	matrix list y_synth
	matrix list y_obs
	more
	
	local ++i
}
mat colnames rmspe = "RMSPE"
mat rownames rmspe = ${rmspe_names}
matrix list rmspe

mat colnames y_synth = ${synth_names}
matrix list y_synth
mat colnames y_obs = ${synth_names}
matrix list y_obs

matrix te= y_obs - y_synth

//Gráfico incluyendo todos los pseudo controles sintéticos
preserve
drop _all
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace
order year, first

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_4?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_5?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_35, lcolor(red) lpattern(solid) lwidth(medthick)),
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura7.jpg", replace
restore


//Restringiendo el plot a un número de estados con un nivel mínimo de calidad
///Creamos una minibase de datos con el RMSPE de cada estado
preserve
clear
quietly: svmat2 rmspe, rnames(code)
rename rmspe1 rmspe_
*matrix drop rmspe 

quietly: save "Placebos in space rmspe.dta", replace	
restore

preserve
drop _all
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
merge m:1 code using "Placebos in space rmspe.dta", assert(3) nogen noreport
erase "Placebos in space rmspe.dta"

sort code year	

gen foo=rmspe_ if code=="35"		//the treated state
egen rmspe_treated_=mean(foo)
drop foo
gen rmspe_ratio_ = rmspe_ / rmspe_treated
drop rmspe_ rmspe_treated_

table code, c(mean rmspe_ratio)	

quietly: save "Placebos in space.dta", replace
restore


///Replicando el gráfico pero sólo con estados cuyo RMSPE es menos que 2x el de SP
preserve
use "Placebos in space.dta" if rmspe_ratio_<=2, clear		//<- filtering those above 2
table code, c(mean rmspe_ratio)
quietly: tab code
return list
drop rmspe_ratio_

quietly: reshape wide te_@, i(year) j(code) string
order year te_*

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_4?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_5?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_35, lcolor(red) lpattern(solid) lwidth(medthick)),
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
subtitle("Excluding those with RMSPE > 2x SP", tstyle(subheading) margin(b=2))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura7_1.jpg", replace
restore

///Replicando el gráfico pero sólo con estados cuyo RMSPE es menos que 1.5x el de SP
preserve
use "Placebos in space.dta" if rmspe_ratio_<=1.5, clear		//<- filtering those above 1.5
table code, c(mean rmspe_ratio)
quietly: tab code
return list
drop rmspe_ratio_

quietly: reshape wide te_*, i(year) j(code) string
order year te_*

tsset year
#delimit;
graph twoway 
(tsline te_1*, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2*, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3*, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_4*, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_35, lcolor(red) lpattern(solid) lwidth(medthick)),
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
subtitle("Excluding those with RMSPE > 1.5x SP", tstyle(subheading) margin(b=2))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura7_2.jpg", replace
restore


**# Pregunta 8
preserve
clear
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
sort code year 

gen te2			=te^2
gen te2_pre		=te2 if year<1999
gen te2_post	=te2 if year>=1999
collapse (mean) te2_pre te2_post, by(code)
	
gen ratio = sqrt(te2_post)/ sqrt(te2_pre)
gsort -ratio 
list 

gen rank=_n
gen p=rank/24

gen treated=(code=="35")
separate ratio, by(treated)
list
labmask rank, val(code)
#delimit;
graph twoway 
(bar ratio1 rank, base(0) color(red))
(bar ratio0 rank, base(0) color(gs12)),
ytitle("") ylabel(, angle(0) format(%5.2fc) labsize(medium) nogrid)
xtitle("") xlabel(1(1)38, labsize(medium) angle(90) nogrid notick valuelabel)
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura8.jpg", replace
restore

preserve
drop _all
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace
order year, first

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_4?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_5?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_35, lcolor(red) lpattern(solid) lwidth(medthick))
(tsline te_31, lcolor(blue) lpattern(dash) lwidth(medthick))
(tsline te_42, lcolor(green) lpattern(dash) lwidth(medthick)),
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura8_2.jpg", replace
restore


**# Pregunta 9
import delimited "df.csv", clear

drop gini 
drop populationextremepoverty
drop yearsschooling
xtset code year
gen pobreza = proportionextremepoverty

drop if inlist(code, 28, 29)

#delimit ;
synth homiciderates 
stategdpcapita stategdpgrowthpercent yearsschoolingimp populationprojectionln 
giniimp homiciderates pobreza, 
trunit(35) trperiod(1999) fig ;
#delimit cr
graph export "figura9_1.jpg", replace

//Generando los pseudo controles sintéticos
macro drop rmspe_names synth_names
local i=1
foreach state_code of numlist 11 12 13 14 15 16 17 21 /*22*/ 23 24 25 26 27 31 32 33 35 41 42 43 50 51 52 53 {
    display _n(1) as result "State `state_code' (iteration `i')"
	
	#delimit;
	synth homiciderates 
	stategdpcapita stategdpgrowthpercent yearsschoolingimp  
	populationprojectionln giniimp homiciderates pobreza, 
	trunit(`state_code') trperiod(1999) ;
	#delimit cr		
    
	if `i'==1 	{	//for the first iteration, it just creates the vectors separately
		matrix rmspe 	= e(RMSPE)
		matrix y_synth 	= e(Y_synthetic)
		matrix y_obs   	= e(Y_treated)
	}
	else 	{		//for the next iterations, we put the vectors (separately) next to the previous ones
	    matrix rmspe 	= rmspe \ e(RMSPE)
		matrix y_synth 	= y_synth, e(Y_synthetic)	
		matrix y_obs 	= y_obs, e(Y_treated)	
	}
	global rmspe_names ${rmspe_names} `state_code'
	global synth_names ${synth_names} "synth_`state_code'"
	
	matrix list rmspe		//just to see how the accumulation process works, comment out once you actually understand it
	matrix list y_synth
	matrix list y_obs
	more
	
	local ++i
}
mat colnames rmspe = "RMSPE"
mat rownames rmspe = ${rmspe_names}
matrix list rmspe

mat colnames y_synth = ${synth_names}
matrix list y_synth
mat colnames y_obs = ${synth_names}
matrix list y_obs

matrix te= y_obs - y_synth

//Gráfico incluyendo todos los pseudo controles sintéticos
preserve
drop _all
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace
order year, first

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_4?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_5?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_35, lcolor(red) lpattern(solid) lwidth(medthick)),
ytitle("Gap homicide rates") ylabel(-30(5)30) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1990(5)2005 2009) xline(1999) xscale(range(1990 2009))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura9_2.jpg", replace
restore

preserve
clear
quietly: svmat2 rmspe, rnames(code)
rename rmspe1 rmspe_
*matrix drop rmspe 

quietly: save "Placebos in space rmspe.dta", replace	
restore

preserve
drop _all
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
merge m:1 code using "Placebos in space rmspe.dta", assert(3) nogen noreport
erase "Placebos in space rmspe.dta"

sort code year	

gen foo=rmspe_ if code=="35"		//the treated state
egen rmspe_treated_=mean(foo)
drop foo
gen rmspe_ratio_ = rmspe_ / rmspe_treated
drop rmspe_ rmspe_treated_

table code, c(mean rmspe_ratio)	

quietly: save "Placebos in space.dta", replace
restore

preserve
clear
svmat2 te, names(col) rnames(year)
renvars synth_11-synth_53, subst("synth" "te")
destring year, replace

quietly: reshape long te_, i(year) j(code) string
sort code year 

gen te2			=te^2
gen te2_pre		=te2 if year<1999
gen te2_post	=te2 if year>=1999
collapse (mean) te2_pre te2_post, by(code)
	
gen ratio = sqrt(te2_post)/ sqrt(te2_pre)
gsort -ratio 
list 

gen rank=_n
gen p=rank/24

gen treated=(code=="35")
separate ratio, by(treated)
list
labmask rank, val(code)
#delimit;
graph twoway 
(bar ratio1 rank, base(0) color(red))
(bar ratio0 rank, base(0) color(gs12)),
ytitle("") ylabel(, angle(0) format(%5.2fc) labsize(medium) nogrid)
xtitle("") xlabel(1(1)38, labsize(medium) angle(90) nogrid notick valuelabel)
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
graph export "figura9_3.jpg", replace
restore



exit