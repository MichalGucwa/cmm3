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
# shelx.tcl --
#
# Run shelx program for direct methods or patterson search
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc shelx_prereq { } {
#------------------------------------------------------------------------------
  global configure
  if { ![file exists [FindExecutable "$configure(SHELX)"]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------------
proc shelx_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $typedefVar typedef

  set typedef(_shelx_mode) { menu { "Patterson search" "direct methods" }
				{ PATTERSON DIRECT } }
  set typedef(_shelx_input_format)     { menu { "MTZ file" "Shelx hkl file" }
						{ MTZ SHELX } }

  set typedef(_shelx_hklf)	{ menu { "normalised amplitudes" intensities } { 3 4 } }

  set typedef(_shelx_lattice) { menu { primitive "body centred" "face centred" \
				"A-face centred" "B-face centred" "C-face centred" } 
			{ -1 -2 -4 -5 -6 -7 } }

  set typedef(_shelx_data_type) { menu { isomorphous anomalous } }

  return 1

}


#------------------------------------------------------------------------------
proc  shelx_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  if { [ regexp MTZ [GetValue $arrayname INPUT_FORMAT ]] } {
    set array(INPUT_FILES) MTZIN
    set array(LABIN) "FP SIGFP"
    if { [regexp isomorphous [GetValue $arrayname DATA_TYPE] ] } {
      append array(LABIN) " FPH SIGFPH" 
    } else {
      append array(LABIN) " DP SIGDP"
    }
  } else {
    set array(INPUT_FILES) HKLIN 
  }

  set array(SFAC_LIST) "N $array(HEAVY_TYPE)"
  set array(UNIT_LIST) "200 $array(NHEAVY)"
#  for { set n 1 } { $n <= $array(N_SFAC) } { incr n } {
#    append array(SFAC_LIST) $array(SFAC,$n) " "
#    append array(UNIT_LIST) $array(UNIT,$n) " "
#  }

  if { [ElementExists configure SHELX] && $configure(SHELX) != "" } {
    set array(SHLEX_PROGRAM) $configure(SHELX)
  }

  return 1
}

#-----------------------------------------------------------------------
proc ShelxSfac { arrayname counter } {
#-----------------------------------------------------------------------

  CreateLine line \
    label "Element" \
    widget SFAC \
    label "Number of atoms" \
    widget UNIT

}

#-----------------------------------------------------------------------
proc ShelxVect { arrayname counter } {
#-----------------------------------------------------------------------

  CreateLine line \
    label "Vector   x" \
    widget VECT_X \
    label "   y" \
    widget VECT_Y \
    label "   z" \
    widget VECT_Z
}

#----------------------------------------------------------------------
proc shelx_set_lattice { arrayname } {
#----------------------------------------------------------------------
   upvar #0 $arrayname array

   SetValue $arrayname LATTICE \
	[GetLatticeFromSpaceGp $array(SPACE_GROUP) -shelx ]
}

#-----------------------------------------------------------------------
proc shelx_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Shelx - Heavy Atom Search" "Shelx" \
	[ list "Cell Parameters" \
	"Exclude Reflections" \
	"Shelx Patterson Search Parameters" \
	"Shelx Direct Methods Parameters" ] ] == 0 } return

  SetProgramHelpFile "shelx"


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    label "NOTE This task uses the Shelx program which is not distributed with CCP4 - click Help for details" -italics


  CreateTitleLine line TITLE

  CreateLine line \
     label "Try to find heavy atoms by" \
     widget SHELX_MODE

  CreateLine line \
     label "Input format is" \
     widget INPUT_FORMAT \
     label "using" \
     widget DATA_TYPE \
     label data \
    toggle_display INPUT_FORMAT open MTZ

  CreateLine line \
    label "Input format is" \
    widget INPUT_FORMAT \
    label "data is" \
    widget SHELX_HKLF \
    toggle_display INPUT_FORMAT open SHELX


#=FILES================================================================

  OpenFolder file 

  OpenSubFrame frame -toggle_display INPUT_FORMAT open SHELX 

  CreateInputFileLine line \
      "Enter input HKL file name (HKLIN)" \
      "HKL in" \
       HKLIN DIR_HKLIN

  CreateLine line \
    label "Optionally extract cell parameters from MTZ file.."  -italic

  CloseSubFrame


  CreateInputFileLine line \
      "Enter input MTZ file name (MTZIN)" \
      "MTZ in" \
       MTZIN DIR_MTZIN \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam cell CELL \
        -setfileparam space_group_name SPACE_GROUP \
        -command "shelx_set_lattice $arrayname"

  OpenSubFrame frame -toggle_display INPUT_FORMAT open MTZ 

  CreateLabinLine line \
    "Protein experimental amplitude (FP) and optional sigma (SIGFP)" \
     MTZIN FP FP  [list F FP] \
     -sigma Sigma SIGFP  {}

  CreateLabinLine line \
    "Derivative experimental amplitude (FPH) and optional sigma (SIGFPH)" \
     MTZIN FPH FPH [list FPH] \
     -sigma SigmaPH SIGFPH  {} \
     -toggle_display DATA_TYPE open isomorphous

  CreateLabinLine line \
    "Anomalous data (DP SIGDP)" \
    MTZIN DP DP [list DP] \
    -sigma SIGDP SIGDP [list SIGDP] \
    -toggle_display DATA_TYPE open anomalous

  CloseSubFrame

#--------------------------------------------------------------------

  OpenFolder 1

  SetProgramHelpFile shelx

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Space group" \
    help symmetry \
    widget SPACE_GROUP -oblig -command "shelx_set_lattice $arrayname" \
    label "and lattice type" \
    help lattice \
    widget LATTICE -oblig \
    label "   Wavelength" \
    widget CELL_LAMBDA -oblig

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help cell \
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
    message "Estimates standard deviations on cell dimensions (ZERR)" \
    label "Cell ESDs a" \
    widget CELL_ERR_1 -width 8 -oblig \
    label "b" \
    widget CELL_ERR_2 -width 8 -oblig \
    label "c" \
    widget CELL_ERR_3 -width 8 -oblig \
    label "alpha" \
    widget CELL_ERR_4 -width 8 -oblig \
    label "beta" \
    widget CELL_ERR_5 -width 8 -oblig \
    label "gamma" \
    widget CELL_ERR_6 -width 8 -oblig 

  CreateLine line \
    message "Enter number of heavy atoms to search for" \
    label "Search for" \
    widget NHEAVY \
    label "atoms of" \
    widget HEAVY_TYPE


#  CreateLine line \
#    message "Number of copies of formula units (Z)" \
#    label "Number of copies of formula defined below" \
#    widget CELL_Z


#  CreateExtendingFrame N_SFAC ShelxSfac \
#	"Define composition of one molecule" \
#	"Add Element" \
#	[list SFAC UNIT ]

#-------------------------------------------------------------------------------

  OpenFolder 3 SHELX_MODE open PATTERSON hide

  CreateLine line \
    label Try \
    widget TRY_NVECTORS \
    label "superposition vectors"

  CreateLine line \
    label "Enter 'known' vectors:" -italic

  CreateExtendingFrame INPUT_NVECT ShelxVect \
        "Enter 'known' vectors" \
        "Add Vector" \
        [list VECT_X VECT_Y VECT_Z ]

#-----------------------------------------------------------------------------------

  OpenFolder 4 SHELX_MODE open DIRECT hide

  CreateLine line \
    label Try \
    message "Override default TREF np - set to 5000 for difficult structures" \
    widget TREF_NP \
    label "direct methods attempts using" \
    message "Override default TREF nE" \
    widget TREF_NE \
    label reflections in the full tangent formula"

  CreateLine line \
    message "Fudge factor allow for exptl error & avoid 'uranium' solution (TREF kapscal)" \
    label "Multiple products of Es in triplet phase relation by" \
    widget TREF_KAPSCAL 



#-----------------------------------------------------------------------------------

  OpenFolder 2 INPUT_FORMAT closed MTZ  hide

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  CreateLine line \
    message "Exclude reflections in set selected for FreeR \
                             calculation (FREERFLAG&FREE)" \
    help include_freer \
    widget EXCLUDE_FREER \
    label "FreeR label" \
    widget EXCLUDE_FREER_LABEL \
    label "of value " \
    widget EXCLUDE_FREER_VALUE

  CreateLineTemplate "EXCLUDE" {0.0 0.6 0.8}

  CreateLine line \
   message "Exclude FPs which are small compared to sigma FP (EXCLUDE SIGP)" \
    help exclude_sigp \
    widget EXCLUDE_SIGP \
        -toggleon \
    label "FP less than n * sigmaF where n is " \
    widget EXCLUDE_SIGP_FACTOR \
    format template "EXCLUDE"

  CreateLine line \
   message "Exclude FPHs which are small compared to sigma FPH(EXCLUDE SIGH)" \
    help exclude_sigp \
    widget EXCLUDE_SIGH \
        -toggleon \
    label "FPH less than n * sigmaFH where n is " \
    widget EXCLUDE_SIGH_FACTOR \
    format template "EXCLUDE"

  CreateLine line \
    message "Exclude refs with small absolute FP values(EXCLUDE FPMAX)" \
    help exclude_fpmax \
    widget EXCLUDE_FPMAX \
        -toggleon \
    label "F absolute value less than " \
    widget EXCLUDE_FPMAX_MAX \
    format template "EXCLUDE"

  CreateLine line \
   message "Exclude refs with large diff between FP and FPH (EXCLUDE DIFF)" \
    help exclude_diff \
    widget EXCLUDE_DIFF \
        -toggleon \
    label "Difference between F1 and F2 greater than" \
    widget EXCLUDE_DIFF_LIMIT \
    format template "EXCLUDE"

}
