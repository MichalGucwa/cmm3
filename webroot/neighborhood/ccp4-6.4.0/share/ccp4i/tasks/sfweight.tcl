# ======================================================================
# sfweight.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc sfweight_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable csigmaa]] } {
    return 0
  }
  return 1
}
#---------------------------------------------------------------------
proc sfweight_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Structure factor weighting (sigmaa)" "sfweight" \
	     [ list \
               "Options" \
              ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "csigmaa"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_sfweight"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN  "FP"    FP     [list FP FP.F_sigF.F] \
      -sigma "SIGFP" SIGFP  [list FP FP.F_sigF.sigF] \

  CreateLabinLine line \
      "Calculated amplitude (FCAL) and phase (PHICAL)" \
      HKLIN  "FCAL"   FC     [list FC   FCAL   FC.F_phi.F] \
      -sigma "PHICAL" PHIC   [list PHIC PHICAL FC.F_phi.phi] \

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "FreeR flag" FREE  [list FreeR_flag] \
      -toggle_display MODEFREE open 1

  CreateLine line \
      message "Optionally specify Free-R set" \
      help colin-free \
      label "Use Free-R flag" \
      widget MODEFREE

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

#-----------------------------------------------------

  OpenFolder 1 closed

  CreateLine line \
      message "Use more reflections per parameter when data is poor" \
      help num-reflns \
      widget MODENRFL -toggleon \
      label "Set number of reflections per spline parameter to" \
      widget VALUNRFL

}
