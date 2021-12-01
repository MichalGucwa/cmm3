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
# xfit.tcl --
#
# Run xfit
#
# CCP4Interface 
#
# =======================================================================


#----------------------------------------------------------------------
proc xfit_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(INPUT_XYZS) ""
  for { set n 1 } { $n <= $array(NXYZS) } { incr n } {
    append array(INPUT_XYZS) "XYZIN,$n "
  }
  set array(INPUT_MAPS) ""
  for { set n 1 } { $n <= $array(NMAPS) } { incr n } {
    append array(INPUT_MAPS) "MAPIN,$n "
  }

  return 1

}

#----------------------------------------------------------------------
proc xfit_xyzin { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  CreateLine line \
    label "Input PDB # $counter" \
    -italic
   
  CreateInputFileLine line \
    "Enter input PDB file name (XYZIN)" \
    "PDB file" \
     XYZIN DIR_XYZIN \
     -help files \
     -setfileparam space_group_name SPACE_GROUP \
     -setfileparam cell CELL
}

#----------------------------------------------------------------------
proc xfit_mapin { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  CreateLine line \
    label "Input map # $counter" \
    -italic
   
  CreateInputFileLine line \
    "Enter input map file name (MAPIN)" \
    "Map/Mask" \
     MAPIN DIR_MAPIN \
     -help files \
     -setfileparam space_group_number SPACE_GROUP \
     -setfileparam cell CELL
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

#----------------------------------------------------------------------
proc xfit_task_window { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Launch xfit" "xfit" \
        [ list "Crystal data" "Xfit defaults" ] ] == 0 } return

  SetProgramHelpFile "xfit"

#=PROTOCOL==============================================================

  OpenFolder protocol 

#=FILES================================================================

  OpenFolder file

  CreateExtendingFrame NXYZS  xfit_xyzin \
     "Define input pdb file (XYZIN)"  \
     "Add input pdb file"  \
     [list   XYZIN  DIR_XYZIN ]

  CreateExtendingFrame NMAPS  xfit_mapin \
     "Define input map file (MAPIN)"  \
     "Add input map file"  \
     [list   MAPIN  DIR_MAPIN ]

#=PARAMETERS==========================================================

  OpenFolder 1 closed

  CreateLine line \
	message "Space group (default from map) (SYMM)" \
        help spacegroup \
	label "  Space group" \
	widget SPACE_GROUP 

  CreateLine line \
	message "Cell dimensions (default from map/pdb) (CELL)" \
        help cell \
	label "Cell a" \
	widget CELL_1 \
	label "b" \
	widget CELL_2 \
	label "c" \
	widget CELL_3 \
	label "alpha" \
	widget CELL_4 \
	label "beta" \
	widget CELL_5 \
	label "gamma" \
	widget CELL_6

  OpenFolder 2 closed

    CreateLine line \
    message "Contour radius for map plotting" \
    help "contour" \
    label "Contour radius" \
    widget CONT_RAD


}

