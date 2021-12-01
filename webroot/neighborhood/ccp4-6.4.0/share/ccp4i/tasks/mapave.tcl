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
# mapave.tcl --
#
# Run maprot to generate averaged map
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc mapave_ncs_operators { arrayname counter } {
#-----------------------------------------------------------------------

   CreateLine ops_frame \
        message "Enter Averaging Operator (ROTA EULER & TRAN)" \
        label "alpha" \
        widget NCS_OP_ALPHA \
        label "beta" \
        widget NCS_OP_BETA \
        label "gamma" \
        widget NCS_OP_GAMMA \
        label "xtran" \
        widget NCS_OP_XTRAN \
        label "ytran" \
        widget NCS_OP_YTRAN \
        label "ztran" \
        widget NCS_OP_ZTRAN
}


#-----------------------------------------------------------------------
proc  mapave_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------

  DefineMenu _mapave_mode [list "Averaged density within mask" \
				"Averaged density for whole unit cell" \
				"Correlation map" \
				"Correlation map and mask" ] \
			[ list GRAPHICS \
				AVERAGED \
				CORRELATION \
				CORRELATION_MASK ]

  DefineMenu _mapave_input [ list "map which covers unit cell" \
				  "map which covers asymmetric unit" \
				  "MTZ file" ] \
			   [ list CELL_MAP ASYM_MAP MTZ ]

  return 1

}

#-----------------------------------------------------------------------
proc mapave_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(SCALE) ""
  set array(MAPROT_MODE) FROM

  set input [GetValue $arrayname MAPAVE_INPUT]
  set mode [GetValue $arrayname MAPAVE_MODE]


  set array(OUTPUT_FILES) "MAPOUT"
  if [StringSame $mode GRAPHICS AVERAGED ] {
     if [StringSame $input MTZ ] {
       set array(INPUT_FILES) "HKLIN MSKIN"
     } else {
       set array(INPUT_FILES) "MAPIN MSKIN"
     }
     if [StringSame $mode AVERAGED ] {
       set array(MAPROT_MODE) BOTH
       set array(SCALE) [expr 1.0 / double($array(NCS_NOPS)) ]
     }
  } elseif [StringSame $mode CORRELATION CORRELATION_MASK ] {
     set array(MAPROT_MODE) CORR
     if [StringSame $input MTZ ] {
       set array(INPUT_FILES) "HKLIN"
     } else {
       set array(INPUT_FILES) "MAPIN"
     }
     if [StringSame $mode CORRELATION_MASK ] {
       append array(OUTPUT_FILES) " MSKOUT"

       set nops [GetSpaceGroupNops  $array(SPACE_GROUP)]
       if { $nops <= 0 } {
        WarningMessage "Space group not recognised. 
Can not calculate mask volume.
Aborting running map averaging."
         return 0
       }
       if { $array(N_COVERED_MOLS) == {} ||
            $array(NNCS) == {} } {
         WarningMessage "You have not entered either the number of molecules to be found 
or the number of molecules in the asymmetric unit.
Aborting running map averaging."
          return 0
     }
       set array(VOLUME) [expr $array(N_COVERED_MOLS) * \
  	( 1.0 - $array(FRAC_SOLVENT) ) / \
	( $array(NNCS) * $nops ) ]
#     puts "VOLUME $array(VOLUME)"
    }
  }
  return 1
}

#-----------------------------------------------------------------------
proc mapave_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Map Averaging" "Map Averaging" \
        [ list "NCS Operators" \
		"Correlation Map Parameters" \
		"Correlation Mask Parameters" \
		"Map Parameters" ] ] == 0 } return

  SetProgramHelpFile maprot

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Specify type of input data available" \
    label "Input from" \
    widget MAPAVE_INPUT

  CreateLine line \
    message "Use mapmask to perform which function" \
    help keywords \
    label "Create" \
    widget MAPAVE_MODE


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input map file name (MAPIN)" \
      "Map in" \
       MAPIN DIR_MAPIN \
       -setfileparam space_group_number SPACE_GROUP \
       -fileout MAPOUT DIR_MAPOUT _ave \
       -fileout MSKOUT DIR_MSKOUT _ave \
       -toggle_display MAPAVE_INPUT hide MTZ open

  OpenSubFrame frame -toggle_display MAPAVE_INPUT open MTZ hide

   CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MAPOUT DIR_MAPOUT _ave \
       -setfileparam space_group_number SPACE_GROUP \
       -setfileparam cell CELL

  CreateLabinLine line \
    "Choose amplitude (F1) and optional sigma (SIG1)" \
     HKLIN "F1    " F1  {} \
     -sigma "Sigma  " SIG1  {}

  CreateLabinLine line \
    "Choose phase (PHI) and optional weighting factor (W)" \
     HKLIN "PHI   " PHI  {} \
     -sigma "Weight " W  {}

  CloseSubFrame

  CreateInputFileLine line \
      "Enter input mask file name (MSKIN)" \
      "Mask in" \
       MSKIN DIR_MSKIN \
       -setfileparam space_group_number SPACE_GROUP \
       -setfileparam cell CELL \
       -setfileparam grid GRID \
	-toggle_display MAPAVE_MODE open [list GRAPHICS AVERAGED ]

  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT

  CreateOutputFileLine line \
      "Enter mask file name or click file browser icon (MSKOUT)" \
      "Mask out" \
      MSKOUT DIR_MSKOUT \
	 -toggle_display MAPAVE_MODE open [list CORRELATION_MASK ]

#------------------------------------------------------------NCS operators

  OpenFolder 1 

  CreateExtendingFrame NCS_NOPS mapave_ncs_operators \
        "Add/remove line to define extra averaging operator" \
        "Add operator" \
        [ list NCS_OP_CONVENTION \
        NCS_OP_ALPHA \
        NCS_OP_BETA \
        NCS_OP_GAMMA \
        NCS_OP_XTRAN \
        NCS_OP_YTRAN \
        NCS_OP_ZTRAN ]

#---------------------------------------------------------map parameters
  OpenFolder 4 MAPAVE_MODE closed


  CreateLine line \
    message "Cell dimensions (default from map file) (CELL)" \
    help "cell" \
    label "Set cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8

  CreateLine line \
    message "Set grid values (GRID)" \
    help grid \
    widget IFGRID \
    label "Set grid x=" \
    widget GRID_1 \
    label "y=" \
    widget GRID_2 \
    label "z=" \
    widget GRID_3

#---------------------------------------------------------correlation parameters
  OpenFolder 2 MAPAVE_MODE open [list CORRELATION CORRELATION_MASK ] hide

  CreateLine line \
    message "Space group for Maprot working map (maprot SYMMETRY)" \
    label "Space group" \
    widget SPACE_GROUP -oblig

  CreateLine line \
    message "Default 8.0, increase if mask has many spurious peaks (RADIUS)" \
    help radius \
    label "Radius of correlation" \
    widget RADIUS -oblig \
    label "Angstrom"

  CreateLine line \
    message "Correlation map limits set by user (XYZLIM)" \
    help xyzlim \
    label "Correlation map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2 \
    label "y"  \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"  \
    widget XYZLIM_5  \
    widget XYZLIM_6

#----------------------------------------------------------------------correlation mask

  OpenFolder 3 MAPAVE_MODE open CORRELATION_MASK  hide

  SetProgramHelpFile mapmask

  CreateLine line \
    label "Number of molecules in the asymmetric  unit" \
    widget NNCS -oblig \
    message "Parameters to decide cutoff for mask (mapmask VOLUME)" \
    help mask_volume \
    label "Create mask to cover" \
    widget N_COVERED_MOLS -oblig \
    label "molecules"

  CreateLine line \
    message "Fraction solvent content of unit cell" \
    label "Fraction solvent content" \
    widget FRAC_SOLVENT -oblig


  SetProgramHelpFile ncsmask

  CreateLine line \
    message "Cleanup mask (ncsmask PEAK)" \
    help peak \
    widget IFPEAK \
	-toggleon \
    label "Cleanup mask to have" \
    widget PEAK \
    label "contiguous regions"

}

