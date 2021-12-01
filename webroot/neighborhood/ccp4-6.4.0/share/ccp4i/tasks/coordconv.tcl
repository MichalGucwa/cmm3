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
# rotaprep.tcl --
#
# Import a formatted reflection file (eg from DENZO) and create multirecord
#   MTZ file
#
# CCP4Interface 
# Created Oct97 by Liz Potterton
#
# =======================================================================


#------------------------------------------------------------------------
proc coordconv_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_coordconv_input_format)	{ menu	{	"PDB" \
						"CCP4 fractional coordinates" \
						"CCP4 HA (heavy atom) format" \
						"Shelx full format" \
						"Shelx short format" \
						"Cambridge Structural Database" \
						"X-Plor"  } \
	{ PDB FRAC HA SHELX-F SHELX-S CSD XPLOR } }

  set typedef(_coordconv_output_format)  { menu  {       "PDB" \
                                                "CCP4 fractional coordinates" \
						"CCP4 HA (heavy atom) format" \
                                                "X-Plor"  } \
        				{ PDB FRAC HA XPLOR } }

  return 1

}


#---------------------------------------------------------------------
proc coordconv_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  switch [GetValue $arrayname INPUT_FORMAT] \
  PDB {
    set array(XYZIN) $array(PDBIN)
    set array(DIR_XYZIN) $array(DIR_PDBIN)
  } HA {
    set array(XYZIN) $array(HAIN)
    set array(DIR_XYZIN) $array(DIR_HAIN)
  } default {
    set array(XYZIN) $array(ANYIN)
    set array(DIR_XYZIN) $array(DIR_ANYIN)
  }
  return 1
}


#-----------------------------------------------------------------------
proc coordconv_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Coordconv - Convert Coordinate Format" "Coordconv" \
	[list "Extra Info" ]] == 0 } return


#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line  \
	message "Choose input coordinate file format(INPUT) "	\
        help input \
	label "Convert file in " \
	widget INPUT_FORMAT \
	label to \
	help output \
	widget OUTPUT_FORMAT


#=FILES================================================================

# frame to enter input file name - note there are two different input lines
# depending on whether input format is mtz or other - only one line is 
# displayed at a time

  OpenFolder file

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
        "In" \
       PDBIN DIR_PDBIN \
        -setfileparam cell CELL\
	-toggle_display INPUT_FORMAT open PDB

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
        "In" \
       HAIN DIR_HAIN \
        -toggle_display INPUT_FORMAT open HA


  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
        "In" \
       ANYIN DIR_ANYIN \
	-toggle_display INPUT_FORMAT hide [list PDB HA]

  CreateOutputFileLine line \
      "Enter output coordinate file name (XYZOUT)" \
       "Out" \
       XYZOUT DIR_XYZOUT \

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine  line  \
        message "Enter orthogonalisation code (1-6) (INPUT ORTH)" \
	help input_orth \
	label "Use orthogonalisation code" \
        widget ORTH_CODE -oblig \
#	toggle_display INPUT_FORMAT hide [list FRAC CSD]


  CreateLine  line  \
	message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
        help "cell" \
	label "Cell dimensions a" \
	widget CELL_1  -oblig \
	label " b" \
	widget CELL_2  -oblig \
	label " c" \
	widget CELL_3  -oblig \
	label " alpha" \
	widget CELL_4  -oblig \
	label " beta" \
	widget CELL_5  -oblig \
	label " gamma" \
	widget CELL_6  -oblig 

}

