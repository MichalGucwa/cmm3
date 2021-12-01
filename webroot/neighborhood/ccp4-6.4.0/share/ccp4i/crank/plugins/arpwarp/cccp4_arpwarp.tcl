# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University 
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University 

# All rights reserved.
#
# This file may not be copied, reproduced, modified or distributed 
# in any way.
#

proc arpwarp_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(ARPWARP_PHASE_RESTRAIN,$counter) w "update_main_scroll $subframe"
	trace vdelete array(ARPWARP_EXCLUDE_FREER,$counter) w "update_main_scroll $subframe"
	trace vdelete array(DOCK_SEQUENCE) w "update_main_scroll $subframe"
	trace vdelete array(INPUT_PDB,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "ARP/wARP and REFMAC will be used for model building with iterative refinement"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1
	
    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 25

    CreateLine line \
	label "Input Phase Columns" \
	widget INPUT_PHASE_COLUMNS -width 25

    OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide [list ""]

    CreateLine line \
	label "Input Pdb" \
	widget INPUT_PDB -width 55
	 
    CloseSubFrame

    OpenSubFrame frame -toggle_display ARPWARP_PHASE_RESTRAIN,$counter open DIRECT

    CreateLine line \
	  label "Input Substructure" \
	  widget INPUT_SUBSTRUCTURE -width 25

    CloseSubFrame

    OpenSubFrame frame -toggle_display ARPWARP_PHASE_RESTRAIN,$counter open MLHL
    
    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 25

    CloseSubFrame

    OpenSubFrame frame -toggle_display ARPWARP_EXCLUDE_FREER,$counter open Y

    CreateLine line \
	label "Input FREER Column" \
	widget INPUT_FREER_COLUMNS -width 25

    CloseSubFrame

    CloseSubFrame

     ##############################
    # Global ARP/wARP parameters #
    ##############################

    OpenSubFrame frame -toggle_display DOCK_SEQUENCE open 1
    CreateLine line \
	label "Dock the autotraced chains to sequence after " \
	message "Only do the sequence docking after this number of autobuilding cycles"\
	widget ARPWARP_SIDE_AFTER \
	-width 2 \
	label " autobuilding cycles."
    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide [list "" ]

    CreateLine line \
	message "Don't use previously created Pdb model " \
	label "Don't use input pdb: " \
 	widget ARPWARP_NOUSEPDB

    CloseSubFrame

    ##############################
    #    Required parameters     #
    ##############################

    CreateLine line \
	label "Use version 6 main chain tracing algorithm " \
	message "Use version 6 main chain tracing algorithm"\
	widget ARPWARP_USE_SIX

    CreateLine line   \
	label "Do" \
	message "The number of autobuilding cycles that will be performed (BIG_CYCLES)" \
	widget ARPWARP_BIG_CYCLES \
	label "cycles of autobuilding with " \
	message "Cycles within autobuilding (SMALL_CYCLES), TOTAL_CYCLES = BIG_CYCLES * SMALL_CYCLES" \
	widget ARPWARP_SMALL_CYCLES \
	 label "ARP/REFMAC cycles within an autobuilding cycle"

    CreateLine line \
	message "Use Free R reflection in refmac?" \
	label "For REFMAC5 " \
	widget ARPWARP_EXCLUDE_FREER \
	label "the Free R flag."

    ##############################
    #  ARP/wARP flow parameters  #
    ##############################


    ##############################
    #      Refmac Parameters     #
    ##############################

    CreateLine line \
	message "Number of cycles of refinement for each internal Refmac run" \
	widget ARPWARP_NCYCLES \
	-width 2 \
	label "cycles of refinement in each Refmac run."

    CreateLine line \
	message "Choose if phase restraints will be used." \
	label "Include "\
	widget ARPWARP_PHASE_RESTRAIN -width 15 \
	label "phase restraints"\

    OpenSubFrame frame -toggle_display ARPWARP_PHASE_RESTRAIN,$counter open MLHL

    CreateLine line \
        label "Apply a blurring factor of" \
	message "A blurring factor can downweight phase probability statistics."\
        widget ARPWARP_PHASE_BLUR
    
    CloseSubFrame

    CreateLine line \
	message "Damp shifts (for limited data or unrestrained refinement) (DAMP)" \
	label "Damp shifts using Pdamp" \
	widget ARPWARP_DAMP_P \
	label "and Bdamp" \
	widget ARPWARP_DAMP_B

    CreateLine line \
	message "Manual or automatic weighting for Xray/geometry terms" \
	widget ARPWARP_WEIGHT_MODE \
	label "matrix weighting for Xray / Geometry " 

    CreateLine line \
	message "The relative matrix weight for xray versus geometrical terms ?" \
	label "Matrix weight for Xray / Geometry " \
	widget ARPWARP_WMAT \
	toggle_display ARPWARP_WEIGHT_MODE,$counter hide AUTO

    CreateLine line \
	message "Tronrud-like scaling (BULK) or a simple scaling factor"\
	label "Use for scaling the "\
	widget ARPWARP_SCALE \
	label "scaling model, with an "\
	message "Use anisotropic scaling factors or isotropic ones"\
	widget ARPWARP_SCANIS \
	label "scaling B factor."

    CreateLine line \
	label "Scaling and sigmaa calculation will be done with the" \
	message "Determines if Rfree reflections will be used in scaling and sigmaa calculations" \
	widget ARPWARP_REFMAC_REF_SET \
	label "set of reflections   "

    CreateLine line \
        message "A Solvent Mask Correction can be used at final refinement stages"\
        widget ARPWARP_SOLVENT \
        label "Solvent Mask correction"

   CreateLine line \
        message "Determines if TLS refinement will be used" \
        widget ARPWARP_TLSONOFF \
        label "Do TLS refinement."

	# Set basic defaults

	if { $array(ARPWARP_BIG_CYCLES,$counter) == "" } {
		set array(ARPWARP_BIG_CYCLES,$counter) 10
	}

	if { $array(ARPWARP_SMALL_CYCLES,$counter) == "" } {
		set array(ARPWARP_SMALL_CYCLES,$counter) 5
	}

	if { $array(ARPWARP_NCYCLES,$counter) == "" } {
		set array(ARPWARP_NCYCLES,$counter) 3
	}

	if { $array(ARPWARP_DAMP_P,$counter) == "" } {
		set array(ARPWARP_DAMP_P,$counter) 0.99
	}

	if { $array(ARPWARP_DAMP_B,$counter) == "" } {
		set array(ARPWARP_DAMP_B,$counter) 0.99
	}

	if { $array(ARPWARP_PHASE_BLUR,$counter) == "" } {
		set array(ARPWARP_PHASE_BLUR,$counter) 1.0
	}

	if { $array(ARPWARP_SIDE_AFTER,$counter) == "" } {
		set array(ARPWARP_SIDE_AFTER,$counter) 7
	}

        if { $array(ARPWARP_WEIGHT_MODE,$counter) == "" } {
		set array(ARPWARP_WEIGHT_MODE,$counter) Automatic
	}

        if { $array(ARPWARP_SCALE,$counter) == "" } {
		set array(ARPWARP_SCALE,$counter) BULK
	}

        if { $array(ARPWARP_SCANIS,$counter) == "" } {
		set array(ARPWARP_SCANIS,$counter) anisotropic
	}

}

proc arpwarp_plugin_update { arrayname counter } {
    upvar #0 $arrayname array

}


proc arpwarp_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "ARPWARP_PHASE_RESTRAIN" \
	"ARPWARP_EXCLUDE_FREER" \
	"ARPWARP_SCALE" \
	"ARPWARP_SCANIS" \
	"ARPWARP_REFMAC_REF_SET" \
	"ARPWARP_WEIGHT_MODE"

    DefineMenu _arpwarp_phase_restrain [list "NO" \
	 				    "MLHL" \
					    "DIRECT" ] \
	[list NO MLHL DIRECT]

    DefineMenu _arpwarp_exclude_freer [list "do not use" "use"] \
	[list N Y]
	
    DefineMenu _arpwarp_scale [list "BULK" "SIMPLE"] \
	[list BULK SIMPLE]

    DefineMenu _arpwarp_scanis [list "isotropic" "anisotropic"] \
	[list N Y]

    DefineMenu _arpwarp_refmac_ref_set [list "working" \
	 				    "free"] \
	[list N Y]

    # New
    DefineMenu _arpwarp_weight_mode [list "Automatic" \
	 				 "Manual"] \
	[list AUTO MANUAL]
}	
