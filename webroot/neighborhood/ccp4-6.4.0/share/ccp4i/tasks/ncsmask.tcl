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
# mapave.tcl --
#
# Run maprot to generate averaged map
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc ncs_operators { arrayname counter } {
#-----------------------------------------------------------------------

   CreateLine ops_frame \
        message "Enter Averaging Operator (ROTA EULER & TRAN)" \
        label "alpha" \
        widget NCS_OP_ALPHA \
        label "beta" \
        widget NCS_OP_BETA \
        label "gamma" \
        widget NCS_OP_GAMMA \
        label "xtran" \
        widget NCS_OP_XTRAN \
        label "ytran" \
        widget NCS_OP_YTRAN \
        label "ztran" \
        widget NCS_OP_ZTRAN
}


#-----------------------------------------------------------------------
proc  ncsmask_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  DefineMenu _ncsmask_mode [ list "Create mask from coordinates" \
				"Edit existing mask" ] \
			[ list CREATE CLEANUP ]

  return 1

}

#-----------------------------------------------------------------------
proc ncsmask_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set input_mode [GetValue $arrayname NCSMASK_MODE]
  if [regexp  CREATE $input_mode ] { 
    set array(INPUT_FILES) "XYZIN"
  } else {
    set array(INPUT_FILES) MSKIN
  }
  return 1
}

#-----------------------------------------------------------------------
proc  ncsmask_ifncs { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  if { $array(IFMONOMER) || $array(IFOVERLAP) } {
    set array(IFNCS) 1
  } else {
    set array(IFNCS) 0
  }
}

#-----------------------------------------------------------------------
proc ncsmask_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Ncsmask - Create and Edit Mask" "Edit Mask" \
        [ list "Creating Mask Options" \
		"Editing Mask Options" \
		"Mask Cleanup Options" \
		"NCS Operators"  ] ] == 0 } return

  SetProgramHelpFile ncsmask

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Use ncsmask to perform which function" \
    help keywords \
    widget NCSMASK_MODE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
      "Coords in" \
       XYZIN DIR_XYZIN \
	-fileout MSKOUT DIR_MSKOUT  -- \
	-toggle_display NCSMASK_MODE open CREATE

  CreateInputFileLine line \
      "Enter input mask file name (MSKIN)" \
      "Mask in" \
       MSKIN DIR_MSKIN \
        -fileout MSKOUT DIR_MSKOUT  _mod \
	-toggle_display NCSMASK_MODE hide CREATE

  CreateOutputFileLine line \
      "Enter mask file name or click file browser icon (MSKOUT)" \
      "Mask out" \
      MSKOUT DIR_MSKOUT

#----------------------------------------------------------------create mask

  OpenFolder 1 NCSMASK_MODE open [list CREATE ] hide

  CreateLine line \
    message "Default 3.0 (RADIUS)" \
    help radius \
    label "Radius for building mask from atoms" \
    widget RADIUS \
    label "Angstrom"

   CreateLine line \
    message "Space group (default as in map file) (SYMMETRY)" \
    help symmetry \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    widget IFXYZLIM \
        -toggleon \
    label "Set map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6

  CreateLine line \
    message "Set grid values (GRID)" \
    widget IFGRID \
        -toggleon \
    help grid \
    label "Set map grid x=" \
    widget GRID_1 \
    label "y=" \
    widget GRID_2 \
    label "z=" \
    widget GRID_3

#---------------------------------------------------edit extent

  OpenFolder 2 NCSMASK_MODE hide [list CREATE ] open

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    widget IFXYZLIM \
        -toggleon \
    label "Reset map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6



#--------------------------------------------------------mask cleanup
  OpenFolder 3 

  CreateLine line \
    message "Cleanup mask (PEAK)" \
    help peak \
    widget IFPEAK \
	-toggleon \
    label "Cleanup mask to have" \
    widget PEAK \
    label "contiguous region(s)"

  CreateLine line \
    message "Smooth mask using sphere radius (max 5) (SMOOTH)" \
    help smooth \
    widget IFSMOOTH \
	-toggleon \
    label "Remove features less than" \
    widget SMOOTH \
    label "grid points"

  CreateLine line \
    message "Only works if NCS is only single proper rotation axis (MONOMER)" \
    help monomer \
    widget IFMONOMER \
	-command "ncsmask_ifncs $arrayname" \
    label "Reduce a multimer mask to cover only a monomer"

  CreateLine line \
    message "Remove mask elements that are not present in symmetry partners (OVERLAP)" \
    help overlap \
    widget IFOVERLAP \
	-toggleon \
	-command "ncsmask_ifncs $arrayname" \
    label "Perform overlap removal for" \
    widget OVERLAP_NCYCLE \
    label "cycles"

  CreateLine line \
    message "Trim mask to minimum extent (NOTRIM)" \
    help notrim \
    widget IFTRIM \
    label "Trim mask to minimum box"

#------------------------------------------------------------NCS operators
  OpenFolder 4 IFNCS open 1 hide

  CreateExtendingFrame NCS_NOPS ncs_operators \
        "Add/remove line to define extra averaging operator" \
        "Add operator" \
        [ list NCS_OP_ALPHA \
        NCS_OP_BETA \
        NCS_OP_GAMMA \
        NCS_OP_XTRAN \
        NCS_OP_YTRAN \
        NCS_OP_ZTRAN ]


# Run procedure to determine whether NCS_OPs folder is open
   ncsmask_ifncs $arrayname

}

