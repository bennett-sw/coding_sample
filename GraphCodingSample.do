// Analysis of Wealth Inequality by Race, Education, and Age
// Date: Oct. 26, 2021
clear all
use RA_21_22

// Dividing all monetary variables by 1000 -> new unit is thousands of US $
replace asset_total = asset_total/1000
replace asset_housing = asset_housing/1000
replace debt_total = debt_total/1000
replace debt_housing = debt_housing/1000
replace income = income/1000

/*
SECTION 1: Key trends in median total wealth over the last 30 years by race and education
*/

preserve
	// generating total_wealth var, as defined in task 
	gen total_wealth = (asset_total - debt_total) // unweighted total wealth
	egen med_wealth = median(total_wealth), by(year race education)
	// TODO: Check if this collapse command is redundant given the above lines
	collapse med_wealth, by(year race education)
	sort year 

// Plot: categorizes by both race and education
	/* key: 
			lpattern: solid line := college degree, longdash_dot := some college
			dotted line := no college
			lcolor: Hispanic := dkgreen, white := blue, black := red
	
*/

	twoway (line med_wealth year if race == "black" & education == "no college", lcolor(red) lwidth(medthick) lpattern(dash))  ///
		(line med_wealth year if race == "black" & education == "some college", lcolor(red) lwidth(medthick) lpattern(longdash_dot))  ///
		(line med_wealth year if race == "black" & education == "college degree", lcolor(red) lwidth(medthick) lpattern(solid))  ///
		(line med_wealth year if race == "Hispanic" & education == "no college", lcolor(dkgreen) lwidth(medthick) lpattern(dash))  ///
		(line med_wealth year if race == "Hispanic" & education == "some college", lcolor(dkgreen) lwidth(medthick) lpattern(longdash_dot))  ///
		(line med_wealth year if race == "Hispanic" & education == "college degree", lcolor(dkgreen) lwidth(medthick) lpattern(solid))  ///
		(line med_wealth year if race == "white" & education == "no college", lcolor(blue) lwidth(medthick) lpattern(dash))  ///
		(line med_wealth year if race == "white" & education == "some college", lcolor(blue) lwidth(medthick) lpattern(longdash_dot)) ///
		(line med_wealth year if race == "white" & education == "college degree", lcolor(blue) lwidth(medthick) lpattern(solid) title(Median Wealth by Race and Education 1989-2016) ytitle(Median Wealth (2016 `$')) xtitle(Year) legend(order(1 "Black, No college" 2 "Black, Some college" 3 "Black, College degree" 4 "Hispanic, No college" 5 "Hispanic, Some college" 6 "Hispanic, College degree" 7 "White, No college" 8 "White, Some college" 9 "White, College degree")) )
		// TODO: Need to add 'other' category
// saving graph
	graph save booth_graph1, replace

restore

/*
SECTION 2
*/
preserve
	keep if race == "black" | race == "white"
	gen housing_wealth = asset_housing - debt_housing
	collapse (median) housing_wealth, by(race year education)
	//egen med_housing_wealth = median(housing_wealth), by(year race education)

// Plot 2: median housing wealth for black and white households
	twoway (line housing_wealth year if race == "black" & education == "no college", lcolor(red) lwidth(medthick) lpattern(dash))  ///
	(line housing_wealth year if race == "black" & education == "some college", lcolor(red) lwidth(medthick) lpattern(longdash_dot))  ///
	(line housing_wealth year if race == "black" & education == "college degree", lcolor(red) lwidth(medthick) lpattern(solid))  /// 
	(line housing_wealth year if race == "white" & education == "no college", lcolor(blue) lwidth(medthick) lpattern(dash)) ///
	(line housing_wealth year if race == "white" & education == "some college", lcolor(blue) lwidth(medthick) lpattern(longdash_dot)) ///
	(line housing_wealth year if race == "white" & education == "college degree", lcolor(blue) lwidth(medthick) lpattern(solid) title(Median Housing Wealth for Blacks/Whites by Education 1989-2016) ytitle(Median Housing Wealth (2016 `$')) xtitle(Year) legend(order(1 "Black, No college" 2 "Black, Some college" 3 "Black, College degree" 4 "White, No college" 5 "White, Some college" 6 "White, College degree")) )
	graph save booth_graph2, replace

restore
/*
SECTION 3
*/
//preserve
	keep if race == "black" | race == "white"
	keep if age>=25
	gen housing_wealth = asset_housing - debt_housing
	egen med_housing_wealth = median(housing_wealth), by(year race education)
	collapse housing_wealth, by(race year education)
	
	// Calculating losses in housing wealth by group, comparing 2007 to 2010
	gen housing_wealth_lag = housing_wealth[_n-1] //housing wealth for year t-3
	gen housing_wealth_change =  housing_wealth - housing_wealth_lag
	gen housing_wealth_change_perc = 100*((housing_wealth - housing_wealth_lag)/housing_wealth_lag)

// Plot 5: housing_wealth_change for black and white households over age of 25
	twoway (line housing_wealth_change year if race == "black" & education == "no college", lcolor(red) lwidth(medthick) lpattern(dash))  ///
		(line housing_wealth_change year if race == "black" & education == "some college", lcolor(red) lwidth(medthick) lpattern(longdash_dot))  ///
		(line housing_wealth_change year if race == "black" & education == "college degree", lcolor(red) lwidth(medthick) lpattern(solid))  /// 
		(line housing_wealth_change year if race == "white" & education == "no college", lcolor(blue) lwidth(medthick) lpattern(dash)) ///
		(line housing_wealth_change year if race == "white" & education == "some college", lcolor(blue) lwidth(medthick) lpattern(longdash_dot)) ///
		(line housing_wealth_change year if race == "white" & education == "college degree", lcolor(blue) lwidth(medthick) xline(2007) lpattern(solid) title(Median Housing Wealth Change for Blacks and Whites (Age>25) 1989-2016) ytitle(Median Housing Wealth (2016 Thousands of `$')) ylabel(#5) xtitle(Year) legend(order(1 "Black, No college" 2 "Black, Some college" 3 "Black, College degree" 4 "White, No college" 5 "White, Some college" 6 "White, College degree")) )
		graph save booth_graph5, replace
// Plot 3: median housing wealth for black and white households over age of 25
	twoway (line housing_wealth year if race == "black" & education == "no college", lcolor(red) lwidth(medthick) lpattern(dash))  ///
	(line housing_wealth year if race == "black" & education == "some college", lcolor(red) lwidth(medthick) lpattern(longdash_dot))  ///
	(line housing_wealth year if race == "black" & education == "college degree", lcolor(red) lwidth(medthick) lpattern(solid))  /// 
	(line housing_wealth year if race == "white" & education == "no college", lcolor(blue) lwidth(medthick) lpattern(dash)) ///
	(line housing_wealth year if race == "white" & education == "some college", lcolor(blue) lwidth(medthick) lpattern(longdash_dot)) ///
	(line housing_wealth year if race == "white" & education == "college degree", lcolor(blue) lwidth(medthick) xline(2007) lpattern(solid) title(Median Housing Wealth for Blacks and Whites (Age>25) 1989-2016) ytitle(Median Housing Wealth (2016 `$')) xtitle(Year) legend(order(1 "Black, No college" 2 "Black, Some college" 3 "Black, College degree" 4 "White, No college" 5 "White, Some college" 6 "White, College degree")) )
	graph save booth_graph3, replace
	
//restore
	// Plot 4: median non-housing wealth for black and white households over age of 25
preserve
	keep if race == "black" | race == "white"
	keep if age >= 25
	gen non_housing_assets = asset_total - asset_housing
	gen non_housing_debts = debt_total - debt_housing
	gen non_housing_wealth = non_housing_assets - non_housing_debts
	collapse (median) non_housing_wealth, by(race year education)
	twoway (line non_housing_wealth year if race == "black" & education == "no college", lcolor(red) lwidth(medthick) lpattern(dash))  ///
	(line non_housing_wealth year if race == "black" & education == "some college", lcolor(red) lwidth(medthick) lpattern(longdash_dot))  ///
	(line non_housing_wealth year if race == "black" & education == "college degree", lcolor(red) lwidth(medthick) lpattern(solid))  /// 
	(line non_housing_wealth year if race == "white" & education == "no college", lcolor(blue) lwidth(medthick) lpattern(dash)) ///
	(line non_housing_wealth year if race == "white" & education == "some college", lcolor(blue) lwidth(medthick) lpattern(longdash_dot)) ///
	(line non_housing_wealth year if race == "white" & education == "college degree", lcolor(blue) lwidth(medthick) lpattern(solid) xline(2007, lwidth(thin) lcolor(black)) title(Median Non-Housing Wealth for Blacks and Whites (Age>25) 1989-2016) ytitle(Median Housing Wealth (2016 `$')) xtitle(Year) legend(order(1 "Black, No college" 2 "Black, Some college" 3 "Black, College degree" 4 "White, No college" 5 "White, Some college" 6 "White, College degree")) )


restore
