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
# rotamer.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc rotamer_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

#---------------------------------------------------------------------
proc rotamer_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  return 1
}

#---------------------------------------------------------------------
proc rotamer_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname \
       "Compare coordinates against Penultimate Rotamer Library" "Rotamer" \
       [ list "Parameters" ] ] == 0 } return

  SetProgramHelpFile "rotamer"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  # Input PDB file
  CreateInputFileLine line \
     "Enter name of coordinate file (PDB format) to check against the library" \
     "Coordinate file" \
     XYZIN DIR_XYZIN

#--------------------------------------------------Parameters Folder
# This folder sets the user-defined parameters

  OpenFolder 1

  CreateLine line \
     help keywords \
     message "Default value is 30 degrees (DELTA keyword)" \
     widget USE_DELTA -toggleon \
     label "Report side chain torsion angle deviations >" \
     widget DELTA -command "rotamer_check_angle $arrayname" \
     label "degrees from the nearest rotamer"

}

#---------------------------------------------------------------------
proc rotamer_check_angle { arrayname } {
#---------------------------------------------------------------------
# Check that the supplied angle is in the range 0 to 180 degrees
# Reset if outside this range
  upvar #0 $arrayname array
  set angle $array(DELTA)
  if { $angle == "" } { return }
  if { $angle < 0 } {
    set array(DELTA) 0
  } elseif { $angle > 180 } {
    set array(DELTA) 180
  }
  return
}
     


