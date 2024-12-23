clear *
cd "C:\Users\Gianfranco\Desktop\PC3_Econometria"

**# Setup
use repgermany_modif-1.dta, clear

//declarando la base como panel
xtset index year


**# Pregunta 1
preserve
gen w_germany =(index== 7)
collapse (mean) gdp, by( w_germany year)
reshape wide gdp, i(year) j(w_germany)

#delimit ;
twoway 
(line gdp0 year, lcolor(gray) lpattern(dash) sort)
(line gdp1 year, lcolor(black) sort), 
ytitle("GDP per capita") 
xtitle("Year") xline(1990, lcolor(gray))
legend(label(1 "Other countries (Average)"))
scheme (s1color) legend(label(2 "West Germany")) ;
#delimit cr
restore

**# Pregunta 2
preserve

#delimit ;
synth gdp 
infrate trade schooling industry invest, 
trunit(7) trperiod(1990) nested fig;
#delimit cr

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
ytitle("GDP treated and synth") 
xtitle("Year") xlabel(1960(5)2005 2009) xline(1990) xscale(range(1990 2009));
#delimit cr
restore

**# Pregunta 4
preserve

matrix gaps 		= e(Y_treated) - e(Y_synthetic)
keep year
svmat gaps

#delimit ;
twoway 
(line gaps year ,lcolor(black) lwidth(thick))
(connect gaps year , lcolor(black) lpattern(dash) sort), 
ytitle("Gap GDP") ylabel(-3700(600)400) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1960(5)2005) xline(1990) xscale(range(1960 2003));
#delimit cr
restore

**# Pregunta 5
preserve

#delimit ;
synth gdp 
infrate trade schooling industry invest, 
trunit(7) trperiod(1975) nested fig ;
#delimit cr

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
ytitle("GDP treated and synth") 
xtitle("Year") xlabel(1960(5)2005) xline(1975) xscale(range(1990 2003));
#delimit cr
restore

**# Pregunta 6
//Estimado inicial: fijémonos en los estados que componen el control sintético
preserve
#delimit ;
synth gdp 
infrate trade schooling industry invest, 
trunit(7) trperiod(1990) nested fig keep("original_estimate.dta", replace);
#delimit cr


//Ejecutamos el leave one out estimator dejando de lado cada vez 1 Estado
foreach j of numlist 1 3 12 {
	display _n(2) as result "País `j'"
	
	use repgermany_modif-1.dta, clear
	
	drop if index==`j'
	#delimit;
	synth gdp 
	infrate trade schooling industry invest, 
	trunit(7) trperiod(1990) nested
	keep("leaveoneout_without`j'.dta", replace);
	#delimit cr		
	
	use "leaveoneout_without`j'.dta", clear
	keep _Co_Number _time _Y_synthetic _Y_treated
	rename _Y_synthetic _Y_synthetic_`j'
	save "leaveoneout_without`j'.dta", replace
}

use _Co_Number _time _Y_treated	_Y_synthetic using "original_estimate.dta", clear
foreach j of numlist 1 3 12 {
	merge 1:1 _Co_Number _time using "leaveoneout_without`j'.dta", nogen
	erase "leaveoneout_without`j'.dta"
}

#delimit ;
twoway 
(line _Y_synthetic_1 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_3 _time, lcolor(gray) lpattern(solid))
(line _Y_synthetic_12 _time, lcolor(gray) lpattern(solid))
(line _Y_treated _time, lcolor(black) lwidth(thick) lpattern(solid) )
(line _Y_synthetic _time, lcolor(black) lpattern(dash) ),
xtitle("Year") xlabel(1960(5)2005 2005) xline(1990) xscale(range(1960 2005))
legend(
		order(7 "Observed West Germany" 8 "Synthetic West Germany" 1 "West Germany leave-one-out West Germany") pos(6) 
	);
#delimit cr

restore

**# Pregunta 7
use repgermany_modif-1.dta, clear

//Generando los pseudo controles sintéticos
macro drop rmspe_names synth_names
local i=1
foreach pais_code of numlist 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    display _n(1) as result "Pais `pais_code' (iteration `i')"
	
	#delimit ;
	synth gdp 
	infrate trade schooling industry invest, 
	trunit(`pais_code') trperiod(1990) nested;
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
	global rmspe_names ${rmspe_names} `pais_code'
	global synth_names ${synth_names} "synth_`pais_code'"
	
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
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace
order year, first

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))			
(tsline te_3, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_4, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_5, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_6, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_7, lcolor(red) lpattern(solid) lwidth(medthick))
(tsline te_8, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_9, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_10, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_12, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_14, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_16, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_18, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_19, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_20, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_21, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
,
ytitle("Gap GDP") ylabel(-5000(2000)12000) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1960(5)2005) xline(1990) xscale(range(1960 2003))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
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
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
merge m:1 code using "Placebos in space rmspe.dta", assert(3) nogen noreport
erase "Placebos in space rmspe.dta"

sort code year	

gen foo=rmspe_ if code=="7"		//the treated state
egen rmspe_treated_=mean(foo)
drop foo
gen rmspe_ratio_ = rmspe_ / rmspe_treated
drop rmspe_ rmspe_treated_

table code, c(mean rmspe_ratio)	

quietly: save "Placebos in space.dta", replace
restore


///Replicando el gráfico pero sólo con estados cuyo RMSPE es menos que RMSPE el de West Germany
preserve
use "Placebos in space.dta" if rmspe_ratio_<=1, clear		//<- filtering those above 1
table code, c(mean rmspe_ratio)
quietly: tab code
return list
drop rmspe_ratio_

quietly: reshape wide te_@, i(year) j(code) string
order year te_*

tsset year
#delimit;
graph twoway 
(tsline te_7, lcolor(red) lpattern(solid) lwidth(medthick)),
ytitle("Gap GDP") ylabel(-4000(1000)3000) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1960(5)2005) xline(1990) xscale(range(1960 2003))
subtitle("Excluding those with RMSPE > West Germany", tstyle(subheading) margin(b=2))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
restore

**# Pregunta 8
preserve
clear
svmat2 te, names(col) rnames(year)
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
sort code year 

gen te2			=te^2
gen te2_pre		=te2 if year<1990
gen te2_post	=te2 if year>=1990
collapse (mean) te2_pre te2_post, by(code)
	
gen ratio = sqrt(te2_post)/ sqrt(te2_pre)
gsort -ratio 
list 

gen rank=_n
gen p=rank/24

gen treated=(code=="7")
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
restore



**# Pregunta 9
use repgermany_modif-1.dta, clear

#delimit ;
synth gdp 
infrate trade schooling industry invest, 
trunit(7) trperiod(1990) fig;
#delimit cr


//Generando los pseudo controles sintéticos
macro drop rmspe_names synth_names
local i=1
foreach pais_code of numlist 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    display _n(1) as result "Pais `pais_code' (iteration `i')"
	
	#delimit ;
	synth gdp 
	infrate trade schooling industry, 
	trunit(`pais_code') trperiod(1990);
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
	global rmspe_names ${rmspe_names} `pais_code'
	global synth_names ${synth_names} "synth_`pais_code'"
	
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
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace
order year, first

tsset year
#delimit;
graph twoway 
(tsline te_1?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_2?, lcolor(gs12 ..) lpattern(solid) lwidth(thin))
(tsline te_3, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_4, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_5, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_6, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_7, lcolor(red) lpattern(solid) lwidth(medthick))
(tsline te_8, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_9, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_10, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_12, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_14, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_16, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_18, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_19, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_20, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
(tsline te_21, lcolor(gs12 ..) lpattern(solid) lwidth(thin)) 
,
ytitle("Gap GDP") ylabel(-5000(2000)12000) yline(0, lcolor(black) lpattern(dash)) yscale(range(-30 30)) 
xtitle("Year") xlabel(1960(5)2005) xline(1990) xscale(range(1960 2003))
legend(off) 
graphregion(fcolor(white)) plotregion(margin(zero) lcolor(black));
#delimit cr
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
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace

quietly: reshape long te_@, i(year) j(code) string
merge m:1 code using "Placebos in space rmspe.dta", assert(3) nogen noreport
erase "Placebos in space rmspe.dta"

sort code year	

gen foo=rmspe_ if code=="7"		//the treated state
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
foreach i in 1 2 3 4 5 6 7 8 9 10 12 14 16 18 19 20 21 {
    rename synth_`i' te_`i'
}
destring year, replace

quietly: reshape long te_, i(year) j(code) string
sort code year 

gen te2			=te^2
gen te2_pre		=te2 if year<1990
gen te2_post	=te2 if year>=1990
collapse (mean) te2_pre te2_post, by(code)
	
gen ratio = sqrt(te2_post)/ sqrt(te2_pre)
gsort -ratio 
list 

gen rank=_n
gen p=rank/24

gen treated=(code=="7")
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
restore

