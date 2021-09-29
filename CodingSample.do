/*
 TODO: Give description of what this .do file does, as well as what input this 
 .do file takes, and what output this gives. 
 TODO: Set up sections; for example, Section 0: 
*/
** Author: Bennett Smith-Worthington

// Section 0: Setting up Stata
cls
clear all
program drop _all
set more off

// Section 1: Defining Paths

// Section 1.0: User, dropbox, and auxiliary paths
global path "/Users/bennettsw" // Bennett's path 
//global path "D:" // Marco's path
global dbox "$path/Dropbox/PeruContraloria/Data/Denuncias"
global aux_path "$path/aux_data" // "Local" folder for aux data

// Section 1.1: Input paths
global in_path "$dbox/in"
global complaints_learning "$in_path/ComplaintsLearning"
global page_times_path "$complaints_learning/PageTimes"
global app_wide_path "$complaints_learning/app_wide_files"
global first_round "$app_wide_path/First_round"
global make_up "$app_wide_path/Makeup_sessions/fixed_files"
global complaints_data "$complaints_learning/complaints_data"

// Section 1.2: Output paths
global out "$dbox/out"
global parsed_data "$out/Lab Experiment/Cleaned data/Parsed data"
local games "corruption iat_ethnicity iat payment_info public_goods trust big_five menu_app"

// Section 1.3: Setting up auxiliary directory and path 
cap mkdir "$aux_path" 
cd "$aux_path"

/*
Section 2: Programs 
*/

// TODO: Add decsription of each program. Follow the format given by Marco's 
// tables_and_plots.do; put input and output as well (a la Marco)
// This program reshapes the data from wide to long. First, it changes names of variables
// then it reshapes them accordingly 

program reshaper
	foreach game of local games {
				import delimited "$aux_path/parsed_results_`game'", encoding(UTF-8) colrange(1:1000) clear 
				
				// Adding round number to the end of the variable 
				rename `game'* `game'*#, addnumber
				
				// Dropping the game name as a prefix for each variable
				rename `game'* **
			save "$aux_path/parsed_results_`game'", replace 
			export delimited using "$aux_path/parsed_results_`game'", replace 
	}
end


// This program removes the name of the game in a variable so that each sheet is displayed more cleanly 
program cleaner 
		
		// dropping no responses for menu app
		use "$aux_path/parsed_results_menu_app", clear 
		drop if missing(menu_app1playercourse_choice) 	
		export delimited "$aux_path/parsed_results_menu_app", replace 
		
		// dropping no responses for payment info
		use "$aux_path/parsed_results_payment_info", clear 
		drop if missing(payment_info1playercourse_choice) 	
		export delimited "$aux_path/parsed_results_payment_info", replace 

end


/*
Section 3: TODO: Give a name to this section that describes what the code within
the section does 
*/

// Explain what this code does, and why I use python instead of stata. Give the 
// reason why I use python instead of stata (max 1 line)
python:
from sfi import Macro
from os import listdir
from os.path import isfile, join

# setting up paths
first_round = Macro.getGlobal("first_round")
make_up = Macro.getGlobal("make_up")

# getting file names
first_round_files = [f for f in listdir(first_round) if isfile(join(first_round, f))]
make_up_files = [f for f in listdir(make_up) if isfile(join(make_up, f))]

# omitting unnecessary files
first_round_files = [f for f in first_round_files if f != ".DS_Store"]
make_up_files = [f for f in make_up_files if f != ".DS_Store"]
make_up_files = [f for f in make_up_files if f != ".R"]

# joining files into string
# first_round_files_str = join(first_round_files, " ")
# make_up_files_str = join(make_up_files, " ")

# calculating num files per round
num_first_round_files = len(first_round_files)
num_make_up_files = len(make_up_files)
num_total_files = num_first_round_files + num_make_up_files

# storing the file names as stata global
Macro.setGlobal("first_round_files", " ".join(first_round_files))
Macro.setGlobal("make_up_files", " ".join(make_up_files))

# storing num files as stata local
Macro.setLocal("num_first_round_files", str(num_first_round_files))
Macro.setLocal("num_make_up_files", str(num_make_up_files))
Macro.setLocal("num_total_files", str(num_total_files))

# storing iterable paths as stata global
Macro.setGlobal("round_paths", first_round + " " + make_up)
end


// Section 4: TODO: Give this a name 
// Need to document this well, given that there are multiple nested loops. 
// Be concise! 
// First, give a single line explanation of what this code block does 
local path_counter = 1
// Say what this loop iterates over 
foreach path of global round_paths { // Or put the comment here 
	
	local counter = 1
	// Say what this if/else statement does/means 
	if `path_counter' == 1 {
		global apps_wide_files $first_round_files
	}
	else {
	    global apps_wide_files $make_up_files
	}
	// Say what this loop does/ what it iterates over 
	foreach file of global apps_wide_files { // again, could be here 
		
		
		//importing and parsing the apps_wide_files 
		import delimited "`path'/`file'", encoding(UTF-8) colrange(1:1000) clear
			
			local file_counter = `counter'+(`path_counter'-1)*`num_first_round_files'
			rename participant*label participant_label
			rename participant*code participant_code
			rename sessioncode session_code
			tostring(participant_label), replace
			tostring(session_code), replace

			// Line that explains what this block does
			local file_counter = `counter'+(`path_counter'-1)*`num_first_round_files'
			save "$aux_path/data_`file_counter'", replace
			if `file_counter' == 15 export delimited "$aux_path/data_`file_counter'", replace
			local ++counter
	}
	local ++path_counter // brief explanation of why we increment this path_counter
}

local --counter // since the counter increases after the last file is imported
// TODO: Rename the counters! They need names that accurately represent what
// they store. 

// Append loop, as it appeared before: 
// ** Append loop
forvalues index = 2 (1) `file_counter' {
	use "$aux_path/data_1" 
	append using "$aux_path/data_`index'", force
	save "$aux_path/data_1", replace	
}	

export delimited "$aux_path/data_1", replace

















// Keeping variables of importance in each game 
foreach game of local games {
	preserve
		use data_1, clear
		// TODO: create a global with the variables that are present in every 
		// game's database, like participant_code participant_label; then 
		// replace the variables with the global ($participant_identifiers) in each call. 
		global participant_indentifiers participant_code participant_label
		// Keeping relevant variables depending on the game we're looking at
		if "`game'" == "corruption" keep(participant_code participant_label corruption*playercitizen_choice_ corruption*playerasked_amount session_code)
		if "`game'"== "iat_ethnicity" keep(participant_code participant_label session_code iat_ethnicity*playeriat_score iat_ethnicity*playeriat_feedback)  // Need to ask what variables to keep here
		if "`game'" == "iat" keep(participant_code participant_label session_code iat*playeriat_score iat*playeriat_feedback)
		if "`game'" ==  "payment_info" keep(participant_code participant_label session_code payment_info*playercourse_choice)
		if "`game'" == "public_goods" keep(participant_code participant_label session_code public_goods*player*contribution)
		if "`game'" == "trust" keep(participant_code participant_label session_code trust*group*sent_amount trust*group*sent_back_amount) 
		if "`game'" == "big_five" keep(participant_code participant_label session_code bigfive*player*extraversion bigfive*player*agreeableness bigfive*player*conscientiousness bigfive*player*neuroticism bigfive*player*openness)
		
		// TODO: add section on menu game, i just dont know which var we want here: 
		if "`game'" == "menu_app" keep(participant_code participant_label session_code *course_choice)
		
		// If a participant_label = "label_" and some number, that means that it was a supervisor playing
		// So, this is dropping participants that are actually supervisors in non-interactive games
		drop if ("`game'" == "iat" | "`game'" == "iat_ethnicity" | "`game'" == "payment_info" | "`game'" == "big_five") & (participant_label == "label_1" | participant_label == "label_2" | participant_label == "label_3" | participant_label == "label_4")
		
		/* KEEP THIS COMMENTED FOR NOW SO THAT IT CAN BE EDITED LATER
		
		// Renaming bigfive to big_five
		if "`game'" == "big_five" rename bigfive* big_five* 
		
		
		
		// removing 'player' from name of each variable name in corruption game
		if "`game'" == "corruption" | "`game'" == "public_goods" rename *player* **
		if "`game'" == "iat_ethnicity" rename *1playeriat* **
		*/
		// Saving and exporting parsed results to csv with name of game in file name
		save "$aux_path/parsed_results_`game'", replace 
		export delimited using "$aux_path/parsed_results_`game'", replace 
	restore
	}
// remind the reader of what this code does again (the program below)
cleaner 
// check the original .do file on git to see if reshaper is used? 
// I think it was called 'behavioral parser'
//reshaper 
/*
Variables of importance: Public goods: contributions, Trust: send, send back, Corruption: citizen_choice_scenario_num, asked amount, IAT: iat_score, iat_feedback, big five: the five personality characteristics.
*/

//deleting aux_data
//!rmdir "$aux_path" /s /q

