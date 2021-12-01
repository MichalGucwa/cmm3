# ======================================================================
# pattcalc.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc pattcalc_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cpatterson]] } {
    return 0
  }
  return 1
}
#------------------------------------------------------------------------
proc pattcalc_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  return 1
}

#---------------------------------------------------------------------
proc pattcalc_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Patterson calculation" "pattcalc" \
	     [ list \
	       "Map properties" \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cpatterson"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout MAPOUT DIR_MAPOUT "_patterson"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN  "FP"    FP     [list FP FP.F_sigF.F] \
      -sigma "SIGFP" SIGFP  [list FP FP.F_sigF.sigF] \

  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT

#-----------------------------------------------------

  OpenFolder 1 closed

  CreateLine line \
      message "Truncate resolution" \
      help resolution \
      widget RESOLUTION -toggleon \
      label "Truncate resolution to" \
      widget RESOLUTION_MAX \
      label "Angstroms"


  CreateLine line \
      message "Override default grid spacing" \
      help grid \
      widget GRID -toggleon \
      label "Define grid sampling  nx=" \
      widget GRID_1 \
      label " ny= " \
      widget GRID_2 \
      label " nz= " \
      widget GRID_3

#-----------------------------------------------------

  OpenFolder 2 closed

  CreateLine line \
      message "Exclude reflections by |E| value" \
      help e-limit \
      widget MODEEFILTER -toggleon \
      label "Exclude reflections with E > " \
      widget VALUEFILTER

  CreateLine line \
      message "|E|squared and |E||F| Pattersons" \
      help e-weight \
      widget MODEEWEIGHT -toggleon \
      label "Sharpened Patterson with" \
      widget VALUEWEIGHT \
      label "proportion of |E|. " \
      label "1.0 for |E|squared, 0.5 for |E||F|" -italic

  CreateLine line \
      message "Perform origin removal" \
      help origin-removal \
      label "Origin removed Patterson" \
      widget MODEORIGREM

}

