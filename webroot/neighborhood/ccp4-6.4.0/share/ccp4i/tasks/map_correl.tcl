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
# map_correl.tcl --
#
# Run sfall and overlapmap
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc map_correl_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef

  set typedef(_correlate_mode) { menu { section atom residue } }

  set typedef(_sfall_input_mode1) { menu { "from a map file"
					"calculated from input MTZ"  }
					{ MAP HKL } }

  set typedef(_sfall_input_mode2) { menu { "from a map file"
                                        "calculated from input MTZ" 
                                        "calculated from input coordinates" }
                                        { MAP HKL COORDS } }

  set typedef(_correlate_bfactors) { menu { "Add increment to"
                                        "Reset all" }
                                        { BADD BRESET } }

  return 1
}
#-----------------------------------------------------------------------
proc map_correl_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) {}
  if { $array(INPUT_MTZ) } { append array(INPUT_FILES) " HKLIN" }
  if { $array(INPUT_COORDS) } { append array(INPUT_FILES) " XYZIN" }
  if { [regexp MAP $array(INPUT_MODE_1) ] } { append array(INPUT_FILES) " MAPIN_1" }
  if { [regexp MAP $array(INPUT_MODE_2) ] } { append array(INPUT_FILES) " MAPIN_2" }

  return 1
}

#-----------------------------------------------------------------------
proc MapCorrelChains { arrayname counter } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    message "Chain name and the residue ids of first and last residue  (CHAIN)" \
    help chain \
    label "Chain name" \
    widget CHAIN_NAME \
    label "first residue id" \
    widget CHAIN_RES1 \
    label "last residue" \
    widget CHAIN_RES2

  return 1
}

#------------------------------------------------------------------------
proc map_correl_input_coords {arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

# Set flags INPUT_COORDS and INPUT_MTZ which determine whether the
# input file lines for coords and mtz file are displayed 

  if { [regexp COORDS [GetValue $arrayname INPUT_MODE_1]] ||
       [regexp COORDS [GetValue $arrayname INPUT_MODE_2]] ||
       ![regexp section [GetValue $arrayname CORRELATE_MODE]]  ||
       $array(IF_REAL_SPACE) } {
     set array(INPUT_COORDS) 1
  } else {
     set array(INPUT_COORDS) 0
  }

    if { [regexp HKL [GetValue $arrayname INPUT_MODE_1]] ||
       [regexp HKL [GetValue $arrayname INPUT_MODE_2]]  } { 
      set array(INPUT_MTZ) 1
    } else {
      set array(INPUT_MTZ) 0
    }
}

#------------------------------------------------------------------------
proc map_correl_getchains { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [PdbGetChains [GetFullFileName0 $arrayname XYZIN] chain chain_range ]  } {
    set increment [expr [llength $chain] - $array(NCHAINS) ]
    update_extendingframe MapCorrelChains 0 $arrayname NCHAINS \
                $array(NCHAINS) $increment 1
    for { set i 1 } { $i <= $array(NCHAINS) } { incr i } {
      set ii [expr $i -1]
      set array(CHAIN_NAME,$i) [lindex $chain $ii]
      set array(CHAIN_RES1,$i) [lindex [lindex $chain_range $ii] 0]
      set array(CHAIN_RES2,$i) [lindex [lindex $chain_range $ii] 1]
    }
  }
}


#-----------------------------------------------------------------------
proc map_correl_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Map Correlation" "Correlation" \
        [ list "Cell Parameters" \
	"Protein Chains" \
	"Reset Atomic Radii and Bfactors" ] ] == 0 } return

  SetProgramHelpFile overlapmap

  source  [SearchPath TOP utils pdb_utils.tcl]

  map_correl_input_coords $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "List correlation for map sections or by structure atom/resue" \
    label "List a correlation by" \
    help correlate \
    widget CORRELATE_MODE \
	-command "map_correl_input_coords $arrayname"


  CreateLine line \
    message "Calculate a Real Space R factor a la Branden/Jones" \
    help real_space_r \
    widget IF_REAL_SPACE \
    label "List a 'real space R-factor'" \


#=FILES================================================================

  OpenFolder file 


  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam resolution_min RESOLUTION_MIN \
        -setfileparam resolution_max RESOLUTION_MAX \
	-setfileparam cell CELL

  CreateInputFileLine line \
      "Enter PDB file name (XYZIN)" \
      "Coordinates" \
      XYZIN DIR_XYZIN \
	-command "map_correl_getchains $arrayname" \
	-toggle_display INPUT_COORDS open 1

  CreateLine line \
    label "First map" \
    widget INPUT_MODE_1 \
	-command "map_correl_input_coords $arrayname"

  CreateInputFileLine line \
      "Enter first input map (MAPIN1)" \
	"Map 1" \
	MAPIN_1 DIR_MAPIN_1 \
	-toggle_display INPUT_MODE_1 open MAP
     

  OpenSubFrame frame -toggle_display INPUT_MODE_1 open HKL

  CreateLabinLine line \
    "Choose amplitude (F1) and optional sigma (SIG1)" \
     HKLIN F1 F1  {} \
     -sigma Sigma SIGF1  {} 

  CreateLabinLine line \
    "Choose phase (PHI) and optional weighting factor (W)" \
     HKLIN PHI PHI1  {} \
     -sigma Weight W1  {}

  CloseSubFrame


    CreateLine line \
    label "Second map" \
    widget INPUT_MODE_2 \
	-command "map_correl_input_coords $arrayname"

  CreateInputFileLine line \
      "Enter second input map (MAPIN2)" \
        "Map 2" \
        MAPIN_2 DIR_MAPIN_2 \
        -toggle_display INPUT_MODE_2 open MAP


  OpenSubFrame frame -toggle_display INPUT_MODE_2 open HKL

  CreateLabinLine line \
    "Choose amplitude (F2) and optional sigma (SIG2)" \
     HKLIN F2 F2  {} \
     -sigma Sigma SIGF2  {}

  CreateLabinLine line \
    "Choose second phase (PHI2) and optional weighting factor (W2)" \
     HKLIN "PHI2  " PHI2  {} \
     -sigma "Weight " W2  {}

  CloseSubFrame


#=PARAMETERS==========================================================


  OpenFolder 1

  SetProgramHelpFile sfall

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    label "Resolution less than" \
    widget RESOLUTION_MIN  -oblig \
    label "A or greater than" \
    widget RESOLUTION_MAX  -oblig \
    label "A"

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    widget SPACE_GROUP -oblig

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    widget IFCELL \
        -toggleon \
    label "Set cell a" \
    widget CELL_1 -width 8 -oblig \
    label "b" \
    widget CELL_2 -width 8 -oblig \
    label "c" \
    widget CELL_3 -width 8 -oblig \
    label "alpha" \
    widget CELL_4 -width 8 -oblig \
    label "beta" \
    widget CELL_5 -width 8 -oblig \
    label "gamma" \
    widget CELL_6 -width 8 -oblig


  CreateLine line \
    message "Override default grid spacing" \
    help grid \
    label "Grid spacing x= " \
    widget GRID_1 \
    label " y= " \
    widget GRID_2 \
    label " z= " \
    widget GRID_3

  OpenFolder 2
  
  CreateLine line \
    label "List correlations for residue ranges.." -italic

  CreateExtendingFrame NCHAINS MapCorrelChains \
        "Add/remove line to define extra protein chain" \
        "Add chain" \
        [ list CHAIN_NAME \
		CHAIN_RES1 \
		CHAIN_RES2 ]
  

  OpenFolder 3 CORRELATE_MODE hide section closed

  SetProgramHelpFile sfall

  CreateLine line \
    message "Resolution dependent (Sfall VDWR)" \
    label "Maximum atomic radius used to build atom/residue mask" \
    help vdwr \
    widget SFALL_VDWR 

  CreateLine line \
    message "Edit B factors in output coordinate file" \
    widget CORRELATE_BFAC \
    label "B factors"

  CreateLine line \
    message "Add smearing factor (NOT recommended) (Sfall BADD)" \
    label "Add smearing factor" \
    help badd \
    widget SFALL_BADD \
    label "to atomic Bfactors" \
    toggle_display CORRELATE_BFAC open [list BADD]

  SetProgramHelpFile pdbset

  CreateLine line \
    message "Set all B factors to specified value (Pdbset BFACTOR)" \
    help bfactor \
    label "Set all atomic Bfactors to" \
    widget PDBSET_BFACTOR \
    toggle_display CORRELATE_BFAC open [list BRESET]

}
