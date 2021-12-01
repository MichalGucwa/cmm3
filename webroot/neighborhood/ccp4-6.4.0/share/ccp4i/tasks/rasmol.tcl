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
# header.tcl --
#
# Template for task interface
#
# CCP4Interface 
#
# =======================================================================

proc start_rasmol { arrayname } {

   upvar #0 $arrayname array

  exec rasmol [GetFullFileName0 $arrayname XYZIN]

}

proc rasmol_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "List File Headers" "Header" \
         {} -action_buttons quit ] == 0 } return


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
	-noinfo

  CreateLine line \
	button "Run RasMol" \
        -command "start_rasmol $arrayname"

#  pack forget $line.b1
#  pack $line.b1 -side right

}

