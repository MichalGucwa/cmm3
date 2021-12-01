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
# mapcutting.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc mapcutting_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _mapcutting_definecell [list "cubic" "arbitrary"] \
      [list CUBIC ARBITRARY]

  return 1
}

#---------------------------------------------------------------------
proc mapcutting_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    "Cut density from a map for use in molecular replacement search" \
	    "Mapcutting" [ list "Map parameters" ] ] == 0 } return

  SetProgramHelpFile "maprot"

  set array(INITIALISED) 0

#=PROTOCOL=============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateLine line label "Input electron density map (over at least 1 ASU)" -italic
  CreateInputFileLine line \
        "Enter name of input electron density map file (MAPIN)" \
        "Map file" \
        MAPIN DIR_MAPIN

  CreateLine line label "Input mask (over masked region only)" -italic
  CreateInputFileLine line \
        "Enter name of input mask file (MSKIN)" \
        "Mask file" \
        MSKIN DIR_MSKIN

  CreateLine line label "Output cut map (in cubic cell)" -italic
  CreateOutputFileLine line \
        "Enter name of output map file (CUTOUT)" \
        "Output map file" \
        CUTOUT DIR_CUTOUT

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line label "Note: cell and grid should usually be cubic." -italic

  CreateLine line \
        message "Decide whether to use a cubic (recommended) or arbitrary cell" \
        help cell \
        label "Define" \
        widget CELL_TYPE \
        label "pseudo-cell and grid"

  OpenSubFrame frame toggle_display CELL_TYPE open [list CUBIC]

  CreateLine line \
        message "Cubic pseudo-cell edge - cell angles will be 90 degs. (CELL)" \
        help cell \
        label "Length of cell edge for cubic cell:" \
        widget CELL_CUBIC \
        label "Angstroms"

  CreateLine line \
        message "Cubic pseudo-cell grid (GRID)" \
        help grid \
        label "Grid sampling on x,y and z:" \
        widget GRID_CUBIC

  CloseSubFrame

  OpenSubFrame frame toggle_display CELL_TYPE hide [list CUBIC]

  CreateLine line \
	message "Cubic pseudo-cell dimensions (CELL)" \
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

  CreateLine line \
	message "Cubic pseudo-cell grid (GRID)" \
	help grid \
	label "Grid sampling x=" \
	widget GRID_1 \
	label "y=" \
	widget GRID_2 \
	label "z=" \
	widget GRID_3

 CloseSubFrame

}
