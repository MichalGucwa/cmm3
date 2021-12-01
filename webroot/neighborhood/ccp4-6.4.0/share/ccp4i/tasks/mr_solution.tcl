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
# mr_solution.tcl --
#
# CCP4Interface 
#
# =======================================================================

source [SearchPath TOP utils amore_utils.tcl]

#-----------------------------------------------------------------
proc mr_solution_setup { typedefVar arrayname } {
#-----------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  set typedef(_mr_solution_contact) { menu { CA all } }

# Load the MR database or open the window
  source [SearchPath TOP tasks mr_utils.tcl ]
  mr_open_database

  return 1
}

#---------------------------------------------------------------------
proc mr_solution_xyzshft { arrayname counter } {
#---------------------------------------------------------------------

#  puts "mr_solution_xyzshft counter $counter"

   CreateLine line \
     message "Names of models will be extracted from solution file" \
     label "Model $counter" \
     widget MODEL

  CreateInputFileLine line \
     "File name will be extracted from database" \
     "Coords file" \
      XYZSHFT DIR_XYZSHFT
}


#-------------------------------------------------------------------
proc mr_solution_read_solfil { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  if { ![ReadFile [GetFullFileName0 $arrayname SOLFIL] text ] } {
    WarningMessage "Could not open solution file [GetFullFileName0 $arrayname SOLFIL]"
    return 
  }

  set nlines 0
  set split_text [split $text \n]
  foreach line [lrange $split_text 0 [expr [llength $split_text] -2]] {
    if { [string range $line 0 0] != "#" } { incr nlines }
  }

  set model_list [ExtractFromText $text "SCRIPT MR" 0 all] 
  if { $model_list == "" } {
    WarningMessage "Could not find solutions from Amore fitting function in file
[GetFullFileName0 $arrayname SOLFIL]"
    return
  }
  set model_list [lrange $model_list 4 end ]

  set nm 0
  foreach model $model_list {
    incr nm; set array(MODEL,$nm) $model
    set im [mr_get_model_number $model]
    set array(XYZSHFT,$nm) $mr_database(XYZSHFT,$im)
    set array(DIR_XYZSHFT,$nm) $mr_database(DIR_XYZSHFT,$im)
  }
  set array(N_MODELS) $nm

  set array(N_SOLUTIONS) [expr $nlines / $nm]
#  puts "nlines $nlines nm $nm N_SOLUTIONS $array(N_SOLUTIONS)"
#  puts "XYZSHFT $array(XYZSHFT,$nm)"

# Try to extract the symmetry and cell from the solution file header
  set symmetry [lindex [amore_extract_mr_header \
	  [GetFullFileName0 $arrayname SOLFIL] SYMMETRY] 0]
  if { $symmetry != "" } {
    set array(SPACE_GROUP) $symmetry
  }
  set cell [lindex [amore_extract_mr_header \
	  [GetFullFileName0 $arrayname SOLFIL] CELL] 0]
  if { [llength $cell] == 6 } {
    set i 0
    foreach item [list CELL_1 CELL_2 CELL_3 CELL_4 CELL_5 CELL_6] {
      set array($item) [lindex $cell $i]
      incr i
    }
  }

# Redraw the task window to update the view
  set w $array(WINDOW)
  RerenderTask $w $arrayname mr_solution
}

#-------------------------------------------------------------------
proc mr_solution_run { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  set array(AMORE_DATABASE) [FileJoin [GetDbDirPath] mr_database.def ]

  set array(INPUT_FILES) SOLFIL
  for { set nm 1 } { $nm <= $array(N_MODELS) } { incr nm }  {
    append array(INPUT_FILES) " XYZSHFT,$nm"
  }

  set title "Build model from solutions"
  for { set n 1 } { $n <=  $array(N_MODELS) } { incr n } {
    append title " [file tail $array(XYZSHFT,$n)]"
  }
  SetDefaultTitle $arrayname $title

  return 1
}

#---------------------------------------------------------------------
proc mr_solution_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"MR_solution - Build AMoRe Output Model" "MR Solution" \
         [list "Cell parameters for coordinate file" ] \
	] == 0 } return

  mr_model_menu $arrayname
  SetProgramHelpFile "amore"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Run Distang to identify bad contacts within asymmetric unit and between" \
    widget IFBADCONTACTS \
    label "List bad contacts between" \
    widget CONTACT_MODE \
    label "atoms within and between asymmetric units" 

  OpenFolder file 

  CreateInputFileLine line \
     "Enter name of solution file from Amore fitting function" \
     "Fitting solution file" \
      SOLFIL DIR_SOLFIL \
	-command "mr_solution_read_solfil $arrayname"

  CreateLine line \
    label "Apply the solution transformations to the origin shifted coordinates from:" -italic

  CreateExtendingFrame N_MODELS mr_solution_xyzshft \
    "Select models to use" \
    "Add model" \
    [ list MODEL XYZSHFT DIR_XYZSHFT ] \
	-noaddline

  CreateLine line \
    label "Enter root file name for output model coordinates" \
	-italic

   CreateOutputFileLine line \
     "If >1 solution then multiple output files created with _n appended to name" \
     "Output coords" \
     XYZOUT DIR_XYZOUT

  update_extendingframe mr_solution_xyzshft 0 $arrayname N_MODELS \
                0 $array(N_MODELS) 0

#===========================================================cell parameters

  OpenFolder 1 closed

  SetProgramHelpFile pdbset

  CreateLine line \
     widget USE_HKLIN \
     label "Extract symmetry and cell info from MTZ file"

 CreateInputFileLine line \
     "Extract space group & symmetry info from MTZ file" \
     "MTZ in" \
      HKLIN DIR_HKLIN \
 	-setfileparam cell CELL \
        -setfileparam space_group_name SPACE_GROUP \
	-toggle_display USE_HKLIN open { 1 }

  CreateLine line \
    message "Space group (extracted from solution file unless an MTZ file is specified)" \
    label "Set space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (extracted from solution file unless an MTZ file is specified)" \
    help "cell" \
    widget CELL \
	-toggleon \
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


}

