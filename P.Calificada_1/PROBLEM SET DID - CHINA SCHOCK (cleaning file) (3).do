/* Download the data and unzip it */
pwd
shell curl -o cbp99st.zip "https://www2.census.gov/programs-surveys/cbp/datasets/1999/cbp99st.zip"
unzipfile cbp99st.zip, replace

/*-------------*/
/* Import data */
/*-------------*/
import delimited "cbp99st.txt", clear
* keeping the data aggregated at the 3 digit NAICS
keep if substr(naics,4,3)=="///"

***LOOPING***

*forvalues loops over numbers
gen hello=0

forvalues i = 1/5 {
display "Hello world!" 
display `i'
replace hello=`i'
}

/*-------------*/
/* Import data */
/*-------------*/
import delimited "cbp99st.txt", clear
* keeping the data aggregated at the 3 digit NAICS
keep if substr(naics,4,3)=="///"

cd "H:\UMD\PUCP\data"
global year "96 97 98 99 00 01 02 03 04 05 06"
foreach yy of global year {

if `yy'==96 | `yy'==97 | `yy'==98 | `yy'==99 {
shell curl -o cbp`yy'st.zip "https://www2.census.gov/programs-surveys/cbp/datasets/19`yy'/cbp`yy'st.zip"
}
else if `yy'!=96 | `yy'!=97 | `yy'!=98 | `yy'!=99 {
shell curl -o cbp`yy'st.zip "https://www2.census.gov/programs-surveys/cbp/datasets/20`yy'/cbp`yy'st.zip"
}
unzipfile cbp`yy'st.zip, replace
import delimited "cbp`yy'st.txt", clear
keep if substr(naics,4,3)=="///"
* keeping all 3-digit manufacturing sector
/*keep if naics=="311///" | naics=="312///" | naics=="313///" | naics=="314///" | naics=="315///" | naics=="316///" | naics=="321///" | naics=="322///" | naics=="323///" | naics=="324///" | naics=="325///" | naics=="326///" | naics=="327///" | naics=="331///" | naics=="332///" | naics=="333//" | naics=="334///" | naics=="335///" | naics=="336///" | naics=="337///" | naics=="339///" */

keep fipstate naics emp qp1 ap est
if `yy'==96 | `yy'==97 | `yy'==98 | `yy'==99 {
	gen year=19`yy' 
}
else if `yy'!=96 | `yy'!=97 | `yy'!=98 | `yy'!=99 {
	gen year=20`yy' 
}
save cbp`yy'st.dta, replace
}

use cbp98st.dta, clear 
append using cbp99st.dta 
append using cbp00st.dta 
append using cbp01st.dta 
append using cbp02st.dta 
append using cbp03st.dta
append using cbp04st.dta 
append using cbp05st.dta
append using cbp06st.dta 


