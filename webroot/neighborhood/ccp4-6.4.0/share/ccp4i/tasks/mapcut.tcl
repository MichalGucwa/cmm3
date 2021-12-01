# ======================================================================
# mapcut.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------------
proc mapcut_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  DefineMenu _mapcut_mapsrc	[ list MTZ map ] \
				[ list MTZ MAP ]
  DefineMenu _mapcut_msksrc	[ list PDB mask ] \
				[ list PDB MSK ]
  DefineMenu _mapcut_mapdst	[ list MTZ map ] \
				[ list MTZ MAP ]
  return 1
}


#---------------------------------------------------------------------
proc mapcut_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Map cutting to prepare density for MR" "Mapcut" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cmapcut"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      message "Set input data sources" \
      label "Read density from" \
      widget MAPSRC \
      label "file and cut it using mask from" \
      widget MSKSRC \
      label "file."

  CreateLine line \
      message "Set output data sources" \
      label "Write density to" \
      widget MAPDST \
      label "file."

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Input electron density to be cut:" -italic

  CreateInputFileLine line \
      "Enter input reflection file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_mapcut" \
       -toggle_display MAPSRC open MTZ

  CreateLabinLine line \
      "Choose F/phi" \
      HKLIN    "F"   FMAP       [list FWT ] \
      -sigma   "PHI" PHIMAP     [list PHWT] \
       -toggle_display MAPSRC open MTZ

  CreateInputFileLine line \
      "Enter input map file name" \
      "MAP in" \
      MAPIN DIR_MAPIN \
      -fileout HKLOUT DIR_HKLOUT "_mapcut" \
       -toggle_display MAPSRC open MAP

  CreateLine line \
      label "Input mask to define cut region:" -italic

  CreateInputFileLine line \
      "Enter input coordinate file to determine mask." \
      "PDB in" \
      XYZIN DIR_XYZIN \
       -toggle_display MSKSRC open PDB

  CreateInputFileLine line \
      "Enter input mask file name" \
      "MASK in" \
      MSKIN DIR_MSKIN \
       -toggle_display MSKSRC open MSK

  CreateLine line \
      label "Output cut electron density:" -italic

  CreateOutputFileLine line \
      "Enter output mtz file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT \
       -toggle_display MAPDST open MTZ

  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT \
       -toggle_display MAPDST open MAP

#-----------------------------------------------------

  OpenFolder 1 open

  CreateLine line \
      message "How many times bigger than the cut region should the output cell be?" \
      label "Multiplier for output cell:" \
      widget GRDMUL -width 4

  CreateLine line \
      message "How much space should be included in the mask around each atom" \
      label "Radius for mask around atoms:" \
      widget MSKRAD -width 4

  CreateLine line \
      message "Padding by one reciprocal cell may improve MR results" \
      widget DOPAD -width 4 \
      label "Pad resolution by one reflection to help MR."

}
