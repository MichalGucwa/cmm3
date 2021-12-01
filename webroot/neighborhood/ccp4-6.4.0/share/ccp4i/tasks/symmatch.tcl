#
#     Copyright (C) 2011  Kevin Cowtan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# symmatch.tcl --
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------
proc symmatch_task_window { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Symmetry match models" "Symmatch" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

  SetProgramHelpFile "csymmatch"

#=PROTOCOL==============================================================

  OpenFolder protocol 
  
  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Enter input coordinate file containing the model to be moved" \
      "Work PDB in" \
       XYZIN1 DIR_XYZIN1 \
       -fileout XYZOUT DIR_XYZOUT "_symmatch"

  CreateInputFileLine line \
        "Enter input coordinate file containing the fixed model" \
      "Reference PDB in" \
       XYZIN2 DIR_XYZIN2

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

#=PARAMETERS==========================================================

  OpenFolder 1 open

  CreateLine line \
      message "Move the origin and change hand if necessary." \
      help origin-hand \
      widget ORIGINHAND -width 4 \
      label "Apply origin shift and hand correction."

  CreateLine line \
      message "Resdiues/monomers with atoms within this distance will be moved as a unit" \
      help connectivity-radius \
      label "Connectivity radius: " \
      widget CONNECTRAD -width 4

}
