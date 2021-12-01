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
# whatcheck.tcl --
#
# Run whatcheck
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc whatcheck_prereq { } {
#-----------------------------------------------------------------------
  # Check that WHATCHECK executable is available
  if { ![file exists [FindExecutable whatcheck]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc whatcheck_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef

  return 1
}

#-----------------------------------------------------------------------
proc whatcheck_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(TITLE) == "" } {
      set array(TITLE) "what_check run on [GetFullFileName0 $arrayname XYZIN]"
  }
  return 1
}

#-----------------------------------------------------------------------
proc whatcheck_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Whatcheck: Protein validation" "Whatcheck" ] == 0 } return

  SetProgramHelpFile whatcheck

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      label "Run Whatcheck to perform checks on a set of protein coordinates" \
      -italic

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter PDB file name (XYZIN)" \
      "Coordinates" \
      XYZIN DIR_XYZIN

}
