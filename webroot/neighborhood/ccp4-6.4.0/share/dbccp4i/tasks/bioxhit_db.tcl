#
#     Copyright (C) 1999-2008  Peter Briggs, STFC
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id: bioxhit_db.tcl,v 1.2 2008/08/12 10:48:25 pjx Exp $
# ======================================================================
# bioxhit_db.tcl --
#
# Demonstration interface to a crystallographic knowledge base
# for heavy atom refinement, deliverable D5.2.16
#
# CCP4Interface 
#
# =======================================================================

# Import the db client API functions
global env
source [FileJoin [GetEnvPath DBCCP4I_TOP] ClientAPI dbClientAPI.tcl]

#-----------------------------------------------------------------
proc bioxhit_db_setup { typedefVar arrayname } {
#-----------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname  array

  # Check that the handler is available
  if { ! [::dbClientAPI::DbVerifyConnection] } {
      WarningMessage "No connection to database handler!"
      return 0
  }
  # Check that the SQLite database is supported
  if { ! [::dbClientAPI::DbSupported sqlite] } {
      WarningMessage "SQLite knowledge base not available!"
      return 0
  }
  # Acquire name of current project
  set project [GetCurrentProject]

  # Define internal parameters and types

  # Status of the SQLite db
  DefineVariable $arrayname HAS_SQLITE_DB       _logical               0

  # List of projects
  DefineVariable $arrayname PROJECTS_MENU       _list                  ""
  DefineVariable $arrayname PROJECTS_ALIAS      _list                  ""
  # List of available datasets
  set typedef(_bioxhit_db_projects) [list varmenu PROJECTS_MENU PROJECTS_ALIAS 10]

  # List of datasets for selection
  DefineVariable $arrayname N_DATASETS          _positiveint           0
  DefineVariable $arrayname DATASETS_MENU       _list                  ""
  DefineVariable $arrayname DATASETS_ALIAS      _list                  ""
  # List of available datasets
  set typedef(_bioxhit_db_datasets) [list varmenu DATASETS_MENU DATASETS_ALIAS 10]

  # List of HA substructures for selection
  DefineVariable $arrayname N_HA_SETS _positiveint 0
  DefineVariable $arrayname HA_SETS_MENU       _list                  ""
  DefineVariable $arrayname HA_SETS_ALIAS      _list                  ""
  # List of available substructures
  set typedef(_bioxhit_db_hasets) [list varmenu HA_SETS_MENU HA_SETS_ALIAS 10]

  # Print diagnostics to screen if interested
  ##bioxhit_db_printDatabaseInfo $project

  # Try to acquire the data from the knowledge base

  # Define parameters for widgets
  DefineVariable $arrayname PROJECT _bioxhit_db_projects "$project"
  # Datasets
  DefineVariable $arrayname SELECTED_DATASET _bioxhit_db_datasets ""
  DefineVariable $arrayname MTZFILE _MTZ_file ""
  DefineVariable $arrayname DIR_MTZFILE _default_dirs "Full path.."
  DefineVariable $arrayname FMEAN _mtz_label_f ""
  DefineVariable $arrayname SIGFMEAN _mtz_label_sig ""
  DefineVariable $arrayname DANO _mtz_label_d ""
  DefineVariable $arrayname SIGDANO _mtz_label_dw ""
  DefineVariable $arrayname XNAME _text ""
  DefineVariable $arrayname DNAME _text ""
  DefineVariable $arrayname CURRENT_HA _positiveint 0
  # HA substructures
  DefineVariable $arrayname SELECTED_HA_SET _bioxhit_db_hasets 0
  DefineVariable $arrayname HAFILE,0 _ha_file ""
  DefineVariable $arrayname DIR_HAFILE,0 _default_dirs ""
  DefineVariable $arrayname HA_ID,0 _positiveint 0
  # Add a new dataset
  DefineVariable $arrayname NEW_DATASET _logical 0
  DefineVariable $arrayname NEW_DATASET_NAME _text "" 
  DefineVariable $arrayname NEW_MTZFILE _MTZ_file ""
  DefineVariable $arrayname DIR_NEW_MTZFILE _default_dirs ""
  DefineVariable $arrayname NEW_FMEAN _mtz_label_f ""
  DefineVariable $arrayname NEW_SIGFMEAN _mtz_label_sig ""
  DefineVariable $arrayname NEW_DANO _mtz_label_d ""
  DefineVariable $arrayname NEW_SIGDANO _mtz_label_dw ""
  DefineVariable $arrayname NEW_XNAME _text ""
  DefineVariable $arrayname NEW_DNAME _text ""
  # Add a new HA file
  DefineVariable $arrayname NEW_HA _logical 0
  DefineVariable $arrayname NEW_HAFILE _ha_file ""
  DefineVariable $arrayname DIR_NEW_HAFILE _default_dirs ""

  # Initialise the project menu
  bioxhit_db_UpdateProjectMenu $arrayname

  # Initialise the status of any associated SQLite db
  bioxhit_db_setSQLiteStatus $arrayname

  # Initialise the dataset info
  bioxhit_db_UpdateDatasetMenu $arrayname
  if { $array(N_DATASETS) > 0 } {
      # Get the initial dataset
      set array(SELECTED_DATASET) [lindex $array(DATASETS_MENU) 0]
  }

  return 1
}

#-----------------------------------------------------------------
proc bioxhit_db_run { arrayname } {
#-----------------------------------------------------------------
    # This does nothing - the interface is effectively
    # interactive
    # This is left as a placeholder
    return 1
}

#-----------------------------------------------------------------
proc bioxhit_db_task_window { arrayname } {
#-----------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname  \
	"BIOXHIT Demo Knowledge Base" "Knowledge Base" \
	[ list "Dataset Details" \
	     "Heavy Atom Substructure Files"] \
	    -action_buttons { quit } ] == 0 } return

  set applybutton [button $array(WINDOW).buttons.save\
                -text "Apply HA Changes" \
                -relief raised  \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
		-command "bioxhit_db_apply $arrayname"]

  set array(_APPLY_BUTTON) $applybutton

#=PROTOCOL==============================================================

  OpenFolder protocol 

  # Title line is not required since we never actually run a job
  ##CreateTitleLine line TITLE

  CreateLine line \
      label "Demonstration interface to interact with example SQLite Knowledge Base" \
      -italic

  CreateLine line \
      label "Current project is" \
      widget PROJECT \
      -command "bioxhit_db_SelectProject $arrayname"

  # Frame for when SQLite db is available
  OpenSubFrame frame -toggle_display HAS_SQLITE_DB open 1

  CreateLine line \
      label "Selected dataset:" \
      widget SELECTED_DATASET \
      -command "bioxhit_db_SelectDataset $arrayname" \
      toggle_display N_DATASETS hide 0

  CreateLine line \
      label "No datasets found in the database" -italic \
      toggle_display N_DATASETS open 0

  # Frame to display for when the user wants to add new datasets
  OpenSubFrame frame -toggle_display NEW_DATASET open 0

  # Make a button to allow new datasets to be added
  CreateLine line \
      message "Add a new dataset to the database" \
      button "Add a new dataset" \
      -command "bioxhit_db_AddDataset $arrayname"

  CloseSubFrame

  OpenSubFrame frame -toggle_display NEW_DATASET open 1

  CreateLine line \
      label "Enter details for the new dataset and click Apply to add to the database" \
      -italic

  CreateLine line \
      label "Dataset Name" \
      widget NEW_DATASET_NAME -width 20

  CreateInputFileLine line \
      "Reflection data file" \
      "MTZ file" \
       NEW_MTZFILE  DIR_NEW_MTZFILE

  CreateLabinLine line \
      "Derivative amplitude (Fmean) and sigma (SIGFmean)" \
      NEW_MTZFILE "Fmean" NEW_FMEAN "" \
      -sigma "SigFmean" NEW_SIGFMEAN  {NULL}

  CreateLabinLine line \
      "Anomalous difference (Dano) and sigma (SIGDano)" \
      NEW_MTZFILE "Dano" NEW_DANO "" \
      -sigma "SigDano" NEW_SIGDANO  {NULL}

  CreateLine line \
      label "Crystal name" \
      widget NEW_XNAME \
      label "Dataset name" \
      widget NEW_DNAME

  # Make buttons to add the dataset, or cancel
  CreateLine line \
      message "Add a new dataset to the database" \
      button "Apply" \
      -command "bioxhit_db_AddDatasetApply $arrayname" \
      button "Cancel" \
      -command "bioxhit_db_AddDatasetCancel $arrayname"

  CloseSubFrame

  CloseSubFrame

  # Frame for when SQLite db is not available
  OpenSubFrame frame -toggle_display HAS_SQLITE_DB open 0

  CreateLine line \
      label "There is no SQLite knowledge database associated with this project"

  CloseSubFrame

#=FILES================================================================

  OpenFolder file

  # Nothing in here for now

#=======================================================================

  OpenFolder 1 HAS_SQLITE_DB open { 1 } hide

  CreateInputFileLine line \
      "Reflection data file" \
      "MTZ file" \
       MTZFILE  DIR_MTZFILE

  CreateLabinLine line \
      "Derivative amplitude (Fmean) and sigma (SIGFmean)" \
      MTZFILE "Fmean" FMEAN "" \
      -sigma "SigFmean" SIGFMEAN  {NULL}

  CreateLabinLine line \
      "Anomalous difference (Dano) and sigma (SIGDano)" \
      MTZFILE "Dano" DANO "" \
      -sigma "SigDano" SIGDANO  {NULL}

  CreateLine line \
      label "Crystal name" \
      widget XNAME \
      label "Dataset name" \
      widget DNAME

  CreateLine line \
      label "Current Heavy Atom Substructure file" \
      widget SELECTED_HA_SET -width 20 \
      -command "bioxhit_db_UpdateCurrentHA $arrayname"

  #=======================================================================

  OpenFolder 2 HAS_SQLITE_DB open { 1 } hide

  CreateLine line \
      label "Heavy atom substructures..." -italic \
      toggle_display N_HA_SETS hide 0

  CreateLine line \
      label "No heavy atom substructures currently associated with this dataset" \
      -italic \
      toggle_display N_HA_SETS open 0

  CreateExtendingFrame N_HA_SETS bioxhit_db_HAsets \
      "Available HA files associated with this dataset" \
      "Add HA file" \
      [list HAFILE DIR_HAFILE HA_ID] \
      -edit_proc bioxhit_db_EditHASets

  #=======================================================================

  # Initialise everything on startup
  bioxhit_db_LoadDataset $arrayname $array(SELECTED_DATASET)
}

#-----------------------------------------------------------------
proc bioxhit_db_setSQLiteStatus { arrayname } {
#-----------------------------------------------------------------
    # Check that the SQLite database is supported
    upvar #0 $arrayname array
    
    if { ! [::dbClientAPI::DbSupported sqlite] } {
	set array(HAS_SQLITE_DB) 0
	return
    }
    # Check whether the current project has an SQLite database
    set project [GetValue $arrayname PROJECT]
    if { ! [::dbClientAPI::HasSQLdb $project] } {
	set array(HAS_SQLITE_DB) 0
	return
    }
    # There is an SQLite db
    set array(HAS_SQLITE_DB) 1
}

#-----------------------------------------------------------------
proc bioxhit_db_EditHASets { arrayname n } {
#-----------------------------------------------------------------
    # Proceduere that is invoked when the user adds or
    # deletes a HA file from the window
    upvar #0 $arrayname array

    # Make the "apply" button visible
    bioxhit_db_showApplyButton $arrayname
}

#-----------------------------------------------------------------
proc bioxhit_db_HAsets { arrayname counter } {
#-----------------------------------------------------------------
    # Draw a line of the HA extending frame
    # This displays details of the available HA datasets
    CreateInputFileLine line \
      "Heavy Atom substructure data file (.ha format)" \
      "Substructure \#$counter" \
       HAFILE DIR_HAFILE
}

#-----------------------------------------------------------------
proc bioxhit_db_UpdateCurrentHA { arrayname } {
#-----------------------------------------------------------------
    # User changed the currently selected HA file
    # Update the database accordingly
    upvar #0 $arrayname array
    set project $array(PROJECT)
    set dataset $array(SELECTED_DATASET)
    set current_ha [GetValue $arrayname SELECTED_HA_SET]
    if { $current_ha == 0 } {
	set current_ha "None"
    }
    ::dbClientAPI::UpdateHAForDataset $project $dataset $current_ha
}

#-----------------------------------------------------------------
proc bioxhit_db_AddDataset { arrayname } {
#-----------------------------------------------------------------
    upvar #0 $arrayname array
    # Allow the user to add a new dataset to the database
    set array(NEW_DATASET) 1
}

#-----------------------------------------------------------------
proc bioxhit_db_AddDatasetApply { arrayname } {
#-----------------------------------------------------------------
    upvar #0 $arrayname array
    # Check the data entered by the user and add to the database
    # if it all checks out

    # Collect the data
    set project $array(PROJECT)
    set dataset [string trim $array(NEW_DATASET_NAME)]
    set mtzfile [GetFullFileName0 $arrayname NEW_MTZFILE]
    if { ![file isfile $mtzfile] } {
	WarningMessage "MTZ file doesn't exist, or isn't a file"
	return
    }
    if { $dataset == "" } {
	WarningMessage "The dataset name cannot be blank"
	return
    }
    set fmean $array(NEW_FMEAN)
    set sigfmean $array(NEW_SIGFMEAN)
    if { $fmean == "Unassigned" || $sigfmean == "Unassigned" } {
	WarningMessage "Both Fmean and sigFmean must be assigned"
	return
    }
    set dano $array(NEW_DANO)
    set sigdano $array(NEW_SIGDANO)
    if { $dano == "Unassigned" } {
	set dano ""
	set sigdano ""
    }
    if { $sigdano == "Unassigned" } {
	set sigdano ""
    }
    set xname $array(NEW_XNAME)
    set dname $array(NEW_DNAME)
    set dbCmd [list ::dbClientAPI::DefineDataset $project $dataset $mtzfile \
		  $fmean $sigfmean]
    if { $dano != "" && $sigdano != "" } {
	lappend dbCmd "-dano" $dano $sigdano
    }
    if { $xname != "" && $dname != "" } {
	lappend dbCmd "-mtz" $xname $dname
    }

    # Apply the command
    eval $dbCmd

    # Update the menu
    bioxhit_db_UpdateDatasetMenu $arrayname
    
    # Hide the add controls again
    set array(NEW_DATASET) 0
}

#-----------------------------------------------------------------
proc bioxhit_db_AddDatasetCancel { arrayname } {
#-----------------------------------------------------------------
    upvar #0 $arrayname array
    # Cancel the option to add a new dataset
    set array(NEW_DATASET) 0
}

#-----------------------------------------------------------------
proc bioxhit_db_showApplyButton { arrayname } {
#-----------------------------------------------------------------
    # Make the "apply" button visible
    upvar #0 $arrayname array
    set applybutton $array(_APPLY_BUTTON)
    pack $applybutton -side left -expand 1
}

#-----------------------------------------------------------------
proc bioxhit_db_hideApplyButton { arrayname } {
#-----------------------------------------------------------------
    # Hide the "apply" button
    upvar #0 $arrayname array
    set applybutton $array(_APPLY_BUTTON)
    pack forget $applybutton
}

#-----------------------------------------------------------------
proc bioxhit_db_UpdateProjectMenu { arrayname } {
#-----------------------------------------------------------------
    # Update the menu of projects
    upvar #0 $arrayname array

    set projects [::dbClientAPI::ListProjects]

    UpdateVariableMenu $arrayname initialise 0 \
	PROJECTS_MENU $projects \
	PROJECTS_ALIAS $projects \
	"bioxhit_db_SelectProject $arrayname"
}

#-----------------------------------------------------------------
proc bioxhit_db_SelectProject { arrayname } {
#-----------------------------------------------------------------
    # User switched project so update the window
    upvar #0 $arrayname array

    # Switch projects
    DbChangeFile $array(PROJECT) 
    # Status of SQLite db
    bioxhit_db_setSQLiteStatus $arrayname
    # Update the list of datasets for this project
    bioxhit_db_UpdateDatasetMenu $arrayname
    # Reset the selected dataset
    if { [llength $array(DATASETS_MENU)] > 0 } {
	set selected_dataset [lindex $array(DATASETS_MENU) 0]
    } else {
	set selected_dataset {}
    }
    set array(SELECTED_DATASET) $selected_dataset
    # Load the dataset
    bioxhit_db_LoadDataset $arrayname $selected_dataset 
}

#-----------------------------------------------------------------
proc bioxhit_db_UpdateDatasetMenu { arrayname } {
#-----------------------------------------------------------------
    # Update the menu of datasets and associated data
    upvar #0 $arrayname array
    
    set project $array(PROJECT)
    set datasets [::dbClientAPI::ListDatasets $project]

    UpdateVariableMenu $arrayname initialise 0 \
	DATASETS_MENU $datasets \
	DATASETS_ALIAS $datasets \
	"bioxhit_db_SelectDataset $arrayname"

    set array(N_DATASETS) [llength $datasets]
}

#-----------------------------------------------------------------
proc bioxhit_db_LoadDataset { arrayname dataset } {
#-----------------------------------------------------------------
    # Load the data for a specific dataset
    upvar #0 $arrayname array

    set project $array(PROJECT)

    # Dataset information
    set array(MTZFILE) [::dbClientAPI::GetDatasetAttribute $project \
			    $dataset "MTZfileName"]
    set array(DIR_MTZFILE) "Full path.."
    set array(FMEAN) [::dbClientAPI::GetDatasetAttribute $project \
			  $dataset "Fmean"]
    set array(SIGFMEAN) [::dbClientAPI::GetDatasetAttribute $project \
			     $dataset "SigFmean"]
    set array(DANO) [::dbClientAPI::GetDatasetAttribute $project \
			 $dataset "Dano"]
    set array(SIGDANO) [::dbClientAPI::GetDatasetAttribute $project \
			    $dataset "SigDano"]
    set array(XNAME) [::dbClientAPI::GetDatasetAttribute $project \
			  $dataset "MTZCrystalName"]
    set array(DNAME) [::dbClientAPI::GetDatasetAttribute $project \
			  $dataset "MTZDatasetName"]

    bioxhit_db_UpdateHASets $arrayname

    # Update the current dataset
    set array(SELECTED_DATASET) $dataset

    # Hide the apply button
    bioxhit_db_hideApplyButton $arrayname
}

#-----------------------------------------------------------------
proc bioxhit_db_UpdateHASets { arrayname } {
#-----------------------------------------------------------------
    # Load the data for a specific dataset
    upvar #0 $arrayname array

    set project $array(PROJECT)
    set dataset [GetValue $arrayname SELECTED_DATASET]

    # Heavy atom substructures
    set n_ha_sets 0
    set ha_sets_menu {}
    set ha_sets_alias {}
    set ha_sets [::dbClientAPI::ListDatasetHASubstructures $project $dataset]
    set current_ha [::dbClientAPI::GetDatasetAttribute $project \
			$dataset "CurrentHA"]

    # Populate lists and menus
    set array(SELECTED_HA_SET) "None"
    if { [llength $ha_sets] > 0 } {
	# Set up details of the HA substructures
	foreach ha_set $ha_sets {
	    set ha_file [::dbClientAPI::GetHAAttribute $project $ha_set "HAfileName"]
	    lappend ha_sets_menu [file tail $ha_file]
	    lappend ha_sets_alias $ha_set
	    incr n_ha_sets
	    set array(HAFILE,$n_ha_sets) $ha_file
	    set array(HA_ID,$n_ha_sets) $ha_set
	    # Set the currently selected HA set
	    if { $current_ha == $ha_set } {
		set array(SELECTED_HA_SET) [file tail $ha_file]
	    }
	}
    }
    # Add None to the end of the HA menu
    lappend ha_sets_menu "None" 
    lappend ha_sets_alias 0
    # Update the menu - this will automatically update everywhere that the menu
    # is displayed in the task interface
    UpdateVariableMenu $arrayname initialise 0 \
	HA_SETS_MENU $ha_sets_menu \
	HA_SETS_ALIAS $ha_sets_alias \
	"bioxhit_db_UpdateCurrentHA $arrayname"

    # Update the HA extending frame display
    set increment [expr $n_ha_sets - $array(N_HA_SETS)]
    UpdateExtendingFrame bioxhit_db_HAsets 0 $arrayname $increment
}

#-----------------------------------------------------------------
proc bioxhit_db_SelectDataset { arrayname } {
#-----------------------------------------------------------------
    # Load up the dataset selected by the user
    upvar #0 $arrayname array
    set dataset $array(SELECTED_DATASET)
    bioxhit_db_LoadDataset $arrayname $dataset
}

#-----------------------------------------------------------------
proc bioxhit_db_apply { arrayname } {
#-----------------------------------------------------------------
    # Try to apply changes to the HA details
    # made by the user
    upvar #0 $arrayname array

    set project $array(PROJECT)
    set dataset $array(SELECTED_DATASET)
    set redraw 0

    # Try to work out what happened
    # Either the user added or deleted a file
    set ha_files {}
    set n $array(N_HA_SETS)
    for { set i 1 } { $i <= $n } { incr i } {
	if { $array(HAFILE,$i) != "" } {
	    lappend ha_files [GetFullFileName0 $arrayname HAFILE,$i]
	}
    }

    # Files currently in the db
    set db_files {}
    foreach id [::dbClientAPI::ListDatasetHASubstructures $project $dataset] {
	lappend db_files [::dbClientAPI::GetHAAttribute $project $id HAfileName]
    }
    
    # Deleted files
    foreach ha $db_files {
	if { [lsearch $ha_files $ha] < 0 } {
	    # Cannot delete HA files once they are in the db
	    WarningMessage \
"Sorry, heavy atom files cannot be removed from
the database once they have been added. 

$ha

is still in the database."
	    # Schedule an update
	    set redraw 1
	}
    }
    # Added files
    foreach ha $ha_files {
	if { [lsearch $db_files $ha] < 0 } {
	    # Add it to the database
	    ::dbClientAPI::NewHASubstructure $project $ha $dataset
	}
    }
    
    # Update the ha display if required
    if { $redraw } {
	bioxhit_db_UpdateHASets $arrayname
    }
    
    # Hide the apply button again
    bioxhit_db_hideApplyButton $arrayname
}

#-----------------------------------------------------------------
proc bioxhit_db_printDatabaseInfo { project } {
#-----------------------------------------------------------------
    # This is a diagnostic function which prints out info
    # from the database to the screen
    # it is not required during normal running of this interface
    # but may be instructive to examine later
    set datasets [::dbClientAPI::ListDatasets $project]
    if { [llength $datasets] == 0 } {
	puts "Datasets: none found"
    } else {
	puts "Datasets:"
	foreach dataset $datasets {
	    puts "\t$dataset"
	    # Print out the attributes
	    set attributes [list MTZfileProject \
				MTZfileName \
				Fmean \
				SigFmean \
				Dano \
				SigDano \
				MTZCrystalName \
				MTZDatasetName \
				CurrentHA]
	    foreach attribute $attributes {
		set value \
		    [::dbClientAPI::GetDatasetAttribute $project $dataset $attribute]
		puts "\t\t$attribute: $value"
	    }
	    # Associated HA substructures?
	    set ha_sets [::dbClientAPI::ListDatasetHASubstructures $project \
			     $dataset]
	    if { [llength $ha_sets] == 0 } {
		puts "\tNo heavy atom sets associated with this substructure"
	    } else {
		set current_ha [::dbClientAPI::GetDatasetAttribute $project $dataset \
				    CurrentHA]
		puts "\tAssociated heavy atom sets:"
		foreach ha_set $ha_sets {
		    if { $ha_set == $current_ha } {
			puts -nonewline "**"
		    }
		    puts "\tHA substructure $ha_set: "
		    set attributes [list HAfileProject \
					HAfileName \
					JobNumber]
		    foreach attribute $attributes {
			set value \
			    [::dbClientAPI::GetHAAttribute $project \
				 $ha_set $attribute]
			puts "\t\t$attribute: $value"
		    }
		}
	    }
	}
    }
}