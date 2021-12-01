# ======================================================================
# ecalculate.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc ecalculate_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cecalc ]] } {
    return 0
  }
  return 1
}
#---------------------------------------------------------------------
proc ecalculate_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Calculate E's from F's" "ecalculate" \
	     [ list \
              ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cecalc"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_ecalculate"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN  "FP"    FP     [list FP FP.F_sigF.F] \
      -sigma "SIGFP" SIGFP  [list FP FP.F_sigF.sigF]

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

}
