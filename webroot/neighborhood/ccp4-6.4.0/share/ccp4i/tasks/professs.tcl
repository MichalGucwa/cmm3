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
# professs.tcl --
#
# CCP4Interface 
#
# =======================================================================


#------------------------------------------------------------------------
proc professs_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_professs_input_format)	{ menu	{	"PDB" \
						"CCP4 HA (heavy atom) format" } \
                                                { PDB HA } }

  set typedef(_tidy_mode)      { menu { "origin"
                                      "centre (fractional)"
                                      "centre (orthogonal)" }
                                       { DEFAULT FRAC ORTH } }

  set typedef(_output_mode)      { menu { "all sets"
                                      "best sets only"}
                                        { ALL BEST } }

  return 1

}


#---------------------------------------------------------------------
proc professs_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  
  if { $array(USE_XYZOUT) } {
     set array(OUTPUT_FILES) " XYZOUT"
  }

  switch [GetValue $arrayname INPUT_FORMAT] \
  PDB {
    set array(XYZIN) $array(PDBIN)
    set array(DIR_XYZIN) $array(DIR_PDBIN)
  } HA {
    set array(XYZIN) $array(HAIN)
    set array(DIR_XYZIN) $array(DIR_HAIN)
  } 
  return 1
}


# procedure to draw task window
#---------------------------------------------------------------------
proc professs_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    "Search for NCS in substructure" \
	    "Distangncs" [list "Crystal parameters" "Parameters"] ] == 0 } return

  SetProgramHelpFile "professs"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line  \
	message "Choose input coordinate file format "	\
	label "Use heavy atom coordinates in " \
	widget INPUT_FORMAT \
	label "format"

  CreateLine line \
        help files \
        message "Generate output PDB file for use with LSQKAB" \
	widget USE_XYZOUT \
	label "Output PDB file with related sets of atoms"

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
      "Enter input PDB coordinate file name (XYZIN)" \
        "PDB input file" \
       PDBIN DIR_PDBIN \
        -setfileparam cell CELL\
        -setfileparam space_group_name SPACE_GROUP \
	-toggle_display INPUT_FORMAT open PDB

  CreateInputFileLine line \
      "Enter input ,ha coordinate file name (XYZIN)" \
        "HA input file" \
       HAIN DIR_HAIN \
        -toggle_display INPUT_FORMAT open HA

  CreateLine line \
	message "Default settings to move coordinates near a set centre (TIDYINPUT)" \
	help TIDYINPUT \
	widget USE_TIDY \
	label "Generate symmetry equivalent coordinates nearest to" \
        widget TIDY_MODE

  # Subframe for specifying centre for symmetry equivalent atoms
  OpenSubFrame frame -toggle_display USE_TIDY open { 1 }

  CreateLine line \
	message "Define centre for tidying input coordinates (TIDYINPUT)" \
	label "  Move coordinates to centre on x" \
	widget TIDY_X -oblig \
        label "y" \
	widget TIDY_Y -oblig  \
        label "z" \
	widget TIDY_Z -oblig  \
	toggle_display TIDY_MODE open [list FRAC ORTH] \

  CloseSubFrame

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT \
	  -toggle_display USE_XYZOUT open 1

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line \
	message "Space group (SYMM)" \
	help spacegroup \
	label "Space group" \
	widget SPACE_GROUP -oblig

  CreateLine line \
	message "Cell dimensions (from PDB if available) (CELL)" \
	help "cell" \
	label "Cell a" widget CELL_1 -width 8 -oblig \
	label "b"      widget CELL_2 -width 8 -oblig \
	label "c"      widget CELL_3 -width 8 -oblig \
	label "alpha"  widget CELL_4 -width 8 -oblig \
	label "beta"   widget CELL_5 -width 8 -oblig \
	label "gamma"  widget CELL_6 -width 8 -oblig  
  
  OpenFolder 2

  CreateLine line \
	message "Define maximum atom distance to analyse (DIST)" \
	label "Maximum atom distance" \
        widget DISTANCE -oblig \
	message "Difference less than which distances are considered equal (TOLER)" \
	label "Atom distance tolerance" \
        widget TOLERANCE -oblig
  
  OpenSubFrame frame -toggle_display USE_XYZOUT open [list 1]
  CreateLine line \
	message "List all operators or only those matching many atoms (LIST)" \
	label "Output" \
        widget OUTPUT_MODE -oblig
  CloseSubFrame
}
