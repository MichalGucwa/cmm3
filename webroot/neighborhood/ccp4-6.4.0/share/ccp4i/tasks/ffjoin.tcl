#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# ffjoin.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------------
proc ffjoin_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

# Do checks and setup before running

#
# List of input files
  set array(INPUT_FILES) "XYZIN"
  if {[GetValue $arrayname FFJOIN_NFILES] == "2"} {
      append array(INPUT_FILES) " XYZIN1"
  } elseif {[GetValue $arrayname FFJOIN_NFILES] == "3"} {
      append array(INPUT_FILES) " XYZIN1 XYZIN2"
  }

    return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc ffjoin_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

# Menu for number of input files
  DefineMenu _ffjoin_nfiles [list "one" "two" "three"] \
	  [list 1 2 3]

# procedure must return sucess code (1) for drawing task window to continue
  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc ffjoin_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array


  if { [CreateTaskWindow $arrayname  \
        "Merge model fragments obtained from FFFeaR" "FFJoin" \
        [ list "Fragment Merging Parameters" \
	       "Fragment Removal"
	] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "ffjoin"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Select number of input files for input to ffjoin program" \
        label "Merge linked fragments from" \
        widget FFJOIN_NFILES \
	label "FFFeaR output files"

  CreateLine line \
        message "Remove fragments with lower confidence value, if overlapping fragments cannot be merged" \
	widget DELETE_CLASH \
	label "Delete clashing fragments with lower confidence values"


#=FILES================================================================ 

  OpenFolder file

  # Input PDB file
  CreateInputFileLine line \
        "Enter name of file containing fragments output by fffear (XYZIN)" \
	"Fragments in" \
	XYZIN DIR_XYZIN \
	-fileout XYZOUT DIR_XYZOUT "_ffjoin"

  # Addition PDB files
  CreateInputFileLine line \
        "Additional file with fffear fragments for merging (XYZIN1)" \
	"Addition input fragments" \
	XYZIN1 DIR_XYZIN1 \
	-toggle_display FFJOIN_NFILES open [list 2 3]

  CreateInputFileLine line \
        "Additional file with fffear fragments for merging (XYZIN2)" \
	"Addition input fragments" \
	XYZIN2 DIR_XYZIN2 \
	-toggle_display FFJOIN_NFILES open [list 3]

  # Output PDB file with merged fragments
  CreateOutputFileLine line \
	"Output file with merged fragments (XYZOUT)" \
	"Output merged fragments" \
	XYZOUT DIR_XYZOUT

#--------------------------------------------------JOIN folder
# This folder sets the parameters for joining the fragments

    OpenFolder 1
  
    CreateLine line \
	    help join \
	    message "Maximum separation of any pair of corresponding C-alpha atoms in a pair of fragments for merging (JOIN RADIUS)" \
	    label "Consider fragments to be mergable if the C-alpha separation is less than" \
	    widget JOIN_RADIUS \
	    label "A"

    CreateLine line \
	    message "Minimum number of overlapping C-alphas for fragments to be considered mergable (JOIN OVERLAP)" \
	    label "Try to merge fragments with at least" \
	    widget JOIN_OVERLAP \
	    label "overlapping C-alpha atoms"

    CreateLine line \
	    message "Don't attempt to merge fragments running in opposite directions (JOIN NOREVERSE)" \
	    widget JOIN_NOREVERSE \
	    label "Do not merge fragments running in opposite directions"

#--------------------------------------------------BUMP folder
# This folder sets the parameters for removing clashing fragments

    OpenFolder 2 DELETE_CLASH hide [list 0]

    CreateLine line \
	    help bump \
	    message "Maximum C-alpha separation for fragments which are considered as clashing (BUMP RADIUS)" \
	    label "Consider fragments to be clashing if the C-alpha separation is less than" \
	    widget BUMP_RADIUS \
	    label "A after all other merging"
}
