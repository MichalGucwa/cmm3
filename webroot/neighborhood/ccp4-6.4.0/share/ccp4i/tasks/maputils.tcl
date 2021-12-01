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
# maputils.tcl --
#
# Run mapmask for map/mask utilities
# maprot for interpolation and rotation
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc  maputils_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------

  DefineMenu _mapmask_mode [ list 	"Edit a map/mask file" \
					"Extend a map/mask file" \
					"Print a map/mask file" \
					"Interpolate map to alternative grid" \
					"Rotate map" \
					"Create mask from map" \
					"Scale map using a mask" \
					"Solvent flatten a map using a mask" \
					"Combine maps/masks" ] \
			[ list	 	EDIT \
					EXTEND \
					PRINT \
					INTERPOLATE \
					ROTATE \
					CREATE_MASK \
					SCALE_BY_MASK \
					SOLVENT_FLATTEN \
					COMBINE ]

  DefineMenu _mapmask_which	[ list "map" "mask" ] \
				[ list MAP MASK ]

  DefineMenu _mapmask_which_1	[ list "two map files" \
				"two mask files" \
				"a map and a mask" ] \
				[ list MAP MASK BOTH ]

  DefineMenu _mapmask_ext_mode	[ list "cover all atoms in molecule" \
					"asymmetric unit" \
					"unit cell" \
					"same extent as another map" \
					"extent defined by user" ] \
				[ list MOLECULE ASU CELL MATCH USER ]

  DefineMenu _mapmask_extend	[ list "applying program default" \
					"copying density" \
					"applying symmetry" \
					"overlapping copy & symmetry" ] \
				[list 	DEFAULT \
				      	COPY \
					XTAL \
					OVERLAP ]

  DefineMenu _mapmask_mask	[ list "density above cutoff" \
					"fraction of output mask" \
					"fraction of unit cell" ] \
				[ list CUT FRAC VOLUME ]

  DefineMenu _mapmask_scale_1	[ list "by applying scale factor" \
					"to set mean and SD" ] \
				[ list FACTOR SIGMA ]

  DefineMenu _mapmask_scale_2 	[ list "mean for protein and solvent" \
					"ratio of SD/mean for protein" ] \
				[ list MEAN RATIO ]

  DefineMenu _mapmask_flip	[ list "flattening" "flipping" ] \
				[ list "1.0" "2.0" ]
				
  DefineMenu _mapmask_combine	[ list addition multiplication ] \
				[ list ADD MULT ]

  return 1

}

#-----------------------------------------------------------------------
proc maputils_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(IFMAPROT) 0
  set array(IFXYZLIM) 0
  set array(XYZLIM_MODE) ""
  set array(IFBORDER) 0
  set array(IFMASK) 0
  set array(IFSOLVENT_FLAT) 0
  set array(IFCOMBINE) 0
  set array(INPUT_FILES) ""
  set array(OUTPUT_FILES) ""

  set mode [GetValue $arrayname MAPMASK_MODE]
  set ifmap [regexp MAP [GetValue $arrayname MAPMASK_OBJECT]]
  set array(SPACE_GROUP) [GetSpaceGroupNumber $array(SPACE_GROUP)] 
  
  if { ![StringSame $mode EDIT]}  { set array(IFAXIS) 0 }
  if { ![StringSame $mode EXTEND]}  { set array(IFPAD) 0 }
  if { ![StringSame $mode PRINT EDIT ]}  { set array(IFSCALE) 0 }
  if { ![StringSame $mode CREATE_MASK ]}  { set array(IFPRINT) 0 }

  if [StringSame $mode PRINT] {

    set array(SCALE_MODE) [GetValue $arrayname SCALE_MODE_1]
    set array(IFPRINT) 1
    if $ifmap { set array(INPUT_FILES) MAPIN } \
        else  { set array(INPUT_FILES) MSKIN }

  } elseif [StringSame $mode EXTEND ] {

    if $ifmap { set array(INPUT_FILES) MAPIN; set array(OUTPUT_FILES) MAPOUT } \
        else  { set array(INPUT_FILES) MSKIN; set array(OUTPUT_FILES) MSKOUT }

    switch [GetValue $arrayname EXTEND_FUNCTION] \
    USER {
      set array(IFXYZLIM) 1
    } MOLECULE {
      lappend array(INPUT_FILES) XYZIN
      set array(IFBORDER) 1
    } MATCH {
      lappend array(INPUT_FILES) MAPLIM
      set array(XYZLIM_MODE) MATCH
    } CELL {
      set array(XYZLIM_MODE) CELL
    } ASU {
       set array(XYZLIM_MODE) ASU
    }
  } elseif [StringSame $mode EDIT ] {

    set array(SCALE_MODE) [GetValue $arrayname SCALE_MODE_1]
    if $ifmap { set array(INPUT_FILES) MAPIN; set array(OUTPUT_FILES) MAPOUT } \
        else  { set array(INPUT_FILES) MSKIN; set array(OUTPUT_FILES) MSKOUT }

  } elseif [StringSame $mode INTERPOLATE ROTATE ] {

    set array(IFMAPROT) 1
    set array(INPUT_FILES) MAPIN; set array(OUTPUT_FILES) MAPOUT
    set array(IFXYZLIM) 1

  } elseif [StringSame $mode CREATE_MASK] {

    set array(IFMASK) 1
    if $array(IFPRINT) { set array(MAPMASK_OBJECT) MASK}
    set array(INPUT_FILES) MAPIN
    set array(OUTPUT_FILES) MSKOUT

  } elseif [StringSame $mode SCALE_BY_MASK] {

    set array(IFSCALE) 1
    set array(SCALE_MODE) [GetValue $arrayname SCALE_MODE_2]
    set array(INPUT_FILES) [list MAPIN MSKIN2]
    set array(OUTPUT_FILES) MAPOUT

  } elseif [StringSame $mode SOLVENT_FLATTEN] {

    set array(IFSOLVENT_FLAT) 1
    set array(INPUT_FILES) [list MAPIN MSKIN2]
    set array(OUTPUT_FILES) MAPOUT

  } elseif [StringSame $mode COMBINE ] {

    set array(IFCOMBINE) 1
    if $ifmap {
      set array(INPUT_FILES) [list MAPIN MAPIN2]
      set array(OUTPUT_FILES) MAPOUT
    } else {
      set array(INPUT_FILES) [list MSKIN MSKIN2]
      set array(OUTPUT_FILES) MSKOUT
    }

  }

  return 1
}

#-----------------------------------------------------------------------
proc maputils_input_files { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(IMAP1) 0
  set array(IMAP2) 0
  set array(IMASK1) 0
  set array(IMASK2) 0
  set array(OMAP) 0
  set array(OMASK) 0

  set mode [GetValue $arrayname MAPMASK_MODE]
  set object [GetValue  $arrayname MAPMASK_OBJECT]

  if [StringSame $mode EDIT EXTEND ] {
    if [StringSame $object MAP ] {
      set array(IMAP1) 1
      set array(OMAP) 1
    } else {
      set array(IMASK1) 1
      set array(OMASK) 1
   }
  } elseif [StringSame $mode INTERPOLATE ROTATE ] {
      set array(IMAP1) 1
      set array(OMAP) 1
  } elseif  [StringSame $mode PRINT ] {
    if [regexp MAP $object ] {
      set array(IMAP1) 1
    } else {
      set array(IMASK1) 1
    }
  }  elseif  [StringSame $mode CREATE_MASK ] {
     set array(IMAP1) 1
     set array(OMASK) 1
  }  elseif  [StringSame $mode SCALE_BY_MASK SOLVENT_FLATTEN ] {
     set array(IMAP1) 1
     set array(IMASK2) 1
     set array(OMAP) 1
  }  elseif  [StringSame $mode COMBINE ] {
     if [StringSame $object MAP ] {
       set array(IMAP1) 1
       set array(IMAP2) 1
       set array(OMAP) 1
     } else {
       set array(IMASK1) 1
       set array(IMASK2) 1
       set array(OMASK) 1
     }
  }
}

#-----------------------------------------------------------------------
proc mapmask_scale { arrayname } {
#-----------------------------------------------------------------------
# Draw the scale lines since will be used in several context

  CreateLine line \
    message "Scale density by scale factors or by setting mean&SD (SCALE FACTOR/SIGMA)" \
    help scale \
    widget IFSCALE \
    label "Scale density" \
    widget SCALE_MODE_1 \
    label "Multiply density by" \
    message " " \
    widget SCALE_FACTOR_1 \
    label "and add" \
    widget SCALE_FACTOR_2 \
    toggle_display SCALE_MODE_1 open FACTOR

  CreateLine line \
    message "Scale density by scale factors or by setting mean&SD (SCALE FACTOR/SIGMA)" \
    help scale \
    widget IFSCALE \
    label "Scale the map" \
    widget SCALE_MODE_1 \
    label "Scale density to have SD" \
    message " " \
    widget SCALE_SIGMA_1 \
    label "and mean" \
    widget SCALE_SIGMA_2 \
    toggle_display SCALE_MODE_1 hide FACTOR
}


#-----------------------------------------------------------------------
proc maputils_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Edit/Rotate Map & Mask" "Map Utilities" \
        [ list "Print File" \
		"Edit File" \
		"Extend File" \
		"Interpolate Map to Different Grid" \
		"Rotate Map" \
		"Create Mask from Map" \
		"Scale Map Using a Mask" \
		"Solvent Flatten a Map" \
		"Combine Maps/Masks"    \
		"Cell Parameters" ] ] == 0 } return

  SetProgramHelpFile mapmask

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Use mapmask to perform which function" \
    help keywords \
    widget MAPMASK_MODE \
	-command "maputils_input_files $arrayname" \
    toggle_display MAPMASK_MODE hide [list EDIT EXTEND PRINT COMBINE ]

  CreateLine line \
    message "Use mapmask to perform which function" \
    help keywords \
    widget MAPMASK_MODE \
	 -command "maputils_input_files $arrayname" \
    label "for a" \
    widget MAPMASK_OBJECT \
	 -command "maputils_input_files $arrayname" \
    label "file" \
    toggle_display MAPMASK_MODE open [list EDIT EXTEND PRINT ]

   CreateLine line \
    message "Use mapmask to perform which function" \
    help keywords \
    widget MAPMASK_MODE \
	 -command "maputils_input_files $arrayname" \
    label "for" \
    widget MAPMASK_OBJECT \
	 -command "maputils_input_files $arrayname" \
    label "files" \
    toggle_display MAPMASK_MODE open [list COMBINE ]

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input map file name (MAPIN)" \
      "Map in" \
       MAPIN DIR_MAPIN \
       -fileout MAPOUT DIR_MAPOUT _1  \
       -setfileparam space_group_number SPACE_GROUP \
       -setfileparam cell CELL \
       -setfileparam grid GRID \
       -setfileparam xyzlim XYZLIM \
       -toggle_display IMAP1 open 1

  CreateInputFileLine line \
      "Enter input map file name (MAPIN2)" \
      "Map in" \
       MAPIN2 DIR_MAPIN2 \
       -toggle_display IMAP2 open 1

  CreateInputFileLine line \
      "Enter input mask file name (MSKIN)" \
      "Mask in" \
       MSKIN DIR_MSKIN \
       -fileout MSKOUT DIR_MSKOUT _1 \
       -toggle_display IMASK1 open 1

  CreateInputFileLine line \
      "Enter input mask file name (MSKIN2)" \
      "Mask in" \
       MSKIN2 DIR_MSKIN2  \
       -toggle_display IMASK2 open 1

#  OpenSubFrame frame -toggle_display  MAPMASK_MODE open [list INTERPOLATE ROTATE ]
#
#  CreateLine line \
#    label "Read crystal parameters from MTZ file:" -italic
#
#  CreateInputFileLine line \
#        "Enter name of MTZ file containing cell and space group info" \
#        "MTZ file" \
#        MTZIN DIR_MTZIN \
#        -setfileparam space_group_name SPACE_GROUP \
#        -setfileparam cell CELL
#
#  CloseSubFrame


  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT \
       -toggle_display OMAP open 1

  CreateOutputFileLine line \
      "Enter mask file name or click file browser icon (MSKOUT)" \
      "Mask out" \
      MSKOUT DIR_MSKOUT \
       -toggle_display OMASK open 1

#--------------------------------------------------------------print
  OpenFolder 1  MAPMASK_MODE open PRINT hide

  CreateLine line \
    message "Print sections to log file (PRINT)" \
    help print \
    label "Print sections along" \
    widget PRINT_AXIS \
	-toggleon \
    label "axis from section" \
    widget PRINT_FIRST \
    label "to section" \
    widget PRINT_LAST \
    label "in steps of" \
    widget PRINT_STEP

  mapmask_scale $arrayname

#--------------------------------------------------------------edit
  OpenFolder 2  MAPMASK_MODE open EDIT hide

  CreateLine line \
    message "Change space group record in map/mask file (SYMMETRY)?" \
    help symmetry \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Change axis order in output file (AXIS)" \
    help axis \
    widget IFAXIS \
    label "Change axis order to" \
    widget AXIS

  mapmask_scale $arrayname
  
#--------------------------------------------------------------extend
  OpenFolder 3  MAPMASK_MODE open EXTEND hide

  CreateLine line \
    message "Extend map to asym unit, cover molecule or defined volume? (XYZLIM,BORDER)" \
    help extend \
    label "Extend map to" \
    widget EXTEND_FUNCTION 

  OpenSubFrame frame   -toggle_display EXTEND_FUNCTION open MOLECULE

  CreateInputFileLine line \
      "Enter name of file containing molecule coordinates (XYZIN)" \
      "PDB file" \
      XYZIN DIR_XYZIN

  CreateLine line \
    message "Extend map beyond the molecule for BORDER Angstrom" \
    help border \
    label "Border around molecule" \
    widget BORDER 

  CloseSubFrame

   OpenSubFrame frame   -toggle_display EXTEND_FUNCTION open MATCH

   CreateInputFileLine line \
      "Enter name of map file of required extent (MAPLIM)" \
      "Map file" \
      MAPLIM DIR_MAPLIM

  CloseSubFrame

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    label "Map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6 \
    toggle_display  EXTEND_FUNCTION open USER

  CreateLine line \
    message "Default: copy if output map within input; use symmetry if map extended (EXTEND)" \
    help extend \
    label "Extend map by" \
    widget EXTEND_MODE \
    label "and" \
    message "For map which does not contain asym unit set fixed density in unknown region (PAD)" \
    help pad \
    widget IFPAD \
    label "pad with value" \
    widget PADRHO \
    label "where density unknown"
    
#--------------------------------------------------------------create mask
  OpenFolder 6  MAPMASK_MODE open CREATE_MASK hide

  CreateLine line \
    message "Select criteria for mask boundary (MASK)" \
    help mask \
    label "Select mask for" \
    widget MASKMODE \
    message "Cutoff density value (MASK CUT mskcit)" \
    widget MASKCUT \
    toggle_display MASKMODE open CUT
 
  CreateLine line \
    message "Select criteria for mask boundary (MASK)" \
    help mask \
    label "Select mask for" \
    widget MASKMODE \
    message "Fraction of output mask that should be above threshold (MASK FRAC mskfrc )" \
    widget MASKFRAC \
    toggle_display MASKMODE open FRAC

  CreateLine line \
    message "Select criteria for mask boundary (MASK)" \
    help mask \
    label "Select mask for" \
    widget MASKMODE \
    message "Fraction of unit cell above threshold (MASK VOLUME mskvol)" \
    widget MASKVOLUME \
    toggle_display MASKMODE open VOLUME

  CreateLine line \
    message "Print sections to log file (PRINT)" \
    help print \
    widget IFPRINT \
	-toggleon \
    label "Print sections along" \
    widget PRINT_AXIS \
    label "axis from section" \
    widget PRINT_FIRST \
    label "to section" \
    widget PRINT_LAST \
    label "in steps of" \
    widget PRINT_STEP


#--------------------------------------------------------------scale by mask
  OpenFolder 7  MAPMASK_MODE open SCALE_BY_MASK hide

  CreateLine line \
    message "Choose how to use mask to scale density (SCALE MEAN/RATIO)" \
    help scale \
    label "Scale density by setting" \
    widget SCALE_MODE_2 \
    label "Mean density:  protein region" \
    widget SCALE_MEAN_1 \
    label "solvent region" \
    widget SCALE_MEAN_2 \
    toggle_display SCALE_MODE_2 open MEAN

  CreateLine line \
    message "Choose how to use mask to scale density (SCALE MEAN/RATIO)" \
    help scale \
    label "Scale density by setting" \
    widget SCALE_MODE_2 \
    label "Protein density: SD is" \
    widget SCALE_RATIO \
    label "of the mean" \
    toggle_display SCALE_MODE_2 open RATIO
    
#--------------------------------------------------------------solvent flatten
  OpenFolder 8  MAPMASK_MODE open SOLVENT_FLATTEN hide

  CreateLine line \
    message "Outside mask density shift multiplied by 1(flattening) or 2(flipping) (SOLV FLIP flipfac)" \
    help solv \
    label "Perform solvent" \
    widget SOLVENT_FLIP_FACTOR  \
    label  "in solvent region"

  CreateLine line \
    message "Attenuate negative density inside the mask (SOLV ATTN attn)" \
    help solv \
    label "Multiply negative density in protein region by" \
    widget SOLVENT_ATTN_FACTOR
  
#--------------------------------------------------------------combine
  OpenFolder 9  MAPMASK_MODE open COMBINE hide

  CreateLine line \
    message "Combine two maps/masks by addition/multiplication (COMBINE)" \
    help maps \
    label "Combine maps/masks by" \
    widget COMBINE_FUNCTION

#---------------------------------------------------------interpolate
  OpenFolder 4  MAPMASK_MODE open INTERPOLATE hide

  SetProgramHelpFile maprot

  CreateLine line \
    message "Choose new grid values (GRID)" \
    help grid \
    label "Grid x=" \
    widget GRID_1 \
    label "y=" \
    widget GRID_2 \
    label "z=" \
    widget GRID_3

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    label "Map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6


#---------------------------------------------------------rotate
  OpenFolder 5  MAPMASK_MODE open ROTATE hide

  CreateLine line \
    label "Rotation operator - Euler angles" -italic

   CreateLine ops_frame \
        message "Enter Averaging Operator (ROTA EULER & TRAN)" \
        label "alpha" \
        widget NCS_OP_ALPHA,1 \
        label "beta" \
        widget NCS_OP_BETA,1 \
        label "gamma" \
        widget NCS_OP_GAMMA,1 \
        label "xtran" \
        widget NCS_OP_XTRAN,1 \
        label "ytran" \
        widget NCS_OP_YTRAN,1 \
        label "ztran" \
        widget NCS_OP_ZTRAN,1 \

  CreateLine line \
    label "Create new map with.." -italic

  CreateLine line \
    message "Choose new grid values (GRID)" \
    help grid \
    label "Grid x=" \
    widget GRID_1 \
    label "y=" \
    widget GRID_2 \
    label "z=" \
    widget GRID_3

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    label "Map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6


#------------------------------------------------------------------cell params

  OpenFolder 10 MAPMASK_MODE open [list INTERPOLATE ROTATE ] hide

  CreateLine line \
    message "Space group (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    widget SPACE_GROUP


  CreateLine line \
    message "Cell dimensions (default from map file) (CELL)" \
    help "cell" \
    label "Set cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8



  maputils_input_files $arrayname
}

