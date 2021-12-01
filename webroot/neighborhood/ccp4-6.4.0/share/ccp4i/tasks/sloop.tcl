# ======================================================================
# sloop.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc sloop_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable csloop]] } {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
proc sloop_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Loop building using Sloop" "Sloop" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "csloop"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input coordinate file name for loop building" \
      "PDB in" \
      XYZIN DIR_XYZIN \
      -fileout XYZOUT DIR_XYZOUT "_sloop"
 
  CreateInputFileLine line \
      "Enter input reflection file name for loop building" \
      "MTZ in" \
      HKLIN DIR_HKLIN

  CreateLabinLine line \
      "Choose F/phi" \
      HKLIN        "F"   FMAP    [list FWT ] \
      -dependent   "PHI" PHIMAP  [list PHWT]

  CreateOutputFileLine line \
      "Enter output pdb file name" \
      "PDB out" \
      XYZOUT DIR_XYZOUT

#-----------------------------------------------------

  OpenFolder 1 closed

  CreateLine line \
      message "Using data beyond 1.75A is slow and seldom helps." \
      help resolution \
      label "Maximum data resolution to use in map calculation:" \
      widget RESOLUTION_MAX -width 4

  CreateLine line \
      message "Clash radius to prevent overlap with existing main chain." \
      help clash-radius \
      label "Clash radius:" \
      widget CLASH_RAD -width 4

  CreateLine line \
      message "Clash penalty to prevent overlap with existing main chain." \
      help clash-penalty \
      label "Clash penalty:" \
      widget CLASH_SCR -width 4
}
