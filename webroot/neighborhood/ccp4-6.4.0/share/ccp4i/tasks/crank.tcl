#
# Copyright (C) 2004-2005 Steven Ness and Navraj S. Pannu, Leiden University
# Copyright (C) 2006-2007 Navraj S. Pannu, Leiden University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# Experimental data input - Crystal/Dataset
# 
#
proc crystal_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes
    
    foreach subframe $all_subframes {
	trace vdelete array(INPUT_INTENSITY) w "update_main_scroll $subframe"  
 	for  { set i 0 } { $i < $array(N_CRYSTALS) } { incr i} {
	    trace vdelete array(CRYSTAL_INPUT_SUBSTRUCTURE,$i) w "update_main_scroll $subframe"  
 	    trace vdelete array(CRYSTAL_NATIVE,$i) w "update_main_scroll $subframe"  
	}
    }

    OpenSubFrame frame -toggle_display CRYSTAL_NATIVE,$counter open 1

    lappend all_subframes $frame

        CreateLine line \
            label "                                                       " \
            label "                                                       " \
            label "                                                       "

    CloseSubFrame

    OpenSubFrame frame -toggle_display CRYSTAL_NATIVE,$counter open 0

    lappend all_subframes $frame	

    OpenSubFrame frame -toggle_display PREMADE_START open "DETECT"

    lappend all_subframes $frame	

    CreateLine line \
	label "Substructure atom" \
	message "Element name of substructure atom" \
	widget CRYSTAL_ATOM_NAME -oblig \
	label "Number of substructure atoms per monomer" \
	message "Approximate number of substructure atoms to find per monomer" \
	widget CRYSTAL_N_ATOMS -oblig

    CloseSubFrame

    OpenSubFrame frame -toggle_display PREMADE_START hide "DETECT"

    lappend all_subframes $frame	

    CreateLine line \
	label "Number of different anomalous scatterers in crystal" \
        message "More than one type of anomalous scatterer" \
        widget N_WATOMS -command "setup_experiment $arrayname"


    OpenSubFrame frame -toggle_display CRYSTAL_INPUT_SUBSTRUCTURE,$counter open 1

    lappend all_subframes $frame	
    
    CreateLine line \
 	label "Input substructure " \
 	message "Input a substructure" \
 	widget CRYSTAL_INPUT_SUBSTRUCTURE_TYPE

    OpenSubFrame frame -toggle_display CRYSTAL_INPUT_SUBSTRUCTURE_TYPE,$counter open "Pdb"

    lappend all_subframes $frame	

    CreateInputFileLine line \
 	"Enter input substructure PDB file name" \
 	"COORDS in" \
 	SUBSTRUCTURE_INPUT_COORDSIN DIR_SUBSTRUCTURE_INPUT_COORDSIN \
	-command "getatomname $arrayname $counter"

    CloseSubFrame

    OpenSubFrame frame -toggle_display CRYSTAL_INPUT_SUBSTRUCTURE_TYPE,$counter open "Manual"

    lappend all_subframes $frame	

    CreateLine line \
	label "Coordinate format" \
	message "Choose to input either orthogonal or fractional coordinates" \
	widget COORDINATE_FORMAT 

   CreateExtendingFrame N_ATOMS atom_proc \
	"Define Atom" \
	"Add Atom" \
	[list  ATOM_ID \
	     ATOM_X \
	     ATOM_Y \
	     ATOM_Z \
	     ATOM_X_NOREF \
	     ATOM_Y_NOREF \
	     ATOM_Z_NOREF \
	     ATOM_OCCU \
	     ATOM_BISO \
	     ATOM_OCCU_NOREF \
	     ATOM_BISO_NOREF \
	     ISOTROPIC_B] \
	-counter $counter 

    CloseSubFrame

    CloseSubFrame

    CloseSubFrame

    CloseSubFrame

    OpenSubFrame frame -toggle_display CRYSTAL_NATIVE,$counter open 1

    lappend all_subframes $frame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 1

    lappend all_subframes $frame

    CreateLabinLine4 line \
	"I" \
	HKLIN "I"  DATA_I {} \
	-sigma "SIGI" DATA_SIGI {} \
	-toggle_display DATA_ANOMALOUS,$counter open 1 \
	-command "rungetstuff $arrayname 0"

    CloseSubFrame
 
    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 0

    lappend all_subframes $frame

    CreateLabinLine4 line \
	"F" \
	HKLIN "F"  DATA_F {} \
	-sigma "SIGF" DATA_SIGF {} \
	-toggle_display DATA_ANOMALOUS,$counter open 1 \
	-command "rungetstuff $arrayname 0"

    CloseSubFrame

    CloseSubFrame

    OpenSubFrame frame -toggle_display CRYSTAL_NATIVE,$counter open 0

    lappend all_subframes $frame


   Create_nolabel_ExtendingFrame N_DATA data_proc \
	"Define Data" \
	"Add new Dataset to this Crystal" \
	[list  DATA_TYPE \
	     DATA_CUKALPHA \
	     DATA_ANOMALOUS \
	     N_WATOMS \
	     ATOM_WAVE_ID1 \
	     DATA_FPRIME1 \
	     DATA_FPRIMEPRIME1 \
	     ATOM_WAVE_ID2 \
	     DATA_FPRIME2 \
	     DATA_FPRIMEPRIME2 \
	     ATOM_WAVE_ID3 \
	     DATA_FPRIME3 \
	     DATA_FPRIMEPRIME3 \
	     ATOM_WAVE_ID4 \
	     DATA_FPRIME4 \
	     DATA_FPRIMEPRIME4 \
	     ATOM_WAVE_ID5 \
	     DATA_FPRIME5 \
	     DATA_FPRIMEPRIME5 \
	     ATOM_WAVE_ID6 \
	     DATA_FPRIME6 \
	     DATA_FPRIMEPRIME6 \
	     DATA_WAVELENGTH \
	     DATA_TYPE \
	     DATA_I \
	     DATA_SIGI \
	     DATA_I_PLUS \
	     DATA_SIGI_PLUS \
	     DATA_I_MINUS \
	     DATA_SIGI_MINUS \
	     DATA_F \
	     DATA_SIGF \
	     DATA_F_PLUS \
	     DATA_SIGF_PLUS \
	     DATA_F_MINUS \
	     DATA_SIGF_MINUS ] \
	-noaddline \
	-counter $counter 

    CloseSubFrame

    rebuild_varmenus $arrayname
}

proc data_proc { arrayname c2 counter } {

    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(INPUT_INTENSITY) w "update_main_scroll $subframe"  
	for  { set i 0 } { $i < $array(N_CRYSTALS) } { incr i} {
	    trace vdelete array(CRYSTAL_INPUT_SUBSTRUCTURE,$i) w "update_main_scroll $subframe"  
	    trace vdelete array(CRYSTAL_NATIVE,$i) w "update_main_scroll $subframe"  
	}
    } 

    OpenSubFrame frame -toggle_display CRYSTAL_NATIVE,$counter open 0

    lappend all_subframes $frame

    CreateLine line \
	label "Dataset : $c2" \
	message "Dataset : $c2" \
	label "Type" \
	message "Type" \
	widget DATA_TYPE \
	-command "rebuild_varmenus $arrayname" 

    CreateLine line \
	label "Data collected at CuKa wavelength" \
	message "Use f' and f'' for atom at CuKa" \
	widget DATA_CUKALPHA 

    CloseSubFrame

    OpenSubFrame frame -toggle_display [Indxv DATA_CUKALPHA $counter $c2] hide 1

    lappend all_subframes $frame
    
    atom_wave_proc $arrayname $counter $c2

    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 1

    lappend all_subframes $frame

    CreateLabinLine4 line \
	"I" \
	HKLIN "I"  DATA_I {} \
	-sigma "SIGI" DATA_SIGI {} \
	-toggle_display [Indxv DATA_ANOMALOUS $counter $c2] hide 1 \
	-command "rungetstuff $arrayname 0"

    CreateLabinLine4 line \
	"IP" \
	HKLIN "IP+" DATA_I_PLUS {} \
	-sigma "SIGIP+" DATA_SIGI_PLUS {} \
	-dependent "IP-" DATA_I_MINUS {} \
	-sigma "SIGIP-" DATA_SIGI_MINUS {} \
	-toggle_display [Indxv DATA_ANOMALOUS $counter $c2] hide 0 \
	-command "rungetstuff $arrayname 0"

    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 0

    lappend all_subframes $frame

    CreateLabinLine4 line \
	"F" \
	HKLIN "F"  DATA_F {} \
	-sigma "SIGF" DATA_SIGF {} \
	-toggle_display [Indxv DATA_ANOMALOUS $counter $c2] hide 1 \
	-command "rungetstuff $arrayname 0"

    CreateLabinLine4 line \
	"F" \
 	HKLIN "FP+" DATA_F_PLUS {} \
	-sigma "SIGFP+" DATA_SIGF_PLUS {} \
	-dependent "FP-" DATA_F_MINUS {} \
	-sigma "SIGFP-" DATA_SIGF_MINUS {} \
	-toggle_display [Indxv DATA_ANOMALOUS $counter $c2] hide 0 \
	-command "rungetstuff $arrayname 0"

    CloseSubFrame

    rebuild_varmenus $arrayname
}

proc atom_proc { arrayname c1 counter } {

    upvar #0 $arrayname array

    if { [info exists array(CRYSTAL_ATOM_NAME,$counter)] } {
	if { $array(ATOM_ID,${counter}_${c1}) == "" } {
	    set array(ATOM_ID,${counter}_${c1}) [string toupper $array(CRYSTAL_ATOM_NAME,$counter)] 
	}
    }	

    if { [info exists array(BFACTOR)] } {
	if { $array(ATOM_BISO,${counter}_${c1}) == "" } {
	    set array(ATOM_BISO,${counter}_${c1}) $array(BFACTOR) 
	}
    }
	
    CreateLine line \
	label "Atom $c1 : " \
	-italic \
	label "Atom ID" \
	message "Atom ID" \
	widget ATOM_ID 
#	 	label "Isotropic B factors" \
#		message "Isotropic B factors " \
#		widget ISOTROPIC_B 
	

    CreateLine line \
	message "Coordinates : " \
	label "Coords : " \
	message "X Coordinate" \
	label "X" \
	widget ATOM_X \
	message "Do not refine x coordinate" \
	label "NOREF" \
	widget ATOM_X_NOREF \
	message "Y Coordinate" \
	label "Y" \
	widget ATOM_Y \
	message "Do not refine y coordinate" \
	label "NOREF" \
	widget ATOM_Y_NOREF \
	message "Z Coordinate" \
	label "Z" \
	widget ATOM_Z \
	message "Do not refine z coordinate" \
	label "NOREF" \
	widget ATOM_Z_NOREF 

    CreateLine line \
	message "Atomic occupancy" \
	label "Occupancy" \
	widget ATOM_OCCU \
	message "Do not refine the occupancy" \
	label "NOREF" \
	widget ATOM_OCCU_NOREF \
	message "Atomic isotropic B factor" \
	label "Biso" \
	widget ATOM_BISO  \
	message "Do not refine the B factor" \
	label "NOREF" \
	widget ATOM_BISO_NOREF 

    rebuild_varmenus $arrayname
}

proc atom_wave_proc { arrayname crys data } {

    upvar #0 $arrayname array
    global all_subframes

    if { [info exists array(CRYSTAL_ATOM_NAME,$crys)] } {
	if { $array(ATOM_WAVE_ID1,${crys}_${data}) == "" } {
	    set array(ATOM_WAVE_ID1,${crys}_${data}) [string toupper $array(CRYSTAL_ATOM_NAME,$crys)] 
	}
    }	

    OpenSubFrame frame -toggle_display PREMADE_START open "DETECT"

    lappend all_subframes $frame

	CreateLine line \
	    label "Atom : " \
	    -italic \
	    label "f'" \
	    message "f' - F prime" \
	    widget DATA_FPRIME1 -oblig \
	    label "f''" \
	    message "f'' - F double prime" \
	    widget DATA_FPRIMEPRIME1 -oblig 

    CloseSubFrame

    OpenSubFrame frame -toggle_display PREMADE_START hide "DETECT"

    lappend all_subframes $frame 
    
    for { set i 1 } { $i <= $array(N_WATOMS,$crys) } { incr i } {
	CreateLine line \
	    label "Atom : $i" \
	    -italic \
	    label "Atom ID" \
	    message "Atom ID" \
	    widget ATOM_WAVE_ID$i -oblig \
	    label "f'" \
	    message "f' - F prime" \
	    widget DATA_FPRIME$i -oblig \
	    label "f''" \
	    message "f'' - F double prime" \
	    widget DATA_FPRIMEPRIME$i -oblig 
    }

    CloseSubFrame

    rebuild_varmenus $arrayname
}

proc rebuild_varmenus { arrayname } {
    global typedef
    global tcl_platform
    upvar #0 $arrayname array

    global PluginList
    global XMLParse
    global all_subframes

     if { ( [info exists array(N_PROGRAMS)] && [info exists array(N_CRYSTALS) ] ) } {
	 if { ( ($array(N_PROGRAMS) == 0) || ($array(N_CRYSTALS) == 0 ) ||
		($array(N_PROGRAMS) == "") || ($array(N_CRYSTALS) == "" ) ) } {
	     return 0
	 }
     } else {
	 return 0
     }

    # Each step has it's own set of varmenus, initialize all of these now
    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {
	set menulist_experimental_columns($step) {}
	set menulist_f_columns($step) {}
	set menulist_i_columns($step) {}
	set menulist_phase_columns($step) {}
	set menulist_hl_columns($step) {}
	set menulist_ea_columns($step) {}
	set menulist_fa_columns($step) {}
	set menulist_alpha_columns($step) {}
	set menulist_phic_columns($step) {}
	set menulist_freer_columns($step) {}
	set menulist_substructure($step) {}
	set menulist_substructure_list($step) {}
	set menulist_substructure_model($step) {}
	set menulist_pdb($step) {}
	set menulist_pdb_list($step) {}
	set menulist_pdb_model($step) {}
	set menulist_defaults($step) {}
    }

    # Loop over all program steps setting all the input sources
    # of data.  For this part, all the programs get identical 
    # lists.  It's only down below in the step part that the 
    # varmenus become different.
    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {

	#
	# Update the menulists for the CRYSTAL/DATASET section
	#
	lappend menulist_experimental_columns($step) "IN"
 	lappend menulist_substructure($step) "IN"
	lappend menulist_freer_columns($step) "1_PREP"
	lappend menulist_f_columns($step) "IN_X1_D1"
    }

    #
    # Update the menulists for the PROGRAM section

    for { set menulist 1 } { $menulist <= [expr $array(N_PROGRAMS) + 1] } { incr menulist } {
 	for { set step 1 } { $step < $menulist } { incr step } {
	    set name [string tolower $array(PROGRAM_NAME,$step)]
	    set tag $array(PROGRAM_TAG,$step)

	    #
	    # Pseudocode:
	    # Find if the current $name matches any of
	    # the plugin names.  If so, find what kinds
	    # of columns or data to append to which lists
	    # and append it.
	    #

	    # Find matching plugin name
	    foreach program $PluginList {
 		if { [string compare [string tolower $program] $name] == 0 } {
		    #
		    # Add Experimental Columns
		    #
		    if { [info exists XMLParse(crank__plugin=${name}__output__experimental_columns)] } {
			# Add an experimental column for this dataset
			lappend menulist_experimental_columns($menulist) $tag
			# Add an F_COLUMN for each CRYSTAL/DATASET pair
			for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
			    for { set j 1 } { $j <= $array(N_DATA,$i) } { incr j } {
				set type $array(DATA_TYPE,${i}_${j})
				set column "X${i}_D${j}"
				lappend menulist_f_columns($menulist) "${tag}_${column}"
			    }
			}
		    }
		    if { [info exists XMLParse(crank__plugin=${name}__output__f_columns)] } {
			lappend menulist_f_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__i_columns)] } {
			lappend menulist_i_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__phase_columns)] } {
			lappend menulist_phase_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__hl_columns)] } {
			lappend menulist_hl_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__ea_columns)] } {
			lappend menulist_ea_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__fa_columns)] } {
			lappend menulist_fa_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__alpha_columns)] } {
			lappend menulist_alpha_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__phic_columns)] } {
			lappend menulist_phic_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__freer_columns)] } {
			lappend menulist_freer_columns($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__substructure)] } {
			lappend menulist_substructure($menulist) $tag
		    }					
		    if { [info exists XMLParse(crank__plugin=${name}__output__pdb)] } {
			lappend menulist_pdb($menulist) $tag
		    }					
		}
	    }
	    
	}
    }

    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {
		
	UpdateVariableMenu $arrayname initialise 0 \
	    INPUT_EXPERIMENTAL_COLUMNS_LIST,$step $menulist_experimental_columns($step) \
	    INPUT_EXPERIMENTAL_COLUMNS_ALIAS,$step $menulist_experimental_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_F_COLUMNS_LIST,$step $menulist_f_columns($step) \
 	    INPUT_F_COLUMNS_ALIAS,$step $menulist_f_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_I_COLUMNS_LIST,$step $menulist_i_columns($step) \
 	    INPUT_I_COLUMNS_ALIAS,$step $menulist_i_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_PHASE_COLUMNS_LIST,$step $menulist_phase_columns($step) \
 	    INPUT_PHASE_COLUMNS_ALIAS,$step $menulist_phase_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_HL_COLUMNS_LIST,$step $menulist_hl_columns($step) \
 	    INPUT_HL_COLUMNS_ALIAS,$step $menulist_hl_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_EA_COLUMNS_LIST,$step $menulist_ea_columns($step) \
 	    INPUT_EA_COLUMNS_ALIAS,$step $menulist_ea_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_FA_COLUMNS_LIST,$step $menulist_fa_columns($step) \
 	    INPUT_FA_COLUMNS_ALIAS,$step $menulist_fa_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_ALPHA_COLUMNS_LIST,$step $menulist_alpha_columns($step) \
 	    INPUT_ALPHA_COLUMNS_ALIAS,$step $menulist_alpha_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_FREER_COLUMNS_LIST,$step $menulist_freer_columns($step) \
 	    INPUT_FREER_COLUMNS_ALIAS,$step $menulist_freer_columns($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_SUBSTRUCTURE_LIST,$step $menulist_substructure($step) \
 	    INPUT_SUBSTRUCTURE_ALIAS,$step $menulist_substructure($step)

 	UpdateVariableMenu $arrayname initialise 0 \
 	    INPUT_PDB_LIST,$step $menulist_pdb($step) \
 	    INPUT_PDB_ALIAS,$step $menulist_pdb($step)

    }

    set inputsubstructure 0

    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {
	if { [ info exists array(PROGRAM_NAME,$step) ] } {
	    set program_name [string tolower $array(PROGRAM_NAME,$step)]
	} else {
	    set program_name ""
	}


	set experimental_columns [lindex $menulist_experimental_columns($step) [expr [llength $menulist_experimental_columns($step)] - 1]]
	set f_columns [lindex $menulist_f_columns($step) [expr [llength $menulist_f_columns($step)] -1]]
	set i_columns [lindex $menulist_i_columns($step) [expr [llength $menulist_i_columns($step)] -1]]
	set phase_columns [lindex $menulist_phase_columns($step) [expr [llength $menulist_phase_columns($step)] -1]]
	set hl_columns [lindex $menulist_hl_columns($step) [expr [llength $menulist_hl_columns($step)] -1]]
	set ea_columns [lindex $menulist_ea_columns($step) [expr [llength $menulist_ea_columns($step)] -1]]
	set fa_columns [lindex $menulist_fa_columns($step) [expr [llength $menulist_fa_columns($step)] -1]]
	set alpha_columns [lindex $menulist_alpha_columns($step) [expr [llength $menulist_alpha_columns($step)] -1]]
	set phic_columns [lindex $menulist_phic_columns($step) [expr [llength $menulist_phic_columns($step)] -1]]
	set freer_columns [lindex $menulist_freer_columns($step) [expr [llength $menulist_freer_columns($step)] -1]]
	set substructure [lindex $menulist_substructure($step) [expr [llength $menulist_substructure($step)] -1]]
	set pdb [lindex $menulist_pdb($step) [expr [llength $menulist_pdb($step)] -1]]

	set array(INPUT_EXPERIMENTAL_COLUMNS,$step) $experimental_columns
	set array(INPUT_F_COLUMNS,$step) $f_columns 		
	set array(INPUT_I_COLUMNS,$step) $i_columns
	set array(INPUT_PHASE_COLUMNS,$step) $phase_columns
	set array(INPUT_HL_COLUMNS,$step) $hl_columns
	set array(INPUT_EA_COLUMNS,$step) $ea_columns
	set array(INPUT_FA_COLUMNS,$step) $fa_columns
	set array(INPUT_ALPHA_COLUMNS,$step) $alpha_columns
	set array(INPUT_FREER_COLUMNS,$step) $freer_columns
	set array(INPUT_SUBSTRUCTURE,$step) $substructure
	set array(INPUT_PDB,$step) $pdb

	if { [info exists XMLParse(crank__plugin=${program_name}__input__substructure)] } {
	    if { $array(INPUT_SUBSTRUCTURE,$step) == "IN" } {
		set inputsubstructure 1
	    }
	}

	if { $program_name == "shelxc" } {
	    set array(INPUT_EXPERIMENTAL_COLUMNS,$step) "IN"
	}
    }

    for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
	foreach subframe $all_subframes {
	    trace vdelete array(CRYSTAL_INPUT_SUBSTRUCTURE,$i) w "update_main_scroll $subframe"
	}
	if {$inputsubstructure == 1} {
 	    if { $array(CRYSTAL_NATIVE,$i) == 0 } {
		set array(CRYSTAL_INPUT_SUBSTRUCTURE,$i) 1
	    }
	} else {
	    set array(CRYSTAL_INPUT_SUBSTRUCTURE,$i) 0
	}
	SetSystemVar block_scroll_update 0
	update_main_scroll $array(FRAME_experiment_proc_0)
    }
}


proc new_varmenu { arrayname counter } {

    global typedef
	
    if { ![info exists typedef(_input_experimental_columns_$counter)] } {
	set typedef(_input_experimental_columns_$counter) \
	    [list varmenu INPUT_EXPERIMENTAL_COLUMNS_LIST,$counter INPUT_EXPERIMENTAL_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_EXPERIMENTAL_COLUMNS,$counter _input_experimental_columns_$counter ""
    }

    if { ![info exists typedef(_input_f_columns_$counter)] } {
	set typedef(_input_f_columns_$counter) \
	     [list varmenu INPUT_F_COLUMNS_LIST,$counter INPUT_F_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_F_COLUMNS,$counter _input_f_columns_$counter ""
    }

    if { ![info exists typedef(_input_i_columns_$counter)] } {
	set typedef(_input_i_columns_$counter) \
	    [list varmenu INPUT_I_COLUMNS_LIST,$counter INPUT_I_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_I_COLUMNS,$counter _input_i_columns_$counter ""
    }

    if { ![info exists typedef(_input_phase_columns_$counter)] } {
	set typedef(_input_phase_columns_$counter) \
	    [list varmenu INPUT_PHASE_COLUMNS_LIST,$counter INPUT_PHASE_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_PHASE_COLUMNS,$counter _input_phase_columns_$counter ""
    }

    if { ![info exists typedef(_input_hl_columns_$counter)] } {
	set typedef(_input_hl_columns_$counter) \
	    [list varmenu INPUT_HL_COLUMNS_LIST,$counter INPUT_HL_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_HL_COLUMNS,$counter _input_hl_columns_$counter ""
    }

    if { ![info exists typedef(_input_ea_columns_$counter)] } {
	set typedef(_input_ea_columns_$counter) \
	    [list varmenu INPUT_EA_COLUMNS_LIST,$counter INPUT_EA_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_EA_COLUMNS,$counter _input_ea_columns_$counter ""
    }

    if { ![info exists typedef(_input_fa_columns_$counter)] } {
	set typedef(_input_fa_columns_$counter) \
	    [list varmenu INPUT_FA_COLUMNS_LIST,$counter INPUT_FA_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_FA_COLUMNS,$counter _input_fa_columns_$counter ""
    }

    if { ![info exists typedef(_input_alpha_columns_$counter)] } {
	set typedef(_input_alpha_columns_$counter) \
	    [list varmenu INPUT_ALPHA_COLUMNS_LIST,$counter INPUT_ALPHA_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_ALPHA_COLUMNS,$counter _input_alpha_columns_$counter ""
    }

    if { ![info exists typedef(_input_freer_columns_$counter)] } {
	set typedef(_input_freer_columns_$counter) \
	    [list varmenu INPUT_FREER_COLUMNS_LIST,$counter INPUT_FREER_COLUMNS_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_FREER_COLUMNS,$counter _input_freer_columns_$counter ""
    }

    if { ![info exists typedef(_input_substructure_$counter)] } {
	set typedef(_input_substructure_$counter) \
	     [list varmenu INPUT_SUBSTRUCTURE_LIST,$counter INPUT_SUBSTRUCTURE_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_SUBSTRUCTURE,$counter _input_substructure_$counter ""
    }

    if { ![info exists typedef(_input_pdb_$counter)] } {
	set typedef(_input_pdb_$counter) \
	     [list varmenu INPUT_PDB_LIST,$counter INPUT_PDB_ALIAS,$counter 20]
	DefineVariable $arrayname INPUT_PDB,$counter _input_pdb_$counter ""
    }

    # Default menus
    if { ![info exists typedef(_default_menu_$counter)] } {
	set typedef(_default_menu_$counter) \
	    [list varmenu DEFAULT_MENU_LIST,$counter DEFAULT_MENU_ALIAS,$counter 20]
	DefineVariable $arrayname DEFAULT_MENU,$counter _default_menu_$counter ""
    }
}

#
# The main crank experiment design section
#
#
# Determine which program we should run and run it.   
#
# Also, setup the next program to be run:
#  If we are running program X, then the next logical program is Y.
#
#
proc experiment_proc { arrayname counter } {
    upvar #0 $arrayname array
    global XMLParse
    global PluginList

    # Are we building a pipeline?  If so, don't update the
    # varmenus.  We will do so when we're done constructing
    # the pipeline.
    global building_pipeline

    new_varmenu $arrayname $counter

    # Set the PROGRAM_NAME to the current program we are running
    #
    if { [info exists array(PROGRAM_NAME,[expr $counter + 1])] } {
        set program $array(PROGRAM_NAME,$counter)
    } else {
        set program $array(EXPERIMENTAL_PROGRAM)
    }


    # Set the correct PROGRAM_NAME to the string we just found
    set array(PROGRAM_NAME,$counter) $program
    set array(PROGRAM_TAG,$counter) "${counter}_${program}"
    set array(PROGRAM_STEP,$counter) $counter

    set name [string tolower $program]
 
    foreach program $PluginList {
	if { [string compare [string tolower $program] $name] == 0 } {
	    ${name}_proc $arrayname $counter

	    if { ![info exists array(PROGRAM_NAME,[expr $counter + 1])] } {
	
		set nextprogram $XMLParse(crank__plugin=${name}__nextprogram)

		foreach program2 $PluginList {
		    if { [string compare [string tolower $program2] $nextprogram] == 0 } {
			set array(EXPERIMENTAL_PROGRAM) [string toupper $nextprogram]
		    }
		}
	    } else {
		set nextprogram $array(PROGRAM_NAME,[expr $counter + 1])
		set array(EXPERIMENTAL_PROGRAM) [string toupper $nextprogram]
	    }
	}
    }
    rebuild_varmenus $arrayname
    set_program_defaults $arrayname
}

proc clear_program_defaults { arrayname } {
    upvar #0 $arrayname array

    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {
	if { [ info exists array(PROGRAM_NAME,$step) ] } {
	    set program_name [string tolower $array(PROGRAM_NAME,$step)]
	} else {
	    set program_name ""
	}

	if { $program_name == "arpwarp" } {
    	    if { [info exists array(ARPWARP_PHASE_RESTRAIN,$step) ] } {
		set array(ARPWARP_PHASE_RESTRAIN,$step) "" 
	    }
	}

	if { $program_name == "buccaneer" } {
  	    if { [info exists array(BUCCANEER_PHASE_RESTRAIN,$step) ] } {
		set array(BUCCANEER_PHASE_RESTRAIN,$step) ""
	    } 
	}

	if { $program_name == "solomon" } {

  	    if { [info exists array(SOLOMON_PHASE_COMB,$step) ] } {
		set array(SOLOMON_PHASE_COMB,$step) "" 
	    }
	}

	if { $program_name == "parrot" } {

  	    if { [info exists array(PARROT_PHASE_COMB,$step) ] } {
		set array(PARROT_PHASE_COMB,$step) "" 
	    }
	}
    }

}

proc set_program_defaults { arrayname } {
    global tcl_platform
    upvar #0 $arrayname array

    set windows 0

    if { [string compare $tcl_platform(platform) "windows"] == 0 } {
	set windows 1
    }

     if { ( [info exists array(N_PROGRAMS)] && [info exists array(N_CRYSTALS) ] ) } {
	 if { ( ($array(N_PROGRAMS) == 0) || ($array(N_CRYSTALS) == 0 ) ||
		($array(N_PROGRAMS) == "") || ($array(N_CRYSTALS) == "" ) ) } {
	     return 0
	 }
     } else {
	 return 0
     }

    # check if the refmac version has the SAD and SIRAS function:
    set refmac_sad 0
    set refmac_siras 0

    if { [file exists [FindExecutable refmac5]] } {
	set refmac_command "refmac5 -i"
	set refmac_script "\nEND\n"
	set command "$refmac_command << \"$refmac_script\""
	catch {eval exec $command } output
	if { [regexp {refmac5; version *([0-9.]*)} $output match version]} {
	    if { $version >= 5.5 } {
		set refmac_sad 1
	    }
	    if { $version >= 5.6 } {
		set refmac_siras 1
	    }
	}
    }

    set native_exists 0
    set anomalous_exists 0

    set mad_experiment 0
    set sad_experiment 0    
    set siras_experiment 0    

    if { [info exists array(N_CRYSTALS) ] } {

	for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
	    if { ($array(N_DATA,$i) > 1) } {
		set mad_experiment 1
	    } else {
		if { [info exists array(CRYSTAL_NATIVE,$i) ] } {
		    if { $array(CRYSTAL_NATIVE,$i) } {
			set native_exists 1
		    } 
		}
		if { [info exists array(DATA_ANOMALOUS,$i) ] } {
		    if { $array(DATA_ANOMALOUS,${i}_1) } {
			set anomalous_exists 1
		    }
		}
	    }
	}

	if { ($mad_experiment == 0) && ($array(N_CRYSTALS) == 1) && ($array(N_DATA,1) == 1) && $anomalous_exists} {
	    set sad_experiment 1
	}    

	if { ($mad_experiment == 0) && ($array(N_CRYSTALS) == 2) && $native_exists && $anomalous_exists } {
	    set siras_experiment 1
	}
    }

    if { !($mad_experiment || $siras_experiment || $sad_experiment) } {
	return 0
    }

    set bp3_used 0
    set nshelxe 0
    set inputsubstructure 0

    for { set step 1 } { $step <= [expr $array(N_PROGRAMS) + 1] } { incr step } {
	if { [ info exists array(PROGRAM_NAME,$step) ] } {
	    set program_name [string tolower $array(PROGRAM_NAME,$step)]
	} else {
	    set program_name ""
	}

	# By default, use fast phasing in bp3 for a MAD experiment - not any more
	
	if { $program_name == "bp3" } {

	    set bp3_used 1
	    
#	    if { $mad_experiment == 1 } {
#		set array(BP3_PHASE,$step) 1
#	    } 
 	}

	if { $program_name == "refmac" } {
	    set bp3_used 1
        }

        if { $program_name == "shelxe" } {
	    set nshelxe 2
	}

        if { ( ($program_name == "pirate") || ($program_name == "resolvedm") ||
               ($program_name == "dm")     || ($program_name == "solomon")   ||
	       ($program_name == "parrot") ) } {
            set found_solomon_before_denmod 0
            set found_shelxe_before_denmod 0
            for { set ii 0 } { $ii < $step } { incr ii } {

		if { [ info exists array(PROGRAM_NAME,$ii) ] } {
		    set regexp_program [string tolower $array(PROGRAM_NAME,$ii)]
		} else {
		    set regexp_program ""
		}
                
		if { $regexp_program == "solomon" } {
                    set found_solomon_before_denmod 1
                    set array(SOLOMON_DENMOD,$ii) 0
                    set array(SOLOMON_HAND,$ii) 1
                    set array(SOLOMON_HLOUTPUT,$ii) 1
                    break
                }
                if { $regexp_program == "shelxe" } {
                    set found_shelxe_before_denmod 1
                    set array(SHELXE_DENMOD,$ii) 0
                    break
                }
            }

            if { ( ( ($found_solomon_before_denmod || $found_shelxe_before_denmod) ) &&
                   ( ($program_name == "dm")   || ($program_name == "solomon") || 
		     ($program_name == "parrot") ) ) } {
                set array([string toupper ${program_name}]_HAND,$step) 0
                set array([string toupper ${program_name}]_OPT,$step) 0
                set array([string toupper ${program_name}]_DENMOD,$step) 1
            }
        }

	if { $program_name == "resolvemb" } {
	    if { [info exists array(RESOLVEMB_BUILD,$step) ] } {
 		if { $array(RESOLVEMB_BUILD,$step) == "" } {
		    set array(RESOLVEMB_BUILD,$step) "quick"
		}
	    }	
	}

	if { $program_name == "arpwarp" } {

  	    if { [info exists array(ARPWARP_PHASE_RESTRAIN,$step) ] } {
		if { $array(ARPWARP_PHASE_RESTRAIN,$step) == "" } {
		    if { ( ($sad_experiment) ||
 			   ($siras_experiment) ||
			   ( ($mad_experiment)  && 
 			     ($bp3_used == 0)  &&
			     ($nshelxe  > 1) ) && 
  			   ($refmac_sad || $refmac_siras) ) } {
			set array(ARPWARP_PHASE_RESTRAIN,$step) "DIRECT"
			set array(ARPWARP_EXCLUDE_FREER,$step) "use"
			set array(ARPWARP_REFMAC_REF_SET,$step) "free"
		    } elseif { $bp3_used  == 1 }  {
			set array(ARPWARP_PHASE_RESTRAIN,$step) "MLHL"
			set array(ARPWARP_EXCLUDE_FREER,$step) "do not use"
			set array(ARPWARP_REFMAC_REF_SET,$step) "working"
		    } else {
			set array(ARPWARP_PHASE_RESTRAIN,$step) "NO"
			set array(ARPWARP_EXCLUDE_FREER,$step) "do not use"
			set array(ARPWARP_REFMAC_REF_SET,$step) "working"
		    }
		}
	    }
	}

	if { $program_name == "buccaneer" } {

  	    if { [info exists array(BUCCANEER_PHASE_RESTRAIN,$step) ] } {
		if { $array(BUCCANEER_PHASE_RESTRAIN,$step) == ""} {
		    if { ( ($sad_experiment) ||
			   ($siras_experiment) || 
			   ( ($mad_experiment)  && 
                             ($bp3_used == 0)  &&
                             ($nshelxe  > 1) ) &&  
                           ($refmac_sad || $refmac_siras) ) && !$windows } { 
			set array(BUCCANEER_PHASE_RESTRAIN,$step) "DIRECT"
   		    } elseif { $bp3_used == 1 } {
 			set array(BUCCANEER_PHASE_RESTRAIN,$step) "MLHL"
		    } else {
			set array(BUCCANEER_PHASE_RESTRAIN,$step) "NO"
		    }
		}
	    }
	}

	if { $program_name == "solomon" } {

  	    if { [info exists array(SOLOMON_PHASE_COMB,$step) ] } {
		if { $array(SOLOMON_PHASE_COMB,$step) == "" } {
		    if { ( ($sad_experiment) && ($array(SOLOMON_HAND,$step) == 0) ) } {
			set array(SOLOMON_PHASE_COMB,$step) "DIRECT"
		    } else {
			set array(SOLOMON_PHASE_COMB,$step) "MLHL"
		    }
		}
	    }
	}

	if { $program_name == "parrot" } {

  	    if { [info exists array(PARROT_PHASE_COMB,$step) ] } {
		if { $array(PARROT_PHASE_COMB,$step) == "" } {
		    if { ( ($sad_experiment) ) } {
			set array(PARROT_PHASE_COMB,$step) "DIRECT"
		    } else {
			set array(PARROT_PHASE_COMB,$step) "MLHL"
		    }
		}
	    }
	}
    }
}

proc setup_experiment { arrayname } {
    upvar #0 $arrayname array
    global all_subframes

    set experiment $array(EXPERIMENT_SETUP)

    # Save a few pieces of information for the experiment, so the user
    # doesn't have to re-enter them if they change the experiment.

# save coordinates ***NSP save names
    set save_ncrystal $array(N_CRYSTALS)
    for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
        if { [info exists array(N_WATOMS,$i)] } {
            if { $array(N_WATOMS,$i) > 6 } {
                WarningMessage "Unfortunately, there is a limit to 6 different types of anomalous atoms to input"
                return
            }
        }

        set save_ndata($i) $array(N_DATA,$i)
        set save_atomname($i) [string toupper $array(CRYSTAL_ATOM_NAME,$i)]
        set save_natoms($i) $array(CRYSTAL_N_ATOMS,$i)
        set save_nwatoms($i) $array(N_WATOMS,$i)
        for { set j 1 } { $j <= $array(N_DATA,$i) } { incr j } {
            for { set k 1 } { $k <= $array(N_WATOMS,$i) } { incr k } {
                set save_fprime($i,$j,$k) $array(DATA_FPRIME$k,${i}_${j})
                set save_fprimeprime($i,$j,$k) $array(DATA_FPRIMEPRIME$k,${i}_${j})
                set save_watomname($i,$j,$k) [string toupper $array(ATOM_WAVE_ID$k,${i}_${j})]
            }
        }
    }

    deletecrystals $arrayname

    for { set i 1 } { $i <= $save_ncrystal } { incr i } {
        if { [info exists save_atomname($i)] } {
            set array(CRYSTAL_ATOM_NAME,$i) [string toupper $save_atomname($i)]
        }

        if { [info exists save_natoms($i)] } {
            set array(CRYSTAL_N_ATOMS,$i) $save_natoms($i)
        }

        if { [info exists save_nwatoms($i)] } {
            if { $array(PREMADE_START) != "Substructure detection" } {
                set array(N_WATOMS,$i) $save_nwatoms($i)
            } else {
                set array(N_WATOMS,$i) 1
            }
        }

        for { set j 1 } { $j <= $save_ndata($i) } { incr j } {
            for { set k 1 } { $k <= $array(N_WATOMS,$i) } { incr k } {
                 if { [info exists save_fprime($i,$j,$k)] } {
                     set array(DATA_FPRIME$k,${i}_${j}) $save_fprime($i,$j,$k)
                 }
                if { [info exists save_fprimeprime($i,$j,$k)] } {
                    set array(DATA_FPRIMEPRIME$k,${i}_${j}) $save_fprimeprime($i,$j,$k)
                }
                if { [info exists save_watomname($i,$j,$k)] } {
                    set array(ATOM_WAVE_ID$k,${i}_${j}) $save_watomname($i,$j,$k)
                }
            }
        }
    }

    # Setup the experiment the user requested
    # 
    # Tcl does not keep the same variable names
    # between invocations of these various options, so
    # in the future consider saving all these values so that the user
    # doesn't have to re-enter values when she changes the experiment
    # type.

    if { [StringSame $experiment "Single wavelength anomalous diffraction (SAD)"] } {
	set array(DATA_TYPE,1_1) "SAD"
	set array(CRYSTAL_NATIVE,1) 0
	set array(DATA_ANOMALOUS,1_1) 1
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 1	
    } elseif { [StringSame $experiment "Single isomorphous replacement with anomalous scattering (SIRAS)"] } {	
	set array(DATA_TYPE,1_1) "Native"
	set array(CRYSTAL_NATIVE,1) 1
	set array(DATA_ANOMALOUS,1_1) 0
	set array(DATA_TYPE,2_1) "Derivative"
	set array(DATA_ANOMALOUS,2_1) 1
	set array(CRYSTAL_NATIVE,2) 0
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_toggleframe0 crystal_proc 1 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 1
    } elseif { [StringSame $experiment "Two wavelength anomalous diffraction (2W-MAD)"] } {	
	set array(DATA_TYPE,1_1) "Peak"
	set array(DATA_TYPE,1_2) "Inflection"
	set array(CRYSTAL_NATIVE,1) 0
	set array(DATA_ANOMALOUS,1_1) 1
	set array(DATA_ANOMALOUS,1_2) 1	
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 1
    } elseif { [StringSame $experiment "Three wavelength anomalous diffraction (3W-MAD)"] } {	
	set array(DATA_TYPE,1_1) "Peak"
	set array(DATA_TYPE,1_2) "Inflection"
	set array(DATA_TYPE,1_3) "High Remote"
	set array(CRYSTAL_NATIVE,1) 0
	set array(DATA_ANOMALOUS,1_1) 1
 	set array(DATA_ANOMALOUS,1_2) 1
 	set array(DATA_ANOMALOUS,1_3) 1
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 1
    } elseif { [StringSame $experiment "Four wavelength anomalous diffraction (4W-MAD)"] } {	
	set array(DATA_TYPE,1_1) "Peak"
	set array(DATA_TYPE,1_2) "Inflection"
	set array(DATA_TYPE,1_3) "High Remote"
	set array(DATA_TYPE,1_4) "Low Remote"
	set array(DATA_ANOMALOUS,1_1) 1
 	set array(DATA_ANOMALOUS,1_2) 1
 	set array(DATA_ANOMALOUS,1_3) 1
 	set array(DATA_ANOMALOUS,1_4) 1
	set array(CRYSTAL_NATIVE,1) 0
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 1
    } elseif { [StringSame $experiment "Two wavelength anomalous diffraction with native (2W-MAD-N)"] } {	
	set array(DATA_TYPE,1_1) "Native"
	set array(CRYSTAL_NATIVE,1) 1
	set array(DATA_ANOMALOUS,1_1) 0
	set array(DATA_TYPE,2_1) "Peak"
	set array(DATA_TYPE,2_2) "Inflection"
	set array(CRYSTAL_NATIVE,2) 0
	set array(DATA_ANOMALOUS,2_1) 1
	set array(DATA_ANOMALOUS,2_2) 1	
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_toggleframe0 crystal_proc 1 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 1
    } elseif { [StringSame $experiment "Three wavelength anomalous diffraction with native (3W-MAD-N)"] } {	
	set array(DATA_TYPE,1_1) "Native"
	set array(CRYSTAL_NATIVE,1) 1
	set array(DATA_ANOMALOUS,1_1) 0
	set array(DATA_TYPE,2_1) "Peak"
	set array(DATA_TYPE,2_2) "Inflection"
	set array(DATA_TYPE,2_3) "High Remote"
	set array(CRYSTAL_NATIVE,2) 0
	set array(DATA_ANOMALOUS,2_1) 1
	set array(DATA_ANOMALOUS,2_2) 1	
	set array(DATA_ANOMALOUS,2_3) 1	
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_toggleframe0 crystal_proc 1 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 1
    } elseif { [StringSame $experiment "Four wavelength anomalous diffraction with native (4W-MAD-N)"] } {	
	set array(DATA_TYPE,1_1) "Native"
	set array(CRYSTAL_NATIVE,1) 1
	set array(DATA_ANOMALOUS,1_1) 0
	set array(DATA_TYPE,2_1) "Peak"
	set array(DATA_TYPE,2_2) "Inflection"
	set array(DATA_TYPE,2_3) "High Remote"
	set array(DATA_TYPE,2_4) "Low Remote"
	set array(CRYSTAL_NATIVE,2) 0
	set array(DATA_ANOMALOUS,2_1) 1
	set array(DATA_ANOMALOUS,2_2) 1	
	set array(DATA_ANOMALOUS,2_3) 1	
	set array(DATA_ANOMALOUS,2_4) 1	
	update_toggleframe0 crystal_proc 0 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 1 $arrayname N_DATA,1 1 0
	update_toggleframe0 crystal_proc 1 $arrayname N_CRYSTALS 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 0
	update_extendingframe0 data_proc 2 $arrayname N_DATA,2 1 1
    }

    rebuild_varmenus $arrayname

    SetSystemVar block_scroll_update 0	
}

proc setup_inputdata { arrayname } {
    upvar #0 $arrayname array

    if { [StringSame $array(INPUT_DATA) "Amplitudes"] } {
	set array(INPUT_INTENSITY) 0
    } else {
	set array(INPUT_INTENSITY) 1
    }

    rebuild_varmenus $arrayname

    SetSystemVar block_scroll_update 0	
}


#
# Clear all current program steps and make the default pipeline
#
proc add_program { arrayname } {
    upvar #0 $arrayname array	

    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 1
    rebuild_varmenus $arrayname
}

#
# Clear all current program steps
#
proc clear_pipeline { arrayname } {
    upvar #0 $arrayname array
    global all_subframes
        
    if { $array(N_PROGRAMS) > 0 } {
	set n_prog $array(N_PROGRAMS)
 	for { set i 0 } { $i < $n_prog } { incr i} {
	    delete_frame $arrayname experiment_proc 0
 	}
	set array(N_PROGRAMS) 0

	foreach subframe $all_subframes {
	    trace vdelete array(COOT_EXISTS) w "update_main_scroll $subframe"
	    trace vdelete array(SHOW_ALL_PIPELINE_INPUT) w "update_main_scroll $subframe"
	    trace vdelete array(DISPLAY_PIPELINE) w "update_main_scroll $subframe"
	}

	SetSystemVar block_scroll_update 0
	update_main_scroll $array(FRAME_experiment_proc_0)
    }

    rebuild_varmenus $arrayname
}

proc fix_scroll { arrayname } {
    upvar #0 $arrayname array
    global all_subframes
    
    foreach subframe $all_subframes {
	trace vdelete array(COOT_EXISTS) w "update_main_scroll $subframe"
	trace vdelete array(SHOW_ALL_PIPELINE_INPUT) w "update_main_scroll $subframe"
	trace vdelete array(DISPLAY_PIPELINE) w "update_main_scroll $subframe"
	trace vdelete array(PREMADE_START) w "update_main_scroll $subframe"
	trace vdelete array(PREMADE_END) w "update_main_scroll $subframe"
    }

    SetSystemVar block_scroll_update 0
    update_main_scroll $array(FRAME_experiment_proc_0)

    rebuild_varmenus $arrayname
}

#
proc add_premade_pipeline { arrayname } {
    upvar #0 $arrayname array

    if { $array(N_PROGRAMS) > 0 } {
 	clear_pipeline $arrayname
	set $array(N_PROGRAMS) 0
    }

    # Are we building a pipeline?  If so, don't update the
    # varmenus.  We will do so when we're done constructing
    # the pipeline.
    global building_pipeline
	
    set building_pipeline 1

    # Depending on the selection of the user, fill the pipeline with
    # the appropriate programs.
    set start $array(PREMADE_START)
    set end $array(PREMADE_END)

    if {  ( ( ( ([ string compare $start "Substructure phasing"]   == 0) || 
		([ string compare $start "Hand determination"]     == 0) ||
		([ string compare $start "Density modification"]   == 0) ||
		([ string compare $start "Model building"]         == 0) ) && 
	      ([ string compare $end   "Substructure detection"]   == 0) ) ||
	    ( ( ([ string compare $start "Hand determination"]     == 0) ||
		([ string compare $start "Density modification"]   == 0) ||
		([ string compare $start "Model building"]         == 0) ) && 
	      ( ([ string compare $end   "Substructure detection"] == 0) || 
		([ string compare $end   "Substructure phasing"]   == 0) ) ) ||
	    ( ([ string compare $start "Model building"]           == 0) && 
 	      ( ([ string compare $end   "Substructure detection"] == 0) || 
		([ string compare $end   "Substructure phasing"]   == 0) ||
		([ string compare $end   "Hand determination"]     == 0) ||
		([ string compare $end   "Density modification"]   == 0) ) ) ) } {
 	WarningMessage "The start step selected is after the end step."
	return
    }
    set done 0
    set step 0

    set array(EXPERIMENTAL_PROGRAM) "PREP"
    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
    incr step

    if { [ string compare $start "Substructure detection"] == 0 } {

	if { [ string compare $array(FIND_PROGS) "SHELXC/D" ] == 0 } {
	    set array(EXPERIMENTAL_PROGRAM) "SHELXC"
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	    incr step
	    set array(EXPERIMENTAL_PROGRAM) "SHELXD"
	} else {
	    set array(EXPERIMENTAL_PROGRAM) "AFRO"
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	    incr step
	    set array(EXPERIMENTAL_PROGRAM) "CRUNCH2"
	}

	if { [ string compare $end "Substructure detection"] == 0 } {
	    set done 1
	} else {
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	}
    }

    if { ( ( ([ string compare $start "Substructure detection"] == 0) ||
	     ([ string compare $start "Substructure phasing"] == 0) ) && 
	   !$done) } {

	if { [ string compare $array(REFINE_PROGS) "NONE" ] } {
 	    set array(EXPERIMENTAL_PROGRAM) $array(REFINE_PROGS)
	}

	if { [ string compare $end "Substructure phasing"] == 0 } {
	    set done 1
	} elseif { [ string compare $array(REFINE_PROGS) "NONE" ] } {
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	}
    }

    if { ( ( ([ string compare $start "Substructure detection"] == 0) ||
	     ([ string compare $start "Substructure phasing"]   == 0) ||
	     ([ string compare $start "Hand determination"]   == 0) ) &&
	   !$done) } {

	if { [ string compare $array(HAND_PROGS) "NONE" ] } {
 	    set array(EXPERIMENTAL_PROGRAM) $array(HAND_PROGS)
	}

	if { [ string compare $end "Hand determination"] == 0 } {
	    set done 1
	} elseif { [ string compare $array(HAND_PROGS) "NONE" ] } {
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	}
    }

    if { ( ( ([ string compare $start "Substructure detection"] == 0) ||
	     ([ string compare $start "Substructure phasing"]   == 0) ||
	     ([ string compare $start "Hand determination"]   == 0) ||
	     ([ string compare $start "Density modification"]   == 0) ) &&
	   !$done) } {

	if { [ string compare $array(DM_PROGS) "NONE" ] } {
 	    set array(EXPERIMENTAL_PROGRAM) $array(DM_PROGS)
	}

	if { [ string compare $end "Density modification"] == 0 } {
	    set done 1
	} elseif { [ string compare $array(DM_PROGS) "NONE" ] } {
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	}
    }

    if { !$done } {
 	if { [ string compare $array(MODEL_PROGS) "NONE" ] } {
 	    set array(EXPERIMENTAL_PROGRAM) $array(MODEL_PROGS)
	}

	if { [ string compare $end "Model building"] == 0 } {
	    set done 1
	} elseif { [ string compare $array(MODEL_PROGS) "NONE" ] } {
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
	}

	if { $array(DISPLAY_COOT) } {
  	    set array(EXPERIMENTAL_PROGRAM) "COOT"
	    update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 0
 	} 
    }

    if { $done } {
	update_toggleframe0 experiment_proc 0 $arrayname N_PROGRAMS 1 1
    }

    set building_pipeline 0

    rebuild_varmenus $arrayname
}

#
# Check to see if $atomname is present in the file
# $CLIBD/atomsf.lib
#
proc check_atomname { arrayname atomname } {
    upvar #0 $arrayname array
    global env
	
    set atomname [string tolower $atomname]
    set atomsf "[file join $env(CLIBD) atomsf.lib]"

    set file_id [open $atomsf r]

    set done 0
    while { !$done } {
	gets $file_id line
	if { ! [regexp {AD.*} $line]} {
	    set done 1
	 }
    }
	
    lappend atomlist $line
    gets $file_id line
    gets $file_id line
    gets $file_id line
    gets $file_id line

    while { [gets $file_id line] >= 0 } {
	lappend atomlist $line
	gets $file_id line
	gets $file_id line
	gets $file_id line
	gets $file_id line
	lappend cu_structure_factors $line
    }

    set match 0
    for { set i 0 } { $i < [llength $atomlist] } { incr i } {
	if { [regexp {([A-Za-z+0-9-]*) } [lindex $atomlist $i] full atom] } {
	    set atom [string tolower $atom]
	    if { [string compare $atomname $atom] == 0 } {
		set match 1
		set i [expr $i - 1]
		set fprime  [lindex [lindex $cu_structure_factors $i] 0]
		set fprimeprime [lindex [lindex $cu_structure_factors $i] 1]
		break
	    }
	}
    }

    if { $match == 1 } {
	return 1
    } else {
	return 0
    }
}

#
# Get the atomic form factors for $atomname from the information in
# $CLIBD/atomsf.lib
#
proc GetFormFactors { atomname } {
    global env
	
    set atomname [string tolower $atomname]
    set atomsf "[file join $env(CLIBD) atomsf.lib]"

    set file_id [open $atomsf r]

    set done 0
    while { !$done } {
	gets $file_id line
	if { ! [regexp {AD.*} $line]} {
	    set done 1
	}
    }
	
    lappend atomlist $line
    gets $file_id line
    gets $file_id line
    gets $file_id line
    gets $file_id line

    while { [gets $file_id line] >= 0 } {
	lappend atomlist $line
	gets $file_id line
	gets $file_id line
	gets $file_id line
	gets $file_id line
	lappend cu_structure_factors $line
    }

    set match 0
    for { set i 0 } { $i < [llength $atomlist] } { incr i } {
	if { [regexp {([A-Za-z+0-9-]*) } [lindex $atomlist $i] full atom] } {
	    set atom [string tolower $atom]
	    if { [string compare $atomname $atom] == 0 } {
		set match 1
		set i [expr $i - 1]
		set fprime  [lindex [lindex $cu_structure_factors $i] 0]
		set fprimeprime [lindex [lindex $cu_structure_factors $i] 1]
		break
	    }
	}
    }

    if { $match == 1 } {
	return "$fprime $fprimeprime"
    } else {
	return "0.0 0.0"
    }
}

proc deletecrystals { arrayname } {
    upvar #0 $arrayname array
    # Delete all current crystals/datasets

    global all_subframes

    if { $array(N_CRYSTALS) > 0 } {

	set n_crystals $array(N_CRYSTALS)
	for { set i 0 } { $i < $n_crystals } { incr i} {
	    delete_frame $arrayname crystal_proc 0
	}

 	set array(N_CRYSTALS) 0
	rebuild_varmenus $arrayname
    }
}

proc rungetstuff { arrayname force } {
    upvar #0 $arrayname array
    global env
    global tcl_platform

    set good 1

    set input_res ""
    set input_seq ""

    if { ($array(SEQIN) != "") && ($array(DOCK_SEQUENCE) == 1) } {
	set input_seq "[GetFullFileName0 $arrayname SEQIN]"
	set seq_type [string tolower [string range $input_seq [expr [string length $input_seq] - 3] [string length $input_seq]]]
	set pir_file [string equal $seq_type pir]
	set seq_file [string equal $seq_type seq] 
	set fas_file [string equal $seq_type fas] 
	if { !$fas_file && [string equal $seq_type sta] } {
	  set fas_file 1
	}
	if { !( ($pir_file) || ($seq_file)  || ($fas_file) ) } {
	    WarningMessage "The sequence file must end with .pir, .seq or .fas/.sta/.fasta"
	    return 0
	}

	set offset -1
	if { $pir_file } {
	    set offset 1 
	} elseif { $fas_file } {
	    set offset 0
	}

	if {[ReadFile $input_seq sequence_text]} {
	    set data [split $sequence_text "\n"]
	    set formatted ""

	    set n 0
	    foreach line $data {
		if { ( ([string match $line {>*} ] == 0) && ($n > $offset) ) } {
 		    regsub -all {[^a-zA-Z]} $line "" tmp
		    if { $tmp != "" } {
			if { $formatted == ""} {
			    set formatted "[string toupper $tmp]"
			} else {
			    set formatted "$formatted[string toupper $tmp]"
			}
		    }
		}
 		incr n
	    }    
	    set array(SEQUENCE) $formatted
	    set array(NRESIDUES) [string length $formatted]
	    set input_res "NRES $array(NRESIDUES)\n"
	}
    } elseif { ($array(NRESIDUES) > 0) || ($array(NUCLEOTIDES_PRESENT)) } {

	if { ($array(NRESIDUES) < 0) && ($array(NRESIDUES) != "") } {
	    WarningMessage "Number of residues must be greater than or equal to 0"
	    return
	} elseif { ($array(NRESIDUES) > 0) } { 
	    set input_res "NRES $array(NRESIDUES)\n"
	}

	if { $array(NUCLEOTIDES_PRESENT) } {
	    if { $array(NNUCLEOTIDES) == "" } {
		return
	    }

	    if { $array(NNUCLEOTIDES) < 0 } {
		WarningMessage "Number of nucleotides must be greater than 0"
		return
	    }

	    set input_res "$input_res NNUC $array(NNUCLEOTIDES)"
	} else {
	    set nnucleotides 0
	}
    } else {
	return
    }

    if { $array(HKLIN) == "" } {
	return
    }

    set windows 0

    if { [string compare $tcl_platform(platform) "windows"] == 0 } {
	set windows 1
    }

    set input_mtz "[GetFullFileName0 $arrayname HKLIN]"

    if { [llength [split $input_mtz]] > 1 } {  
 	WarningMessage "The input mtz file name or directory must not contain any spaces"
	return
    }

    set crystal_input ""
    # Loop over all crystals/datasets
    if { $array(N_CRYSTALS) > 0 } {
	set column_list {}
	for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
	    set crystal_input "$crystal_input XTAL XTAL$i\n"
	    if { $array(CRYSTAL_NATIVE,$i) == 0 } {
		set crystal_input "$crystal_input ATOM Se\nNUMB 1\n"
	    }
	    for { set j 1 } { $j <= $array(N_DATA,$i) } { incr j } {
		set data_anomalous $array(DATA_ANOMALOUS,${i}_${j})
		if { $array(INPUT_INTENSITY) } {
 		    if { $data_anomalous == 0 } {
			if { $array(CRYSTAL_NATIVE,$i) == 0 } {
			    set ii $array(DATA_I,${i}_${j})
			    set sigi $array(DATA_SIGI,${i}_${j})
                        } else {
                            set ii $array(DATA_I,${i})
                            set sigi $array(DATA_SIGI,${i})
                        }

			    if { $ii == "" || [StringSame $ii "Unassigned"]  || 
				 $sigi == "" || [StringSame $sigi "Unassigned"] } {
 				set good 0
			    }			    

 			set crystal_input "$crystal_input DNAME DATA$j\n COLU I=$ii SI=$sigi\n"
			
			lappend column_list $ii
			lappend column_list $sigi
			
		    } else {
			# Check for presence of both I+ and I-
			# Make sure I+ and I- are different
			set i_plus $array(DATA_I_PLUS,${i}_${j})
			set sigi_plus $array(DATA_SIGI_PLUS,${i}_${j})
			set i_minus $array(DATA_I_MINUS,${i}_${j})
			set sigi_minus $array(DATA_SIGI_MINUS,${i}_${j})

 			set crystal_input "$crystal_input DNAME DATA$j\n COLU I+=$i_plus SI+=$sigi_plus I-=$i_minus SI-=$sigi_minus\n"
			
			    if { $i_plus == "" || [StringSame $i_plus "Unassigned"] || 
				 $sigi_plus == "" || [StringSame $sigi_plus "Unassigned"] ||
				 $i_minus == "" || [StringSame $i_minus "Unassigned"] ||
				 $sigi_minus == "" || [StringSame $sigi_minus "Unassigned"] || 
				 [StringSame $i_plus $i_minus] || [StringSame $sigi_plus $sigi_minus] } {
				set good 0
			    }

			lappend column_list $i_plus
			lappend column_list $sigi_plus
			lappend column_list $i_minus
			lappend column_list $sigi_minus
			
		    }
		} else {
		    if { $data_anomalous == 0 } {
                        if { $array(CRYSTAL_NATIVE,$i) == 0 } {
                            set f $array(DATA_F,${i}_${j})
                            set sigf $array(DATA_SIGF,${i}_${j})
                        } else {
                            set f $array(DATA_F,${i})
                            set sigf $array(DATA_SIGF,${i})
                        }			
  			set crystal_input "$crystal_input DNAME DATA$j\n COLU F=$f SF=$sigf\n"

			if { $f == "" || [StringSame $f "Unassigned"]  || 
			     $sigf == "" || [StringSame $sigf "Unassigned"] } {
			    set good 0
			}			    

			lappend column_list $f
			lappend column_list $sigf
			
		    } else {
			set f_plus $array(DATA_F_PLUS,${i}_${j})
			set sigf_plus $array(DATA_SIGF_PLUS,${i}_${j})
			set f_minus $array(DATA_F_MINUS,${i}_${j})
			set sigf_minus $array(DATA_SIGF_MINUS,${i}_${j})

			if { $f_plus == "" || [StringSame $f_plus "Unassigned"] || 
			     $sigf_plus == "" || [StringSame $sigf_plus "Unassigned"] ||
			     $f_minus == "" || [StringSame $f_minus "Unassigned"] ||
			     $sigf_minus == "" || [StringSame $sigf_minus "Unassigned"] || 
			     [StringSame $f_plus $f_minus] || [StringSame $sigf_plus $sigf_minus] } {
			    set good 0
			}

 			set crystal_input "$crystal_input DNAME DATA$j\n COLU F+=$f_plus SF+=$sigf_plus F-=$f_minus SF-=$sigf_minus\n"

			lappend column_list $f_plus
			lappend column_list $sigf_plus
			lappend column_list $f_minus
			lappend column_list $sigf_minus
			
		    }
		}		    
	    }
	}
    } else {
	return
    }

    #
    # Check if any dataset is specified more than once in the experimental data section.
    #

    for { set m 0 } { $m < [expr [llength $column_list] - 1] } { incr m } {
	for { set n [expr $m + 1] } { $n < [llength $column_list] } { incr n } {
	    if { [StringSame [lindex $column_list $m] [lindex $column_list $n]] } {
		set good 0
	    }
	}
    }

    if { ! $array(NUCLEOTIDES_PRESENT) } { 
	if { ( ($array(NRESIDUES) == 0) || ($array(NRESIDUES) == "") ) && ($array(SEQIN) == "") } {
	    return 
	}
    }
	 
    if { ($array(NMONOMERS) == "") } {
	set nmonomers 0
    } else {
	if { $array(NMONOMERS) < 0 } {
	    WarningMessage "Number of monomers must be greater than 0"
	    return
	}
	set nmonomers $array(NMONOMERS)
    }

    if { $good == 0 } {
 	if { $array(INPUT_INTENSITY) } {
	    if {$data_anomalous == 1} {
		set ip $array(DATA_I_PLUS,$array(REF_CRYSTAL)_$array(REF_DATASET))
		set sigip $array(DATA_SIGI_PLUS,$array(REF_CRYSTAL)_$array(REF_DATASET))
	    } else {
		if { $array(CRYSTAL_NATIVE,$i) == 0 } {
		    set ip $array(DATA_I,$array(REF_CRYSTAL)_$array(REF_DATASET))
		    set sigip $array(DATA_SIGI,$array(REF_CRYSTAL)_$array(REF_DATASET))
		} else {
		    set ip $array(DATA_I,$array(REF_CRYSTAL))
		    set sigip $array(DATA_SIGI,$array(REF_CRYSTAL))
		}
	    }
	    if { [string compare $ip "Unassigned"] == 0 || $ip == "" ||
		 [string compare $sigip "Unassigned"] == 0 || $sigip == "" } {
		return 0
	    }
	    set crystal_input "XTAL XNAME\n DNAME DATA1\n COLU I=$ip SI=$sigip\n"
	} else {
	    if {$data_anomalous == 1} {
		set ip $array(DATA_F_PLUS,$array(REF_CRYSTAL)_$array(REF_DATASET))
		set sigip $array(DATA_SIGF_PLUS,$array(REF_CRYSTAL)_$array(REF_DATASET))
	    } else {
		set ip $array(DATA_F,$array(REF_CRYSTAL)_$array(REF_DATASET))
		set sigip $array(DATA_SIGF,$array(REF_CRYSTAL)_$array(REF_DATASET))
	    }
 	    if { [string compare $ip "Unassigned"] == 0 || $ip == "" ||
		 [string compare $sigip "Unassigned"] == 0 || $sigip == "" } {
		return 0
	    }
 	    set crystal_input "XTAL XNAME\n DNAME DATA1\n COLU F=$ip SF=$sigip\n"
	}
    }

    # Run GCX

    if { [file exists [FindExecutable gcx] ] } {
	set gcx [FindExecutable gcx]
    } else {
	set gcx [file join $env(CRANK) bin gcx] 
    }

    if { $array(DOCK_SEQUENCE) && [file exists $input_seq] } {
	if { [llength [split $input_seq]] > 1 } {  
	    WarningMessage "The input sequence file name or directory must not contain any spaces"
	    return
	}
    }

    if { $nmonomers == 0 } {
	if { ($array(DOCK_SEQUENCE) && [file exists $input_seq]) && !$windows } {
 	    set command "$gcx HKLIN $input_mtz SEQIN $input_seq << \"NOUT \n $crystal_input\""
	} else {
	    set command "$gcx HKLIN $input_mtz << \"$input_res \n NOUT \n $crystal_input\""
	}
    } else {
 	if { ($array(DOCK_SEQUENCE) && [file exists $input_seq]) && !$windows } {
	    set command "$gcx HKLIN $input_mtz SEQIN $input_seq << \"NOUT \n NMON $nmonomers \n $crystal_input\""
	} else {
	    set command "$gcx HKLIN $input_mtz << \"$input_res \n NMON $nmonomers \n NOUT \n $crystal_input\""
	}

    }

    if { ![catch {eval exec $command} output] } {

	if { [regexp {.*Highly improbable number of monomers inputted.*} $output full] } {
	    set array(NMONOMERS) ""
	    return 0
	}

	if { $nmonomers == 0 } {
	    if { ![regexp {.*Setting the number of monomers to * *([-0-9.]*).*} $output full nmonomers] } {
		puts "Search string not found\n"
		return 0
	    }
	}

	set data $output
	set data [split $data "\n"]
    
	array set listmatt {}
	array set listsolv {}
	array set listprob {}

	set crys 1
    

	foreach line $data {
	    if {       [regexp {    *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
		if { $number != "" } {
		    set listmatt($number) $matthews
		    set listsolv($number) $sol
		    set listprob($number) $prob
		}
	    } elseif { [regexp {   *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
		if { $number != "" } {
		    set listmatt($number) $matthews
		    set listsolv($number) $sol
		    set listprob($number) $prob
		}
	    }
 	    regsub -all {\s+} $line " " line
	    if { [regexp {.*Cell Dimensions: *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*).*} $line junk a b c alpha beta gamma ] } {
		if { ( ($a != "") && ($gamma != "") ) && $good } {
		    set array(CELL_A,$crys) $a
		    set array(CELL_B,$crys) $b
		    set array(CELL_C,$crys) $c
		    set array(CELL_ALPHA,$crys) $alpha
		    set array(CELL_BETA,$crys) $beta
		    set array(CELL_GAMMA,$crys) $gamma
		    incr crys
		} 
	    } elseif { [regexp {.*Calculated substructure detection resolution cut off *([0-9.]*).*} $line junk hirescut] } {
		if { ($hirescut != "") && $good } {
		    for { set i 1 } { $i < 4 } { incr i } {
			if { ![info exists array(AFRO_HIGH_RES_CUTOFF,$i)] } {
			    set array(AFRO_HIGH_RES_CUTOFF,$i)   $hirescut
			}
			if { ![info exists array(SHELXC_HIGH_RES_CUTOFF,$i)] } {
			    set array(SHELXC_HIGH_RES_CUTOFF,$i) $hirescut
			}
			if { ![info exists array(SHELXD_HIGH_RES_CUTOFF,$i)] } {
			    set array(SHELXD_HIGH_RES_CUTOFF,$i) $hirescut
			}
		    }
		}
	    } 
	}

	if { [info exists array(SOLVENT_CONTENT)] } {
	    if { ($array(SOLVENT_CONTENT) == "") || ($force == 1) } {
		if [info exists listsolv($nmonomers)] {
		    set array(SOLVENT_CONTENT) $listsolv($nmonomers)
		}  else {
		    WarningMessage "Number of monomers input is not possible - please set manually in Derived parameters section"
		    set array(NMONOMERS) ""
		    return 0
		}
	    }
	}

	if { [info exists array(NMONOMERS)] } {
	    if { ($array(NMONOMERS) == "") || ($force == 1) } {
 		if [info exists listsolv($nmonomers)] {
		    set array(NMONOMERS) $nmonomers
		    set array(MATTHEWS) $listmatt($nmonomers)
		    set array(KRPROB) $listprob($nmonomers)
		} else {
		    WarningMessage "Number of monomers input is not possible - please set manually in Derived parameters section"
		}
	    }
	}

	if { ![regexp {.*estimated likelihood-based overall B factor is * *([-0-9.]*).*} $output full likebfactor] } {
	    puts "B-factor search string not found\n"
	}

	if { ![regexp {.*B-factor from Wilson plot is * *([-0-9.]*).*} $output full wilsbfactor] } {
	    puts "B-factor search string not found\n"
	}

	if { $good == 1 } {
	    if { ![regexp {.*Reference crystal ([1-9]*).*} $output full array(REF_CRYSTAL)] } {
		puts "Search string not found\n"
	    }

	    if { ![regexp {.*Reference dataset ([1-9]*).*} $output full array(REF_DATASET)] } {
		puts "Search string not found\n"
	    }
	} else {
	    if { [info exists array(HIGH_RES_LIMIT)] } {
		if { $array(HIGH_RES_LIMIT) != 0.0 && $array(HIGH_RES_LIMIT) != "" } {	
		    if { $array(HIGH_RES_LIMIT) > 3.0 } {
			set substruct_high_res_cutoff $array(HIGH_RES_LIMIT)
		    } elseif { [expr $array(HIGH_RES_LIMIT) + 0.5 ] > 3.0 } {
			set substruct_high_res_cutoff 3.0
		    } else {
			set substruct_high_res_cutoff [expr $array(HIGH_RES_LIMIT) + 0.5]
		    }

		    for { set i 1 } { $i < 4 } { incr i } {
			set array(AFRO_HIGH_RES_CUTOFF,$i) $substruct_high_res_cutoff
			set array(SHELXC_HIGH_RES_CUTOFF,$i) $substruct_high_res_cutoff
			set array(SHELXD_HIGH_RES_CUTOFF,$i) $substruct_high_res_cutoff
		    }
		}
	    }
	}	

	if { ($likebfactor < $wilsbfactor) } {
	    set bfactor $likebfactor
	}  else {
	    set bfactor $wilsbfactor
	}

	if { ($bfactor     < 10) } {
	    set bfactor 10
	}	

	if { ($array(BFACTOR) == "") || ($force == 1) } {
	    set array(BFACTOR) $bfactor
	}

	if { [info exists array(HIGH_RES_LIMIT)] } {
	    if { $array(HIGH_RES_LIMIT) != 0.0 && $array(HIGH_RES_LIMIT) != "" } {	
		for { set i 1 } { $i < 3 } { incr i } {
		    set array(PREP_EXCLUDE_RESOLUTION_HI,$i) $array(HIGH_RES_LIMIT) 
		}
	    }
	}
    } else {
	puts $output
 	set data $output
	set data [split $data "\n"]
    }

    return
}

proc getatomname { arrayname c1 } {
    upvar #0 $arrayname array
	
    if { $array(SUBSTRUCTURE_INPUT_COORDSIN,$c1) == "" } {
	return
    }

    set input_pdb [open [GetFullFileName0 $arrayname SUBSTRUCTURE_INPUT_COORDSIN,$c1] r]
    set indata [split [read $input_pdb] "\n"]

    foreach line  $indata {
	regsub -all {\s+} $line " " line
	if { [regexp {HETATM *([0-9]*) *([A-Z]*)} $line junk number atom] || [regexp {ATOM *([0-9]*) *([A-Z]*)} $line junk number atom] } {
	    set array(CRYSTAL_ATOM_NAME,$c1) [string toupper $atom]
	    break
	}
    }
    close $input_pdb
}

proc check_all { arrayname } {
    upvar #0 $arrayname array
    global PluginList 

    #                       Crank Parameters                      
	
    if { $array(HKLIN) == "" } {
	WarningMessage "Input MTZ file not entered"
	return 0
    }
	
    if { $array(HKLOUT) == "" } {
	WarningMessage "Output MTZ file not entered"
	return 0
    }

    rungetstuff $arrayname 0

    #                     Crystals/Datasets                       

    if { $array(REF_CRYSTAL) > $array(N_CRYSTALS) } {
	WarningMessage "The reference crystal has not been defined"
	return 0
    } else {
	if { $array(REF_DATASET) > $array(N_DATA,$array(REF_CRYSTAL)) } {
	    WarningMessage "The reference data set has not been defined for reference crystal"
	    return 0
	}	    
    }

    if { $array(N_CRYSTALS) == 1 } {
	if { $array(DATA_ANOMALOUS,1) != 1 } {
	    WarningMessage "If only one crystal is defined, it must contain anomalous data"
	    return 0
	}
    }

    # Make sure number of protein residues is set (can be 0)
    set nresidues $array(NRESIDUES)

    if { $nresidues == "" } {
	WarningMessage "Number of residues is not set.  Please enter a value (can be zero)"
	return 0
    }

    # Make sure number of nucleotides is set (can be 0)
    set nucleotides_present $array(NUCLEOTIDES_PRESENT)
    set nnucleotides $array(NNUCLEOTIDES)

    if { $nucleotides_present && $nnucleotides == "" } {
	WarningMessage "Number of nucleotides is not set.  Please enter a value (can be zero), or hide the field with the DNA/RNA Present button"
	return 0
    }

    # Make sure (protein residues + nucleotides) > 0
    if { $nucleotides_present } {
	set total [expr $nresidues + $nnucleotides]
    } else {
	set total $nresidues
    }
	
    if { $total <= 0 } {
	WarningMessage "Number of residues + number of nucleotides must be greater than zero"
	return 0
    }

    # Loop over all crystals/datasets
    if { $array(N_CRYSTALS) > 0 } {
	set column_list {}
	for { set i 1 } { $i <= $array(N_CRYSTALS) } { incr i } {
	    set typelist {}
	    set native $array(CRYSTAL_NATIVE,${i})
            set array(CRYSTAL_ATOM_NAME,${i}) [string toupper $array(CRYSTAL_ATOM_NAME,${i})]

	    for { set m 1 } { $m <= $array(N_ATOMS,${i}) } { incr m } {
                set array(ATOM_ID,${i}_${m}) [string toupper $array(ATOM_ID,${i}_${m})]
            }


	    for { set j 1 } { $j <= $array(N_DATA,$i) } { incr j } {
		set type $array(DATA_TYPE,${i}_${j})

		for { set k 1 } { $k <= $array(N_WATOMS,$i) } { incr k } {
		    if { [info exists array(ATOM_WAVE_ID${k},${i}_${j}) ] } { 
			set array(ATOM_WAVE_ID${k},${i}_${j}) [string toupper $array(ATOM_WAVE_ID${k},${i}_${j})]
		    }
		}
				
		# If Native
		if { $native } {
		    # Check for I and SIGI columns
		} else {
		    # If non-Native
		    # Check for presence substructure atom
		    if { ![info exists array(CRYSTAL_ATOM_NAME,${i} ] } {
			if { $array(PREMADE_START) != "Substructure detection" } {
			    set array(CRYSTAL_ATOM_NAME,${i}) [string toupper $array(ATOM_WAVE_ID1,${i}_1)]
			    set array(CRYSTAL_N_ATOMS,${i}) 5
			}
		    }


		    set atomname $array(CRYSTAL_ATOM_NAME,${i})
		    if { $atomname == "" } {
			WarningMessage "No Atom Name Entered\nPlease enter an Atom Name"
			return 0
		    }
                    set atomname [string toupper $atomname]
                    set array(CRYSTAL_ATOM_NAME,${i}) $atomname
		    # Check validity of substructure atom (It must be a valid element name)
		    if { [check_atomname $arrayname $atomname] == 0 } {
			WarningMessage "Incorrect atom name ($atomname):\n\nPlease choose a valid CCP4\natom name from \$CLIBD/sfatom.lib"
			return 0
		    }

		    # Check number of substructure atoms
		    set natoms $array(CRYSTAL_N_ATOMS,${i})
		    if { $natoms == "" } {
			WarningMessage "Number of Atoms not entered\nPlease enter number of Atoms"
			return 0
		    }
					
		    if { $natoms <= 0 } {
			WarningMessage "Must have at least one atom"
			return 0
		    }

		    if { $natoms >= 1000 } {
			WarningMessage "Too many atoms entered ($natoms).  Perhaps you entered the number of total atoms?"
			return 0
		    }

		    # Check data type
		    set data_type $array(DATA_TYPE,${i}_${j})
		    lappend typelist $data_type
		    if { $data_type == "" } {
			WarningMessage "Type of data not entered"
			return 0
		    }
					
		    # If non-anomalous
		    set data_anomalous $array(DATA_ANOMALOUS,${i}_${j})
 		    if { $array(INPUT_INTENSITY) } {
			if { $data_anomalous == 0 } {
			    if { $array(CRYSTAL_NATIVE,$i) == 0 } {
				set ii $array(DATA_I,${i}_${j})
				set sigi $array(DATA_SIGI,${i}_${j})
			    } else {
				set ii $array(DATA_I,${i})
				set sigi $array(DATA_SIGI,${i})
			    }
			    
			    lappend column_list $ii
			    lappend column_list $sigi
			
			    if { $ii == "" || [StringSame $ii "Unassigned"] } {
				WarningMessage "I column not set for crystal=$i dataset=$j"
				return 0
			    }
			    
			    if { $sigi == "" || [StringSame $sigi "Unassigned"] } {
				WarningMessage "SIGI column not set for crystal=$i dataset=$j"
				return 0
			    }
			} else {
			    # Check for presence of both I+ and I-
			    # Make sure I+ and I- are different
			    set i_plus $array(DATA_I_PLUS,${i}_${j})
			    set sigi_plus $array(DATA_SIGI_PLUS,${i}_${j})
			    set i_minus $array(DATA_I_MINUS,${i}_${j})
			    set sigi_minus $array(DATA_SIGI_MINUS,${i}_${j})

			    lappend column_list $i_plus
			    lappend column_list $sigi_plus
			    lappend column_list $i_minus
			    lappend column_list $sigi_minus
			
			    if { $i_plus == "" || [StringSame $i_plus "Unassigned"] } {
				WarningMessage "I+ column not set for crystal=$i dataset=$j"
				return 0
			    }
			
			    if { $sigi_plus == "" || [StringSame $sigi_plus "Unassigned"] } {
				WarningMessage "SIGI+ column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { $i_minus == "" || [StringSame $i_minus "Unassigned"] } {
				WarningMessage "I- column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { $sigi_minus == "" || [StringSame $sigi_minus "Unassigned"] } {
				WarningMessage "SIGI- column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { [StringSame $i_plus $i_minus] } {
				WarningMessage "You have set both the I+ and I- columnns for crystal=$i dataset=$j to ($i_plus).\n"
				return 0
			    }

			    if { [StringSame $sigi_plus $sigi_minus] } {
				WarningMessage "You have set both the SIGI+ and SIGI- columnns for crystal=$i dataset=$j to ($sigi_plus).\n"
				return 0
			    }
			}
		    } else {
			if { $data_anomalous == 0 } {
			    # If non-anomalous
			    # Check for presence of F/SIGF
			    set f $array(DATA_F,${i}_${j})
			    set sigf $array(DATA_SIGF,${i}_${j})
			
			    lappend column_list $f
			    lappend column_list $sigf
			
			    if { $f == "" || [StringSame $f "Unassigned"] } {
				WarningMessage "F column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { $sigf == "" || [StringSame $sigf "Unassigned"] } {
				WarningMessage "SIGF column not set for crystal=$i dataset=$j"
				return 0
			    }
			} else {
			    # Check for presence of both I+ and I-
			    # Make sure F+ and F- are different
			    set f_plus $array(DATA_F_PLUS,${i}_${j})
			    set sigf_plus $array(DATA_SIGF_PLUS,${i}_${j})
			    set f_minus $array(DATA_F_MINUS,${i}_${j})
			    set sigf_minus $array(DATA_SIGF_MINUS,${i}_${j})

			    lappend column_list $f_plus
			    lappend column_list $sigf_plus
			    lappend column_list $f_minus
			    lappend column_list $sigf_minus
			
			    if { $f_plus == "" || [StringSame $f_plus "Unassigned"] } {
				WarningMessage "F+ column not set for crystal=$i dataset=$j"
				return 0
			    }
			
			    if { $sigf_plus == "" || [StringSame $sigf_plus "Unassigned"] } {
				WarningMessage "SIGF+ column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { $f_minus == "" || [StringSame $f_minus "Unassigned"] } {
				WarningMessage "F- column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { $sigf_minus == "" || [StringSame $sigf_minus "Unassigned"] } {
				WarningMessage "SIGF- column not set for crystal=$i dataset=$j"
				return 0
			    }

			    if { [StringSame $f_plus $f_minus] } {
				WarningMessage "You have set both the F+ and F- columnns for crystal=$i dataset=$j to ($f_plus)."
				return 0
			    }

			    if { [StringSame $sigf_plus $sigf_minus] } {
				WarningMessage "You have set both the SIGF+ and SIGF- columnns for crystal=$i dataset=$j to ($sigf_plus).\n"
				return 0
			    }
			}
		    }
		    
		    set data_cukalpha $array(DATA_CUKALPHA,${i}_${j})
		    
		    # If "Data collected at CuKalpha"
		    if { $data_cukalpha } {
			# Set wavelength to CuKalpha = 1.5418A
			set $array(DATA_WAVELENGTH,${i}_${j}) 1.5418
			# Use GetFormFactors to determine f' and f''
			set atom_name [string toupper $array(CRYSTAL_ATOM_NAME,${i})]
			set form [GetFormFactors $atom_name]
			set fprime [lindex [split $form " "] 0]
			set fprimeprime [lindex [split $form " "] 1]
			# Set array elements
			set array(ATOM_WAVE_ID1,${i}_${j}) $atom_name
			set array(DATA_FPRIME1,${i}_${j}) $fprime
			set array(DATA_FPRIMEPRIME1,${i}_${j}) $fprimeprime
			
		    } else {
			# If !"Data collected at CuKalpha"
			# Check for f', f''.  Wavelength is optional
			#
			if { $array(PREMADE_START) == "Substructure detection" } {
			    set array(N_WATOMS,$i) 1
 			    set array(ATOM_WAVE_ID1,${i}_${j}) $array(CRYSTAL_ATOM_NAME,$i)
			} 

                       for { set k 1 } { $k <= $array(N_WATOMS,$i) } { incr k } {
                            set fprime $array(DATA_FPRIME$k,${i}_${j})
                            set fprimeprime $array(DATA_FPRIMEPRIME$k,${i}_${j})
                            set name $array(ATOM_WAVE_ID$k,${i}_${j})

                            if { $name == "" } {
                                WarningMessage "ATOM ID $k not set for crystal=$i dataset=$j"
                                return 0
                            }

                            if { $fprime == "" } {
                                WarningMessage "F' (fprime) not set for crystal=$i dataset=$j atom=$k"
                                return 0
                            }
                            if { $fprimeprime == "" } {
                                WarningMessage "F'' (fprimeprime) not set for crystal=$i dataset=$j atom=$k"
                                return 0
                            }
		       }
		    }
		}
	    }
            if {$array(CELL_A,$i) == "" } {
                set array(CELL_A,$i)     $array(CELL_1)
                set array(CELL_B,$i)     $array(CELL_2) 
                set array(CELL_C,$i)     $array(CELL_3)
                set array(CELL_ALPHA,$i) $array(CELL_4)
                set array(CELL_BETA,$i)  $array(CELL_5)
                set array(CELL_GAMMA,$i) $array(CELL_6)
            }
	}

	# Check the $typelist datastructure just built to make sure there
	# is only one label of each type present.

	for { set m 0 } { $m < [expr [llength $typelist] - 1] } { incr m } {
	    for { set n [expr $m + 1] } { $n < [llength $typelist] } { incr n } {
		if { [StringSame [lindex $typelist $m] [lindex $typelist $n]] } {
		    WarningMessage "Dataset $m ([lindex $typelist $m]) and Dataset $n ([lindex $typelist $n]) have the same type.\nPlease choose a different data type for each dataset"
		    return 0
		}
	    }
	}

	#
	# Check if any dataset is specified more than once in the experimental data section.
	#
	for { set m 0 } { $m < [expr [llength $column_list] - 1] } { incr m } {
	    for { set n [expr $m + 1] } { $n < [llength $column_list] } { incr n } {
		#puts "m=($m)([lindex $column_list $m]) n=($n)([lindex $column_list $n])"
		if { [StringSame [lindex $column_list $m] [lindex $column_list $n]] } {
		    WarningMessage "Column [lindex $column_list $m]) has been specified in two different datasets.\nEach experimental column referred to must be unique"
		    return 0
		}
	    }
	}
    }

    #                Required Parameters Section                   

    if { ![info exists array(NMONOMERS)] } {
	rungetstuff $arrayname 1
	if { ![info exists array(NMONOMERS)] } {
	    WarningMessage "Number of monomers could not be automatically set - Please set manually in Derived parameters section"
	    return 0
	}
    }

    # Make sure B-factor is set and is greater than 0
    set bfactor $array(BFACTOR)
    if { $bfactor == "" } {
	WarningMessage "Please enter in the sequence or number of residues/nucleotides and the mtz file."
	return 0
    }

    if { $bfactor < 0 } {
	WarningMessage "Bfactor is less than zero.  It must be greater than zero"
	return 0
    }


    # Make sure Solvent content is set and is between 0 and 1
    set solvent_content $array(SOLVENT_CONTENT)
    if { $solvent_content == "" } {
	WarningMessage "Please enter in the sequence or number of residues/nucleotides and the mtz file."
	return 0
    }

    if { $solvent_content < 0 } {
	WarningMessage "Solvent content is less than zero.  It must be between zero and one"
	return 0
    }

    if { $solvent_content > 1 } {
	WarningMessage "Solvent content is greater than one.  It must be be between zero and one"
	return 0
    }


    ################################################################
    #                 Experimental Pipeline Section                #
    ################################################################

    #
    # Check to make sure input pulldown menus are set for all program steps
    #
	
    # Loop over all programs in the pipeline
    # For each different kind of program, have a separate section
    # here, checking to make sure that:
    #  - Inputs are all pointing to a valid field
    #
    for { set i 1 } { $i <= $array(N_PROGRAMS) } { incr i } {
	set name $array(PROGRAM_NAME,${i})

	foreach program $PluginList {
	    if { [string compare [string tolower $program] $name] == 0 } {
		if { [info exists XMLParse(crank__plugin=${name}__input__experimental_columns)] } {
		    if { $array(INPUT_EXPERIMENTAL_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Experimental Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__f_columns)] } {
		    if { $array(INPUT_F_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput F Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__i_columns)] } {
		    if { $array(INPUT_I_COLUMNS,$i) == "" } {
			 WarningMessage "Program Step $i :: $program_name\nInput I Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__phase_columns)] } {
		    if { $array(INPUT_PHASE_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Phase Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__hl_columns)] } {
		    if { $array(INPUT_HL_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Hl Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__ea_columns)] } {
		    if { $array(INPUT_EA_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Ea Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__fa_columns)] } {
		    if { $array(INPUT_FA_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Fa Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__alpha_columns)] } {
		    if { $array(INPUT_ALPHA_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Alpha Columns is Missing"
			return 0
		    }
		}
		if { [info exists XMLParse(crank__plugin=${name}__input__freer_columns)] } {
		    if { $array(INPUT_FREER_COLUMNS,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Freer Columns is Missing"
			return 0
		    }
		}

		if { [info exists XMLParse(crank__plugin=${name}__input__substructure)] } {
		    if { $array(INPUT_SUBSTRUCTURE,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Substructure is Missing"
			return 0
		    }
		}

		if { [info exists XMLParse(crank__plugin=${name}__input__pdb)] } {
		    if { $array(INPUT_PDB,$i) == "" } {
			WarningMessage "Program Step $i :: $program_name\nInput Pdb is Missing"
			return 0
		    }
		}		
	    }
	}
    }


    ################################################################
    #                 Other miscellaneous checks                   #
    ################################################################

    if { $array(N_PROGRAMS) == 0 } {
	WarningMessage "You have not added any programs to the pipeline.\nPlease add at least one program to the pipeline to run Crank"
	return 0
    }

    ################################################################
    #        Check for temporary program specific limitations      #
    ################################################################

    return 1
}

# 
# CCP4i - Start a Crank run
#
proc crank_run { arrayname } {
    upvar #0 $arrayname array
    global PluginList
    
    set array(INPUT_FILES) "HKLIN"
    set array(OUTPUT_FILES) "HKLOUT XYZOUT"

    #
    # Check to make sure all fields in the interface are filled in properly
    #
    set good [check_all $arrayname]
    if { !$good } {
	return 0
    }

    for { set i 1 } { $i <= $array(N_PROGRAMS) } { incr i } {
	set array(OUTPUT_EXPERIMENTAL_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_F_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_I_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_PHASE_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_HL_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_EA_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_FA_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_ALPHA_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
	set array(OUTPUT_FREER_COLUMNS,$i) [join "$i $array(PROGRAM_NAME,$i)" _]
    }


    # Calculate the total number of datasets for the .com files
    set total 0
    for { set i 0 } { $i < $array(N_CRYSTALS) } { incr i } {
	for { set j 0 } { $j < $array(N_DATA,$i) } { incr j } {
	    set total [expr $total + 1]
	}
    }
    set array(TOTAL_DATASETS) $total

    #
    #
    # Setup datastructures to output this Crank job as a database.def file
    #
    # The simple bits
    set array(CCP4DB_DATESTR) [clock format [clock seconds]]		
    set array(CCP4DB_DATE) [GetDate -format seconds]
    set array(CCP4DB_USER) [GetUserId]

    for { set i 1 } { $i <= $array(N_PROGRAMS) } { incr i } {
	set name $array(PROGRAM_NAME,$i)
	set tag $array(PROGRAM_TAG,$i)
	if { [string compare $name "AFRO"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	    set array(CCP4DB_OUTPUT_FILES,$i) "crank.out.$tag.mtz"
	} elseif { [string compare $name "CRUNCH2"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	} elseif { [string compare $name "BP3"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	    set array(CCP4DB_OUTPUT_FILES,$i) "crank.out.$tag.mtz"
	} elseif { [string compare $name "DM"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	    set array(CCP4DB_OUTPUT_FILES,$i) "crank.out.$tag.mtz"
	} elseif { [string compare $name "SHELXC"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	    set array(CCP4DB_OUTPUT_FILES,$i) "crank.out.$tag.mtz"
	} elseif { [string compare $name "SHELXD"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	} elseif { [string compare $name "SHELXE"] == 0 } {
	    set array(CCP4DB_INPUT_FILES,$i) "crank.in.$tag.mtz"
	    set array(CCP4DB_OUTPUT_FILES,$i) "crank.out.$tag.mtz"
	}
		
    }	

    if { ![info exists array(LOW_RES_LIMIT)] } {
		set array(LOW_RES_LIMIT) 9999.0
    }

    # Setup pointers for all plugin .com files
    for { set i 1 } { $i <= $array(N_PROGRAMS) } { incr i } {
	set name [string tolower $array(PROGRAM_NAME,$i)]
	set array(PROGRAM_COM,$i) [file join $name cccp4_$name.com]
    }

    #
    # Loop through all programs and make sure that all input columns
    # are filled in by looking through the plugin index.xml
    # files, they contain all input and output columns.
    #
#	for { set i 1 } { $i <= $array(N_PROGRAMS) } { incr i } {
#		
#	}
	
    return 1
}


#
# CCP4i - Setup variables and menus at the start of a run
#
proc crank_setup { typedefVar arrayname } {
    upvar #0 $typedefVar typedef
    upvar #0 $arrayname array

    global env
    global status

    if { $env(CRANK) == "" } {
	WarningMessage "Please set CRANK environment variable - this is required."
	return 0
    }

    if { ! ([file exists [FindExecutable gcx] ] || 
	    [file exists [file join $env(CRANK) bin gcx] ]) } {
        WarningMessage "Can not find executable gcx - please ensure it is in your path"
        return 0
    }

    global XMLParse

    global param_list

    global PluginList

    global programs_toggleframe_list

    global all_subframes

    set all_subframes ""

    #
    # The list of data items that will get passed to the
    # CreateToggleFrame that makes the experiment palette.
    #
    # This is necessary because some programs have pulldown
    # menus (DefineMenus) that need to have their data items already
    # set up before they are created. This is a global variable that
    # needs to get referenced and updated in the plugin _setup
    # functions.
    #
    set programs_toggleframe_list \
	[list PROGRAM_NAME \
	     INPUT_EXPERIMENTAL_COLUMNS \
	     INPUT_EXPERIMENTAL_COLUMNS_LIST \
	     INPUT_EXPERIMENTAL_COLUMNS_ALIAS \
	     INPUT_F_COLUMNS \
	     INPUT_F_COLUMNS_LIST \
	     INPUT_F_COLUMNS_ALIAS \
	     INPUT_I_COLUMNS \
	     INPUT_I_COLUMNS_LIST \
	     INPUT_I_COLUMNS_ALIAS \
	     INPUT_PHASE_COLUMNS \
	     INPUT_PHASE_COLUMNS_LIST \
	     INPUT_PHASE_COLUMNS_ALIAS \
	     INPUT_HL_COLUMNS \
	     INPUT_HL_COLUMNS_LIST \
	     INPUT_HL_COLUMNS_ALIAS \
	     INPUT_EA_COLUMNS \
	     INPUT_EA_COLUMNS_LIST \
	     INPUT_EA_COLUMNS_ALIAS \
	     INPUT_FA_COLUMNS \
	     INPUT_FA_COLUMNS_LIST \
	     INPUT_FA_COLUMNS_ALIAS \
	     INPUT_ALPHA_COLUMNS \
	     INPUT_ALPHA_COLUMNS_LIST \
	     INPUT_ALPHA_COLUMNS_ALIAS \
	     INPUT_FREER_COLUMNS \
	     INPUT_FREER_COLUMNS_LIST \
	     INPUT_FREER_COLUMNS_ALIAS \
	     INPUT_SUBSTRUCTURE \
	     INPUT_SUBSTRUCTURE_LIST \
	     INPUT_SUBSTRUCTURE_ALIAS \
	     INPUT_PDB \
	     INPUT_PDB_LIST \
	     INPUT_PDB_ALIAS \
	     DEFAULT_MENU \
	     DEFAULT_MENU_LIST \
	     DEFAULT_MENU_ALIAS \
	    ]

    set PluginList {}
    set param_list {}
	
    #
    # Load all plugins
    #
    set crankbin "[file join $env(CRANK) bin]"
    source [file join $crankbin crankutils.tcl]
    set crankplugins "[file join $env(CRANK) plugins]"
    doplugins $crankplugins
    verifyplugins

    #
    # Source all plugin files so we can use their utility functions
    #
    set pluggin_deffiles {}
    foreach program $PluginList {

	if { [info exists XMLParse(crank__plugin=${program}__name)] } {
	    set name $XMLParse(crank__plugin=${program}__name)
	} else {
	    crank_error "No name for program ($program)"
	}

	if { [info exists XMLParse(crank__plugin=${program}__tclproc)] } {
	    set tclproc $XMLParse(crank__plugin=${program}__tclproc)
	} else {
	    crank_error "No tclproc for program ($program)"
	}
	# Source crank_program.tcl
	if { [info exists XMLParse(crank__plugin=${program}__cccp4file)] } {
	    set cccp4file $XMLParse(crank__plugin=${program}__cccp4file)

	    set cccp4filename [file join $crankplugins $name $cccp4file]

	    if { ![file exists $cccp4filename] } {
		crank_error "cccp4filename ($cccp4filename) does not appear to exist"
	    }
	    source [file join $crankplugins $name $cccp4file]
	    ${name}_setup

	} else {
	    crank_error "No cccp4file for program ($program)"
	}

	#
	# Setup the variable to load in the plugin .def files
	#	
	if { [info exists XMLParse(crank__plugin=${program}__cccp4deffile)] } {
	    set cccp4deffile $XMLParse(crank__plugin=${program}__cccp4deffile)
	    lappend plugin_deffiles "[file join $crankplugins $program $cccp4deffile]" 
	}
    }

    foreach file $plugin_deffiles {
 	set fileid [open $file r]
	while { [gets $fileid line] >= 0 } {
	    if { [string length $line ] > 0 } {
		# Handle insertion of data from another def file
		switch [string range $line 0 0 ] \
		    "@" {
			eval "set filename [string range $line 1 end]"
			if { [ReadFile $filename tmp_full_text -split] } {
			    # Insert the file contents at the correct position
			    set full_text [concat [lrange $full_text 0 $nl] \
					       $tmp_full_text [lrange $full_text [expr {$nl + 1}] end]]
			    set nl_full_text [llength $full_text]
			}
		     } "#" {
		     } default {
			 set element [lindex $line 0 ]
			 switch [llength $line] \
			     2 {
				 set array($element) [lindex $line 1]
			     } 3 {
				 set array(_$element) [lindex $line 1]
				 set array($element) [lindex $line 2]
				 #            if {[catch "set value [lrange $line 2 end]"]} {
				 #              Report 1 "ERROR reading value of parameter $element from file $filn"
				 #              set value ""
				 #            }
			     }
			 if { ![regexp {,[1-9]} $element] } {
			     lappend param_list $element
			 }
			 # Check for reserved prefixes that are normally used for
			 # internal admin varibles
		     }
	    }
	}
	
    }


    # The type of each dataset
    DefineMenu _data_type [list "SAD" \
			       "Native" \
			       "Derivative" \
			       "Peak" \
			       "Inflection" \
			       "High Remote" \
			       "Low Remote" \
			       "Other" ] \
	[list SAD NATIVE SIRAS PEAK INFL HREM LREM OTHER]

    if { ([file exists [FindExecutable shelxc]] && [file exists [FindExecutable shelxd]] &&
	  [file exists [FindExecutable shelxe]]) } {
	set shelx 1
	DefineMenu _find_progs [list AFRO/CRUNCH2 SHELXC/D ] 
    } else {
	set shelx 0
	DefineMenu _find_progs [list AFRO/CRUNCH2 ] 
    }

#   DefineMenu _refine_progs [list BP3 REFMAC SHELXE ] 
    DefineMenu _refine_progs [list BP3 SHELXE ] 

    DefineMenu _hand_progs [list SOLOMON NONE ] 

    if { ([file exists [FindExecutable resolve_giant]]) } {
	set resolve 1
	DefineMenu _dm_progs [list SOLOMON PARROT DM PIRATE RESOLVEDM ]
    } else {
	set resolve 0
 	DefineMenu _dm_progs [list SOLOMON PARROT DM PIRATE ] 
    }

    if { [file exists [FindExecutable arp_warp]] } {
	set arpwarp 1
	if { ([file exists [FindExecutable cbuccaneer]]) } {
	    set buc 1
	    if { $resolve } {
		DefineMenu _model_progs [list BUCCANEER ARPWARP RESOLVEMB ] 
	    } else {
 		DefineMenu _model_progs [list BUCCANEER ARPWARP ] 
	    }
	} else {
	    set buc 0
	    if { $resolve } {
	 	DefineMenu _model_progs [list ARPWARP RESOLVEMB ] 
	    } else {
 	 	DefineMenu _model_progs [list ARPWARP ] 
	    }
	}
    } else {
	set arpwarp 0
	if { ([file exists [FindExecutable cbuccaneer]]) } {
	    set buc 1
	    if { $resolve } {
		DefineMenu _model_progs [list RESOLVEMB BUCCANEER ] 
	    } else {
 		DefineMenu _model_progs [list BUCCANEER ] 
	    }
	} else {
	    set buc 0
	    if { $resolve } {
	 	DefineMenu _model_progs [list RESOLVEMB ] 
	    } 
	}
    }

    if { $arpwarp || $resolve || $buc } {
	DefineMenu _pipeline_step [list "Substructure detection" "Substructure phasing" "Hand determination" "Density modification" "Model building" ] \
	    [list DETECT PHASE HAND DM BUILD]

    } else {
	DefineMenu _pipeline_step [list "Substructure detection" "Substructure phasing" "Hand determination" "Density modification" ] \
 	    [list DETECT PHASE HAND DM]

	DefineMenu _model_progs [list "" ] 
	if { [info exists array(PREMADE_END)] } {
 	    if { ($array(PREMADE_END) == "Model building" ) || ($array(PREMADE_END) == "") } {
		set array(PREMADE_END) "Density modification"
	    }
	}
    }

#    DefineMenu _pipeline_start [list "Substructure detection" \
#			       "Substructure phasing"  "Density modification"] [list DETECT PHASE DM]

     DefineMenu _pipeline_start [list "Substructure detection" "Substructure phasing"] [list DETECT PHASE]

    DefineMenu _experiment_setup [list "Single wavelength anomalous diffraction (SAD)" \
				      "Single isomorphous replacement with anomalous scattering (SIRAS)" "Two wavelength anomalous diffraction (2W-MAD)" \
				      "Three wavelength anomalous diffraction (3W-MAD)" "Four wavelength anomalous diffraction (4W-MAD)" "Two wavelength anomalous diffraction with native (2W-MAD-N)" \
				      "Three wavelength anomalous diffraction with native (3W-MAD-N)" "Four wavelength anomalous diffraction with native (4W-MAD-N)"] [list SAD SIRAS 2WMAD 3WMAD \
																		     4WMAD 2WMADN 3WMADN 4WMADN ]

    DefineMenu _data_input_type [list Intensities Amplitudes ] 

    DefineMenu _substructure_input_type [list Pdb Manual ]

    DefineMenu _coordinate_format_type [list Fractional Orthogonal ]

    set experimental_program_list {}
    set experimental_program_quoted_list {}
    foreach program $PluginList {
	set prog [string toupper $XMLParse(crank__plugin=${program}__name)]
	lappend experimental_program_list $prog
	lappend experimental_program_quoted_list "\"$prog\""
    }
    
    DefineMenu _experimental_program $experimental_program_list $experimental_program_quoted_list

    #
    # Setup variable menus
    #

    # varmenu for the datasets that have been entered so far
    set typedef(_input_experimental_columns) { varmenu INPUT_EXPERIMENTAL_COLUMNS_LIST INPUT_EXPERIMENTAL_COLUMNS_ALIAS 20 }
    set typedef(_input_f_columns) { varmenu INPUT_F_COLUMNS_LIST INPUT_F_COLUMNS_ALIAS 20 }
    set typedef(_input_i_columns) { varmenu INPUT_I_COLUMNS_LIST INPUT_I_COLUMNS_ALIAS 20 }
    set typedef(_input_phase_columns) { varmenu INPUT_PHASE_COLUMNS_LIST INPUT_PHASE_COLUMNS_ALIAS 20 }
    set typedef(_input_hl_columns) { varmenu INPUT_HL_COLUMNS_LIST INPUT_HL_COLUMNS_ALIAS 20 }
    set typedef(_input_ea_columns) { varmenu INPUT_EA_COLUMNS_LIST INPUT_EA_COLUMNS_ALIAS 20 }
    set typedef(_input_fa_columns) { varmenu INPUT_FA_COLUMNS_LIST INPUT_FA_COLUMNS_ALIAS 20 }
    set typedef(_input_alpha_columns) { varmenu INPUT_ALPHA_COLUMNS_LIST INPUT_ALPHA_COLUMNS_ALIAS 20 }
    set typedef(_input_freer_columns) { varmenu INPUT_FREER_COLUMNS_LIST INPUT_FREER_COLUMNS_ALIAS 20 }
    set typedef(_input_substructure) { varmenu INPUT_SUBSTRUCTURE_LIST INPUT_SUBSTRUCTURE_ALIAS 20 }
    set typedef(_input_pdb) { varmenu INPUT_PDB_LIST INPUT_PDB_ALIAS 20 }
    set typedef(_default_menu) { varmenu DEFAULT_MENU_LIST DEFAULT_MENU_ALIAS 20 }

    set typedef(_testmenu) { varmenu INPUT_TEST_LIST INPUT_TEST_ALIAS 8 }

    return 1
}

proc doplugins { crankplugins } {
    global PluginList
    global XMLParse

    # Make a list of all the index.xml files in each directory 
    # in crank/plugins/*.
    set all_pluginxml [glob -nocomplain [file join $crankplugins * *_index.xml]]
	
    #puts "all_pluginxml($all_pluginxml)"

    # Loop over all plugin index.xml files
    foreach pluginxml $all_pluginxml {
	#puts "pluginxml=($pluginxml)"
	
	# Parse the XML from this file into the global datastructure
	XMLParsefile $pluginxml
	
	# Add the name of the plugin to the global plugin list
	set fileid [open "$pluginxml" r]
	while { [gets $fileid line] >= 0 } {		
	    
	    if { [regexp { *<name>([A-Za-z1-9._]*)</name>} $line all match ] } {
		if { ( ($match == "shelxc") ||
		       ($match == "shelxd") ||
		       ($match == "shelxe") ||
		       ($match == "coot")   ||
		       ($match == "resolvedm") ||
		       ($match == "resolvemb") ||
		       ($match == "buccaneer") ||
 		       ($match == "arpwarp") ) } {
 		    if {$match == "arpwarp"} {
			if { [file exists [FindExecutable arp_warp]] } {
			    lappend PluginList $match
			}
		    } elseif { ($match == "resolvedm") || ($match == "resolvemb") } {
  			if { [file exists [FindExecutable resolve_giant]] } {
			    lappend PluginList $match
			}
		    } elseif { ($match == "buccaneer") } {
 			if { [file exists [FindExecutable cbuccaneer]] } {
			    lappend PluginList $match
			}
		    } elseif { ($match == "coot") } {
 			if { [file exists [FindExecutable coot]] } {
			    lappend PluginList $match
			    set array(COOT_EXISTS) 1
			} else {
			    set array(COOT_EXISTS) 0
			}
		    } else {
			if { [file exists [FindExecutable $match]] } {
			    lappend PluginList $match
			}
		    }
		} else {
		    lappend PluginList $match
		}		    
	    }
	}
	close $fileid
    }
}
 
#
# Verify all the plugins
#
#
proc verifyplugins { } {
}

proc Create_nolabel_ToggleFrame { indexVar def_proc0 message title \
         add_text indexed_parameters args } {
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set counter 0
  set ndep 0
  set noaddline 0
  set depframes ""
  set children ""
  set edit_proc ""
  set anchor n

  set nargs [llength $args] ; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ] \
    depend {
       incr ndep
       incr n
       lappend depframes "[lindex $args $n ]"
    } child {
       incr n
       lappend children [lindex $args $n ]
    } noadd {
       set noaddline 1
    } edit_proc {
       incr n; set edit_proc [lindex $args $n ]
    } justify {
       incr n
       set justify [lindex $args $n ]
       switch -exact -- $justify {
	 left {
	   set anchor nw
	 }
	 right {
	   set anchor ne
	 }
	 center {
	   set anchor n
	 }
       }
    }
    incr n
  }

  OpenSubFrame top_frame
  OpenSubFrame frame

  frame $frame.dummy -height 1
  pack $frame.dummy -side top

  append def_proc $def_proc0 _ $counter

# The following parameters are referenced by def_proc and are unique
# for each instance of the toggle frame
  set array(FRAME_$def_proc) $frame
  set array(XF_EDIT_$def_proc) ""
  set array(XF_SELECT_$def_proc) ""

# The following params are refenced bu def_proc0 and are common between all
# instances of the toggle frame
  set array(CHILD_$def_proc0) $children
  foreach child $children {
    set array(PARENT_$child) $def_proc0
  }

  set array(N_DEPFRAMES_$def_proc0) $ndep
  set array(DEPFRAMES_$def_proc0) $depframes

  set array(XF_INDEX_$def_proc0) $indexVar
  set array(FRAME_TYPE_$def_proc0) toggle
  set array(FRAME_TITLE_$def_proc0) $title
  set array(FRAME_ANCHOR_$def_proc0) $anchor
  set array(EDIT_PROC_$def_proc0) $edit_proc
  set array(HELP_$def_proc0) [GetSystemVar frame_program_help]
  set array(VARS_$def_proc0) $indexed_parameters

  if {$array(N_DEPFRAMES_$def_proc0) >= 0 && $array($indexVar) > 0 } {
    append array(UPDATE_SCRIPTS) \
   "update_toggleframe $def_proc0 0 $arrayname $indexVar 0 $array($indexVar) 0\n"
  }
  CloseSubFrame

  if { $noaddline == 0 } {
    create_nolabel_addline_command line $message $indexVar update_toggleframe0  \
         $def_proc0 0  $add_text 1 
#    set array(XF_COMLINE_$def_proc) $line
  }
  CloseSubFrame
}


proc Create_nolabel_ExtendingFrame { indexVar0 def_proc0 message \
            add_text indexed_parameters args } {

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set indexVar $indexVar0
  set del_text ""
  set noaddline 0
  set ndep 0
  set depframes ""
  set edit_proc ""
  set children ""
  set counter 0

  set nargs [llength $args]
  set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ] \
    dependent {
       incr ndep
       incr n; lappend depframes "[lindex $args $n]"
    } child {
       incr n; lappend children [lindex $args $n]
    } edit {
       incr n; lappend edit_proc [lindex $args $n]
    } noadd {
       set noaddline 1
    } delete {
       incr n; set del_text [lindex $args $n ]
    } counter {
       incr n; set counter  [lindex $args $n ]
    }
    incr n
  }

  OpenSubFrame top_frame
 
  append def_proc $def_proc0 _ $counter

  set array(XF_EDIT_$def_proc) ""
  set array(XF_SELECT_$def_proc) ""
  set array(XF_COMLINE_$def_proc) ""

  if { $counter <= 1 } {
    set array(CHILD_$def_proc0) $children
    foreach child $children {
      set array(PARENT_$child) $def_proc0
    }

    set array(N_DEPFRAMES_$def_proc0) $ndep
    set array(DEPFRAMES_$def_proc0) $depframes

    set array(XF_INDEX_$def_proc0) $indexVar
    set array(EDIT_PROC_$def_proc0) $edit_proc
    set array(FRAME_TYPE_$def_proc0) extending
    set array(FRAME_TITLE_$def_proc0) ""
    set array(HELP_$def_proc0) [GetSystemVar frame_program_help]
    set array(VARS_$def_proc0) $indexed_parameters
  }

  if { $counter > 0 } {append indexVar , $counter }

  OpenSubFrame frame

# Add a dummy line so when all other lines are deleted this one
# will determine the size of the remaining space (ie small)

  frame $frame.dummy -height 1
  pack $frame.dummy -side top

  set array(FRAME_$def_proc) $frame

  if { $array(N_DEPFRAMES_$def_proc0) >= 0 \
       && $counter == 0 && $array($indexVar) > 0 } {
#    puts "append UPDATE_SCRIPTS $def_proc0"
    append array(UPDATE_SCRIPTS) \
    "update_extendingframe $def_proc0 $counter $arrayname $indexVar \
		0 $array($indexVar) 0\n"
  }

  CloseSubFrame

  if { $noaddline == 0 } {
    set remo_text "Remove last line"
    create_nolabel_addline_command line $message $indexVar \
	update_extendingframe0 $def_proc0 $counter $add_text 1 
#    set array(XF_COMLINE_$def_proc) $line
  }

  CloseSubFrame

}

proc create_nolabel_addline_command { lineVar message c1 command def_proc0 counter \
   add_text  ifedit } {

  upvar $lineVar line
  
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter

  return
}

#
# CCP4i - Draw main Crank task window
#
proc crank_task_window { arrayname } {
    upvar #0 $arrayname array
    global env
    global param_list
    global programs_toggleframe_list
    global all_subframes

    if { ![CreateTaskWindow $arrayname  \
 	       "CRANK" CRANK \
	       [list "Derived parameters" \
		    "Experimental Pipeline" \
		   ] ] }  { return 0 }

    #
    # Things saved to array(PARAM_LIST) get
    # saved to the .def file that is used to run crank in CCP4_DATABASE/1_crank.def.
    # So, we need to build up this list from the input plugin .def files, which
    # was constructed in crank_setup.
    #
    foreach param $param_list {
	lappend array(PARAM_LIST) $param
    }

    set options_folder 1
    set experiment_folder 2

    # Retrive defaults from XML file if available & requested
    source [SearchPath TOP utils xml_utils.tcl]

    # Populate the task window
    OpenFolder protocol

    # Title frame
    OpenSubFrame frame1

    # The picture, on the left
    #set cranklogo [image create photo -file [ FileJoin $env(CRANK) bin crank-logo.gif ] ]
    #set logo [label $frame1.f1 -image $cranklogo]
#    pack $logo -side left

    CreateLine line \
	message "Enter a title for this job (TITLE)" \
	label "Title" \
	widget TITLE -width 80

    CreateLine line \
	label "Type of experiment" \
	widget EXPERIMENT_SETUP -width 60 \
	-command "clear_program_defaults $arrayname; setup_experiment $arrayname; set_program_defaults $arrayname" 

    CreateLine line \
	label "Input protein sequence" \
	message "Give a protein sequence to be used in model building" \
	widget DOCK_SEQUENCE

    OpenSubFrame frame -toggle_display DOCK_SEQUENCE open 1

    CreateInputFileLine line \
	"Enter name of file containing the protein sequence (SEQIN)" \
	"SEQ in " \
	SEQIN DIR_SEQIN \
	-command "rungetstuff $arrayname 0"	

    CreateLine line \
	label "Total amino acid residues: " \
	varlabel NRESIDUES 

    CloseSubFrame

    OpenSubFrame frame -toggle_display DOCK_SEQUENCE open 0

    CreateLine line \
	label " " \
	message "Number of residues per monomer" \
	label "Number of residues per monomer " \
	widget NRESIDUES -oblig -width 5 \
	-command "rungetstuff $arrayname 0" 
    CloseSubFrame

    CreateLine line \
	label "DNA/RNA present" \
	message "Is DNA/RNA present in this structure?" \
	widget NUCLEOTIDES_PRESENT

    OpenSubFrame frame -toggle_display NUCLEOTIDES_PRESENT open 1    

    CreateLine line \
	label " " \
	message "Number of nucleotides per monomer" \
	label "Number of nucleotides per monomer " \
	widget NNUCLEOTIDES -oblig -width 5 \
	-command "rungetstuff $arrayname 0" 
    CloseSubFrame

    CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
	"MTZ in" \
	HKLIN DIR_HKLIN \
	-fileout HKLOUT DIR_HKLOUT _crank \
	-fileout XYZOUT DIR_XYZOUT _crank \
	-setlabin RFREE_LABEL [list FREE FreeR FreeR_flag] \
	-setfileparam resolution_min LOW_RES_LIMIT \
	-setfileparam resolution_max HIGH_RES_LIMIT \
	-setfileparam space_group_name SPACE_GROUP_NAME \
	-setfileparam space_group_name SPACE_GROUP_NAME \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
	-setfileparam space_group_number SPACE_GROUP_NUMBER 

    if { $array(RFREE_LABEL) != "" && $array(RFREE_LABEL) != "Unassigned" } {
         SetLabin $arrayname HKLIN RFREE_LABEL $array(RFREE_LABEL)
    } else {
         SetLabin $arrayname HKLIN RFREE_LABEL [list FREE FreeR FreeR_flag]
    }

   CreateLine line \
 	message "Either input merged intensities or structure factor amplitudes" \
	label "Input" \
	widget INPUT_DATA \
	-command "setup_inputdata $arrayname" \
        label "Input R-free flag"  \
         widget INPUT_RFREE \
        message "Input an R-free set contained in the input mtz (alternatively, generate an R-free set"

    OpenSubFrame frame -toggle_display PREMADE_START open { "HAND" "DM" "BUILD" }

    lappend all_subframes $frame

    CreateLabinLine4 line \
 	"Hendrickson-Lattman coefficients" \
 	HKLIN      "HLA" HLA {} \
 	-dependent "HLB" HLB {} \
 	-dependent "HLC" HLC {} \
 	-dependent "HLD" HLD {} 
 
    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_RFREE open 0

    lappend all_subframes $frame

    CreateLine line \
        label "FreeR set will consist of " \
        widget RFREE_FRACTION -width 5 \
        label "fraction of the data." \
        message "Fraction of data that is required for the free data set"
    
    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_RFREE open 1

    lappend all_subframes $frame

    CreateLine line \
	message "Label of data in input MTZ file (LABIN FREE)" \
	label "Exclude data with Free R label"  \
	widget RFREE_LABEL -width 25 

    CloseSubFrame

    CreateOutputFileLine line \
	"Enter output MTZ file name (HKLOUT)" \
	"MTZ out" \
	HKLOUT DIR_HKLOUT 

    CreateOutputFileLine line \
	"Enter output PDB file name (XYZOUT)" \
	"PDB out" \
	XYZOUT DIR_XYZOUT 

    pack $line -side top

    CloseSubFrame
 
    OpenFolder file

    #
    # Experimental columns
    #

    OpenSubFrame frame_new -toggle_display TOGGLE_INPUT_EXP_COLUMNS open 1

    Create_nolabel_ToggleFrame N_CRYSTALS crystal_proc \
	"Add new Crystals/Datasets  - The experimental data you collected" \
	"Crystal #" \
	"Add new Cryst als/Datasets" \
	[list  CRYSTAL_ID \
	     N_DATA \
	     CRYSTAL_ATOM_NAME \
	     CRYSTAL_N_ATOMS \
	     CRYSTAL_INPUT_SUBSTRUCTURE \
	     CRYSTAL_INPUT_SUBSTRUCTURE_TYPE \
	     COORDINATE_FORMAT \
	     SUBSTRUCTURE_INPUT_COORDSIN \
	     DIR_SUBSTRUCTURE_INPUT_COORDSIN \
	     CELL_A \
	     CELL_B \
	     CELL_C \
	     CELL_ALPHA \
	     CELL_BETA \
	     CELL_GAMMA \
	     NUM_ATOMS \
	     N_ATOMS \
	     ATOM_ID \
	     ATOM_X \
	     ATOM_Y \
	     ATOM_Z \
	     ATOM_X_NOREF \
	     ATOM_Y_NOREF \
	     ATOM_Z_NOREF \
	     ATOM_OCCU \
	     ATOM_BISO \
	     ATOM_OCCU_NOREF \
	     ATOM_BISO_NOREF \
	     DATA_TYPE \
	     DATA_CUKALPHA \
             N_WATOMS \
             ATOM_WAVE_ID1 \
             DATA_FPRIME1 \
             DATA_FPRIMEPRIME1 \
             ATOM_WAVE_ID2 \
             DATA_FPRIME2 \
             DATA_FPRIMEPRIME2 \
             ATOM_WAVE_ID3 \
             DATA_FPRIME3 \
             DATA_FPRIMEPRIME3 \
             ATOM_WAVE_ID4 \
             DATA_FPRIME4 \
             DATA_FPRIMEPRIME4 \
             ATOM_WAVE_ID5 \
             DATA_FPRIME5 \
             DATA_FPRIMEPRIME5 \
             ATOM_WAVE_ID6 \
             DATA_FPRIME6 \
             DATA_FPRIMEPRIME6 \
	     DATA_WAVELENGTH \
	     DATA_ANOMALOUS \
	     DATA_I \
	     DATA_SIGI \
	     DATA_I_PLUS \
	     DATA_SIGI_PLUS \
	     DATA_I_MINUS \
	     DATA_SIGI_MINUS \
	     DATA_F \
	     DATA_SIGF \
	     DATA_F_PLUS \
	     DATA_SIGF_PLUS \
	     DATA_F_MINUS \
	     DATA_SIGF_MINUS \
	    ] \
	-child data_proc \
	-child atom_proc \
	-noaddline 

    CloseSubFrame 

    OpenFolder 1 closed

#    CreateLine line \
#        message "Choose data set to use in density modification and model building" \
#        label "Use data set" \
#        widget REF_DATASET -width 2 \
#        label "from crystal number" \
#        widget REF_CRYSTAL -width 2 \
#        label "in density modification and model building" 

    CreateLine line \
	label " " \
 	message "Guessing overall b-factor, solvent content and number of monomers if no input is given " \
 	button "Guess Overall B, solvent content (and number of monomers if no input is given)" \
 	-command "rungetstuff $arrayname 1"

    CreateLine line \
	label " " \
 	message "Number of monomers in the asu - Either input here or obtain a value with the Guess button below " \
	widget NMONOMERS -width 3 \
	-command "rungetstuff $arrayname 1" \
 	label "number of monomers in the asu"  

    CreateLine line \
	message "Solvent Content - Either input a number here or obtain a value with the Guess button below" \
	label "Solvent Content" \
	widget SOLVENT_CONTENT \
	message "B-factor - Either input a number here or obtain a value with the Guess button below" \
	label "B-factor" \
	widget BFACTOR

    CreateLine line \
	label "Matthew's coefficient: " \
	varlabel MATTHEWS  \
	label "Kantardjieff-Rupp probability: " \
	varlabel KRPROB 
    
    OpenFolder $experiment_folder
    
    if { [file exists [FindExecutable coot]] } {
	set array(COOT_EXISTS) 1
    } else {
	set array(COOT_EXISTS) 0
    }

    CreateLine line \
	label "Start the pipeline with " \
	message "Give the first step the pipeline will perform" \
	widget PREMADE_START -width 20 \
	-command "fix_scroll $arrayname ; add_premade_pipeline $arrayname" \
	label " and end with " \
	message "Give the last step the pipeline will perform" \
	widget PREMADE_END -width 20 \
	-command "fix_scroll $arrayname ; add_premade_pipeline $arrayname" 

    OpenSubFrame frame -toggle_display COOT_EXISTS open 1    
    
    lappend all_subframes $frame

    CreateLine line \
	label "Display results with coot" \
	message "Display substructure, map and/or models with coot" \
	widget DISPLAY_COOT \
	-command "fix_scroll $arrayname ; SetSystemVar block_scroll_update 0 ; add_premade_pipeline $arrayname"
    CloseSubFrame 

    OpenSubFrame frame -toggle_display PREMADE_START open "DETECT"  

    lappend all_subframes $frame

	CreateLine line \
	    message "Choose the substructure detection program" \
	    label "Substructure detection:" \
	    widget FIND_PROGS -width 18 \
	    -command "add_premade_pipeline $arrayname" 

    CloseSubFrame 

    OpenSubFrame frame -toggle_display PREMADE_START open { "DETECT" "PHASE" } 

    lappend all_subframes $frame

    OpenSubFrame frame -toggle_display PREMADE_END hide "DETECT" 

    lappend all_subframes $frame

    CreateLine line \
	message "Choose the substructure refinement/phasing program" \
	label "Substructure refinement:" \
	widget REFINE_PROGS -width 18 \
	-command "add_premade_pipeline $arrayname" 

    CloseSubFrame

    CloseSubFrame

    OpenSubFrame frame -toggle_display PREMADE_START open { "DETECT" "PHASE" "HAND" }

    lappend all_subframes $frame

    OpenSubFrame frame -toggle_display PREMADE_END hide {"DETECT" "PHASE"}    

    lappend all_subframes $frame

    CreateLine line \
	message "Choose the hand determination program" \
	label "Hand determination:" \
	widget HAND_PROGS -width 18 \
	-command "add_premade_pipeline $arrayname" 

    CloseSubFrame

    CloseSubFrame

    OpenSubFrame frame -toggle_display PREMADE_START open { "DETECT" "PHASE" "HAND" "DM" }

    lappend all_subframes $frame

    OpenSubFrame frame -toggle_display PREMADE_END hide  { "DETECT" "PHASE" "HAND" }     

    lappend all_subframes $frame

    CreateLine line \
	message "Choose the density modification program" \
	label "Density modification:" \
	widget DM_PROGS -width 18 \
	-command "add_premade_pipeline $arrayname"

    CloseSubFrame

    CloseSubFrame

    OpenSubFrame frame -toggle_display PREMADE_END hide { "DETECT" "PHASE" "HAND" "DM" }

    lappend all_subframes $frame

    CreateLine line \
	message "Choose the automated model building program" \
	label "Model building:" \
	widget MODEL_PROGS -width 18 \
	-command "add_premade_pipeline $arrayname" 

    CloseSubFrame

    CreateLine line \
	label "Display individual program options " \
 	message "If desired, change and display individual program options " \
	widget DISPLAY_PIPELINE \
	-command "fix_scroll $arrayname ; SetSystemVar block_scroll_update 0 ; rungetstuff $arrayname 0"

    OpenSubFrame frame -toggle_display DISPLAY_PIPELINE open 1    

    lappend all_subframes $frame

     CreateLine line \
  	label "Next possible program :" \
  	message "Add the next program in the experiment" \
  	widget EXPERIMENTAL_PROGRAM -width 20 \
	button "Add Program" \
 	-command "add_program $arrayname" \
	message "Reset the current pipeline" \
	label "  " \
	button "Reset pipeline" \
	-command "clear_pipeline $arrayname; add_premade_pipeline $arrayname" 

     CreateLine line \
	label "Show all pipeline input columns" \
	message "Show all pipline input columns" \
	widget SHOW_ALL_PIPELINE_INPUT \
	-command "fix_scroll $arrayname"

    CreateToggleFrame N_PROGRAMS experiment_proc \
	"Define Experiment" \
	"Step \#" \
	"Add Program" \
	$programs_toggleframe_list \
	 -justify left \
 	message "Add the current program to the pipeline" \
 	button "Add Program" \
 	-command "add_program $arrayname"

    CloseSubFrame

    if { ($array(N_CRYSTALS) == 0) } {
	setup_experiment $arrayname
    }

    if { ($array(N_PROGRAMS) == 0) } {
	add_premade_pipeline $arrayname
    }
}
