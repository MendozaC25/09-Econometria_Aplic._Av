/*----------------------
Initial script configuration
-----------------------*/

clear all
cls
global main "C:\Users\JUANKY\Downloads"
cd $main
log using first_problem_set.log
*Pregunta Nº1 - Problem Set

/*El 1er ejercicio del Problem Set fue realizado por:
     - PEREZ GONZALES, JUAN CARLOS
*/ 

* Importamos los datos de 1998-1999
forvalues i=98/99 {

shell curl -o cbp`i'st.zip 						"https://www2.census.gov/programs-surveys/cbp/datasets/19`i'/cbp`i'st.zip"
unzipfile cbp`i'st.zip, replace

import delimited "cbp`i'st.txt", clear
* keeping the data aggregated at the 3 digit NAICS
keep if substr(naics,4,3)=="///"
gen year= 19`i'
save "año_19`i'.dta", replace
}

* Importamos los datos de 2000-2006
forvalues x=0/6 {

shell curl -o cbp0`x'st.zip 						"https://www2.census.gov/programs-surveys/cbp/datasets/200`x'/cbp0`x'st.zip"
unzipfile cbp0`x'st.zip, replace

import delimited "cbp0`x'st.txt", clear
* keeping the data aggregated at the 3 digit NAICS
keep if substr(naics,4,3)=="///"
gen year= 200`x'
save "año_200`x'.dta", replace
}

*Juntamos los datos
use año_1998, clear
append using año_1999

forvalues a=0/6 {
append using año_200`a'
}

keep fipstate year naics emp qp1 ap est

/* 
1. What is the level of observation?
Cada observación es un establecimiento.

2. Construct 1 dummy variable called “post_china” where post_china=1 for year>=2001 and 0 otherwise.
*/

gen post_china=0 if year<2001
replace post_china=1 if year>=2001

/* 
3. Construct 1 dummy variable called “manuf” where manuf=1 for all the observations that start with naics code “3” – which is manufacturing - and 0 otherwise.
*/

gen manuf=1 if substr(naics,1,1) == "3"
replace manuf=0 if substr(naics,1,1) != "3"

/* 
4. Construct the values necessary to generate the difference-in-difference estimate (i.e. 2x2 Matrix) of the effect of China entering the WTO on employment (emp). Hint: Define clearly what is your treatment group vs control group and the intervention time. Interpret the results.
*/

sort manuf post_china
by manuf post_china: sum emp
tab  manuf post_china, sum(emp)
*Las observaciones tratadas son los establecimientos manufactureros y los controles son los establecimientos de otros rubros, todos en EE.UU.

/* Restamos las medias obtenidas en el cuadro anterior para obtener el efecto DD

DD = (13366.851 - 15619.126) - (30579.647 - 29539.342) = -3292.58

Interpretación. El efecto causal de la entrada de China a la OMC en empleo en EE.UU. es una redución de 3292.58 trabajadores, en promedio, por establecimiento

*/

/*
5. Estimate a diff-in-diff regression and make sure you get the same diff-in-diff estimate as in part 4.
*/

gen treated=post_china*manuf
reg emp post_china manuf treated

/*
6. Estimate a diff-in-diff regression for the effect of China entering the WTO in 2001 on the number of establishment (est), an average pay (qp1/emp). Interpret the results.
*/
gen av_pay=qp1/emp
reg emp post_china manuf treated av_pay est 

/*
Interpretación. Considerando el salario promedio y el número de establecimientos como regresores adicionales, el efecto causal de la entrada de China a la OMC en empleo en EE.UU. es una redución de 3078.361 trabajadores, en promedio, por establecimiento
*/

/*
7. Estimate same regression as in (5) but now take logs of the dependent variable (i,e,log(emp)). Interpret your results. Is it necessary to take logs?
*/

gen lemp = log(emp)
reg lemp post_china manuf treated 

*He comparado los histogramas del número de trabajadores en niveles y en logaritmos. La segunda muestra una distribución más apegadas a la forma de la distribución normal, a diferencia de la variable en niveles. Por lo tanto, consideramos que si era necesario tomar logaritmos.
hist emp
hist lemp
/*
Interpretación. El efecto causal de la entrada de China a la OMC en empleo en EE.UU. es una redución del 16%, en promedio, en el número de trabajadores por establecimiento.
*/

/*8. Generate one dummy per year. Construct the interaction between each year dummies and your treatment group (manuf). You should have 9 interaction terms.
*/

forvalues b=3(-1)1 {
gen period_`b'=1 if year == 2001-`b'
replace period_`b'=0 if year != 2001-`b'
}

forvalues c=0/5 {
gen period`c'=1 if year == 2001+`c'
replace period`c'=0 if year != 2001+`c'
}

forvalues d=1/3 {
gen treat_`d'= manuf*period_`d'
}

forvalues f=0/5 {
gen treat`f'= manuf*period`f'
}

/*
9. Estimate an event study, i.e. run the following specification: log(emp) vs year dummies, manuf*year dummies (omit the interaction between manuf * year 1998) and control for NAICS-3 digit dummies and state dummies. Hint: when controlling for naics3 and state dummies, you need to use the command “reg y x, absorb(naics3 state).” This will include naics3 dummies and state dummies in your regression. Interpret your results.
Should you expect to see any effect for the interaction term manuf*year 1999 or manuf * year 2000? Did the China shock have a significant effect on employment? Was it a shortrun or long-run effect?
*/ 

reghdfe lemp period_2 period_1 period0 period1 period2 period3 period4 period5 treat_2 treat_1 treat0 treat1 treat2 treat3 treat4 treat5 , absorb(naics fipstate)


/*
Interpretación: Se observa una reducción en el número de empleados previa al año de tratamiento, esto se puede ver en los coeficientes de las variables treat_2 y treat_1, que representan los años 1999 y 2000. Esto se puede deber a la existencia de variables que previamente ya habían influido en el número de empleados en los establecimientos manufactureros durante esos años. La entrada de China, tiene un efecto significativo al 1%. Además, efecto negativo en el empleo de la entrada de China fue de largo plazo, por que se observa coeficientes cada vez mas negativos luego de la entrada de China.
*/
/*
10. Estimate a similar event study on the log(est) and average pay. Interpret your results.
*/
gen lest=log(est)

reghdfe lemp period_2 period_1 period0 period1 period2 period3 period4 period5 treat_2 treat_1 treat0 treat1 treat2 treat3 treat4 treat5 lest av_pay, absorb(naics fipstate)

/*
Controlando por el logaritmo del número de establecimientos y el salario promedio, se observa un efecto significativo solo en un año anterior al tratamiento (treat_1), lo que, a diferencia de la pregunta anterior, indica la existencia de otras variables que influyen en el número de empleados por establecimiento solo un año antes a la llegada de China a la OMC .
*/

log close


