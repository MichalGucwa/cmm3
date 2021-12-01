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
# merge_monomers.tcl --
#
# CCP4Interface
# Merge monomer library files using LIBCHECK
#
# =======================================================================

#----------------------------------------------------------------------
proc merge_monomers_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  return 1
}
   
#------------------------------------------------------------------------
proc merge_monomers_task_window { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Merge together multiple monomer library files" "Merge" \
        {} ] == 0 } return

  SetProgramHelpFile libcheck

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
      label "Input library files:" -italic

  CreateExtendingFrame NFILES merge_monomers_add_lib \
     "Add another file containing monomer descriptions" \
     "Add file" \
     [list LIBIN DIR_LIBIN]

  CreateLine line \
      label "Output library file:" -italic

  CreateOutputFileLine line \
      "Merge descriptions into library file" \
       "Library" LIBOUT DIR_LIBOUT

}

#------------------------------------------------------------------------
proc merge_monomers_run { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) ""
  for { set i 1 } { $i <= $array(NFILES) } { incr i } {
     append array(INPUT_FILES) "LIBIN,$i "
  }
  set array(OUTPUT_FILES) "LIBOUT"

  set title "Merge monomer dictionary files into a single file"
  SetDefaultTitle $arrayname $title

  return 1
}

#------------------------------------------------------------------------
proc merge_monomers_add_lib { arrayname counter } {
#------------------------------------------------------------------------

  CreateInputFileLine line \
    "File containing geometry description" \
    "Library file $counter" LIBIN DIR_LIBIN
}
