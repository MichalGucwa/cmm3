# ======================================================================
# compositeomit.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc compositeomit_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable comit]] } {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
proc compositeomit_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Calculate composite omit map" "compositeomit" \
	     [list "Options"] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "comit"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_omit"

  CreateLabinLine line \
      "Choose F/sigF obs: Observed structure factors" \
      HKLIN    "FP"    FP     [list FP    ] \
      -sigma   "SIGFP" SIGFP  [list SIGFP ]

  CreateLabinLine line \
      "Choose F/phi calc: Input Fcalc map coefficients, e.g. from refmac FC_ALL, PHIC_ALL" \
      HKLIN    "FC"    FC     [list FC_ALL   ] \
      -sigma   "PHIC"  PHIC   [list PHIC_ALL ]

  CreateOutputFileLine line \
      "Output MTZ File" \
      "Work MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

#=Options================================================================

  OpenFolder 1

  CreateLine line \
        message "Number of omit regions" \
        help nomit \
        label "Number of omit regions" \
        widget NOMIT -width 4
}

