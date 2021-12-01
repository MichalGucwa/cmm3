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
# scala.tcl --
#
# Template for task interface
#
# CCP4Interface 
#
# =======================================================================

#--------------------------------------------------------------------
proc scala_setup { typedefname arrayname } { 
#--------------------------------------------------------------------

  upvar #0 $typedefname typedef


set typedef(_scala_sort)	{ menu {	"ascending"
						"descending" } 
					{	"ASCEND" 
						"DESCEND" } }

set typedef(_scala_run_xclude)	{ menu {	"Include" \
						"Exclude" } 
					{	"INCLUDE" \
						"EXCLUDE" }}
set typedef(_scala_run_mode) 	{ menu {	"all" \
						"batch range" \
						"batch list" \
                                                "dataset" \
						"crystal number range" \
						"crystal number list" \
						"resolution range" \
						"rotation range" \
						"SD range" \
						"absolute value >" 
						"detector area" }
					{	"ALL" \
						"BATCHRANGE" \
						"BATCHLIST" \
                                                "DATASET" \
						"XTALRANGE" \
						"XTALLIST" \
						"RESOLUTION" \
						"RANGE" \
						"SDRANGE" \
						"ABSVALUE" 
						"RECTANGLE" } }

set typedef(_scala_scales_run)	{ varmenu RUN_MENU RUN_MENU_ALIAS 8} 

set typedef(_scala_run)		{ varmenu RUN_MENU_0 RUN_MENU_0_ALIAS 8} 

set typedef(_scala_scales_mode)  { menu  {	"constant" \
						"on rotation axis" \
						"on rotation axis & detector" \
						"on rotation axis with secondary beam correction" \
						"on rotation axis with secondary beam absorption correction" \
						"on rotation axis with local 3D correction" \
						"by batch mode" }
					 {	"CONSTANT" \
						"ROTATION" \
						"ROT&DET" \
						SECONDARY \
						ABSORPTION \
						SURFACE \
						"BATCH"  } }


set typedef(_scala_bfactor)	{ menu	{	"no" \
						"isotropic" } 
					{ 	"OFF" \
						"ON" } }

set typedef(_scala_brotation)      { menu	{ "scale layout" \
						"rotation interval" \
						"number of bins" } 
					{ 	"NO_TIME" \
						"BROTATION SPACING" \
						"BROTATION" } }

set typedef(_scala_rotation)	{ menu {	"rotation interval" \
						"number of rotation bins"  }
					{	"SPACING" \
						"" } }

set typedef(_scala_detector)	{ menu {	"interval" \
						"number of bins" } 
					{	"SPACING" \
						"" } }

set typedef(_scala_initial)	{ menu  {	"rotation range mean intensity" \
						"setting all to unit" \
						"setting for individual runs"
						"restoring from dump file" }
					{	MEAN UNITY RUN RESTORE } }


set typedef(scala_integrated) { menu 	{	"integrated (column I)" \
						"profile fitted (IPR)" \
				"IPR for full,integrated for partial" }
					{	"INTEGRATED" \
						"PROFILE" \
						"PR_PART" } }
		
						
set typedef(_scala_output)  { menu {		"averaged intensities" \
						"input data & scale column" \
						"scaled, unmerged & no outliers" \
						"data for POSTREF" \
                                                "unmerged intensities in Scalepack format" } 
					{	"AVERAGE" \
						"SEPARATE" \
						"UNMERGED" \
						"POSTREF" \
						"POLISH" } }
set typedef(_scala_output_keep) { menu {	"Exclude" \
						"Keep" \
						"Keep & scale" } 
					{	"EXCLUDE" \
						"KEEP" \
						"KEEP SCALE" } }

set typedef(_scala_is_mode) { menu {	"integrated intensities" \
					"profile fitted intensities (IPRs)" \
					"profile full & integrated partial" }
				 {	"INTEGRATED" \
					"PROFILE" \
					"PRPART" } }

set typedef(_scala_partials) { menu { "no partials" \
					"summed partials" \
					"scaled partials of fraction >" }
				{	"FULLS" \
					"PARTIALS" \
					"SCALE_PARTIALS" } }

set typedef(_scala_print)	{ menu {	"little" \
						"brief" \
						"cycles" \
						"full" \
						"debug" } }

set typedef(_scala_overlap)	{ menu {	"condensed" \
						"alloverlap" \
						"nooverlap" } }

set typedef(_scala_sd_apply)	{ menu {	"full" \
						"partial" \
						"all" } 
					{	"FULL" \
						"PARTIAL" \
						"BOTH" } }

set typedef(_scala_tail_link)  { menu {		"Link tails" \
						"Unlink tails" } }

set typedef(_scala_surface_link)  { menu {         "Link surface" \
                                                "Unlink surface" } }


set typedef(_scala_exclude_emax) { menu { "E greater than"
					"Es with probability less than"
					"no maximum E criteria" }
				{ EMAX EPROB NOEMAX } } 

set typedef(_scala_anomalous_match) { menu { \
                "in same run" \
		"negation of reciprocal index closest to spindle" \
		"inversion of indices" "specified hkl symmetry" }
					{INRUN SPINDLE INVERT SYMMETRY } } 

set typedef(_scala_truncate_id) { menu { "dataset name" \
                                         "user defined identifier" }
                                       { DATASET USER } }

set typedef(_scala_truncate_prog) { menu { "Ctruncate" \
                                         "old Truncate" }
                                       { CTRUNCATE TRUNCATE } }

set typedef(_scala_batch_define) { menu { "list" \
					   "range" }
                                        { LIST RANGE } }

set typedef(_scala_datasets_in)   [list varmenu DATASETS_IN_MENU {} 20]

set typedef(_scala_datasets_out)  [list varmenu DATASETS_OUT_MENU {} 20]

# If not already defined then define the _image_file type
if { ![info exists typedef(_image_file)] } {
    set typedef(_image_file)	{ file IMG ".img"  "diffraction image file" "" "" }
}

  return 1

}

# procedure run before script is written

#----------------------------------------------------------------
proc scala_run { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

# If not defining multi runs then make sure everything set properly
  if { ! $array(MULTI_RUNS) } { 
    set array(NRUNS) 1
    set array(RUN_DEFS,1) 1
    set array(RUN_MODE,1_1) all
    set array(NSCALES) 1
  }

  if { !$array(CUSTOM_SCALA) } {
    set array(REFINE) 1
    set array(SD_CORRECT) 1
    set array(OUTPUT) AVERAGE
  }

  set array(INPUT_FILES) HKLIN
  if [regexp RESTORE [GetValue $arrayname INITIAL_MODE ] ] {
    append array(INPUT_FILES) " RESTORE_FILE"
  }
  if { [GetValue $arrayname USE_CORNERCORRECT] == 1 } {
    if { ![file exists [GetFullFileName0 $arrayname CORNERCORRECT_FILE]] } {
	WarningMessage "You need to specify a valid
filename for the corner correction
in the \"Scaling Details\" folder."
	return 0
    }
    append array(INPUT_FILES) " CORNERCORRECT_FILE"
  }

  ScaleSetTie $arrayname

# Always keep anomalous pairs in Truncate
  set array(ANOMALOUS) 1

# Call a separate procedure to check the datasets,
# output files and column identifiers
  if { ![ScalaCheckDatasets $arrayname] } { return 0 }

# Setup output file list & check harvesting
  if { [StringSame [GetValue $arrayname OUTPUT] POLISH] } {
    if { ![StringSame [GetValue $arrayname HARVEST_MODE] NOHARVEST] } {
      if { ![SetHarvestParams $arrayname HKLIN  -run] } {
        return 0
      } 
    }
  } else {
    if { ![SetHarvestParams $arrayname HKLIN  -run] } {
      return 0
    } 
  }

# Another harvesting fudge: set HARVEST_INPUT_NAMES to 0
# to prevent the harvest.com component from writing out
# additional PNAME/DNAME commands
  set array(HARVEST_INPUT_NAMES) 0

  return 1
}

#----------------------------------------------------------------
proc ScalaCheckDatasets { arrayname } {
#----------------------------------------------------------------
# Sort out the datasets (and corresponding project names) and
# generate the DATASETS_OUT and PROJECTS_OUT lists
# Determine whether there are multiple output files and if so
# what are their names - check whether they already exist
# Set the column identifiers (if truncate is being run)
#
# Returns 1 if everything is okay to proceed and 0 otherwise 
  upvar #0 $arrayname array


  # Backwards compatibility: runs of the interface pre-6.0 will
  # have RUN_DATASETS and EXCLUDE_DATASET_NAMEs with spaces not /'s,
  # so fix these here
  for { set i 1 } { $i <= $array(NRUNS) } { incr i } {
     for { set j 1 } { $j <= $array(RUN_DEFS,$i) } { incr j } {
        regsub -all { } [string trim $array(RUN_DATASET,[subst $i]_$j)] \
           {/} array(RUN_DATASET,[subst $i]_$j)
     }
  }
  for { set i 1 } { $i <= $array(N_EXCLUDE_DATASETS) } { incr i } {
     regsub -all { } [string trim $array(EXCLUDE_DATASET_NAME,$i)] \
        {/} array(EXCLUDE_DATASET_NAME,$i)
  }

  set array(DATASETS_OUT) ""
  set array(PROJECTS_OUT) ""
  set array(LABELS_OUT)   ""
  set array(N_SCALA_HKLOUT) 0
  if { $array(MULTI_RUNS) } {
    # In multi run mode each run must be explicitly assigned
    # to a dataset
    set nruns $array(NRUNS)
    # Make lists of the ouput datasets
     for { set i 1 } { $i <= $nruns } { incr i } {
       set array(RUN_XNAME_OUT,$i) [lindex $array(RUN_DATASET_OUT,$i) 0]
       set array(RUN_DNAME_OUT,$i) [lindex $array(RUN_DATASET_OUT,$i) 1]
       set dataset_name [lindex $array(RUN_DATASET_OUT,$i) 1]
       set project_name $array(HARVEST_PNAME)
       if { [lsearch $array(DATASETS_OUT) $dataset_name] < 0 } {
          # Add to the list
          lappend array(DATASETS_OUT) $dataset_name
          lappend array(PROJECTS_OUT) $project_name
	  # Deal with the column identifiers
          if { $array(RUN_TRUNCATE) } {
            lappend array(LABELS_OUT) [scala_get_column_id $arrayname $dataset_name]
          }
       }
     }
  } else {
    # Not in multi run mode
    if { $array(N_FILE_DATASETS) <= 1 || $array(COMBINE_DATASETS) } {
       # If there are no datasets in file then user must have
       # assigned a name
       # If there was a single dataset then this will have been
       # been picked up from the file and/or assigned by the user
       set array(DATASETS_OUT) [list $array(HARVEST_DNAME)]
       set array(PROJECTS_OUT) [list $array(HARVEST_PNAME)]
       if { [GetValue $arrayname COLUMN_ID_TYPE] == "DATASET" } {
         set array(LABELS_OUT) $array(HARVEST_DNAME)
       } else {
         set array(LABELS_OUT) $array(LABOUT_LABEL)
       }
    } else {
       # Use the datasets from the input file
       set n_file_datasets $array(N_FILE_DATASETS)
       set project_name $array(HARVEST_PNAME)
       for { set i 1 } { $i <= $n_file_datasets } { incr i } {
         set dataset_name $array(INPUT_DATASET_DEF,$i)
         lappend array(DATASETS_OUT) $dataset_name
         lappend array(PROJECTS_OUT) $project_name
         if { $array(RUN_TRUNCATE) } {
            lappend array(LABELS_OUT) [scala_get_column_id $arrayname $dataset_name]
         }
       }
    }
  }

  # Exclude datasets
  # If any datasets have been excluded then remove them now
  if { $array(EXCLUDE_DATASET) && $array(N_EXCLUDE_DATASETS) > 0 } {
    for { set i 0 } { $i <= $array(N_EXCLUDE_DATASETS) } { incr i } {
      set j [lsearch $array(DATASETS_OUT) [lindex \
        [split $array(EXCLUDE_DATASET_NAME,$i) "/"] 1]]
      if { $j > -1 } {
        set array(DATASETS_OUT) [lreplace $array(DATASETS_OUT) $j $j]
        set array(PROJECTS_OUT) [lreplace $array(PROJECTS_OUT) $j $j]
      }
    }
  }

  # Validate the output dataset and project names
  set ndatasets [llength $array(DATASETS_OUT)]
  set nsets $ndatasets
  if { [StringSame [GetValue $arrayname OUTPUT] POLISH] && \
	  [StringSame [GetValue $arrayname HARVEST_MODE] NOHARVEST] && \
	  $ndatasets == 1 } {
      # We're outputing a single non-MTZ file and no harvesting
      # will be written so don't check the dataset information
      set nsets 0
  }

  for { set i 0 } { $i < $nsets } { incr i } {
    set dataset_name [lindex $array(DATASETS_OUT) $i]
    set project_name [lindex $array(PROJECTS_OUT) $i]
    if { [string trim $dataset_name] == "" || [string trim $project_name] == "" } {
	  WarningMessage "One or more Project/Dataset pair have not been properly
assigned

You must assign valid Project and Dataset names before
running the task."
          return 0
    }
    # Special case: the default name from Mosflm is "Unspecified"
    # Warn the user and let them abort the run if they wish to change
    # it manually
    if { [regexp -- "^Unspecified$" $dataset_name] } {
      if { [ regexp Abort [ChooseOptionDialog "Check Dataset Name" "Dataset" \
	      "A dataset will be output with the name

\"Unspecified\"

It is recommended that you change this name to something else before
running the Scala job."  \
	[list "Proceed" "Abort Run"] -default 1] ] } {
            return 0
      }
    }
  }

  # Check that Truncate label ids are unique for Cad
  if { $array(RUN_TRUNCATE) && $array(RUN_CAD) } {
    for { set i 0 } { $i < [expr $ndatasets - 1] } { incr i } {
      set label_id1 [lindex $array(LABELS_OUT) $i]
      for { set j [expr $i + 1]} { $j < $ndatasets } { incr j } {
        set label_id2 [lindex $array(LABELS_OUT) $j]
	if { $label_id1 == $label_id2 } {
	  WarningMessage "One or more column identifiers for Truncate are identical
You must assign a unique column id for each output dataset
before running the task"
          return 0
        }
      }
    }
  }

  # Deal with output files
  if { [regexp AVERAGE|UNMERGED|POLISH [GetValue $arrayname OUTPUT]] } {
    # For POLISH output - use the SCALOUT parameter
    if { [StringSame [GetValue $arrayname OUTPUT] POLISH] } {
      set hklout "SCALOUT"
    } else {
      # Otherwise use the HKLOUT parameter
      set hklout "HKLOUT"
    }
    # If there is only one output dataset then there will only be one output
    # file i.e. HKLOUT/SCALOUT
    # Otherwise, generate all the output file names from scala and check these
    # explicitly
    if { $ndatasets < 1 } {
      WarningMessage "This task run will not generate any output files!

Please check the settings before rerunning."
      return 0
    } elseif { $ndatasets == 1 } {
      set array(OUTPUT_FILES) $hklout
    } elseif { [regexp AVERAGE [GetValue $arrayname OUTPUT]] &&
               $array(RUN_TRUNCATE) && $array(RUN_CAD) } {
      set array(OUTPUT_FILES) $hklout
    } elseif { [regexp UNMERGED [GetValue $arrayname OUTPUT]] &&
               $array(UNMERGED_TOGETHER) } {
      set array(OUTPUT_FILES) $hklout
    } else {
      set array(OUTPUT_FILES) ""
      set basename [ GetFullFileName [FileRootName $array($hklout)] $array(DIR_$hklout)]
      set output_files ""
      set existing_files 0
      foreach dataset_name $array(DATASETS_OUT) {
	if { ![StringSame [GetValue $arrayname OUTPUT] POLISH] } {
          set output_file "[subst $basename]_[subst $dataset_name].mtz"
        } else {
          set output_file "[subst $basename]_[subst $dataset_name].hkl"
        }
        if { [file exists $output_file] } { incr existing_files }
        lappend output_files $output_file
      }
  
      # Warning message about multiple output files
      set message "This task run will output more than one dataset.

Scala will output a separate file for each dataset, using the file name you
have given as the basename. The following files will be generated:\n"
      foreach output_file $output_files { append message "\n  $output_file" }

      if { $existing_files > 0 } {
        append message "\n
One or more of these files already exists and will be overwritten.
Do you want to continue or abort this task run and change the base file name before
rerunning?"
        if { [ regexp Abort [ChooseOptionDialog "Files Exist" "Files Exist" $message \
	      [list "Delete Files" "Abort Run"] -default 1] ] } {
           return 0
        }
        # Delete the files
        foreach output_file $output_files { DeleteFile $output_file }
      } else {
        # Just warn the user
        WarningMessage $message
      }
      # Setup OUTPUT_FILES
      set i 0
      foreach output_file $output_files {
        incr i
        set array(SCALA_$hklout,$i) [file tail $output_file]
        set array(DIR_SCALA_$hklout,$i) $array(DIR_$hklout)
        append array(OUTPUT_FILES) " SCALA_$hklout,$i"
      }
      set array(N_SCALA_$hklout) $i
    }
  } else {
    # In modes other than AVERAGE, UNMERGED and POLISH, only one output
    # file is produced (and it's always in MTZ format)
    set array(OUTPUT_FILES) HKLOUT
  }

  # Okay to proceed
  return 1
}

#-------------------------------------------------------------------------
proc scala_get_column_id { arrayname dataset_name } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { [GetValue $arrayname COLUMN_ID_TYPE] == "DATASET" } {
    return $dataset_name
  } else {
    if { $array(MULTI_RUNS) } {
      # Multi runs: use the output definitions
      for { set i 1 } { $i <= $array(N_OUTPUT_DATASETS) } { incr i } {
        if { $array(OUTPUT_DATASET_DEF,$i) == $dataset_name } {
          return $array(OUTPUT_DATASET_LABEL,$i)
        }
      }
    } else {
      # No multi runs: use the input definitions
      for { set i 1 } { $i <= $array(N_FILE_DATASETS) } { incr i } {
        if { $array(INPUT_DATASET_DEF,$i) == $dataset_name } {
          return $array(INPUT_DATASET_LABEL,$i)
        }
      }
    }
    return ""
  }
}

#-------------------------------------------------------------------------
proc scala_sort_hklin { arrayname counter } {
#-------------------------------------------------------------------------

    CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       SORT_HKLIN DIR_SORT_HKLIN
}

#--------------------------------------------------------------------------
proc  ScalaCheckInputMtz { arrayname } {
#--------------------------------------------------------------------------

  upvar #0 $arrayname array

  set name_list ""
  set type_list ""
  GetMtzColumnByType  [GetFullFileName0 $arrayname HKLIN]  * name_list type_list

  foreach item { SCALE FRACTIONCALC IPR XDET ROT } {
    if { [lsearch $name_list "$item"] >= 0 } { 
      set array(HKLIN_$item) 1
    } else {
      set array(HKLIN_$item) 0
    }
  }

# check if input file is sorted and set RUN_SORTMTZ appropriately
  if { [ GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] UNMERGED_SORTED sorted] } {
      if { $sorted == 0 } {
        set array(RUN_SORTMTZ) 1
      } else {
        set array(RUN_SORTMTZ) 0
      }
  }

}

#--------------------------------------------------------------------------
proc ScalaGetDatasets { arrayname } {
#--------------------------------------------------------------------------
# Extract the dataset information from the input MTZ file

  upvar #0 $arrayname array

  set ndatasets 0
  if [file exists [GetFullFileName0 $arrayname HKLIN]] {
    GetMtzParam [GetFullFileName0 $arrayname HKLIN] NDATASETS ndatasets
  }
  if { $ndatasets > 0 } {
    GetMtzParam [GetFullFileName0 $arrayname HKLIN] PNAMES pnames
    GetMtzParam [GetFullFileName0 $arrayname HKLIN] XNAMES xnames
    GetMtzParam [GetFullFileName0 $arrayname HKLIN] DNAMES dnames
    set array(RUN_DATASET,1) "[lindex $xnames 0 ]/[lindex $dnames 0 ]"
  } else {
    set array(RUN_DATASET,1) ""
    set pnames ""
    set xnames ""
    set dnames ""
  }
  # Update the extending frames and menus with the possible
  # output datasets
  scala_update_input_datasets $arrayname $xnames $dnames
  scala_update_output_datasets $arrayname $xnames $dnames
  # Update dataset display mode
  scala_update_dataset_display_mode $arrayname
}

#--------------------------------------------------------------------------
proc scala_update_file_datasets_menu { arrayname xnames dnames } {
#--------------------------------------------------------------------------
# Update the variable menu showing the datasets in the input file,
# identified by xname-dname pair

  upvar #0 $arrayname array

  set ndatasets $array(N_FILE_DATASETS)
  set datasets ""
  for { set i 0 } { $i < $ndatasets } { incr i } {
    lappend datasets "[lindex $xnames $i]/[lindex $dnames $i]"
  }
  UpdateVariableMenu $arrayname initialise 0 DATASETS_IN_MENU $datasets 
}

#--------------------------------------------------------------------------
proc scala_update_input_datasets { arrayname xnames dnames } {
#--------------------------------------------------------------------------
# Update the information for input datasets and the extending frame which
# displays it.
# PJX 02/02 The extending frame for displaying this information is an abuse
# of the -noaddline option, so this procedure also has code to explicitly
# update the extending frame whenever the information changes. This requires
# calls to append_extend_frame and delete_frame.
# At some point this should be replaced.

  upvar #0 $arrayname array

  # If there are no datasets then do nothing
  if { [llength $dnames] == 0 } {
    set increment [expr 0 - $array(N_FILE_DATASETS)]
  } else {
    # Overwrite the existing names with the new ones
    set crystals $xnames
    set datasets $dnames

    set n 0
    foreach crystal $crystals {
      incr n
      set array(INPUT_CRYSTAL_DEF,$n) $crystal
      set array(INPUT_CRYSTAL_LABEL,$n) ""
    }
    set n 0
    foreach dataset $datasets {
      incr n
      set array(INPUT_DATASET_DEF,$n) $dataset
      set array(INPUT_DATASET_LABEL,$n) ""
    }
    set increment [expr $n - $array(N_FILE_DATASETS)]
  }

  # Redraw the extending frame
  # Have to do this manually for now grrr
  if { $increment > 0 } {
    # Add frames
      for { set i 0 } { $i < $increment } { incr i } {
	  append_extend_frame $arrayname ScalaInputDatasets 0
          incr array(N_FILE_DATASETS)
      }
  } elseif { $increment < 0 } {
    # Delete frames
      for { set i 0 } { $i > $increment } { incr i -1 } {
	  delete_frame $arrayname ScalaInputDatasets 0
          incr array(N_FILE_DATASETS) -1
      }
  }

  # Update the variable menu with the input datasets
  scala_update_file_datasets_menu $arrayname $xnames $dnames
}

#--------------------------------------------------------------------------
proc ScalaUpdateInputDatasetDisplay { arrayname } {
#--------------------------------------------------------------------------
# PJX 02/02 THIS IS HORRIBLE AND NEEDS TO BE REPLACED
# This procedure does a one-off update of the "noedit" extending frame
# displaying the dataset information from the input file.
# I need this because the CreateExtendingFrame with -noaddline doesn't
# update itself to display existing data when it is first created, e.g.
# when the user does a rerun task
  upvar #0 $arrayname array

  # Manually add the frames for the existing datasets
  if { $array(N_FILE_DATASETS) > 0 } {
    set n_file_datasets $array(N_FILE_DATASETS)
    set array(N_FILE_DATASETS) 0
    for { set i 0 } { $i < $n_file_datasets } { incr i } {
      append_extend_frame $arrayname ScalaInputDatasets 0
      incr array(N_FILE_DATASETS)
    }
  }
}

#--------------------------------------------------------------------------
proc scala_update_output_datasets { arrayname xnames dnames } {
#--------------------------------------------------------------------------
# Populate the extending frame with info from the file
  upvar #0 $arrayname array

  # If there are no datasets then do nothing
  if { [llength $dnames] == 0 } {
    set increment [expr 0 - $array(N_OUTPUT_DATASETS)]
  } else {
    # Overwrite the existing names with the new ones
    set crystals $xnames
    set datasets $dnames

    set n 0
    foreach crystal $crystals {
      incr n
      set array(OUTPUT_CRYSTAL_DEF,$n) $crystal
      if {![ElementExists $arrayname OUTPUT_CRYSTAL_LABEL,$n]} {
        set array(OUTPUT_CRYSTAL_LABEL,$n) ""
      }
    }
    set n 0
    foreach dataset $datasets {
      incr n
      set array(OUTPUT_DATASET_DEF,$n) $dataset
      # Set up output identifiers to append to truncate column labels
      if {![ElementExists $arrayname OUTPUT_DATASET_LABEL,$n]} {
        set array(OUTPUT_DATASET_LABEL,$n) ""
      }
    }
    set increment [expr $n - $array(N_OUTPUT_DATASETS)]
  }

  # Redraw the extending frame
  UpdateExtendingFrame ScalaOutputDatasets 0 $arrayname $increment

  # Update the variable menu of possible output datasets
  scala_update_output_datasets_menu $arrayname 
}

#--------------------------------------------------------------------------------
proc scala_update_output_datasets_menu { arrayname args } {
#--------------------------------------------------------------------------------
# Update variable menu with the list of possible output dataset names
  upvar #0 $arrayname array

  set ndatasets $array(N_OUTPUT_DATASETS)
  set datasets ""

  for { set i 1 } { $i <= $ndatasets } { incr i } {
     lappend datasets "$array(OUTPUT_CRYSTAL_DEF,$i) $array(OUTPUT_DATASET_DEF,$i)"
  }
  UpdateVariableMenu $arrayname initialise 0 DATASETS_OUT_MENU $datasets 

# Special cases - check and initialise some other parameters too
  if { $array(N_OUTPUT_DATASETS) > 0 } {
    if { $array(OUTPUT_DATASET_DEF,1) != "" } {
      set array(HARVEST_DNAME) $array(OUTPUT_DATASET_DEF,1)
    }

# Check that dataset assignments for all runs are okay
    for { set i 1 } { $i <= $array(NRUNS) } { incr i } {
      if { [ElementExists $arrayname RUN_DATASET_OUT,$i] && \
	      [lsearch $array(DATASETS_OUT_MENU) $array(RUN_DATASET_OUT,$i)] < 0 } {
        # Run dataset is no longer in the menu or has not yet been set
        set array(RUN_DATASET_OUT,$i) [lindex $array(DATASETS_OUT_MENU) 0]
      }
    }
  }
}

#--------------------------------------------------------------------------------
proc ScalaDefineRun { arrayname counter } {
#--------------------------------------------------------------------------------
  SetToggleTitle $arrayname ScalaDefineRun $counter "Run $counter"

  CreateExtendingFrame RUN_DEFS ScalaRunOperator \
        "Add line to define a run" \
        "Add definition" \
      [ list RUN_XCLUDE \
	RUN_MODE \
	RUN_IMIN \
	RUN_IMAX \
	RUN_RMIN \
	RUN_RMAX \
	RUN_LIST \
        RUN_DATASET \
	RUN_DATASET_OUT ] \
	-counter $counter

   scala_set_run_menus $arrayname $counter

   scala_set_run_dataset $arrayname $counter
}

#-------------------------------------------------------------------------
proc scala_set_run_dataset { arrayname counter } {
#-------------------------------------------------------------------------
   upvar #0 $arrayname array

   if {![ElementExists $arrayname RUN_DATASET_OUT,$counter]} {
     if { $array(N_OUTPUT_DATASETS) > 0 } {
       set array(RUN_DATASET_OUT,$counter) [lindex $array(DATASETS_OUT_MENU) 0]
     } else {
       set array(RUN_DATASET_OUT,$counter) ""
     }
   }

   CreateLine line \
      label "Assign this run to dataset" \
      widget RUN_DATASET_OUT
}

#-------------------------------------------------------------------------
proc scala_update_run_dataset { arrayname i counter } {
#-------------------------------------------------------------------------
# If the run is defined in terms of a dataset and a dataset has not
# been assigned then assign it automatically to be the same
   upvar #0 $arrayname array

   if { $array(RUN_DATASET_OUT,$counter) == "" } {
     set array(RUN_DATASET_OUT,$counter) [lindex $array(DATASETS_OUT_MENU) 0]
   }
}

#-------------------------------------------------------------------------
proc scala_set_run_menus { arrayname counter } {
#-------------------------------------------------------------------------

  lappend menu "all runs"
  set menu0 ""
  lappend alias ALL
  set alias0 ""

  if { $counter <= 0 } { return }
  
  for { set n 1 } { $n <= $counter } { incr n } {
    lappend menu "run $n"
    lappend menu0 "run $n"
    lappend alias "RUN $n"
    lappend alias0 "RUN $n"
  }
  UpdateVariableMenu $arrayname initialise $counter RUN_MENU  $menu \
        RUN_MENU_ALIAS  $alias
  UpdateVariableMenu $arrayname initialise $counter RUN_MENU_0 $menu0 \
         RUN_MENU_0_ALIAS  $alias0
}

#------------------------------------------------------------------------
proc ScalaRunOperator  { arrayname i counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

# If there is only one run definition and we are drawing it now then
# set the selection to ALL

  if { $array(NRUNS) == 1 && $array(RUN_DEFS,1) == 1 \
	&& $i == 1 && $counter == 1 } { set array(RUN_MODE,1_1) ALL }

  CreateLine line \
    message "Include or exclude set of reflections in the run (RUN ALL)" \
    help "run" \
    label "Include" \
    widget RUN_MODE \
    toggle_display [Indxv RUN_MODE $counter $i ] open ALL

  CreateLine line \
    message "Include or exclude set of reflections in the run (RUN BATCH/CRYSTAL)" \
    help "run_include" \
    widget RUN_XCLUDE \
    help run \
    widget RUN_MODE \
    label "from" \
    widget RUN_IMIN \
    label "to" \
    widget RUN_IMAX \
    toggle_display [Indxv RUN_MODE $counter $i ] open \
	[list BATCHRANGE XTALRANGE ]

  CreateLine line \
    message "Only use  reflections in the range (EXCLUDE/RESOLUTION)" \
    help "exclude" \
    label "Include" \
    widget RUN_MODE \
    label "from" \
    widget RUN_RMIN \
    label "to" \
    widget RUN_RMAX \
    toggle_display [Indxv RUN_MODE $counter $i ] open SDRANGE

  CreateLine line \
    message "Only use  reflections in the range (EXCLUDE/RESOLUTION)" \
    help "resolution" \
    label "Include" \
    widget RUN_MODE \
    label "from (low)" \
    widget RUN_RMIN \
    label "to (high)" \
    widget RUN_RMAX \
    toggle_display [Indxv RUN_MODE $counter $i ] open RESOLUTION

  CreateLine line \
    message "Include/exclude reflections in the rotation range (RUN RANGE)" \
    help "run_range" \
    widget RUN_XCLUDE \
    widget RUN_MODE \
    label "from" \
    widget RUN_RMIN \
    label "to" \
    widget RUN_RMAX \
    toggle_display [Indxv RUN_MODE $counter $i ] open RANGE


  CreateLine line \
    message "Include or exclude set of reflections in the run (EXCLUDE/RESOLUTION)" \
    help "exclude_rectangle" \
    label "Exclude" \
    widget RUN_MODE \
    label "Xmin" \
    widget RUN_RMIN \
    label "Xmax" \
    widget RUN_RMAX \
    label "Ymin" \
    widget RUN_YMIN \
    label "Ymax" \
    widget RUN_YMAX \
    toggle_display [Indxv RUN_MODE $counter $i ] open RECTANGLE

  CreateLine line \
    message "Include or exclude set of reflections in the run (RUN CRYSTAL/BATCH)" \
    help "run_batch" \
    widget RUN_XCLUDE \
    widget RUN_MODE \
    message "Enter list of integer values separated by spaces" \
    widget RUN_LIST \
    toggle_display [Indxv RUN_MODE $counter $i ] open BATCHLIST

  # Following are two subframes for the RUN ... DATASET option
  # The first is displayed when the input file does contain dataset
  # information
  # The second is displayed when there is none, so that the user is
  # not presented with a blank menu of possible datasets

  OpenSubFrame frame -toggle_display N_FILE_DATASETS hide 0

  CreateLine line \
    message "Include dataset from input file in the run (RUN DATASET)" \
    help "run_dataset" \
    label "Include" \
    widget RUN_MODE \
    message "Select a dataset from the input file to include in this run" \
    widget RUN_DATASET -command "scala_update_run_dataset $arrayname $i $counter" \
    toggle_display [Indxv RUN_MODE $counter $i ] open DATASET

  CloseSubFrame

  OpenSubFrame frame -toggle_display N_FILE_DATASETS open 0

  CreateLine line \
    message "Include dataset from input file in the run (RUN DATASET)" \
    help "run_dataset" \
    label "Include" \
    widget RUN_MODE \
    toggle_display [Indxv RUN_MODE $counter $i ] open DATASET

  CreateLine line \
    label "There are no datasets to select from the input file" -italic \
    toggle_display [Indxv RUN_MODE $counter $i ] open DATASET

  CloseSubFrame

    CreateLine line \
    message "Include or exclude set of reflections in the run (RUN CRYSTAL/BATCH)" \
    help "run_crystal" \
    label "Include" \
    widget RUN_MODE \
    message "Enter list of integer values separated by spaces" \
    widget RUN_LIST \
    toggle_display [Indxv RUN_MODE $counter $i ] open XTALLIST


   CreateLine line \
    message "Include reflections dependent on absolute value (EXCLUDE ABSMAX)" \
    help "exclude_absmax" \
    label "Exclude" \
    widget RUN_MODE \
    label "above " \
    widget RUN_RMIN \
    toggle_display [Indxv RUN_MODE $counter $i ] open ABSVALUE

}

#------------------------------------------------------------------------
proc ScalaDefineScales { arrayname counter { multi 1 } } {
#------------------------------------------------------------------------

  if { $multi } {

  CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales_run" \
    label "For" \
    widget SCALES_RUN \
      -command "scala_update_scales_title  $arrayname $counter" \
    help "scales" \
    label "scale" \
    widget SCALES_MODE  \
	-command "ScaleSetTie $arrayname" \
    message "Use Bfactor scaling (SCALES BFACTOR)" \
    label "with" \
    help scales_bfactor \
    widget SCALES_BFACTOR  \
    label "Bfactor scaling"

  } else {
  
    SetSystemVar current_index_counter 1

    CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales" \
    label "Scale" \
    widget SCALES_MODE  \
	-command "ScaleSetTie $arrayname" \
    message "Use Bfactor scaling (SCALES BFACTOR)" \
    label "with" \
    help scales_bfactor \
    widget SCALES_BFACTOR  \
    label "Bfactor scaling"
  }


  CreateLine line \
    message "Define scaling mode along primary beam (SCALES ROTATION)" \
    help "scales_rotation" \
    label "Define scale ranges along rotation axis by" \
    widget SCALES_ROTATION \
    widget SCALES_ROTATION_ROT \
    toggle_display [Indxv SCALES_MODE $counter] open \
	[list ROTATION ROT&DET SECONDARY ABSORPTION SURFACE ]

  CreateLine line \
    message "Define scaling mode along secondary beam (bins = 1 =>no scaling)(SCALES DETECTOR)" \
    help "scales_detector" \
    label "Define scale ranges on detector by" \
    widget SCALES_DETECTOR \
    label "in X" \
    widget SCALES_DETECTOR_NX \
    label "in Y" \
    widget SCALES_DETECTOR_NY \
    toggle_display [Indxv SCALES_MODE $counter] open \
	[list ROT&DET]

  CreateLine line \
    message "Use the minimum order needed (eg 4 - 6)" \
    label "Secondary beam correction maximum number of spherical harmonics" \
    widget SECONDARY_LMAX \
    toggle_display [Indxv SCALES_MODE $counter] open [list SECONDARY]

  CreateLine line \
    message "Use the minimum order needed (eg 4 - 6)" \
    label "Secondary beam correction maximum number of spherical harmonics" \
    widget SECONDARY_LMAX \
    toggle_display [Indxv SCALES_MODE $counter] open [list ABSORPTION] \
    message "Default is the closest axis to the spindle , or l (k for monoclinic)" \
    label "with polar axis" \
    widget SURFACE_POLE

  CreateLine line \
    message "Correction in crystal space - use the minimum order needed (eg 4 - 6)" \
    label "Local 3D correction - max number of spherical harmonics" \
    widget SURFACE_LMAX \
    toggle_display [Indxv SCALES_MODE $counter] open [list SURFACE] \
    message "Default is the closest axis to the spindle , or l (k for monoclinic)" \
    label "with polar axis" \
    widget SURFACE_POLE

# Bfactor subframe

  OpenSubFrame frame -toggle_display [Indxv SCALES_BFACTOR $counter ] hide OFF


   CreateLine line \
     message "Define Bfactor analysis (SCALES BFACTOR/TIME)" \
     help "scales_brotation" \
     label "Independent Bfactors defined by" \
     widget SCALES_BROTATION \
     widget SCALES_BFACTOR_TIME \
     toggle_display [Indxv SCALES_BROTATION $counter ] hide NO_TIME

  CreateLine line \
     message "Define Bfactor analysis (SCALES BFACTOR/TIME)" \
     help "scales_brotation" \
     label "Independent Bfactors defined by" \
     widget SCALES_BROTATION  \
     toggle_display [Indxv SCALES_BROTATION $counter ] open NO_TIME

  CloseSubFrame

  CreateLine line \
     message "Apply correction for diffuse scattering (reflection tails) for this run." \
     help scales_tails \
     widget SCALES_TAILS \
     label "Apply tails correction with width" \
     message "Width of tails in reciprocal space(A**-1)(default = 0.01)" \
     widget TAILS_V \
     label "fraction in peak" \
     message "Fraction of intensity in diffuse peak at theta=0 (default 0.0)" \
     widget TAILS_A0 \
     message "Slope of intensity fraction against (sin theta/lambda)**2 (default = 10)" \
     label slope \
     widget TAILS_A1


  if { $multi } { 
    scala_update_scales_title $arrayname $counter
  } else {
    SetSystemVar current_index_counter ""
  }

}

#----------------------------------------------------------------------
proc ScaleSetTie { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  set det_tie 0
  set surf_tie 0
  for  { set n 1 } { $n <= $array(NSCALES) } { incr n  } {
    case [GetValue $arrayname SCALES_MODE,$n] \
    ROT&DET {
      set det_tie 1
    } SECONDARY {
      set surf_tie 1
    } ABSORPTION {
      set surf_tie 1
    }
  }
  set array(TIE_DETECTOR) $det_tie
  set array(TIE_SURFACE) $surf_tie
}

#----------------------------------------------------------------------
proc scala_update_scales_title { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  SetToggleTitle $arrayname ScalaDefineScales $counter \
     "Scaling protocol for $array(SCALES_RUN,$counter)"
}

#----------------------------------------------------------------------
proc scala_update_dataset_display_mode { arrayname } {
#----------------------------------------------------------------------
# Update the internal parameter DATASET_DISPLAY_MODE
#
# This determines how the input/output dataset information should be
# displayed
# The possible display modes are:
# SINGLE      : user must enter a single dataset name
# SINGLE_ID   : user must enter a single dataset name and single col id
# EDITMANY    : user must enter one or more datasets
# EDITMANY_ID : user must enter one or more datasets and col id.s
# VIEWMANY    : user can view datasets
# VIEWMANY_ID : user can view datasets and enter col. id.s
#
# Special cases:
# EDITSINGLE    : one dataset in input file, user can change it
# EDITSINGLE_ID : one dataset in input file, user can change it and
#                 specify col id
#
# COMBINE    : many datasets in input file, to be treated as one
# COMBINE_ID : as above plus user can specify col
#
# HARVESTONLY: no dataset information will be transferred to the
#              output file but is still needed for harvesting
# NONE       : no dataset information will be transferred to the
#              output file or used for data harvesting
#
  upvar #0 $arrayname array

  # Set the basic mode: SINGLE, EDIT, VIEW, EDITSINGLE
  if { $array(MULTI_RUNS) == 0 } {
    if { $array(N_FILE_DATASETS) == 0 } {
      # No datasets, no multiruns
      set array(DATASET_DISPLAY_MODE) "SINGLE"
    } elseif { $array(N_FILE_DATASETS) == 1 } {
      # Single dataset, no multiruns
      set array(DATASET_DISPLAY_MODE) "EDITSINGLE"
    } else {
      # Datasets, no multiruns
      if { $array(COMBINE_DATASETS) } {
        # Treat all datasets as one
        set array(DATASET_DISPLAY_MODE) "COMBINE"
      } else {
        # Treat each dataset separately
        set array(DATASET_DISPLAY_MODE) "VIEWMANY"
      }
    }
  } else {
    # Multiruns
    set array(DATASET_DISPLAY_MODE) "EDITMANY"
  }

  # Special case: when outputting Scalepack format, if there is
  # only one dataset and harvesting is turned off then no dataset
  # information is required
  if { [StringSame [GetValue $arrayname OUTPUT] POLISH] && \
	  [StringSame [GetValue $arrayname HARVEST_MODE] NOHARVEST ] } {
    if { [regexp -- SINGLE $array(DATASET_DISPLAY_MODE)] } {
      set array(DATASET_DISPLAY_MODE) "NONE"
    }
  }
  # Truncate mode: if running truncate with user defined labels
  # then append _ID to the basic mode
  if { $array(RUN_TRUNCATE) && \
	  [GetValue $arrayname COLUMN_ID_TYPE] == "USER" } {
    append array(DATASET_DISPLAY_MODE) "_ID"
  }

  # Update the display of the "Convert to SF ..." folder
  scala_update_truncate_display_mode $arrayname
}

#----------------------------------------------------------------------
proc scala_update_truncate_display_mode { arrayname } {
#----------------------------------------------------------------------  
  upvar #0 $arrayname array
  if { [regexp AVERAGE [GetValue $arrayname OUTPUT]] && \
	  $array(RUN_TRUNCATE) } {
    set array(SHOW_TRUNCATE) 1
  } else {
    set array(SHOW_TRUNCATE) 0
  }
}

#----------------------------------------------------------------------
proc ScalaInitialRun { arrayname counter } {
#----------------------------------------------------------------------

  CreateLine line \
    message "Enter initial scaling value for this run (INITIAL RUN)" \
    help "initial" \
    label "Initial scale for run number $counter" \
    widget INITIAL_VALUE

}

#----------------------------------------------------------------------
proc ScalaOutputPartials  { arrayname counter } {
#----------------------------------------------------------------------

  CreateLine line \
    message "Output partial reflections for this run (OUTPUT OMIT PARTIALS)" \
    help "output" \
    widget OUTPUT_PARTIALS \
    label "Omit partial reflections for run number $counter"

}

#----------------------------------------------------------------------
proc ScalaSdCorrections { arrayname counter } {
#----------------------------------------------------------------------

  CreateLine line \
    message "Set SD correction for all runs or specific runs" \
    help "sdcorrection_run" \
    label "For" \
    widget SD_RUNS \
    help "sdcorrection" \
    widget SD_APPLY \
    label "reflections  "  \
    help sdcorrection_run \
    widget SD_REFINE \
    label "refine Sdfac before merging" \
    widget SD_ADJUST \
    label "adjust Sdfac before merging"

  CreateLine line \
    message "Define initial values for SD corrections (SDCORRECTION)" \
    help "sdcorrection" \
    label "Initial  values: Sdfac" \
    widget SD_FAC -oblig \
    label "SdB" \
    widget SD_B \
    label "Sdadd" \
    widget SD_ADD -oblig


}

#-------------------------------------------------------------------------
proc ScalaInputDatasets { arrayname counter } {
#-------------------------------------------------------------------------
# Draw one line of the "Define Datasets" extending frame for
# displaying the input dataset definitions
  global configure

  CreateLine line \
    message "Dataset and crystal names which appear in the input MTZ file" \
    help name \
    label "Dataset $counter: crystal name" \
    varlabel INPUT_CRYSTAL_DEF \
    help name \
    label "dataset name" \
    varlabel INPUT_DATASET_DEF \
    toggle_display DATASET_DISPLAY_MODE open [list VIEWMANY]

  CreateLine line \
    message "Dataset and crystal names which appear in the input MTZ file" \
    help name \
    label "Dataset $counter: crystal name" \
    varlabel INPUT_CRYSTAL_DEF \
    help name \
    label "dataset name" \
    varlabel INPUT_DATASET_DEF \
    message "Define an identifier to be appended to the output column labels from Truncate" \
    label "Identifier to append to column label:" \
    widget INPUT_DATASET_LABEL \
    toggle_display DATASET_DISPLAY_MODE open [list VIEWMANY_ID]

  # Update the background colour and width of the varlabels
  set field_list [GetWidget $arrayname INPUT_CRYSTAL_DEF,$counter]
    for {set i 0} {$i<[llength $field_list]} {incr i} {
	set widget [lindex $field_list $i]
	$widget config -width 20 -background $configure(COLOUR_BACKGROUND) \
		-relief groove
    }
  set field_list [GetWidget $arrayname INPUT_DATASET_DEF,$counter]
    for {set i 0} {$i<[llength $field_list]} {incr i} {
	set widget [lindex $field_list $i]
	$widget config -width 20 -background $configure(COLOUR_BACKGROUND) \
		-relief groove
    }
}

#-------------------------------------------------------------------------
proc ScalaOutputDatasets { arrayname counter } {
#-------------------------------------------------------------------------
# Draw one line of the "Define Datasets" extending frame for
# editing the ouput dataset definitions

  CreateLine line \
    message "Define crystal and dataset names which can be assigned in output file" \
    help name \
    label "Define dataset $counter: crystal name" \
    widget OUTPUT_CRYSTAL_DEF \
    -command "scala_update_output_datasets_menu $arrayname" \
    help name \
    label "dataset name" \
    widget OUTPUT_DATASET_DEF \
    -command "scala_update_output_datasets_menu $arrayname" \
    toggle_display DATASET_DISPLAY_MODE open [list EDITMANY]

  CreateLine line \
    message "Define crystal and dataset names which can be assigned in output file" \
    help name \
    label "Define dataset $counter: crystal name" \
    widget OUTPUT_CRYSTAL_DEF \
    -command "scala_update_output_datasets_menu $arrayname" \
    help name \
    label "dataset name" \
    widget OUTPUT_DATASET_DEF \
    -command "scala_update_output_datasets_menu $arrayname" \
    message "Define an identifier to be appended to the output column labels from Truncate" \
    label "Identifier to append to column label:" \
    widget OUTPUT_DATASET_LABEL \
    toggle_display DATASET_DISPLAY_MODE open [list EDITMANY_ID]
}

#-------------------------------------------------------------------------
proc ScalaLinkTails { arrayname counter } {
#-------------------------------------------------------------------------

  CreateLine line  \
    message "Use same tails parameters for two runs (LINK)" \
    help "link" \
    widget TAIL_LINK \
    widget TAIL_RUN1 \
    label "to" \
    widget TAIL_RUN2 \
    toggle_display [Indxv TAIL_RUN1 $counter] hide "all runs"

  CreateLine line  \
    message "Use same tails parameters for two runs (LINK)" \
    help "link" \
    widget TAIL_LINK \
    widget TAIL_RUN1 \
    toggle_display [Indxv TAIL_RUN1 $counter] open "all runs"
    
}

#-------------------------------------------------------------------------
proc ScalaLinkSurface { arrayname counter } {
#-------------------------------------------------------------------------

  CreateLine line  \
    message "Use same surface parameters for two runs (LINK)" \
    help "link" \
    widget SURFACE_LINK \
    widget SURFACE_RUN1 \
    label "to" \
    widget SURFACE_RUN2 \
    toggle_display [Indxv SURFACE_RUN1 $counter] hide "all runs"

  CreateLine line  \
    message "Use same surface parameters for two runs (LINK)" \
    help "link" \
    widget SURFACE_LINK \
    widget SURFACE_RUN1 \
    toggle_display [Indxv SURFACE_RUN1 $counter] open "all runs"

}

#-----------------------------------------------------------------------
proc ScalaExcludeBatch { arrayname counter } {
#-----------------------------------------------------------------------

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches:" \
    widget EXCLUDE_BATCH_LIST \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open LIST

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches from" \
    widget EXCLUDE_BATCH_FIRST \
    label "to" \
    widget EXCLUDE_BATCH_LAST \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open RANGE

}

#-----------------------------------------------------------------------
proc ScalaExcludeDataset { arrayname counter } {
#-----------------------------------------------------------------------

  CreateLine line \
    help exclude_dname \
    message "Select a dataset from the input file to be excluded altogether" \
    label "Excluded dataset #$counter" \
    widget EXCLUDE_DATASET_NAME

}

#-----------------------------------------------------------------------
proc ScalaExcludeRect { arrayname counter } {
#-----------------------------------------------------------------------

  CreateLine line \
    message "Define areas of detector from which data is to be excluded" \
    help "exclude_rectangle" \
    label "Exclude data from detector area Xmin" \
    widget EXCLUDE_XMIN \
    label "Xmax" \
    widget EXCLUDE_XMAX \
    label "Ymin" \
    widget EXCLUDE_YMIN \
    label "Ymax" \
    widget EXCLUDE_YMAX
}

#-----------------------------------------------------------------------
proc ScalaResetProcess { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { !$array(CUSTOM_SCALA) } {
    set array(REFINE) 1
    set array(SD_CORRECT) 1
    set array(OUTPUT) "averaged intensities"
    scala_update_dataset_display_mode $arrayname
  }

}

#-----------------------------------------------------------------------
proc ScalaActivateReject { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(REJECT_CRITERIA) 1

}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc  scala_task_window { arrayname } {

  upvar #0 $arrayname array

  
  if { [CreateTaskWindow $arrayname  \
        "Scala - Scale Experimental Intensities" "Scala" \
        [ list "Convert to SFs & Wilson Plot" \
	"Data Harvesting" \
        "Customise Scala Process" \
        "Define Output Datasets" \
        "Define Runs" \
	"Scaling Protocols" \
	"Scaling Protocol" \
	"Observations Used & Handling of Partials"  \
        "Handling of Anomalous Data" \
	"Excluded Data" \
	"Scaling Details" \
        "Diffuse Scattering Truncation (Tails) Correction Details" \
        "Link surface corrections of multiple runs" \
	"Reject Outliers" \
	"SD Correction Protocols" \
	"MTZ Output Details" \
	"Log File Output"  ] ] == 0 } return

  SetHarvestParams $arrayname HKLIN -init
  SetProgramHelpFile scala


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    widget CUSTOM_SCALA \
	-command "ScalaResetProcess $arrayname" \
    label "Customise Scala process (default is to refine & apply scaling)"

  OpenSubFrame frame -toggle_display CUSTOM_SCALA open 1

  CreateLine line \
    message "Choose type of data output to reflection file (OUTPUT)" \
    help "output" \
    label "       Output" \
    widget OUTPUT -command "scala_update_truncate_display_mode $arrayname ; scala_update_dataset_display_mode $arrayname" \
    label "to MTZ file" \
    toggle_display OUTPUT hide { POLISH }

  CreateLine line \
    message "Choose type of data output to reflection file (OUTPUT)" \
    help "output" \
    label "       Output" \
    widget OUTPUT -command "scala_update_truncate_display_mode $arrayname ; scala_update_dataset_display_mode $arrayname" \
    toggle_display OUTPUT open { POLISH }

  CloseSubFrame

  CreateLine line \
    help anomalous \
    message "I(+) and I(-) are separated for Rmerge, and Ranom calculated" \
    widget ANOMALOUS_ON \
    label "Separate anomalous pairs for merging statistics"

  #-------------------------------------------------------------------
  # Options for running TRUNCATE and CAD
  #-------------------------------------------------------------------
  # These should only be available for OUTPUT AVERAGE since the
  # other modes only produce batch files

  OpenSubFrame frame -toggle_display OUTPUT open AVERAGE

  CreateLine line \
    message "Append table of Wilson plot data to the Scala log file" \
    widget RUN_TRUNCATE -command "scala_update_dataset_display_mode $arrayname" \
    label "Run" \
    widget TRUNCATE_PROG \
    label "to output Wilson plot and SFs after scaling" \
    message "If there are multiple datasets then merge into a single MTZ file using CAD"\
    widget RUN_CAD \
    label "and output a single MTZ file" \
    toggle_display RUN_TRUNCATE open 1

  CreateLine line \
    message "Append table of Wilson plot data to the Scala log file" \
    widget RUN_TRUNCATE -command "scala_update_dataset_display_mode $arrayname" \
    label "Run" \
    widget TRUNCATE_PROG \
    label "to output Wilson plot and SFs after scaling" \
    toggle_display RUN_TRUNCATE open 0

  #-------------------------------------------------------------------
  # Options for running UNIQUEIFY
  #-------------------------------------------------------------------
  UniqueifyFrame1 $arrayname

  CloseSubFrame

  #-------------------------------------------------------------------
  # Options for OUTPUT UNMERGED
  #-------------------------------------------------------------------
  CreateLine line \
    message "Apply scales, sum or scale partials, reject outliers, but do not average observations (OUTPUT UNMERGED)" \
    widget UNMERGED_TOGETHER \
    label "Output a single unmerged batch MTZ file" \
    toggle_display OUTPUT open UNMERGED

  #-------------------------------------------------------------------
  # Options for running PATTERSON
  #-------------------------------------------------------------------
  CreateLine line \
    message "Generate preliminary 4A Patterson from intensities to check for pseudo-translations" \
    widget RUN_PATTERSON \
    label "Generate Patterson map and do peaksearch to check for pseudo-translations" \
    toggle_display OUTPUT open AVERAGE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Enter input MTZ file name (HKLIN)" \
        "MTZ in" \
        HKLIN DIR_HKLIN \
        -fileout HKLOUT DIR_HKLOUT _scala \
        -fileout SCALOUT DIR_SCALOUT _scala \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-setfileparam scales_column HKLIN_SCALE \
	-command "ScalaCheckInputMtz $arrayname" \
	-command "UpdateHarvestMTZ $arrayname HKLIN" \
        -command "ScalaGetDatasets $arrayname"

  CreateLine line \
    message "Can also be used to exclude subsets of data" \
    widget MULTI_RUNS -command "scala_update_dataset_display_mode $arrayname" \
    label "Override automatic definition of 'runs' to mark discontinuities in data"

  CreateLine line \
    message "Resolution exclusion criteria applied to entire dataset (RESOLUTION)" \
    help "resolution" \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Exclude data resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  UniqueifyFrame2

  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT \
      -toggle_display OUTPUT hide { POLISH }

  CreateOutputFileLine line \
      "Enter name of output Scalepack file (SCALEPACK)" \
      "HKL out" \
      SCALOUT DIR_SCALOUT \
      -toggle_display OUTPUT open { POLISH }

#-----------------------------------------------------------truncate

  OpenFolder 1 SHOW_TRUNCATE hide 0
  SetProgramHelpFile "truncate"

  CreateLine line \
    message "Calculate an approximate atom composition based on the number of residues" \
    label "Estimated number of residues in the asymmetric unit" \
    help nresidue \
    widget CONTENTS_NRES -oblig \
    toggle_display TRUNCATE_PROG open TRUNCATE

  CreateLine line \
    message "Override ctruncate estimate of number of residues in the ASU" \
    label "Estimated number of residues in the asymmetric unit" \
    help nresidue \
    widget CONTENTS_NRESC \
    toggle_display TRUNCATE_PROG open CTRUNCATE

  CreateLine line \
    message "Decide how to identify columns from different datasets" \
    label "Use" \
    widget COLUMN_ID_TYPE -command "scala_update_dataset_display_mode $arrayname" \
    label "as identifier to append to column labels"

  # Keep intensities from Truncate?
  CreateLine line \
     message "Keep the intensities from Scala in the output MTZ file(s)" \
     widget OUTPUT_I \
     label "Include the intensities in the output MTZ file(s)" \
     toggle_display TRUNCATE_PROG open TRUNCATE

#--------------------------------------------------------harvesting mode

  OpenFolder 2

 ## pjx 02/02
 ## Explicitly create the harvesting mode line here for now
 ## Hardly the best solution...
 ## CreateHarvestLine line 

    CreateLine line \
      message "Set project and dataset name for automatic harvesting" \
      widget HARVEST_MODE \
      -command "scala_update_dataset_display_mode $arrayname ; util_set_harvesthome $arrayname"

#-------------------------------------------------------scala run mode

  OpenFolder 3 CUSTOM_SCALA  hide 0 open

  CreateLine line \
    message "Do refinement of scale factors (cycles)" \
    help "cycles" \
    widget REFINE \
    label "Refine scale factors" \

  CreateLine line \
    message "Analyse discrepancies and correct SDs (SDCORRECTION)" \
    help sdcorrection \
    widget SD_CORRECT \
    label "Correct Standard Deviations"

#------------------------------------------------------------------Define datasets

  OpenFolder 4 DATASET_DISPLAY_MODE hide NONE open

  # Use the harvest parameters from the harvest.def file
  # Case 1: no dataset information in the input file, no runs defined
  # User must specify harvesting project and dataset names

  OpenSubFrame frame -toggle_display DATASET_DISPLAY_MODE open [list SINGLE SINGLE_ID]

  CreateLine line \
      label "The input file does not contain dataset information. You must define project and dataset names for the output" -italic
  
  CreateHarvestLine line  -noharv 

  CloseSubFrame

  # Case 2: single dataset present in the input file and user is allowed
  # to edit it
 
  OpenSubFrame frame -toggle_display DATASET_DISPLAY_MODE open \
	  [list EDITSINGLE EDITSINGLE_ID]

  CreateLine line \
      label "The input file contains a single dataset, which will be transferred to the output file" -italic
  
  CreateHarvestLine line  -noharv 

  CloseSubFrame

  # Case 3: dataset information present in the input file
  # and/or runs specified
  # User can define multiple dataset names which can be assigned

  OpenSubFrame frame -toggle_display DATASET_DISPLAY_MODE open \
	  [list EDITMANY EDITMANY_ID]

  CreateLine line \
     help name \
     message "Project name as it will appear in the MTZ file" \
     label "Project name" \
     widget HARVEST_PNAME -oblig -command "util_fix_harvestnames $arrayname"

  CreateLine line \
     label "Define one or more output dataset names to which runs can be assigned" \
     -italic

  CreateExtendingFrame N_OUTPUT_DATASETS ScalaOutputDatasets \
     "Define possible datasets for output file" \
     "Add dataset definition" \
     [list OUTPUT_CRYSTAL_DEF OUTPUT_DATASET_DEF OUTPUT_DATASET_LABEL] \
     -edit scala_update_output_datasets_menu

  CloseSubFrame

  # Case 4: multiple datasets are present in the input file but
  # the user wants to treat them as a single dataset

  CreateLine line \
     message "All datasets in the input MTZ will be put into a single dataset in the output MTZ" \
     widget COMBINE_DATASETS \
        -command "scala_update_dataset_display_mode $arrayname" \
     label "Combine all input datasets into a single output dataset" \
     toggle_display DATASET_DISPLAY_MODE open \
     [list VIEWMANY VIEWMANY_ID COMBINE COMBINE_ID]

  OpenSubFrame frame toggle_display DATASET_DISPLAY_MODE open [list COMBINE COMBINE_ID]

  CreateHarvestLine line  -noharv 

  CloseSubFrame

  # Case 5: multiple dataset information present in the input file but
  # no runs are specified
  # Still need to give the option of defining the column identifiers

  OpenSubFrame frame -toggle_display DATASET_DISPLAY_MODE open \
	  [list VIEWMANY VIEWMANY_ID]

  CreateLine line \
      label "NOTE> the input file contains multiple datasets which will be split into separate output files" -italic \
      toggle_display OUTPUT open AVERAGE

  CreateLine line \
      help pname \
      label "Project name" \
      varlabel HARVEST_PNAME

  # Pjx 02/02 This extending frame is for display and cannot be edited
  # by the user - it abuses the -noaddline option and requires special
  # code elsewhere to update it
  CreateExtendingFrame N_FILE_DATASETS ScalaInputDatasets \
        "Define possible datasets for output file" \
        "Add dataset definition" \
      [list INPUT_CRYSTAL_DEF INPUT_DATASET_DEF INPUT_DATASET_LABEL] \
      -noaddline

  CloseSubFrame

  # Truncate: user-defined identifier to append to column labels for
  # single dataset
  CreateLine line \
    message "Enter an identifier for this data set to append to column labels" \
    help labout \
    label "Identifier to append to column labels:" \
    widget LABOUT_LABEL \
    toggle_display DATASET_DISPLAY_MODE open [list SINGLE_ID EDITSINGLE_ID COMBINE_ID]

  # Pjx 02/02 Procedure required to initialise extending frame
  ScalaUpdateInputDatasetDisplay $arrayname

#------------------------------------------------------------------Define runs

  OpenFolder 5 MULTI_RUNS open 1 hide

  CreateLineTemplate RUN_TEMPLATE [list 0 0.15 0.4 0.45 0.55 0.55 ]

  CreateLine line \
    message "Set on run as reference run (RUN REFERENCE)" \
    help "run_reference" \
    widget REFERENCE \
    label "Use" \
    widget REFERENCE_RUN  \
    label "as reference run"

  CreateToggleFrame NRUNS ScalaDefineRun \
        "Add definition of another run of reflections" "Define run" \
         "Add Run Definition"  \
      [ list RUN_DEFS ]  \
      -dependentframe ScalaInitialRun \
      -dependentframe ScalaOutputPartials \
	-child ScalaRunOperator \
	-edit scala_set_run_menus

#---------------------------------------------------------scaling protocols

  OpenFolder 6 MULTI_RUNS open 1 hide

   CreateToggleFrame NSCALES ScalaDefineScales \
        "Define a scaling protocol" "Scaling protocol for all" \
        "Add Scale Protocol"   \
      [ list SCALES_RUN \
	SCALES_MODE \
	SCALES_BFACTOR \
	SCALES_BROTATION \
	SCALES_BFACTOR_TIME \
	SCALES_ROTATION \
	SCALES_ROTATION_ROT \
	SCALES_DETECTOR \
	SCALES_DETECTOR_NX \
	SCALES_DETECTOR_NY \
	SCALES_TAILS \
	TAILS_V \
	TAILS_A0 \
	TAILS_A1 ]

   OpenFolder 7 MULTI_RUNS open 0 hide

   ScalaDefineScales $arrayname 1 0

##-------------------------------------------------------Observations Used

  OpenFolder 8 closed

  SetProgramHelpFile "scala"
  CreateLine line \
    message "Choose how to use partial reflections (INTENSITIES)" \
    help "intensities" \
    label "Use" \
    widget IS_MODE

  CreateLine line \
    help "partials" \
    message "Choose how to select partial reflections (INTENSITIES/PARTIALS)" \
    label "Scaling " \
	-italic \
    label "Use full reflections and" \
    widget IS_PARTIALS \
    toggle_display IS_PARTIALS hide SCALE_PARTIALS

  CreateLine line \
    help "partials" \
    message "Choose how to select partial reflections (INTENSITIES/PARTIALS)" \
    label "Scaling " \
	-italic \
    label "Use full reflections and" \
    widget IS_PARTIALS \
    widget IS_PARTIALS_MINFRAC \
    toggle_display IS_PARTIALS open SCALE_PARTIALS

 CreateLine line \
    help "partials" \
    message "Choose how to select partial reflections (FINAL/PARTIALS)" \
    label "Merging " \
	-italic \
    label "Use full reflections and" \
    widget FINAL_PARTIALS \
    toggle_display FINAL_PARTIALS hide SCALE_PARTIALS

  CreateLine line \
    help "partials" \
    message "Choose how to select partial reflections (FINAL/PARTIALS)" \
    label "Merging " \
	-italic \
    label "Use full reflections and" \
    widget FINAL_PARTIALS \
    widget FINAL_PARTIALS_MINFRAC \
    toggle_display FINAL_PARTIALS  open SCALE_PARTIALS

  CreateLine line \
    label "Selection of partials used for scaling " \
	-italic \
    label ".. (" \
    help partials \
    widget FINAL_DIF_IS \
    label "use different criteria for merging and analysis)"


  CreateLine line \
    message "Only accept partials with total fraction between (INTENSITIES (NO)TEST" \
    help "partials_notest" \
    widget IS_TEST \
    label "Only accept partials with total fraction between" \
    widget IS_TEST_MIN \
    label "and" \
    widget IS_TEST_MAX

  CreateLine line \
    message "Check consistency of MPART flag (INTENSITIES (NO)CHECK)" \
    help "partials_nocheck" \
    widget IS_CHECK \
    label "Apply fraction test if MPART flag present but inconsistent"

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((INTENSITIES (NO)CORRECT)" \
    help "partials_correct" \
    widget IS_CORRECT \
    label "Scale partials in range" \
    widget IS_CORRECT_LIMIT \
    label "to lower acceptance limit" \
    toggle_display IS_CORRECT open 1

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((INTENSITIES (NO)CORRECT)" \
    help "partials_correct" \
    widget IS_CORRECT \
    label "Scale partials outside rejection range" \
    toggle_display IS_CORRECT open 0

  CreateLine line \
    message "Use partials which have missing part? (INTENSITIES (NO)GAP" \
    help "partials_nogap" \
    widget IS_GAP \
    label "Accept partials with gaps  " \
    label "Set maximum number of parts for acceptable partial to" \
    help partials_maxwidth \
    widget IS_MAXWIDTH 

  OpenSubFrame frame  -toggle_display FINAL_DIF_IS open 1

  CreateLine line \
    label "Selection of partials for analysis and merging" \
	-italic

  CreateLine line \
    message "Reject partials with total fraction outside range (FINAL (NO)TEST" \
    help "final_partials_notest" \
    widget FINAL_TEST \
    label "Only accept partials with total fraction between" \
    widget FINAL_TEST_MIN \
    label "and" \
    widget FINAL_TEST_MAX

  CreateLine line \
    message "Check consistency of MPART flag (FINAL (NO)CHECK)" \
    help "final_partials_nocheck" \
    widget FINAL_CHECK \
    label "Apply fraction test if MPART flag present but inconsistent"

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((FINAL (NO)CORRECT)" \
    help "final_partials_correct" \
    widget FINAL_CORRECT \
    label "Scale partials in range" \
    widget FINAL_CORRECT_LIMIT \
    label "to rejection minimum" \
    toggle_display FINAL_CORRECT open 1

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((FINAL (NO)CORRECT)" \
    help "final_partials_correct" \
    widget FINAL_CORRECT \
    label "Scale partials outside rejection range" \
    toggle_display FINAL_CORRECT open 0

  CreateLine line \
    message "Use partials which have missing part? (FINAL (NO)GAP" \
    help "final_partials_nogap" \
    widget FINAL_GAP \
    label "Accept partials with gaps  " \
    label "Set maximum number of parts for acceptable partial to" \
    help final_partials_maxwidth \
    widget FINAL_MAXWIDTH
   
  CloseSubFrame
   

#---------------------------------------------------------------------anomalous
  OpenFolder 9 closed

  CreateLine line \
    help anomalous line \
    widget IF_ANOMALOUS_MATCH \
    label "Match pairs related by" \
    widget ANOMALOUS_MATCH \
    toggle_display ANOMALOUS_MATCH hide SYMMETRY

  CreateLine line \
    help anomalous \
    widget IF_ANOMALOUS_MATCH \
    label "Match pairs related by" \
    widget ANOMALOUS_MATCH \
    widget ANOMALOUS_MATCH_SYM \
    toggle_display ANOMALOUS_MATCH open SYMMETRY


  CreateLine line \
    help anomalous \
    message "use only matching I+ & I- pairs in merging if < DeltaPhi (ANOMALOUS PHIDIF)" \
    label "Maximum difference in phi for matching pairs" \
    widget ANOMALOUS_PHIDIF \
    label "(expert option)" \
    toggle_display IF_ANOMALOUS_MATCH open 1


#------------------------------------------------------------------Exclude data
  OpenFolder 10 open

  # Excluded batches
  CreateLine line \
    label "Exclude batches and/or datasets from scaling:" -italic

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    widget EXCLUDE_BATCH \
    label "Exclude selected batches"

  OpenSubFrame frame -toggle_display EXCLUDE_BATCH open 1

  CreateExtendingFrame N_EXCLUDE_BATCH ScalaExcludeBatch \
    "Select batches from the input file to be excluded altogether" \
    "Add batches" \
    [list EXCLUDE_BATCH_DEFINE \
          EXCLUDE_BATCH_LIST \
          EXCLUDE_BATCH_FIRST \
          EXCLUDE_BATCH_LAST ]

  CloseSubFrame

  # Excluded Datasets
  CreateLine line \
    help exclude_dname \
    message "Select a dataset from the input file to be excluded altogether" \
    widget EXCLUDE_DATASET \
    label "Exclude selected datasets"

  OpenSubFrame frame -toggle_display EXCLUDE_DATASET open 1

  CreateExtendingFrame N_EXCLUDE_DATASETS ScalaExcludeDataset \
    "Select datasets from the input file to be excluded altogether" \
    "Add dataset" \
    [list EXCLUDE_DATASET_NAME]

  CloseSubFrame
    
  OpenSubFrame frame -toggle_display HKLIN_XDET open 1

  CreateLine line \
    label "Set exclusion criteria which apply to all runs" -italic

  CreateLine line \
  help exclude_rectangle \
  widget EXCLUDE_RECT \
  label "Exclude data from defined area(s) of detector"

 CreateExtendingFrame N_EXCLUDE_RECT ScalaExcludeRect \
        "Define rectangular areas of detector from which data is excluded" \
         "Add detector area" \
      [list  EXCLUDE_XMIN \
		EXCLUDE_XMAX \
		EXCLUDE_YMIN \
		EXCLUDE_YMAX ]

  CloseSubFrame

  CreateLine line \
    label "Exclude reflections from scaling:" -italic

  CreateLine line \
     message "Data value exclusion criteria applied to entire dataset (EXCLUDE)" \
     help "exclude_sdmin" \
     widget EXCLUDE_BYSIGMA \
        -toggleon \
     label "Exclude data values less than" \
     widget EXCLUDE_BYSIGMA_1 \
     help "exclude_sdmax" \
     label "SDs or greater than" \
     widget EXCLUDE_BYSIGMA_2 \
     label "SDs"

  CreateLine line \
     message "Data value exclusion criteria applied to entire dataset (EXCLUDE)" \
     help "exclude_absmax" \
     widget EXCLUDE_MAXIMUM \
        -toggleon \
     label "Exclude data greater than" \
     widget EXCLUDE_MAXIMUM_1 \
     label "absolute value"

  # Accept observations previously flagged as rejected by MOSFLM
  CreateLine line \
     label "Accept observations flagged as rejected by MOSFLM:" -italic

  CreateLine line \
     help ACCEPT \
     message "Accept overloaded observations previously rejected by MOSFLM (ACCEPT OVERLOADS)" \
     widget ACCEPT_OVERLOADS \
     label "Accept profile-fitted overloads"

  CreateLine line \
     help ACCEPT \
     message "Set cut-off rms/sd ratio for accepting observations previously rejected by MOSFLM (ACCEPT PKRATIO)" \
     widget ACCEPT_PKRATIO \
            -toggleon \
     label "Accept observations with peak-fitting rms/sd ratio less than" \
     widget PKRATIO

#---------------------------------------------------diffuse scattering tails

  OpenFolder 12 closed

  CreateLine line \
     message "Fix tails correction parameters (FIX/UNFIX)" \
     help "fix" \
     label "Fix:   " \
     widget TAILS_FIX_V \
     label "width of tail   " \
     widget TAILS_FIX_A0 \
     label "fraction I at theta=0   " \
     widget TAILS_FIX_A1 \
     label "Slope of I fraction v. resolution"

  CreateLine line \
     message "Tie TAILS parameter A1 to its starting value if it varies too wildly (TIE A1)" \
     help "tie" \
     widget TIE_A1 \
         -toggleon \
     label "Restrain slope to starting value with SD" \
     widget TIE_A1_SD

  OpenSubFrame frame -toggle_display MULTI_RUNS open 1

  CreateLine line \
    label "Link runs; use same tail parameters for specified runs?" 

  CreateExtendingFrame N_TAIL_LINK ScalaLinkTails \
        "Link/unlink tail parameters for different runs" \
         "Add tails link" \
      [list  TAIL_LINK \
		TAIL_RUN1 \
		TAIL_RUN2 ]

  CloseSubFrame

#--------------------------------------------------------------------link surface corrections

  OpenFolder 13 closed

    CreateLine line \
    label "Link runs; use same surface corrections for specified runs?"

   CreateExtendingFrame N_SURFACE_LINK ScalaLinkSurface \
        "Link/unlink surface parameters for different runs" \
         "Add surface link" \
      [list  SURFACE_LINK \
                SURFACE_RUN1 \
                SURFACE_RUN2 ]



#--------------------------------------------------------scaling details
  OpenFolder 11 closed

  CreateLine line \
      message "Scale input intensities by SCALE column in MTZ file (INSCALE)" \
      widget INSCALE \
      label "Apply scaling from input MTZ SCALE column" \
      toggle_display HKLIN_SCALE open 1

  CreateLine line \
      message "Use correction data to correct for underestimates at the corners of the CCD detector" \
      help "cornercorrect" \
      widget USE_CORNERCORRECT \
      label "Apply Corner Correction for CCD (3x3) detector"

  CreateInputFileLine line \
      "Enter correction file for the CCD detector used in the experiment" \
      "Correction file" \
      CORNERCORRECT_FILE DIR_CORNERCORRECT_FILE \
      -toggle_display USE_CORNERCORRECT open 1

  CreateLine line \
    message "Decide how initial scales are set (INITIAL)" \
    help "initial" \
    label "Initial scaling set by" \
    widget INITIAL_MODE

  CreateInputFileLine line \
        "Enter scala dump file name (RESTORE)" \
        "Input dump file" \
        RESTORE_FILE DIR_RESTORE_FILE \
        -toggle_display INITIAL_MODE open RESTORE


  OpenSubFrame frame -toggle_display INITIAL_MODE open RUN

 CreateExtendingFrame NRUNS ScalaInitialRun \
        "Set initial scaling value for each run" \
        " " \
      [list  INITIAL_VALUE ] -noaddline

  CloseSubFrame

  CreateLine line \
    message "Set number of cycles of refinement and convergence limit (CYCLES)" \
    help "cycles" \
    label "Refine scale factors for" \
    widget CYCLES \
    label "cycles OR to convergence limit" \
    help cycles_converge \
    widget CONVERGE

  CreateLine line \
    message "Use subset of reflections only to speed up initial cycles (SKIP)" \
    widget SKIP \
	-toggleon \
    label "For first" \
    widget SKIP_NCYCLES \
    label "cycles use only every" \
    widget SKIP_NREFLECTIONS \
    label "th reflection"

  CreateLine line \
    widget CYCLE_UNIT_WEIGHT \
    label "Use a unit weighting"

  CreateLine line \
    message "Define filter and damp levels (FILTER)" \
    help "filter" \
    label "Add damping of" \
    widget FILTER_DAMP \
    label "to all eigen shifts before filtering"


  CreateLine line \
    message "Tie primary beam scaling factors together if they vary too wildly (TIE)" \
    help "tie" \
    widget TIE_ROTATION \
	-toggleon \
    label "Restrain neighbouring scale factors on rotation axis to SD" \
    widget TIE_ROTATION_SD \
    toggle_display SCALES_MODE closed CONSTANT

  CreateLine line \
    message "Tie secondary beam scaling factors together if they vary too wildly (TIE)" \
    help "tie" \
    widget TIE_DETECTOR \
	-toggleon \
    label "Restrain neighbouring scale factors on detector plane to SD" \
    widget TIE_DETECTOR_SD \
    toggle_display SCALES_MODE open [list ROT&DET ]

  CreateLine line \
    message "Tie surface scaling factors together if they vary too wildly (TIE)" \
    help "tie" \
    widget TIE_SURFACE \
        -toggleon \
    label "Restrain surface parameters to sphere with SD" \
    widget TIE_SURFACE_SD \
    toggle_display SCALES_MODE open [list SECONDARY ABSORPTION SURFACE ]

  CreateLine line \
    message "Tie B factors together if they vary too wildly (TIE)" \
    help "tie" \
    widget TIE_BFACTOR \
        -toggleon \
    label "Restrain Bfactors along rotation axis with SD" \
    widget TIE_BFACTOR_SD

  CreateLine line \
    message "Override program smoothing factors (variances of weights) (SMOOTHING)" \
    widget SMOOTHING \
	-toggleon \
    label "Smoothing factor for Bfactor/time" \
    widget SMOOTHING_TIME \
    label "  along rotation axis" \
    widget SMOOTHING_ROTATION \
    label "  on detector" \
    widget SMOOTHING_DETECTOR

  CreateLine line \
    message "Override program max of normalised squared deviations (SMOOTHING PROBLIMIT)" \
    help smoothing_prob_limit \
    widget PROB_LIMIT \
	-toggleon \
    label "Probability limit for Bfactor/time" \
    widget PROB_LIMIT_TIME \
    label "  along rotation axis" \
    widget PROB_LIMIT_ROTATION \
    label "  on detector" \
    widget PROB_LIMIT_DETECTOR
   

#----------------------------------------------------Reject outliers

  OpenFolder 14 closed

  CreateLine line \
    message "Exclude very large E values(EXCLUDE EMAX)" \
    label Exclude \
    widget EXCLUDE_EMAX \
    widget EXCLUDE_EMAX_EMAX \
    toggle_display EXCLUDE_EMAX open EMAX

  CreateLine line \
    message "Exclude very large E values(EXCLUDE EMAX)" \
    label Exclude \
    widget EXCLUDE_EMAX \
    widget EXCLUDE_EMAX_EPROB \
    toggle_display EXCLUDE_EMAX open EPROB

  CreateLine line \
    message "Exclude very large E values(EXCLUDE EMAX)" \
    label Exclude \
    widget EXCLUDE_EMAX \
    toggle_display EXCLUDE_EMAX open NOEMAX

    CreateLine line \
      message "Reject outliers during scaling stage (REJECT)" \
      help "reject" \
      widget REJECT_CRITERIA \
      label "Override default criteria for rejecting outliers in scaling & merging" 

    CreateLine line \
      message "Reject outliers during scaling stage (REJECT)" \
      help "reject" \
      label "Scaling" \
	-italic \
      label ": Reject Is >" \
      help reject_sdrej \
      widget REJECT_SDMAX \
	-width 3 \
        -command "ScalaActivateReject $arrayname" \
      label "SDs from mean or" \
      help reject_sdrej2 \
      widget REJECT_SDMAX2 \
	-width 3 \
        -command "ScalaActivateReject $arrayname" \
      label "SDs if two observations  " \
      widget REJECT_BYRUN \
        -command "ScalaActivateReject $arrayname" \
      label "Comparison within runs only"


  CreateLine line \
      message "Reject outliers during final merging  stage (REJECT)" \
      help "reject" \
      label "Final merge" \
	-italic \
      label ": Reject Is >" \
      help reject_sdrej \
      widget MERGE_REJECT_SDMAX \
	-width 3 \
        -command "ScalaActivateReject $arrayname" \
      label "SDs from mean or" \
      help reject_sdrej2 \
      widget MERGE_REJECT_SDMAX2 \
	-width 3 \
        -command "ScalaActivateReject $arrayname" \
      label "SDs if two observations or"

   CreateLine line \
      message "Reject outliers during final merging  stage (REJECT)" \
      label "    " \
      widget MERGE_REJECT_ALL \
        -command "ScalaActivateReject $arrayname" \
      label "SDs for all data" \
      help reject_byrun \
      widget MERGE_REJECT_BYRUN \
        -command "ScalaActivateReject $arrayname" \
      label "Comparison within runs only"


#-------------------------------------------------------SD corrections

  OpenFolder 15 closed

 CreateToggleFrame NSDS ScalaSdCorrections \
        "Define SD correction" "Define SD correction" \
        "Add SD Correction Protocol"   \
      [ list SD_RUNS \
		SD_ADJUST \
		SD_REFINE \
		SD_APPLY \
		SD_FAC \
		SD_B \
		SD_ADD  ]


#------------------------------------------------------------------MTZ output

  OpenFolder 16 OUTPUT hide POLISH closed

  CreateLine line \
    message "Keep original indices or convert to single asymmetric unit (OUTPUT ORIGINAL?REDUCED)" \
    help "output" \
    widget OUTPUT_REDUCED \
    label "Indices reduced to asymmetric unit"  \
    toggle_display OUTPUT open UNMERGED

  CreateLine line \
    label "No options for current set MTZ output mode" \
    toggle_display OUTPUT open [list "AVERAGE" ]


  OpenSubFrame frame -toggle_display  OUTPUT open [list SEPARATE POSTREF ]

  CreateLine line \
    message "Ouput the reference run if it is defined (OUTPUT (NO)REFERENCE)" \
    help "output_separate_reference" \
    widget OUTPUT_REFERENCE \
    label "Write reference run to file"

  CreateLine line \
    message "Write outlier reflections to file (OUTPUT OMIT OUTLIERS)" \
    help "output_separate_omitoutliers" \
    widget OUTPUT_OUTLIERS \
    label "Omit outliers from output"

  CreateExtendingFrame NRUNS ScalaOutputPartials \
        "Output partial reflections for each run" \
        " " \
      [list  OUTPUT_PARTIALS ] -noaddline

  CloseSubFrame

   
#------------------------------------------------------------------log output

  OpenFolder 17 closed

  CreateLine line \
    message "Set level of output to log file (PRINT)" \
    label "Output" \
    widget PRINT \
    label "info to log file with" \
    message "Set amount of overlap matrix written to file (ALLOVERLAP/NOOVERLAP)" \
    help overlapmap \
    widget OVERLAP \
    label "overlap matrix"

# Update the DATASET_DISPLAY_MODE
  scala_update_dataset_display_mode $arrayname

#----------------------------------------------Miscellaneous jobs on startup

# Update the dataset info from the file if there is one
# already set
# PJX this seems to delete existing settings? so comment it out for now
##  if [file exists [GetFullFileName0 $arrayname HKLIN]] {
##    ScalaGetDatasets $arrayname
##  }
}

#=END=======================================================================


