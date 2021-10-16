/*
This .do file iterates over all of the experimental sessions' files, cleans, 
and saves them. 
This .do file deals separately with cross-game data per session vs. 
cross-session data for a single game. For complicated SQL reasons, having both
formats is preferable for later analysis.
*/
** Author: Bennett Smith-Worthington

// Section 0: Setting up Stata
cls
clear all
program drop _all
set more off
/*
Section 1: Defining Paths
*/

// Section 1.0: User, dropbox, and auxiliary paths
global path "/Users/bennettsw" // Bennett's path 
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

// Section 1.4: Declaring globals for games' relevant variables
// participant_indentifiers is a global of variables common to every game
global participant_indentifiers participant_code participant_label session_code
// Structure of game-specific globals: `game'_relevant_vars; these are globals
// that we'll use in 
global corruption_relevant_vars corruption*playercitizen_choice_ corruption*playerasked_amount
global iat_ethnicity_relevant_vars iat_ethnicity*playeriat_score iat_ethnicity*playeriat_feedback
global iat_relevant_vars iat*playeriat_score iat*playeriat_feedback
global payment_info_relevant_vars payment_info*playercourse_choice
global public_goods_relevant_vars public_goods*player*contribution
global trust_relevant_vars trust*group*sent_amount trust*group*sent_back_amount
global big_five_relevant_vars bigfive*player*extraversion bigfive*player*agreeableness bigfive*player*conscientiousness bigfive*player*neuroticism bigfive*player*openness
global menu_app_relevant_vars *course_choice
/*
Section 2: Programs 
*/s
// Note this program is the last thing called in the .do file, so it refers to
// content introduced in Section 4
program renamer
	/*
	Description: 
	There are eight types of games; this program loads each game's parsed  
	data separately and removes the name of the game in a variable so that each 
	sheet is displayed more cleanly. Then, it overwrites the file in 
	$aux_path (see globals).
	
	INPUT: `parsed_results' files of each game (8 files in total)
	OUTPUT: cleaned `parsed_results' files of each game (8 files in total) 
	*/

	foreach game of local games {
				import delimited "$aux_path/parsed_results_`game'", encoding(UTF-8) clear 
				
				// Adding round number to the end of the variable 
				rename `game'* `game'*#, addnumber
				
				// Dropping the game name as a prefix for each variable
				rename `game'* **
			save "$aux_path/parsed_results_`game'", replace 
			export delimited using "$aux_path/parsed_results_`game'", replace 
	}
end




/*
Section 3: File name aggregator
*/
/*
Since the experiment has multiple rounds, and data from each round is kept in a 
round-specific folder, it is necesssary to aggregate all the file names so that
this .do can iterate over all of them later. This chunk of python gets the file
names and puts them into globals. This process is very easily achieved in Python
which is why I use it instead of Stata code. 
*/ 

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

/*
 Section 4: Extracting & Saving Files from Both Rounds
*/
/*
This code goes into the folder associated with each round
(first round and make-up round), loads a file of a particular session, cleans
it, then saves it with the name: "data_`session_number'", where file counter
is the session number  
*/

// Section 4.1: Saving individual files

local path_counter = 1

foreach path of global round_paths { // iterating over each round's folder 
	
	local counter = 1
	// if path_counter is 1 -> process round 1 files; else -> process make-up
	// round files
	if `path_counter' == 1 {
		global apps_wide_files $first_round_files
	}
	else {
	    global apps_wide_files $make_up_files
	}
	// Loop below removes odd punctuation between key variables; cleans other
	// variable names, giving us standard variable names across files
	foreach file of global apps_wide_files { // looping over relevant folder
		
		//importing and cleaning the apps_wide_files 
		import delimited "`path'/`file'", encoding(UTF-8) colrange(1:1000) clear
			
			local session_number = `counter'+(`path_counter'-1)*`num_first_round_files'
			// removing punctuation from key variables
			rename participant*label participant_label
			rename participant*code participant_code
			rename sessioncode session_code
			tostring(participant_label), replace
			tostring(session_code), replace

			// Creates var that counts number of files processed, then 
			// saves the file with that number at the end
			local session_number = `counter'+(`path_counter'-1)*`num_first_round_files'
			save "$aux_path/data_`session_number'", replace
			local ++counter
	}
	local ++path_counter // once done with first folder, need to move to second
}

local --counter // since the counter increases after the last file is imported

// Section 4.2: Combining individual files into one: data_1


// After generating data_1, data_2, ..., data_`session_number' 
// this puts them all into data_1:

forvalues index = 2 (1) `session_number' { 
	// `session_number' ends last loop as how many `data_' files were generated  
	use "$aux_path/data_1" 
	append using "$aux_path/data_`index'", force
	save "$aux_path/data_1", replace	
}	


// Section 4.3: Creating parsed_results files

foreach game of local games {
	// preserving/restoring so we can keep using data_1 again and again 
	preserve
		use data_1, clear
		// keeping relevant vars for each game 
		keep($participant_indentifiers $`game'_relevant_vars)
		
		/* If a participant_label = "label_" and some number, that means that 
		it was a supervisor playing. So, this is dropping participants that are 
		actually supervisors in solo games */
		drop if ("`game'" == "iat" | "`game'" == "iat_ethnicity" | "`game'" == "payment_info" | "`game'" == "big_five") & (participant_label == "label_1" | participant_label == "label_2" | participant_label == "label_3" | participant_label == "label_4")
		export excel "$aux_path/parsed_results_`game'", first(var) replace 
	restore
	}

// Finally, running program 'renamer' so that we can have non-redundant variable
// names in each `parsed_results' file: 
renamer

//deleting aux_data
!rmdir "$aux_path" /s /q

