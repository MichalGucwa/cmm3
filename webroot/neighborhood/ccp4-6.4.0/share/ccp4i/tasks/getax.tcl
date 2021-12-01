#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# getax.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc getax_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array
  
DefineMenu _cn_or_dn [list "Cn" "Dn"] [ list 0 1]

DefineMenu _map_type [list "MTZ file" "MAP file"] [ list 0 1]

DefineMenu _sph_or_sli [list "Sphere" "Slice"] [ list 0 1]
				   
DefineMenu _orth_conv [list "axes along a, c* x a, c* (Brookhaven standard)" \
				   "axes along b, a* x b, a*" \
				   "axes along c, b* x c, b*" \
				   "axes along a+b, c* x (a+b), c*" \
				   "axes along a*, c x a*, c (Rollett)" \
				   "axes along a, b*, a x b*" \
				   " axes along a*, b, a* x b (TNT convention)"] \
				   [ list 1 2 3 4 5 6 7 ]
  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc getax_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Real Space Correlation Search for NCS" "Getax" \
               {"NCS axis" "Multimer Shape" "Report parameters"} ] == 0 } return

  SetProgramHelpFile "getax"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE
  
  CreateLine line \
	   label "Give input as a " \
	   widget MAP_TYPE
	   
  CreateLine line \
	   label "Perform search for a " \
	   widget CN_OR_DN \
	   label "multimer using a "\
 	   widget SPH_OR_SLI \
	   label " shape." 

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
	  label "Run GETAX to search for non-crystallographic symmetry." \
	  -italic

OpenSubFrame frame -toggle_display MAP_TYPE hide 0
  	CreateInputFileLine line \
        "Enter name of input map file (MAPIN) - usually 6A resolution is adequate" \
        "MAP file" \
        MAPIN DIR_MAPIN \
		-fileout XYZOUT DIR_XYZOUT "_getax" \
		-fileout MAPOUT DIR_MAPOUT "_getax"
CloseSubFrame

OpenSubFrame frame -toggle_display MAP_TYPE open 0
  CreateInputFileLine line \
        "Enter name of input mtz file - usually 6A resolution is adequate" \
        "MTZ file" \
        HKLIN DIR_HKLIN \
		-fileout XYZOUT DIR_XYZOUT "_getax" \
		-fileout MAPOUT DIR_MAPOUT "_getax"
		
  CreateLabinLine line \
    "Choose amplitude (F1) and optional sigma (SIG1)" \
     HKLIN "F1    " F1  {} \
    -sigma "Sigma  " SIG1  {}

  CreateLabinLine line2 \
    "Choose phase (PHI) and optional weighting factor (W)" \
     HKLIN "PHI   " PHI  {} \
     -sigma "Weight " W  {}

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    label "Only use resolution between " \
    widget EXCLUDE_RESOLUTION_MIN \
    label "A and" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "A"
	 
CloseSubFrame

CreateOutputFileLine line \
      "Enter output PDB file name (XYZOUT)" \
       "PDB out" \
       XYZOUT DIR_XYZOUT
	   
CreateOutputFileLine line \
      "Enter output MAP file name (MAPOUT)" \
       "MAP out" \
       MAPOUT DIR_MAPOUT
	   
OpenFolder 1

CreateLineTemplate AXIS { 0.0 0.4 0.5 0.6 0.7 0.78 0.88}

  CreateLine line \
          message "Orientation/rotation given in polar angles (kappa=360/n)" \
	  label "NCS multimer axis: " \
	  widget OMEGA -oblig \
	  label " omega " \
	  widget PHIA -oblig \
	  label " phi " \
	  widget KAPPA -oblig \
	  label " kappa" \
	  format template AXIS

OpenSubFrame frame -toggle_display CN_OR_DN hide 0

  CreateLine line \
          message "For Dn symmetry, 2-fold needs to be perpendicular to first axis" \
	  label "Orientation of the 2-fold axis: " \
	  widget OMEGA2 \
	  label " omega " \
	  widget PHI2 \
	  label " phi " \
	  widget KAPPA2 \
	  label " kappa" \
	  format template AXIS
	  
CloseSubFrame

  CreateLine line \
          message "Describes the convention used for the above polar angles - default should be ok in most cases" \
	  label "Orthogonalisation convention used" \
	  widget ORTH_CONV

OpenFolder 2

OpenSubFrame frame -toggle_display SPH_OR_SLI open 0

  CreateLine line \
          message "Estimate of most likely shape of NCS-obeying multimer" \
	  label "Use a sphere with outer radius of " \
	  widget OUT_RAD -oblig \
	  label " and  " \
	  widget OMIT_INNER \
	  label "  omit an inner radius of" \
	  widget INN_RAD
	  
CloseSubFrame

OpenSubFrame frame -toggle_display SPH_OR_SLI hide 0

  CreateLine line \
          message "Estimate of most likely shape of NCS-obeying multimer" \
	  label "Use a disk with outer radius of " \
	  widget OUT_RAD -oblig \
	  label " , a height of  " \
	  widget SLI_HEIGHT -oblig \
	  label " and  " \
	  widget OMIT_INNER \
	  label "  omit an inner radius of" \
	  widget INN_RAD
	  
CloseSubFrame

OpenFolder 3 closed

	CreateLine line \
	  label "Report all positions with a correlation between NCS related regions higher than " \
	  widget REP_REG
	  
	CreateLine line \
          message "Bottom of log file will contain NCS rotation matrix and translation vector" \
	  label "Report the top " \
	  widget REP_TOP \
	  label " possible NCS translations."
}

#--------------------------------------------------------------
proc getax_run { arrayname } {
#--------------------------------------------------------------
  upvar #0 $arrayname array
  
  if {$array(MAP_TYPE) == "MTZ file"} {
    set array(INPUT_FILES) "HKLIN"
  } else {
    set array(INPUT_FILES) "MAPIN"
  }
  return 1
}

#-----------------------------------------------------------------
proc getax_review { arrayname job_id } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  return 1
}
