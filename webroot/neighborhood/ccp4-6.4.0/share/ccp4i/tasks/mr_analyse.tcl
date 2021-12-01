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
# mr_analyse.tcl --
#
# Run analysis of MR data
#
# CCP4Interface 
#
# =======================================================================


#----------------------------------------------------------------------
proc mr_analyse_setup { typedefVar arrayname } {
#----------------------------------------------------------------------

# Source the truncate script for procedure to define cell contents
  source [SearchPath TOP tasks truncate.tcl]
  truncate_setup $typedefVar $arrayname

  return 1
}


#----------------------------------------------------------------------
proc mr_analyse_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  if $array(BANALYSIS) {
    set array(INPUT_FILES) "HKLIN XYZIN"
  } else {
    set array(INPUT_FILES) HKLIN
  }
  return 1
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc mr_analyse_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Analyse Data for MR" "MR Analyse" \
        [ list "Define Map"  "Wilson Plot for B Analysis" ] ] == 0 } return

  SetProgramHelpFile "fft"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    widget BANALYSIS \
    label "Do B value analysis of experimental data and model structure"


#=FILES================================================================


  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MAPOUT DIR_MAPOUT _mr_analyse

  CreateLabinLine line \
    "Choose derivative (F1) and optional sigma (SIG1)" \
     HKLIN FP F1  {FP} \
     -sigma SigmaFP SIG1  {}

  CreateInputFileLine line \
      "Enter input model PDB file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
	-toggle_display BANALYSIS open 1


 CreateOutputFileLine line \
      "Enter map file name (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    label "Exclude data resolution less than " \
    widget EXCLUDE_RESOLUTION_MIN \
    label "A or greater than " \
    widget EXCLUDE_RESOLUTION_MAX \
    label "A"


  OpenFolder 2 BANALYSIS open 1 hide

  truncate_define_contents $arrayname

# Check and use XML
  source [SearchPath TOP utils xml_utils.tcl]
  set array(OUTPUT_XML) [XmlStatus]
  if { $array(OUTPUT_XML) } { 
     set array(XMLFILE) [FileJoin [GetDbDirPath] MR_ANALYSE.xml]
  }

}
