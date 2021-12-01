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
# mr_map.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-------------------------------------------------------------------
proc mr_map_setup { typedefVar arrayname } {
#-------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 mr_database_[GetCurrentProject] mr_database

  source [SearchPath TOP tasks mr_utils.tcl ]

  DefineMenu _mr_map_mode [list "structure factors" \
				"Es" ] \
			  [ list SFMAP EMAP]
  set typedef(_mr_map_model)  { varmenu MODEL_LIST MODEL_ALIAS_LIST 20 }

# Load the MR database or open the window
  mr_open_database

  return 1
}

#-------------------------------------------------------------------
proc mr_map_run { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  set model [mr_get_model_number $array(MODEL)]
  if { $model > 0 } {
    set mr_database(XYZIN,$model) $array(XYZIN)
    set mr_database(DIR_XYZIN,$model) $array(DIR_XYZIN)
    set mr_database(HKLIN,$model) $array(HKLOUT)
    set mr_database(DIR_HKLIN,$model) $array(DIR_HKLOUT)
    set mr_database(XYZSHFT,$model) $array(XYZSHFT)
    set mr_database(DIR_XYZSHFT,$model) $array(DIR_XYZSHFT)
  }

  set array(MODEL_TITLE) $mr_database(MODEL_TITLE,$model)

  set array(INPUT_FILES) XYZIN
  set array(OUTPUT_FILES) HKLOUT
  if $array(AMORE_OPT_COORD) {append array(OUTPUT_FILES) " " XYZSHFT }

  set array(AMORE_DATABASE) [FileJoin [GetDbDirPath] mr_database.def ]

  SetDefaultTitle $arrayname "Generate $array(MODE) map for $array(MODEL)"

  return 1
}

#-------------------------------------------------------------------
proc mr_map_update_xyzin {arrayname } {
#-------------------------------------------------------------------
   upvar #0 $arrayname array
   upvar #0 mr_database_[GetCurrentProject] mr_database

   if { ![ElementExists $arrayname MODEL] || $array(MODEL) == {} } { return }
   set model [mr_get_model_number $array(MODEL)] 
   if { $model > 0 } {
     set array(XYZIN) $mr_database(XYZIN,$model)
     set array(DIR_XYZIN) $mr_database(DIR_XYZIN,$model)
     set array(HKLOUT) $mr_database(HKLIN,$model)
     set array(DIR_HKLOUT) $mr_database(DIR_HKLIN,$model)
     set array(XYZSHFT) $mr_database(XYZSHFT,$model)
     set array(DIR_XYZSHFT) $mr_database(DIR_XYZSHFT,$model)
     CheckFileInput $arrayname XYZIN read
     CheckFileInput $arrayname HKLOUT save
     CheckFileInput $arrayname XYZSHFT save
   }
}

#-------------------------------------------------------------------
proc mr_map_set_resolution_range { arrayname } {
#-------------------------------------------------------------------
# Amore sometimes objects if resolution range for model appears not
# to cover the range of the exprl data - so extend it just a smidgeon 
  upvar #0 $arrayname array

  set array(RESOLUTION_MIN) [expr $array(CRYSTAL_RESOLUTION_MIN) + 1.0 ]
  set array(RESOLUTION_MAX) [expr $array(CRYSTAL_RESOLUTION_MAX) - 0.2 ]
}


#---------------------------------------------------------------------
proc mr_map_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"MR SFs - Create Input SFs for MR from Model" "MR SFs" \
        [ list "Parameters" ] \
	] == 0 } return

  mr_copy_memory mr_database $arrayname
  mr_model_menu $arrayname

  SetProgramHelpFile sfall

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    message "Open the MR Model Database window" \
    button "Open MR Model Database window" \
	-command "RunTask mr_database"

  pack forget $line.b1
  pack $line.b1 -side right


  CreateTitleLine line TITLE

  CreateLine line \
    message "Run AMoRe table function to move coords to origin" \
    widget AMORE_OPT_COORD \
    label "Move model to optimised coordinates before creating map"

  CreateLine line \
    message "Choose type of map to generate" \
    label "Generate MTZ file with" \
    widget MODE \
    label "for model" \
    message "Select model from those listed in the MR Model Database" \
    widget MODEL \
	-command "mr_map_update_xyzin $arrayname"

#  CreateLine line \
#    widget UPDATE_DATABASE \
#    label "Update MR database with derived transformation"

#  CreateLine line \
#    widget AMORE_TABLE \
#    label "Run AMoRe to create table file using SFs/Es as input"

#---------------------------------------------------------------files
  OpenFolder file

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
      "Coords in" XYZIN DIR_XYZIN \
        -fileout HKLOUT DIR_HKLOUT _MR_trial \
        -fileout SF_TABLE DIR_SF_TABLE _MR_trial

  CreateOutputFileLine line \
        "Optimised coords (XYZSHFT)" \
        "Optimised coords" XYZSHFT DIR_XYZSHFT

  CreateOutputFileLine line \
        "Output MTZ file (HKLOUT)" \
        "MTZ out " HKLOUT DIR_HKLOUT

  CreateLaboutLine line \
     "Enter names for model amplitude and phases" \
        HKLOUT "Fcalc" FC \
        -sigma "PHICalc"  PHIC

  CreateLaboutLine line \
     "Enter names for model amplitude and phases" \
        HKLOUT "Ecalc" E \
	-toggle_display MODE open EMAP

#  CreateOutputFileLine line \
#        "Output AMoRe SF table file" \
#        "SF table file" SF_TABLE DIR_SF_TABLE \
# 	-toggle_display AMORE_TABLE open 1

  CreateLine line \
    label "Use space group and cell parameters extracted from MTZ file:" \
	-italic

  CreateInputFileLine line \
      "MTZ file containing correct cell & space group" \
      "Read MTZ" HKLIN DIR_HKLIN \
        -setfileparam cell CRYSTAL_CELL \
        -setfileparam resolution_min CRYSTAL_RESOLUTION_MIN \
        -setfileparam resolution_max CRYSTAL_RESOLUTION_MAX \
        -setfileparam space_group_name SYMMETRY \
	-command "mr_map_set_resolution_range $arrayname"

# Update the xyzin after the widget is draw (otherwise problems!)
  mr_map_update_xyzin $arrayname

#------------------------------------------------------------------------
  OpenFolder 1

   CreateLine line \
    label "Generate SFs for resolution range" \
    widget RESOLUTION_MIN \
    label "to" \
    widget RESOLUTION_MAX

  CreateLine line \
    label "Space group" \
    widget SYMMETRY

  CreateLine line \
    label "Cell" \
    widget CRYSTAL_CELL_1 \
    widget CRYSTAL_CELL_2 \
    widget CRYSTAL_CELL_3 \
    widget CRYSTAL_CELL_4 \
    widget CRYSTAL_CELL_5 \
    widget CRYSTAL_CELL_6
}

