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
# fffear.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------------
proc FffearResetModelResol { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if {$array(MODEL_RESOL)!=""} {
    set array(USE_MODEL_RESOL) 1
  } else {
    set array(USE_MODEL_RESOL) 0
  }
}

#-----------------------------------------------------------------------
proc fffear_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

# Check that the solvent content is sensible
  if {![regexp -- "^(\[01\]?)(\[\.\])(\[0-9\]*)$" $array(SOLC)]} {
      WarningMessage "Solvent content must be a positive fraction"
      return 0
  }

# Set up for SEARCH keyword
# STEPS?
  if {[GetValue $arrayname SEARCH_STEP]!=""} {
      set array(USE_STEP) 1
  } else {
      set array(USE_STEP) 0
  }

# RANGE?
  if {[GetValue $arrayname SEARCH_RANGE]!=""} {
      set array(USE_RANGE) 1
  } else {
      set array(USE_RANGE) 0
  }

# PEAK?
  if {[GetValue $arrayname SEARCH_PEAKS]!=""} {
      set array(USE_PEAKS) 1
  } else {
      set array(USE_PEAKS) 0
  }

# If at least one of the above is set then STEP keyword is required
  if {[GetValue $arrayname USE_STEP] || [GetValue $arrayname USE_RANGE] || [GetValue $arrayname USE_PEAKS] } {
      set array(USE_SEARCH) 1
  } else {
      set array(USE_SEARCH) 0
  }

# Centering
  set array(USE_CENTRE) 0
  set array(USE_FRAC)   0
  set array(USE_ORTH)   0
  if {[GetValue $arrayname FRC_OR_ORTH] == "ORTH"} {
      if { $array(ORTH_X) != "" && $array(ORTH_Y) != "" && $array(ORTH_Z) != "" } {
	  set array(USE_CENTRE) 1
	  set array(USE_ORTH)   1
      }
  } else {
      if { $array(FRAC_X) != "" && $array(FRAC_Y) != "" && $array(FRAC_Z) != "" } {
	  set array(USE_CENTRE) 1
	  set array(USE_FRAC)   1
      }
  }

# Model rotate
# If rotate is selected then need to check that the angles are all set
  if {$array(ROTATE_FRAG)} {
      if { $array(MODEL_ALPHA)=="" || $array(MODEL_BETA)=="" || $array(MODEL_GAMMA)=="" } {
	  set array(ROTATE_FRAG) 0
      }
  }

# Scale
  if {[GetValue $arrayname SCALE_TYPE] == "USER"} {
      if { $array(SCALE_SCALING)=="" || $array(SCALE_BFAC)=="" } {
	  WarningMessage "Scale factors not completely defined"
	  return 0
      }
  } elseif {$array(SCALE_NATURAL)} {
      set array(USE_SCALE) 1
  }

#
# List of input files
  set array(INPUT_FILES) "HKLIN"
  switch [GetValue $arrayname MAP_OR_COORDS] \
  MAP {
      set array(USE_XYZIN) 0
      append array(INPUT_FILES) " MAPIN"
  } PDB {
      set array(USE_XYZIN) 1
      append array(INPUT_FILES) " XYZIN"
  } LIB {
      set array(USE_XYZIN) 1
  }

  return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc fffear_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _fffear_fragments [list "empirical 9-helix" \
					"empirical 9-strand" \
					"empirical 9 a turn" \
					"empirical 9 b turn" \
					"empirical 10 helix end" \
					"theoretical 10 helix" \
					"theoretical 5 helix" \
					"theoretical 10 strand" \
					"theoretical 5 strand" ] \
				[ list emp-helix-9 \
					emp-strand-9 \
					emp-turn_a-9  \
					emp-turn_b-9 \
					emp-helixend-9 \
					theor-helix-10 \
					theor-helix-5 \
					theor-strand-10 \
					theor-strand-5 ]
	


# Define the 'format type' menu

    DefineMenu _fffear_map_or_coords [list "CCP4 map" "PDB" "Fffear fragment library" ] \
	    [list MAP PDB LIB]


# Define the frac/orth menu

    DefineMenu _fffear_frac_orth [list "orthogonal" "fractional"] \
	    [list ORTH FRAC]

# Define menu for scaling

    DefineMenu _fffear_scale_type [list "automatically" "by user-defined values"] \
	    [list AUTO USER]

# Define menus for filter

    DefineMenu _fffear_filter_mapmodel [ list "map" "model" "map and model"] \
	    [list MAP MODEL "MAP MODEL"]

    DefineMenu _fffear_filter_meanvar [ list "local mean" "local mean and variance"]\
	    [list 0 1]

# procedure must return success code (1) for drawing task window to continue
  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc fffear_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array


  if { [CreateTaskWindow $arrayname  \
        "Fast Fourier Feature Recognition for density fitting" "FFFeaR" \
        [ list "Solvent Content" \
	       "Search Function Parameters" \
	       "Masks and Filters" \
	       "Model Atoms and Input Fragment Parameters" \
	       "Scaling of Input Data" \
	       "Centring of Output Fragments"
	] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "fffear"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Select source of the input fragment - coordinates or map" \
        label "Take the input fragment from" \
        widget MAP_OR_COORDS \
	label file

  SetProgramHelpFile fffear_fraglib

  CreateLine line \
        help description \
	label "User library fragment for" \
        widget INPUT_FRAGMENT\
        toggle_display MAP_OR_COORDS open LIB

  SetProgramHelpFile fffear
	

#=FILES================================================================ 

  OpenFolder file

  # Input MTZ
  CreateInputFileLine line \
        "Enter name of input mtz file which will be used to create the map" \
        "MTZ in" \
        HKLIN DIR_HKLIN -setfileparam RESOLUTION_MIN RESO_MIN \
	-setfileparam RESOLUTION_MAX RESO_MAX

  # MTZ labels
  CreateLabinLine line \
        "Assign structure factor amplitudes (FP) and sigmas (SIGFP)" \
        HKLIN "FP"  FP {NULL} \
        -sigma "SIGFP" SIGFP {NULL} \

  CreateLabinLine line \
        "Assign phases (PHIO) and Figures-of-Merit (FOMO)" \
        HKLIN "PHIO"  PHIO {NULL} \
        -sigma "FOMO" FOMO {NULL} \


  # Input coordinate file
  CreateInputFileLine line \
        "Enter name of PDB file containing search fragment" \
        "Search fragment PDB" \
        XYZIN DIR_XYZIN \
  	-toggle_display MAP_OR_COORDS open [list PDB] \
	-fileout XYZOUT DIR_XYZOUT "_fffear"

  # Input map file
  CreateInputFileLine line \
        "Enter name of map file containing search fragment" \
        "Search fragment map" \
        MAPIN DIR_MAPIN \
  	-toggle_display MAP_OR_COORDS open [list MAP]

  # Output file with coordinate fragments
  CreateOutputFileLine line \
	"Output file will contain best matches of fragment density to map density" \
	"Output fragment PDB" \
	XYZOUT DIR_XYZOUT

#--------------------------------------------------SOLC folder
# This folder sets the solvent content
# This is compulsory

    OpenFolder 1

    CreateLine line \
	    help solc \
	    message "Fraction of solvent content, used for scaling (SOLC)" \
	    label "Use solvent fraction" widget SOLC -oblig

    CreateLine line \
	    message "Set the mean density for solvent and protein regions (this affects scaling and density modification)" \
	    widget USE_MEAN \
	    message "Mean density in the solvent region (electrons/cubic Angstroms)" \
	    label "Set the mean density to" \
	    widget SOLVVAL \
	    message "Mean density in the protein region (electrons/cubic Angstroms)" \
	    label "in the solvent region, and" \
	    widget PROTVAL \
	    label "in the protein region"

#--------------------------------------------------SEARCH/RESO folder
# This folder sets the search function parameters

    OpenFolder 2

    CreateLine line \
	    help search \
	    message "Set the orientation step angle in degrees" \
	    label "Search function is in steps of" \
	    widget SEARCH_STEP label "degrees"

    CreateLine line \
	    message "Set the maximum range in degrees for the search" \
	    label "Maximum range of search function:" \
	    widget SEARCH_RANGE label "degrees"

    CreateLine line \
	    message "Set the number of peaks in the search function to output rotated fragment atoms" \
	    label "Output rotated fragments for top" \
	    widget SEARCH_PEAKS label "peaks in the search function"

    CreateLine line \
	    help resolution \
	    message "Resolution range of reflections to include in the translation search" \
	    label "Resolution range to use in translation search: Min" \
	    widget RESO_MIN label "Max" widget RESO_MAX

#--------------------------------------------------MASK/FILTER folder
# This folder sets the parameters for the atom masks and for filters
# applied to the map and to the search model

    OpenFolder 3 closed

    CreateLine line \
	    help mask \
	    message "Apply fragment mask about the model atoms (MASK)" \
	    widget USE_MASK \
	    label "Set the radius of the fragment mask about the model atoms to" \
	    message "This determines the volume over which the agreement between the map and the model are compared" \
	    widget MASK_RADIUS \
	    label "A"

    CreateLine line \
	    help filter \
	    message "Apply a filter to the map and/or model before starting the search (FILTER)" \
	    widget APPLY_FILTER \
	    label "Apply a filter to the" \
	    widget FILTER_MAPMODEL \
	    label "and match the" \
	    widget FILTER_VARIANCE \
	    label "within a radius of" \
	    widget FILTER_RADIUS \
	    label "A"

#--------------------------------------------------MODEL folder
# This folder sets the parameters for the model atoms and input fragment

    OpenFolder 4 closed

    CreateLine line \
	    help model \
	    message "Set the radius over which the atomic density is calculated for each model atom (MODEL RADIUS)" \
	    label "Calculate the atomic density over radius of" \
	    widget MODEL_RADIUS \
	    label "A for each model atom"

    CreateLine line \
	    message "Set the resolution at which the atomic shape functions are calculated (MODEL RESOLUTION)" \
	    widget USE_MODEL_RESOL \
	    label "Change the resolution of the atomic shape function to" \
	    widget MODEL_RESOL -command "FffearResetModelResol $arrayname"\
	    label "A"

    CreateLine line \
	    message "Apply an initial rotation to the model before starting the search (MODEL ROTATE)" \
	    widget ROTATE_FRAG \
	    label "Apply initial rotation to input fragment before search"

    CreateLine line \
	    message "Set angles for rotation of input fragment prior to searching (MODEL ROTATE)" \
	    label "Rotation defined by angles alpha" \
	    widget MODEL_ALPHA \
	    label "beta" \
	    widget MODEL_BETA \
	    label "gamma" \
	    widget MODEL_GAMMA \
	    toggle_display ROTATE_FRAG open [list 1]

#--------------------------------------------------SCALE folder
# This folder sets the parameters for over-riding the internal
# scaling of the program

    OpenFolder 5 closed

    CreateLine line \
	    help scale \
	    message "Determine whether to over-ride fffear's internal scaling (SCALE)" \
	    label "Scale the input data" \
	    widget SCALE_TYPE

    CreateLine line \
	    help scale \
	    message "Override internal scaling - set scale factor to use (SCALE)" \
	    label "Apply scale according to Fsquared =" \
	    widget SCALE_SCALING \
	    label "exp(" \
	    message "Override internal scaling - set b-factor to use (SCALE)" \
	    widget SCALE_BFAC \
	    label "s/2) * Fobs-squared" \
	    toggle_display SCALE_TYPE open [list USER]

    CreateLine line \
	    message "Scale according to F-squared=<scale>Fobs-squared? (SCALE NATURAL)" \
	    widget SCALE_NATURAL \
	    label "Place the map on an absolute scale but do not adjust the B-factor" \
	    toggle_display SCALE_TYPE open [list AUTO]

    CreateLine line \
	    message "Temperature factor to add to all the atoms in the input fragment (MODEL BFACTOR)" \
	    label "Add B-factor of" \
	    widget MODEL_BFAC \
	    label "to all the atoms in the input fragment"

#--------------------------------------------------CENTRE folder
# This folder sets the parameters for centring the output fragments

    OpenFolder 6 closed

    CreateLine line \
	    help centre \
	    message "Coordinates for centring are expressed in fractional or orthogonal units" \
	    label "Use" widget FRC_OR_ORTH label "coordinates"

    CreateLine line \
	    message "Centre the output fragments in the asymmetric unit around x,y,z" \
	    label "Centre the output fragment positions around x" \
	    widget ORTH_X label "y" widget ORTH_Y label "z" widget ORTH_Z \
	    toggle_display FRC_OR_ORTH open [list ORTH]

    CreateLine line \
	    message "Centre the output fragments in the asymmetric unit around x,y,z" \
	    label "Centre the output fragment positions around x" \
	    widget FRAC_X label "y" widget FRAC_Y label "z" widget FRAC_Z \
	    toggle_display FRC_OR_ORTH open [list FRAC]

}
