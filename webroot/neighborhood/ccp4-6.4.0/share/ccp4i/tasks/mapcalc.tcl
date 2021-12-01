# ======================================================================
# mapcalc.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc mapcalc_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cfft]] } {
    return 0
  }
  return 1
}
#------------------------------------------------------------------------
proc mapcalc_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_mapcalc_coeff) { menu { "map coefficients (F/phi)" \
				       "HL coefficients (ABCD)" } \
				    { MAPCOEFF HLCOEFF } }
  return 1
}

#---------------------------------------------------------------------
proc mapcalc_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Map calculation and evaluation" "mapcalc" \
	     [ list \
	       "Map properties" \
	       "Statistics" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cfft"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line  \
        message "Chose the type of input reflection data to use."  \
        label "Calculate electron density map from" \
        widget MODECOEFF

  CreateLine line \
      message "Genarate an output electron density map." \
      help mapout \
      label "Calculate electron density map:" \
      widget MODEMAP -width 4 \
      message "Calculate electron density statistics." \
      help stats \
      label "Calculate electron density statistics:" \
      widget MODESTAT -width 4

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout MAPOUT DIR_MAPOUT "_fft"

  CreateLabinLine line \
      "Choose F/phi" \
      HKLIN    "F"   FMAP    [list pirate.F_phi.F   FWT] \
      -sigma   "PHI" PHIMAP  [list pirate.F_phi.phi PHWT] \
      -toggle_display MODECOEFF open MAPCOEFF

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN  "FP"    FP     [list FP FP.F_sigF.F] \
      -sigma "SIGFP" SIGFP  [list FP FP.F_sigF.sigF] \
      -toggle_display MODECOEFF open HLCOEFF

  CreateLabinLine line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN  "HLA" HLA  [list HLA FP.ABCD.A] \
      -sigma "HLB" HLB  [list HLB FP.ABCD.B] \
      -toggle_display MODECOEFF open HLCOEFF

  CreateLabinLine line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN  "HLC" HLC  [list HLC FP.ABCD.C] \
      -sigma "HLD" HLD  [list HLD FP.ABCD.D] \
      -toggle_display MODECOEFF open HLCOEFF

  OpenSubFrame frame \
      -toggle_display MODEMAP open 1

  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT

  CloseSubFrame

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
      message "Radius for local density statistics" \
      help stats-radius \
      label "Radius for local density stats:" \
      widget RADIUS \
      label " in Angstroms. Default = 4 A" -italic

}

