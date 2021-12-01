#
#     Copyright (C) 1999-20012  Liz Potterton, Peter Briggs, Charles Ballard
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# hgen.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc hgen_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

set typedef(_hgen_mode) { menu { "append in file" \
                                 "separate file" } \
                               { APPE SEPA } }

return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc hgen_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

 if { [CreateTaskWindow $arrayname  \
        "Place riding hydrogens" "Hgen" \
        [ list "Run mode" ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "hgen"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
        "Enter name of input pdb file" \
        "PDB in" \
        XYZIN DIR_XYZIN

  CreateOutputFileLine line \
        "Enter output pdb file name" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

#-------------------------------------------------- mode
  OpenFolder 1 

  CreateLine line \
        message "Select whether to append or use separate file for Hs" \
        label "Use" \
        widget HGEN_MODE \
        label "to write Hs"

}

