#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#==================================================================
# MR utilities - used by all (or most) task interfaces in the 
# MR module
#==================================================================

#-------------------------------------------------------------------
proc  mr_model_menu { arrayname { nmodelsIn {} } } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  if { $nmodelsIn == "" } {
    set nmodels $mr_database(N_MODELS)
  } else {
    set nmodels  $nmodelsIn
  }

#  puts "mr_model_menu nmodels $nmodels"

  set model_list ""
  set model_alias_list ""
  if { $nmodels > 0 } {
  for { set n 1 } { $n <= $nmodels } { incr n } {
    lappend model_list "$mr_database(MODEL_TITLE,$n)"
    lappend model_alias_list $n
  } }

   UpdateVariableMenu $arrayname initialise $nmodels \
        MODEL_LIST $model_list \
        MODEL_ALIAS_LIST $model_list

# Beware if this is first call to mr_model_menu the array
# might not be initialised yet so MODEL might not be defined

  if [ElementExists $arrayname MODEL] {
    if { $array(MODEL) == "" && $nmodels == 1 } {
      set array(MODEL) "$mr_database(MODEL_TITLE,1)"
    }
  }

}

#-----------------------------------------------------------------------------
proc mr_get_model_number { name  } {
#-----------------------------------------------------------------------------
  upvar #0 mr_database_[GetCurrentProject] mr_database
  if { $mr_database(N_MODELS) <= 0 } { return 0 }
  for { set nm 1 } { $nm <= $mr_database(N_MODELS) } { incr nm } {
    if [StringSame $name $mr_database(MODEL_TITLE,$nm) ] {
      return $nm
    }
  }
  return 0
}
#-------------------------------------------------------------------------
proc mr_copy_memory { mr_databaseVar arrayname } {
#-------------------------------------------------------------------------
  upvar #0 mr_database_[GetCurrentProject] mr_database
  upvar #0 $arrayname array

  foreach var [list SORTING_NR TABLING_MI TABLING_MR TABLING_MC     \
	HKLTABLING_MC  ROTING_MI  ROTING_MR ROTING_MC ROTING_MD TRAING_NR      \
	TRAING_MEQ TRAING_MRT TRAING_MT TRAING_MR FITING_MEQ FITING_MT \
	FITING_NR  FITING_NP   ] {
    if { ![ElementExists $arrayname $var] || $array($var) == "" } { 
      set array($var) $mr_database($var) }
  }
}


#-----------------------------------------------------------------
proc mr_block_database { block } {
#-----------------------------------------------------------------
  upvar #0 mr_database_[GetCurrentProject] mr_database
  global mr_database_window
# prcedure is invoked by send command from a running script 
# which is about to update the database

# save the database and block the user from editing it until 
# the 'mr_block_database 0' command

  if $block {

    if [array exists mr_database] { 

      SaveArray mr_database [FileJoin [GetDbDirPath] mr_database.def] mr_database

      set w $mr_database(WINDOW)
      if [winfo exists $w] { 
        PleaseWait "Updating database from running job.."
        set mr_database_window 1
        wm $w withdraw 
      } else { 
        set mr_database_window 0
      }
    } else {
      set mr_database_window 0
    }

  } else { 

     InitialiseArray [FileJoin [GetDbDirPath] mr_database.def] \
	mr_database mr_database

     if $mr_database_window  { 
        PleaseWait ""
        wm deiconify $w
     }
  }
} 

#--------------------------------------------------------------------------
proc mr_open_database {} {
#--------------------------------------------------------------------------
# Called from amore/mr_map/mr_solution setup procedure 
# load the database and open the database window if there are
# currently no models defined

  upvar #0 mr_database_[GetCurrentProject] mr_database
  
  # Initialise parameters
  if { ![array exists mr_database] } {
    InitialiseArray  [SearchPath TOP tasks mr_database.def ] \
        mr_database_[GetCurrentProject] mr_database
  }
  # Always reload the parameters from the file when opening the db
  set db  [FileJoin [GetDbDirPath] mr_database.def]
  if [file exists $db] {
      InitialiseArray $db mr_database_[GetCurrentProject] mr_database
  }

  # Open the MR database window if the db is empty
  if { ( $mr_database(N_MODELS) <= 0 ||
       ($mr_database(N_MODELS) == 1 && $mr_database(MODEL_TITLE,1) == "") )
       && ( ![ElementExists mr_database WINDOW] ||
            ![winfo exists $mr_database(WINDOW)] ) } {
     RunTask mr_database 
  }

}

#--------------------------------------------------------------------------
proc DrawMemoryWidgets { } {
#--------------------------------------------------------------------------

  CreateLine line \
    label "Tabling memory MR" \
    widget TABLING_MR -width 10 \
    label "MI" \
    widget TABLING_MI -width 10 \
    label "MC" \
    widget TABLING_MC -width 10

  CreateLine line \
    label "HKL Tabling memory MC" \
    widget HKLTABLING_MC -width 10

  CreateLine line \
    label "Sorting memory NR" \
    widget SORTING_NR -width 10

  CreateLine line \
    label "Roting memory MR" \
    widget ROTING_MR -width 10 \
    label "MI" \
    widget ROTING_MI -width 10 \
    label "MC" \
    widget ROTING_MC -width 10 \
    label "MD" \
    widget ROTING_MD -width 10

  CreateLine line \
    label "Traing memory MR" \
    widget TRAING_MR -width 10 \
    label "MT" \
    widget TRAING_MT -width 10 \
    label "MEQ" \
    widget TRAING_MEQ -width 10 \
    label "MRT" \
    widget TRAING_MRT -width 10 \
    label "NR" \
    widget TRAING_NR -width 10 \

  CreateLine line \
    label "Fiting memory NR" \
    widget FITING_NR -width 10 \
    label "NP" \
    widget FITING_NP -width 10 \
    label "MT" \
    widget FITING_MT -width 10 \
    label "MEQ" \
    widget FITING_MEQ -width 10

}

#-----------------------------------------------------------------------------
proc clear_mr_db { } {
#-----------------------------------------------------------------------------
  upvar #0 amore_[GetCurrentProject] amore
  upvar #0 mr_database_[GetCurrentProject] mr_database

  if { ![array exists amore] && ![array exists mr_database] } { return }

  WarningMessage "Closing existing AMoRe database when you change database"

  if { [array exists amore] } {
    if { [ElementExists amore WINDOW] } { DeleteTaskWindow $amore(WINDOW) amore amore }
    unset amore
  }

  if { [array exists mr_database] } {
    if { [ElementExists mr_database WINDOW] } {
	DeleteTaskWindow $mr_database(WINDOW) mr_database mr_database }
    unset mr_database
  }

}
