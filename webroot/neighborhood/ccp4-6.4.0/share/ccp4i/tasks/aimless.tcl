#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id: aimless.tcl,v 1.3 2012/06/11 10:56:37 fcx32934 Exp $
# ======================================================================
# aimless.tcl --
#
# Template for task interface
#
# CCP4Interface 
#
# =======================================================================

# Get the Pointless utilities
source [SearchPath TOP tasks pointless_utils.tcl]

#--------------------------------------------------------------------
proc aimless_setup { typedefname arrayname } { 
#--------------------------------------------------------------------

  upvar #0 $typedefname typedef

  PointlessSetup  $typedefname $arrayname

set typedef(_scala_run_mode) 	{ menu {	"batch range" \
						"resolution range" \
						}
					{	"BATCHRANGE" \
						"RESOLUTION" \
						} }

#set typedef(_scala_run_mode) 	{ menu {	"all" \
#						"batch range" \
#						"batch list" \
#						"resolution range" \
#						}
#					{	"ALL" \
#						"BATCHRANGE" \
#						"BATCHLIST" \
#						"RESOLUTION" \
#						} }

set typedef(_scala_scales_run)	{ varmenu RUN_MENU RUN_MENU_ALIAS 8} 

set typedef(_scala_run)		{ varmenu RUN_MENU_0 RUN_MENU_0_ALIAS 8} 

set typedef(_scala_scales_mode)  { menu  {    "with automatic default settings" \
					      "constant" \
					      "on rotation axis" \
					      "on rotation axis with secondary beam correction" \
					      "on rotation axis with secondary beam absorption correction" \
					      "by batch mode" }
					 {        "DEFAULT" \
						  "CONSTANT" \
						  "ROTATION" \
						  "SECONDARY" \
						  "ABSORPTION" \
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
						
set typedef(_scala_output)  { menu {		"averaged intensities" \
						"scaled, unmerged & no outliers"
                                                "both merged and unmerged" \
						"No output"}
					{	    "MERGED" \
						    "UNMERGED" \
						    "BOTH" \
						    "NONE" } }

set typedef(_scala_is_mode) { menu {	"summation intensities" \
					"profile fitted intensities (IPRs)" \
					"combine" }
				 {	"SUMMATION" \
					"PROFILE" \
					"COMBINE" } }

set typedef(_scala_sd_same)	{ menu {	"individual" \
						"same"} 
					{	"INDIVIDUAL" \
						"SAME" } }

set typedef(_scala_sd_apply)	{ menu {	"full" \
						"partial" \
						"all" } 
					{	"FULL" \
						"PARTIAL" \
						"ALL" } }

set typedef(_scala_sd_parameter) { menu {	"SdFac" \
						"SdB" \
						"SdAdd" } 
					{	"SDFAC" \
						"SDB" \
						"SDADD" } }

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

  return 1

}

# procedure run before script is written

#----------------------------------------------------------------
proc aimless_run { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

# If not defining multi runs then make sure everything set properly
  if { ! $array(MULTI_RUNS) } { 
    if { $array(NRUNS) > 0 } {
      set array(MULTI_RUNS) 1
    }
    set array(NRUNS) 1
    set array(RUN_DEFS,1) 1
    set array(RUN_MODE,1_1) all
    set array(NSCALES) 1
  }

  if { !$array(CUSTOM_AIMLESS) } {
    set array(REFINE) 1
  }

  if { !$array(CUSTOM_OUTPUT) } {
    SetValue $arrayname OUTPUT_TYPE MERGED
    SetValue $arrayname OUTPUT_SCALEPACK_TYPE NONE
    set array(OUTPUT) 1
  }

  if { ( [GetValue $arrayname OUTPUT_TYPE] == "NONE" ) && ( [GetValue $arrayname OUTPUT_SCALEPACK_TYPE] == "NONE" ) } {
    set array(OUTPUT) 0
  }

  set array(OUTPUT_TYPE_KEY) [GetValue $arrayname OUTPUT_TYPE]
  if { [GetValue $arrayname OUTPUT_TYPE] == "BOTH" } {
      set array(OUTPUT_TYPE_KEY) "MERGED UNMERGED"
  } elseif { [GetValue $arrayname OUTPUT_TYPE] == "NONE" } {
      set array(OUTPUT_TYPE_KEY) "NOMERGED"
  }

  set array(OUTPUT_SCALEPACK_TYPE_KEY) [GetValue $arrayname OUTPUT_SCALEPACK_TYPE]
  if { [GetValue $arrayname OUTPUT_SCALEPACK_TYPE] == "BOTH" } {
      set array(OUTPUT_SCALEPACK_TYPE_KEY) "MERGED UNMERGED"
  }

  set array(INPUT_FILES) ""
  for { set n 1 } { $n <= $array(N_HKLINX) } { incr n } {
      if { [GetMenuValue $arrayname HKLIN_FILETYPE] == "MTZ" } {
	  append array(INPUT_FILES) " HKLINX,$n"
      } elseif { [GetMenuValue $arrayname HKLIN_FILETYPE] == "XDS" } {
	  append array(INPUT_FILES) " XDS_SCA_IN,$n"
      } elseif { [GetMenuValue $arrayname HKLIN_FILETYPE] == "SCA" } {
	  append array(INPUT_FILES) " XDS_SCA_IN,$n"
      }
      
      if {$array(COPY)} {
	  # suppress NAME command in COPY mode   WHY?
##	  set array(USE_PREV_DATASET,$n) 1
      }

  }

  if { $array(HKLIN_FILETYPE) == "MTZ file" ||
       $array(HKLIN_FILETYPE) == "XDS file" } {
      set array(SHOW_CELL) 0
  }

  if { [regexp RESTORE [GetValue $arrayname INITIAL_MODE ] ] } {
    append array(INPUT_FILES) " RESTORE_FILE"
  }

# Always keep anomalous pairs in Truncate
  set array(ANOMALOUS) 1

# Only allow skip of Pointless in one input file (and COPY and HKLIN_SORTED)
  set array(HKLIN) $array(HKLINX,1)
  set array(DIR_HKLIN) $array(DIR_HKLINX,1)

  if { $array(N_HKLINX) > 1 } {
    set array(HKLIN_SORTED) 0
  }

  set array(RUN_POINTLESS) 1
  if { $array(COPY) && !$array(MULTIPLE_INPUTS)} {
    set array(RUN_POINTLESS) 0
  }

# output files and column identifiers
  if { ![AimlessCheckDatasets $arrayname] } { return 0 }

  return 1
}

#----------------------------------------------------------------
proc DatasetNotalreadyFound { arrayname dname } {
#----------------------------------------------------------------
# 
# Returns 1 if dataset dname is not already in output list (DATASETS_OUT) and 0 if it is 
  upvar #0 $arrayname array
 
  set ndsets [llength $array(DATASETS_OUT)]
  set found 1

  if { $ndsets > 0 } {
      for { set i 0 } { $i < $ndsets } { incr i } {
	  set testname [lindex $array(DATASETS_OUT) $i]
	  if { $testname == $dname } {
	      set found 0
	  }
      }
  }
  return $found
}
#----------------------------------------------------------------
proc AimlessCheckDatasets { arrayname } {
#----------------------------------------------------------------
# Sort out the datasets (and corresponding project names) and
# generate the DATASETS_OUT and PROJECTS_OUT lists
# Determine whether there are multiple output files and if so
# what are their names - check whether they already exist
# Set the column identifiers (if truncate is being run)
#
# Returns 1 if everything is okay to proceed and 0 otherwise 
  upvar #0 $arrayname array

  set array(DATASETS_OUT) ""
  set array(LABELS_OUT)   ""
  set array(N_SCALA_HKLOUT) 0

  # loop input files, copying dataset names
  for { set n 1 } { $n <= $array(N_HKLINX) } { incr n } {
      if { $n == 1 || ! $array(USE_PREV_DATASET,$n) } {
	  #  1st file or not use_previous_dataset
	  if { $array(MULTIDATASETS,$n) } {
	      # Multiple datasets in this file
	      set nadded 0
	      foreach dname $array(FILE_DNAME,$n) {
		  if { [ DatasetNotalreadyFound $arrayname $dname ] } {
		      lappend array(DATASETS_OUT) $dname
		      incr nadded
		  }
	      }
	      if { $nadded == 0 } {
		  # none added, clear USE_PREV_DATASET flag
		  set array(USE_PREV_DATASET,$n) 0
	      }
	  } else {
	      if { [ DatasetNotalreadyFound $arrayname $array(DNAME,$n) ] } {
		  lappend array(DATASETS_OUT) $array(DNAME,$n)
	      } else {
		  # none added, set USE_PREV_DATASET flag
		  set array(USE_PREV_DATASET,$n) 1
	      }
	  }
      }

      if  { $n > 1 && $array(USE_PREV_DATASET,$n) } {
	  # if USE_PREV_DATASET and name different from previous dataset,
	  #  force inclusion of NAME command
	  set n1 [ expr {$n-1} ]
	  if { $array(DNAME,$n1) != $array(DNAME,$n) } {
	      set array(SET_PXDNAME) 1
	  }
      }
  }

  # loop output datasets, set column labels to dataset name or input value (single dataset only)
  for { set i 1 } { $i <= [ llength $array(DATASETS_OUT) ] } { incr i } {
      # Deal with the column identifiers
      if { $array(RUN_TRUNCATE) } {
	  set dataset_name [lindex $array(DATASETS_OUT) $i]
	  lappend array(LABELS_OUT)  [ scala_get_column_id $arrayname $dataset_name ]
      }
  }
  # Validate the output dataset and project names
  set ndatasets [llength $array(DATASETS_OUT)]
  set nsets $ndatasets

  for { set i 0 } { $i < $nsets } { incr i } {
    set dataset_name [lindex $array(DATASETS_OUT) $i]
    if { [string trim $dataset_name] == "" } {
	  WarningMessage "One or more Dataset names have not been properly
assigned

You must assign valid Project and Dataset names before
running the task."
          return 0
    }
    # Special case: the default name from Mosflm is "Unspecified" or "New"
    # Warn the user and let them abort the run if they wish to change
    # it manually
    if { [regexp -- "^Unspecified$" $dataset_name] || [regexp -- "^New$" $dataset_name] } {
      if { [ regexp Abort [ChooseOptionDialog "Check Dataset Name" "Dataset" \
	      "A dataset will be output with the name

\"$dataset_name\"

It is recommended that you change this name to something else before
running the Aimless job."  \
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
  set n_outputfiles 0
  # base name
  set hklout "HKLOUT"

  if { $ndatasets < 1 } {
      WarningMessage "This task run will not generate any output files!

Please check the settings before rerunning."
      return 0
  }
  if { [regexp MERGED [GetValue $arrayname OUTPUT_TYPE]] &&
               $array(RUN_TRUNCATE) && $array(RUN_CAD) } {
      # only one file at end of Aimless->Ctruncate->CAD pipeline
      set array(OUTPUT_FILES) $hklout
      incr n_outputfiles
  } else {
      # Up to 4 files/dataset may be generated
  # Generate all the output file names and check these explicitly
      set array(OUTPUT_FILES) ""
      set basename [ GetFullFileName [FileRootName $array($hklout)] $array(DIR_$hklout)]
      set output_files ""
      set output_mergedmtz_files ""
      set existing_files 0
      set unmerged "_unmerged"
#  Loop datasets
      foreach dataset_name $array(DATASETS_OUT) {
	  set dsname ""
	  if { [llength $array(DATASETS_OUT)] > 1 } { set dsname "_[subst $dataset_name]"}
	  if { [regexp MERGED [GetValue $arrayname OUTPUT_TYPE]] } {
	      set output_file "[subst $basename][subst $dsname].mtz"
	      if { [file exists $output_file] } { incr existing_files }
	      lappend output_files $output_file
	      lappend output_mergedmtz_files $output_file
	  }
	  if { [regexp UNMERGED [GetValue $arrayname OUTPUT_TYPE]] } {
	      set output_file "[subst $basename][subst $dsname]$unmerged.mtz"
	      if { [file exists $output_file] } { incr existing_files }
	      lappend output_files $output_file
	  }
	  if { [regexp MERGED [GetValue $arrayname OUTPUT_SCALEPACK_TYPE]] } {
	      set output_file "[subst $basename][subst $dsname].sca"
	      if { [file exists $output_file] } { incr existing_files }
	      lappend output_files $output_file
	  }
	  if { [regexp UNMERGED [GetValue $arrayname OUTPUT_SCALEPACK_TYPE]] } {
	      set output_file "[subst $basename][subst $dsname]$unmerged.sca"
	      if { [file exists $output_file] } { incr existing_files }
	      lappend output_files $output_file
	  }
      }
      set message ""
      if { [llength $output_mergedmtz_files] > 1 } {
	  # Warning message about multiple output files
	  set message "This task run will output more than one dataset.

Aimless will output a separate file for each dataset, using the file name you
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
  # Okay to proceed
  return 1
}

#-------------------------------------------------------------------------
proc scala_get_column_id { arrayname dataset_name } {
#-------------------------------------------------------------------------
#  column name component for truncate

  upvar #0 $arrayname array
  if { [GetValue $arrayname COLUMN_ID_TYPE] == "DATASET" } {
    return $dataset_name
  } else {
    return $array(LABOUT_LABEL)
  }
}

#--------------------------------------------------------------------------------
proc ScalaDefineRun { arrayname counter } {
#--------------------------------------------------------------------------------
  SetToggleTitle $arrayname ScalaDefineRun $counter "Run $counter"

  CreateExtendingFrame RUN_DEFS ScalaRunOperator \
        "Add line to define a run" \
        "Add definition" \
      [ list \
	RUN_MODE \
	RUN_IMIN \
	RUN_IMAX \
	RUN_RMIN \
	RUN_RMAX \
	        ] \
	-counter $counter

   scala_set_run_menus $arrayname $counter
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
proc RunHasBeenSet  { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(NRUNS) > 0 } {
      set array(RUN_SET) 1
  }
  if { $array(NRUNS) > 1 } {
      set array(MULTI_RUNS) 1
  }
}
#------------------------------------------------------------------------
proc ScalaRunOperator  { arrayname i counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

# If there is only one run definition and we are drawing it now then
# set the selection to ALL

  if { $array(NRUNS) <= 1 && $array(RUN_DEFS,1) == 1 \
	&& $i == 1 && $counter == 1 } { set array(RUN_MODE,1_1) BATCHRANGE }

#  CreateLineTemplate RUN_TEMPLATE [list 0 0.15 0.4 0.45 0.55 0.55 ]

  CreateLine line \
    message "Include a set of batches in the run (RUN BATCH/CRYSTAL)" \
    help run \
    widget RUN_MODE \
    label "from" \
    widget RUN_IMIN  \
    label "to" \
      widget RUN_IMAX -command "RunHasBeenSet $arrayname" \
    toggle_display [Indxv RUN_MODE $counter $i ] open \
	[list BATCHRANGE XTALRANGE ]

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

  # Following are two subframes for the RUN ... DATASET option
  # The first is displayed when the input file does contain dataset
  # information
  # The second is displayed when there is none, so that the user is
  # not presented with a blank menu of possible datasets

}
#------------------------------------------------------------------------
proc SetAllowDnameEdit { arrayname counter } {
#------------------------------------------------------------------------
 upvar #0 $arrayname array
 
# don't display name edits if MULTIDATASET, nor if USE_PREV_DATASET
 set array(ALLOW_DNAME_EDIT) 1
 if { $array(MULTIDATASETS,$counter) || $array(USE_PREV_DATASET,$counter) } {
     set array(ALLOW_DNAME_EDIT) 0
 }

}
#------------------------------------------------------------------------
proc ProcessScalesMode { arrayname counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  
  if {[GetMenuValue $arrayname SCALES_MODE,$counter] == "DEFAULT"} {
      set array(SCALES_SPEC,$counter) 0
  } else {
      set array(SCALES_SPEC,$counter) 1
  }
  set array(SHOW_BFACTOR,$counter) $array(SCALES_SPEC,$counter)
  if {$array(SCALES_BFACTOR,$counter) == OFF} {
      set array(SHOW_BFACTOR,$counter) 0
  }
}
#------------------------------------------------------------------------
proc ScalaDefineScales { arrayname counter { multi 1 } } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $multi } {

  CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales_run" \
    label "For" \
    widget SCALES_RUN \
      -command "scala_update_scales_title  $arrayname $counter" \
    help "scales" \
    label "scale" \
    widget SCALES_MODE -command "ProcessScalesMode $arrayname $counter" \
    message "Use Bfactor scaling (SCALES BFACTOR)" \
    label "with" \
    help scales_bfactor \
    widget SCALES_BFACTOR  \
    label "Bfactor scaling" \
    toggle_display [Indxv SCALES_MODE $counter] hide DEFAULT

  CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales_run" \
    label "For" \
    widget SCALES_RUN \
      -command "scala_update_scales_title  $arrayname $counter" \
    help "scales" \
    label "scale" \
    widget SCALES_MODE -command "ProcessScalesMode $arrayname $counter" \
    toggle_display [Indxv SCALES_MODE $counter] open DEFAULT

  } else {
  
    SetSystemVar current_index_counter 1

    CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales" \
    label "Scale" \
    widget SCALES_MODE -command "ProcessScalesMode $arrayname $counter" \
    message "Use Bfactor scaling (SCALES BFACTOR)" \
    label "with" \
    help scales_bfactor \
    widget SCALES_BFACTOR  \
    label "Bfactor scaling" \
	toggle_display [Indxv SCALES_MODE $counter] hide [list DEFAULT]


    CreateLine line \
    message "Create scaling protocol for which run (or for all) (SCALES RUN)" \
    help "scales" \
    label "Scale" \
    widget SCALES_MODE -command "ProcessScalesMode $arrayname $counter" \
	toggle_display [Indxv SCALES_MODE $counter] open  [list DEFAULT]

  }

  CreateLine line \
    message "Define scaling mode along primary beam (SCALES ROTATION)" \
    help "scales_rotation" \
    label "Define scale ranges along rotation axis by" \
    widget SCALES_ROTATION \
    widget SCALES_ROTATION_ROT \
    toggle_display [Indxv SCALES_MODE $counter] open \
	[list ROTATION SECONDARY ABSORPTION SURFACE ]

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

# Bfactor subframe
  
  OpenSubFrame frame -toggle_display SHOW_BFACTOR,$counter hide 0

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

  if { $multi } { 
    scala_update_scales_title $arrayname $counter
  } else {
    SetSystemVar current_index_counter ""
  }

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
  upvar #0 $arrayname array

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
  if { [regexp MERGED [GetValue $arrayname OUTPUT_TYPE]] && \
	  $array(RUN_TRUNCATE) } {
    set array(SHOW_TRUNCATE) 1
  } else {
    set array(SHOW_TRUNCATE) 0
  }

  if { ( [GetValue $arrayname OUTPUT_TYPE] != "NONE" ) || ( [GetValue $arrayname OUTPUT_SCALEPACK_TYPE] != "NONE" ) } {
    set array(OUTPUT) 1
  }

}

#----------------------------------------------------------------------
proc UpdateSdCorrections { arrayname } {
#----------------------------------------------------------------------
# 
  upvar #0 $arrayname array
  set array(SD_CORRECT) 1
}

#----------------------------------------------------------------------
proc ScalaSdCorrections { arrayname counter } {
#----------------------------------------------------------------------
# sdcorrection initial values for each run (or all)

  upvar #0 $arrayname array

  CreateLine line \
    message "Set SD correction for all runs or specific runs" \
    help "sdcorrection_run" \
    label "For" \
    widget SD_RUNS  -command "UpdateSdCorrections $arrayname"\
    help "sdcorrection" \
    widget SD_APPLY   -command "UpdateSdCorrections $arrayname"\
    label "reflections  "  \
    help sdcorrection_run \
    message "Define initial values for SD corrections (SDCORRECTION)" \
    help "sdcorrection" \
    label "Initial  values: Sdfac" \
    widget SD_FAC -oblig   -command "UpdateSdCorrections $arrayname"\
    label "SdB" \
    widget SD_B   -command "UpdateSdCorrections $arrayname"\
    label "Sdadd" \
    widget SD_ADD -oblig   -command "UpdateSdCorrections $arrayname"

}

#-----------------------------------------------------------------------
proc PointlessExcludeBatch { arrayname counter } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

  OpenSubFrame frame -toggle_display MULTIPLE_INPUTS open 0
  # single input
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
  CloseSubFrame

  OpenSubFrame frame -toggle_display MULTIPLE_INPUTS open 1
  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches:" \
    widget EXCLUDE_BATCH_LIST \
    label "in file #" \
    widget EXCLUDE_BATCH_SERIES \
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
    label "in file #" \
    widget EXCLUDE_BATCH_SERIES \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open RANGE
  CloseSubFrame

    if { $array(EXCLUDE_BATCH) || $array(USE_RESOL_CUTOFF) } {
	set array(EXCLUDE_ANY) 1
    } else {
	set array(EXCLUDE_ANY) 0
    }

}

#-----------------------------------------------------------------------
proc ScalaResetPointless { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(POINTLESS_OPTIONS) 1
  if { !$array(CUSTOM_POINTLESS) } {
    set array(LAUE_MODE) 1
    set array(USE_HKLREF) 0
    set array(USE_XYZIN) 0
    set array(CHOOSE) 0
    set array(COPY) 0
    set array(POINTLESS_OPTIONS) 0
  }
}
#-----------------------------------------------------------------------
proc ScalaResetProcess { arrayname } {
#-----------------------------------------------------------------------
#  Scala flow control
  upvar #0 $arrayname array

  if { $array(CUSTOM_AIMLESS) } {
    set array(REFINE) 0
    set array(SHOW_SCALE_MODEL) 0
      
  } else {
    set array(REFINE) 1
    set array(SHOW_SCALE_MODEL) 1
  }
}
#-----------------------------------------------------------------------
proc ScalaResetShowScale { arrayname } {
#-----------------------------------------------------------------------
#  Scala flow control
  upvar #0 $arrayname array

  if { $array(REFINE) } {
    set array(SHOW_SCALE_MODEL) 1
      
  } else {
    set array(SHOW_SCALE_MODEL) 0
  }
}
#-----------------------------------------------------------------------
proc ScalaResetOutput { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { !$array(CUSTOM_OUTPUT) } {
#   reset defaults
      SetValue $arrayname OUTPUT_TYPE MERGED
      SetValue $arrayname OUTPUT_SCALEPACK_TYPE NONE
  }
}

#-----------------------------------------------------------------------
proc ScalaActivateRejectScale { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(REJECT_SCALE) 1

}
#-----------------------------------------------------------------------
proc ScalaActivateRejectMerge { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(MERGE_REJECT) 1

}

#-----------------------------------------------------------------------
proc PointlessHklin { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array

    # Dataset info #1
    if { $counter == 1 } {
	AimlessFirstDataset  $arrayname $counter
    }

    # HKLIN file: HKLOUT is final file from task
    CreateInputFileLine line \
	"Enter input file name (HKLIN)" \
	"HKLIN  \#$counter" \
	HKLINX DIR_HKLINX \
        -fileout HKLOUT DIR_HKLOUT _scaled \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-command "PointlessGetMtzStuff $arrayname $counter"

    if {$array(COPY)} {
	set array(USE_PREV_DATASET,$counter) 0
    }
    SetAllowDnameEdit $arrayname $counter

    CreateLine line \
	label "Multiple datasets in file, cannot change them here" -italic \
	toggle_display MULTIDATASETSOUT,$counter open 1
	
    # Dataset info #2
    if { $counter != 1 } {
	# Subsequent lines allow reuse of previous dataset
	PointlessSameDataset  $arrayname $counter
	set array(MULTIPLE_INPUTS) 1
    }
}
#-----------------------------------------------------------------------
proc AimlessFirstDataset { arrayname counter } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array
    # Define the first "base" dataset

    CreateLine line \
	label "Project name:" \
	widget PNAME  -command "PointlessChangedPXDname $arrayname" \
	label "crystal name:" \
	widget XNAME  -command "PointlessChangedPXDname $arrayname" \
	label "dataset name:" \
	widget DNAME  -command "PointlessChangedPXDname $arrayname" \
	toggle_display MULTIDATASETSOUT,$counter open 0

}
#---------------------------------------------------------------------
proc PointlessGetMtzStuff { arrayname n } {
#---------------------------------------------------------------------
# Various things to set up for newly assigned MTZ file

    # Fetch the project, crystal and dataset from an MTZ file
    # and populate the appropriate parameters
    upvar #0 $arrayname array
    upvar #0 $n counter

    # clear names
    set array(FILE_PNAME,$n) ""    
    set array(FILE_XNAME,$n) ""    
    set array(FILE_DNAME,$n) ""    

    set mtz [GetFullFileName0 $arrayname HKLINX,$n]
    set xtals [GetMtzXtals $mtz]
    if { [llength $xtals] == 0 } {
	# No data
	return
    }
    # FILE_[PXD]NAME are names from input file(s)
    # DNAMEs will be used to populate the DATASETS_IN array

    set array(DATASETS_IN) ""
    # loop crystals to extract dataset names
    foreach xname $xtals {
      lappend array(FILE_XNAME,$n) $xname
      # dataset names for this crystal
      set dnames [ GetMtzDatasetsInXtal $mtz $xname ]
      foreach dname $dnames {
         lappend array(DATASETS_IN) $dname
	 lappend array(FILE_DNAME,$n) $dname
	 # Lookup the project name associated with this crystal/dataset combination
	 GetMtzParamFromDataset $mtz $xname $dname "PNAME" pname
	 lappend array(FILE_PNAME,$n) $pname
      }
    }

    set array(N_FILE_DATASETS,$n) [ llength $array(DATASETS_IN)]
 
    set array(MULTIDATASETS,$n) 0
    if { $array(N_FILE_DATASETS,$n) > 1 } {
	set array(MULTIDATASETS,$n) 1
	set array(USE_PREV_DATASET,$n) 0
    }
    set array(MULTIDATASETSOUT,$n) $array(MULTIDATASETS,$n)

    # Set XNAME for file to first one (if there's more than one)
    # similarly for the dataset name
    set array(XNAME,$n) [lindex $xtals 0]
    set array(DNAME,$n) [lindex [GetMtzDatasetsInXtal $mtz $array(XNAME,$n)] 0]

    # Lookup the project name associated with this crystal/dataset combination
    GetMtzParamFromDataset $mtz $array(XNAME,$n) $array(DNAME,$n) "PNAME" pname
    set array(PNAME,$n) $pname

    # save current merged status
    set current_merged $array(MERGED_DATA)
    # is it merged?
    PointlessDetermineMerged $arrayname HKLINX,$n MERGED_DATA 

    if { $current_merged == 1 || $array(MERGED_DATA) == 1 } {
      WarningMessage    "This file is merged: input files must be unmerged"
    }

    set array(HKLIN_SORTED) 1
    # check if input file is sorted and set RUN_SORTMTZ appropriately
    if { [ GetParamFromFile MTZ $mtz UNMERGED_SORTED sorted] } {
      if { $sorted == 0 } {
#  not sorted
        set array(HKLIN_SORTED) 0
      } else {
        set array(HKLIN_SORTED) 1
      }
    }

    set array(FILE_RESOLUTION_MIN,$n) $array(EXCLUDE_RESOLUTION_MIN)
    set array(FILE_RESOLUTION_MAX,$n) $array(EXCLUDE_RESOLUTION_MAX)

    for { set i 1 } { $i <= $n } { incr i } {
	# largest resolution range
	if { $array(EXCLUDE_RESOLUTION_MIN) < $array(FILE_RESOLUTION_MIN,$i) } {
	    set array(EXCLUDE_RESOLUTION_MIN) $array(FILE_RESOLUTION_MIN,$i)
	}
	if { $array(EXCLUDE_RESOLUTION_MAX) > $array(FILE_RESOLUTION_MAX,$i) } {
	    set array(EXCLUDE_RESOLUTION_MAX) $array(FILE_RESOLUTION_MAX,$i)
	}
    }

    return
}
#-----------------------------------------------------------------------
proc PointlessXdsin { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array
  
    # Dataset info #1
    if { $counter == 1 } {
	PointlessFirstDataset  $arrayname $counter
    }

    # XDS file
    CreateInputFileLine line \
	"Enter input XDS file name (XDSIN)" \
	"XDS \#$counter" \
	XDS_SCA_IN DIR_XDS_SCA_IN \
	-command "PointlessGetXdsDataset $arrayname $counter" \
        -fileout HKLOUT DIR_HKLOUT _scaled

    # Dataset info #2
    if { $counter != 1 } {
	PointlessSameDataset  $arrayname $counter 
	set array(MULTIPLE_INPUTS) 1
    }


    set array(N_FILE_DATASETS,$counter) 1 
    set array(MULTIDATASETS,$counter) 0 
    set array(MULTIDATASETSOUT,$counter) 0

}

#-----------------------------------------------------------------------
proc PointlessScain { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array
  
    # Dataset info #1
    if { $counter == 1 } {
	PointlessFirstDataset  $arrayname $counter
    }

    # SCA file
    CreateInputFileLine line \
	"Enter input Scalepack file name (SCAIN)" \
	"SCA \#$counter" \
	XDS_SCA_IN DIR_XDS_SCA_IN \
	-command "PointlessGetXdsDataset $arrayname $counter" \
        -fileout HKLOUT DIR_HKLOUT _scaled    

    # Dataset info #2
    if { $counter != 1 } {
	PointlessSameDataset  $arrayname $counter 
	set array(MULTIPLE_INPUTS) 1
    }

    set array(N_FILE_DATASETS,$counter) 1 
    set array(MULTIDATASETS,$counter) 0 
    set array(MULTIDATASETSOUT,$counter) 0
}
#-----------------------------------------------------------------------
proc PointlessSameDataset { arrayname counter } {
#-----------------------------------------------------------------------
 upvar #0 $arrayname array

 set array(ALLOW_SAME_DNAME) 1
 
 if {$array(COPY)} {
     set array(USE_PREV_DATASET,$counter) 0
     set array(ALLOW_SAME_DNAME) 0
 }
 if {$array(MULTIDATASETS,$counter)} {
     set array(ALLOW_SAME_DNAME) 0
 }

    # Subsequent lines allow reuse of previous dataset
    CreateLine line \
	widget USE_PREV_DATASET -command "SetAllowDnameEdit $arrayname $counter"\
	label "Assign to the same dataset as the previous file" \
        toggle_display ALLOW_SAME_DNAME open 1
##        toggle_display MULTIDATASETS,$counter open 0

# don't display name edits if MULTIDATASET, nor if USE_PREV_DATASET
    CreateLine line \
	label "     Project name:" \
	widget PNAME \
	label "crystal name:" \
	widget XNAME \
	label "dataset name:" \
	widget DNAME \
        toggle_display ALLOW_DNAME_EDIT open { 1 }
}
#---------------------------------------------------------------------
proc PointlessGetXdsDataset { arrayname n } {
#---------------------------------------------------------------------
    # Set the project, crystal and dataset from the previous ones
    upvar #0 $arrayname array

    if { $n > 1 } {

	set np [expr  $n - 1 ]
	
	# Set crystal to previous one (if there's more than one)
	# similarly for the dataset name
	set array(PNAME,$n) $array(PNAME,$np)
	set array(XNAME,$n) $array(XNAME,$np)
	set array(DNAME,$n) $array(DNAME,$np)
    }

    set basename "NEW"
    if { [GetMenuValue $arrayname HKLIN_FILETYPE] == "XDS" } {
	set basename "XDS"
    } elseif { [GetMenuValue $arrayname HKLIN_FILETYPE] == "SCA" } {
	set basename "SCA"
    }

    # set names
    if {$array(PNAME,$n) == ""}  {
	set array(PNAME,$n) [subst $basename]project
	PointlessChangedPXDname $arrayname
    }
    if {$array(XNAME,$n) == ""}  {
	set array(XNAME,$n) [subst $basename]crystal
	PointlessChangedPXDname $arrayname
    }
    if {$array(DNAME,$n) == ""}  {
	set array(DNAME,$n) [subst $basename]dataset
	PointlessChangedPXDname $arrayname
    }
    set array(FILE_PNAME,$n) $array(PNAME,$n)
    set array(FILE_XNAME,$n) $array(XNAME,$n)
    set array(FILE_DNAME,$n) $array(DNAME,$n)

    if { [file extension $array(XDS_SCA_IN,$n)] == ".raw"} {
	# looks like a Saint file, can refine this
	set array(CUSTOM_AIMLESS) 0
	ScalaResetProcess $arrayname
    }

    return
}
#-----------------------------------------------------------------------
proc AimlessSetPartial { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

# Set flag to write PARTIAL command

    set array(IS_PARTIALS) 1
}
#-----------------------------------------------------------------------
proc AimlessSetImode { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

# Set flag to write INTENSITIES command
    set array(IS_SET) 1
}
#-----------------------------------------------------------------------
proc AimlessSetImid { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

# Set flag for COMBINE Imid
    set array(IS_COMBINE_IMIDSET) 1
# Set flag to write INTENSITIES command
    set array(IS_SET) 1
}
#-----------------------------------------------------------------------
proc AimlessSetIpower { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

# Set flag for COMBINE power
    set array(IS_COMBINE_POWERSET) 1
# Set flag to write INTENSITIES command
    set array(IS_SET) 1
}
#-----------------------------------------------------------------------
proc PointlessResetInputFileCount { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

    set array(N_HKLINX) 1
    set array(MULTIPLE_INPUTS) 0
    if { $array(HKLIN_FILETYPE) != "MTZ" } {
	set array(TEMPLATE_FILENAMES) 0
    }
    set array(FILE_PNAME,1) ""
    set array(FILE_XNAME,1) ""
    set array(FILE_DNAME,1) ""
    set array(PNAME,1) ""
    set array(XNAME,1) ""
    set array(DNAME,1) ""

    if {[GetMenuValue $arrayname HKLIN_FILETYPE] == "SCA" } {
	# Can't scale Scalepack files (but can SAINT files, see elsewhere)
	set array(CUSTOM_AIMLESS) 1
	ScalaResetProcess $arrayname
    }
}
#---------------------------------------------------------------------
proc PointlessLaue { arrayname } {
#---------------------------------------------------------------------
    # If Laue is set, turn off reference, choose & copy
    #  else revert to copy
    upvar #0 $arrayname array

    if { $array(LAUE_MODE) } {
	set array(USE_HKLREF) 0
	set array(USE_XYZIN) 0
	set array(CHOOSE) 0
	set array(COPY) 0
	set array(POINTLESS_OPTIONS) 1
    } else {
	set array(USE_HKLREF) 0
	set array(USE_XYZIN) 0
	set array(CHOOSE) 0
	set array(COPY) 1
	set array(POINTLESS_OPTIONS) 0
    }
}
#---------------------------------------------------------------------
proc PointlessRef { arrayname } {
#---------------------------------------------------------------------
    # If reference is set, then turn off choose & copy, & turn on HKLOUT
    #  else revert to Laue mode
    upvar #0 $arrayname array

    if { $array(USE_HKLREF) } {
	set array(LAUE_MODE) 0
	set array(CHOOSE) 0
	set array(COPY) 0
	set array(WRITE_HKLOUT) 1
	set array(POINTLESS_OPTIONS) 0
    } else {
	set array(LAUE_MODE) 1
	set array(CHOOSE) 0
	set array(COPY) 0
	set array(POINTLESS_OPTIONS) 1
    }
}

#---------------------------------------------------------------------
proc PointlessChoose { arrayname } {
#---------------------------------------------------------------------
    # If choose is set, then must have HKLOUT, unset reference
    #  else revert to Laue mode
    upvar #0 $arrayname array

    if { $array(CHOOSE) } {
	set array(WRITE_HKLOUT) 1
	set array(LAUE_MODE) 0
	set array(USE_HKLREF) 0
	set array(COPY) 0
	set array(POINTLESS_OPTIONS) 1
    } else {
	set array(LAUE_MODE) 1
	set array(USE_HKLREF) 0
	set array(COPY) 0
	set array(POINTLESS_OPTIONS) 0
    }
}
#---------------------------------------------------------------------
proc PointlessCopy { arrayname } {
#---------------------------------------------------------------------
    # If copy is set, then must have HKLOUT, unset reference
    upvar #0 $arrayname array

    if { $array(COPY) } {
	set array(WRITE_HKLOUT) 1
	set array(LAUE_MODE) 0
	set array(USE_HKLREF) 0
	set array(CHOOSE) 0
	set array(POINTLESS_OPTIONS) 0
    } else {
	set array(LAUE_MODE) 1
	set array(CHOOSE) 0
	set array(USE_HKLREF) 0
	set array(POINTLESS_OPTIONS) 1
    }
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================
#-----------------------------------------------------------------------
proc  aimless_task_window { arrayname } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

  #  Panels after top level and file assign
  if { [CreateTaskWindow $arrayname  \
        "Aimless - Pointless, Aimless, Ctruncate" "Aimless" \
        [ list \
        "Resolution and batch exclusions" \
	"Options for Pointless" \
        "Scaling Protocols" \
        "Scaling Protocol" \
        "Define Runs" \
        "Accepted and Excluded Data" \
        "Reject Outliers" \
        "SD Correction Protocols" \
        "Observations Used & Handling of Partials"  \
	"Scaling Details" \
	"Truncate: convert to structure amplitudes and final output" \
	     ] ] == 0 } return

  SetProgramHelpFile aimless


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      label "Custom scaling options: default is to determine Laue group, refine & apply scales, and write merged data" -italic

  CreateLine line \
      label "  " \
      message "Options to match indices to reference, choose solution or skip" \
      widget CUSTOM_POINTLESS \
      -command "ScalaResetPointless $arrayname" \
      label "Customise symmetry determination" \
      message "Change default to refine and apply scales" \
      widget CUSTOM_AIMLESS \
      -command "ScalaResetProcess $arrayname" \
      label "Option to skip scaling & just merge" \
      message "Change default to write averaged intensities" \
      widget CUSTOM_OUTPUT \
      -command "ScalaResetOutput $arrayname" \
      label "Customise output options"
  #-------------------------------------------------------------------
  #  Option for Pointless
  #-------------------------------------------------------------------
  OpenSubFrame frame -toggle_display CUSTOM_POINTLESS open 1
  CreateLine line \
      label "    " \
      message "Check symmetry-related observations to determine Laue group & space group" \
      widget LAUE_MODE \
      label "Determine Laue group   "  \
      -command "PointlessLaue $arrayname" \
      message "Use reference file to get consistent indexing" \
      widget USE_HKLREF \
      label "Match index to reference  "  \
      -command "PointlessRef $arrayname" \
      message "Choose a previously determined solution by number or group name" \
      widget CHOOSE \
      label "Choose a previous solution" \
      -command "PointlessChoose $arrayname" \
      message "Sort one or more files & output together" \
      widget COPY \
      label "Just sort input file" \
      -command "PointlessCopy $arrayname"
  CloseSubFrame

  #-------------------------------------------------------------------
  #  Option to skip scaling (#*# unecessary!)
  #-------------------------------------------------------------------
#*#  OpenSubFrame frame -toggle_display CUSTOM_AIMLESS open 1
#*#    set array(REFINE) 0
#*#    CreateLine line \
#*#        label "    " \
#*#	message "Do refinement of scale factors (cycles)" \
#*#	help "cycles" \
#*#	widget REFINE -command "ScalaResetShowScale $arrayname"\
#*#	label "Refine scale factors" \
#*#	message "Analyse discrepancies and correct SDs (SDCORRECTION)"
#*#
#*#  CloseSubFrame  
  #-------------------------------------------------------------------
  #  Options for output
  #-------------------------------------------------------------------
  OpenSubFrame frame -toggle_display CUSTOM_OUTPUT open 1

  CreateLine line \
    message "Choose type of data output to reflection file (OUTPUT)" \
    help "output" \
    label " MTZ Output" \
    widget OUTPUT_TYPE -command "scala_update_truncate_display_mode $arrayname " \
    label "   ScalePack Output" \
    widget OUTPUT_SCALEPACK_TYPE -command "scala_update_truncate_display_mode $arrayname ;"

  CloseSubFrame

  #-------------------------------------------------------------------
  #  Option for anomalous
  #-------------------------------------------------------------------
  CreateLine line \
    help anomalous \
    message "I(+) and I(-) are separated for outliers and Rmerge" \
    widget ANOMALOUS_ON \
    label "Separate anomalous pairs for outlier rejection & merging statistics"

  #-------------------------------------------------------------------
  # Options for running TRUNCATE and CAD
  #-------------------------------------------------------------------
  # These should only be available for OUTPUT AVERAGE since the
  # other modes only produce batch files
  OpenSubFrame frame -toggle_display OUTPUT_TYPE open [ list MERGED BOTH ]

  CreateLine line \
    message "Append table of Wilson plot data to the Scala log file" \
    widget RUN_TRUNCATE  \
    label "Run" \
    widget TRUNCATE_PROG \
    label "to output Wilson plot and SFs after scaling" \
    message "If there are multiple datasets then merge into a single MTZ file using CAD"\
    widget RUN_CAD \
    label "and output a single MTZ file" \
    toggle_display RUN_TRUNCATE open 1

  CreateLine line \
    message "Append table of Wilson plot data to the Scala log file" \
    widget RUN_TRUNCATE  \
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
#  CreateLine line \
#    message "Apply scales, sum or scale partials, reject outliers, but do not average observations (OUTPUT UNMERGED)" \
#    widget UNMERGED_TOGETHER \
#    label "Output a single unmerged batch MTZ file" \
#    toggle_display OUTPUT open UNMERGED

#=FILES================================================================

  OpenFolder file 

  # Input reflection files, either
  #  1) multiple input files to Pointless
  #  2) single file for Aimless (COPY option if only one file specified)

  # >>> One or more files for Pointless
  CreateLine line \
      message "Set type for input reflection file(s): MTZ, XDS or Scalepack" \
      label "Input reflection file type:" \
      widget HKLIN_FILETYPE -command "PointlessResetInputFileCount $arrayname" \
      label "    " \
      widget TEMPLATE_FILENAMES \
      label "treat filenames as Mosflm templates (ie to match multiple files)" \
      toggle_display HKLIN_FILETYPE open "MTZ"

  CreateLine line \
      message "Set type for input reflection file(s): MTZ, XDS or Scalepack" \
      label "Input reflection file type:" \
      widget HKLIN_FILETYPE -command "PointlessResetInputFileCount $arrayname" \
      toggle_display HKLIN_FILETYPE hide "MTZ"

  # MTZ file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "MTZ"

  CreateExtendingFrame N_HKLINX PointlessHklin \
      "Enter name of MTZ file" \
      "Add File" \
      [list HKLINX \
	   DIR_HKLINX \
	   FILE_RESOLUTION_MIN FILE_RESOLUTION_MAX \
	   USE_PREV_DATASET PNAME XNAME DNAME \
	   MULTIDATASETS MULTIDATASETSOUT \
	  ]

  CloseSubFrame

  # XDS file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "XDS"

  CreateExtendingFrame N_HKLINX PointlessXdsin \
      "Enter name of XDS file" \
      "Add File" \
      [list XDS_SCA_IN \
	   DIR_XDS_SCA_IN \
	   MULTIDATASETS MULTIDATASETSOUT \
	   USE_PREV_DATASET PNAME XNAME DNAME] 

  CloseSubFrame

  # SCA file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "SCA"

  CreateExtendingFrame N_HKLINX PointlessScain \
      "Enter name of Scalepack file" \
      "Add File" \
      [list XDS_SCA_IN \
	   DIR_XDS_SCA_IN \
	   MULTIDATASETS MULTIDATASETSOUT \
	   USE_PREV_DATASET PNAME XNAME DNAME] 

  CreateLine  line  \
      message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
      help "cell" \
      widget SHOW_CELL -toggleon \
      label "Cell dimensions " \
      widget CELL_1  -oblig \
      widget CELL_2  -oblig \
      widget CELL_3  -oblig \
      widget CELL_4  -oblig \
      widget CELL_5  -oblig \
      widget CELL_6  -oblig   

  CloseSubFrame

  # Reference file for Pointless
  # Optional Reference File
  OpenSubFrame frame -toggle_display USE_HKLREF open  1
    CreateLine line \
      message "Reference file MTZ or PDB" \
      widget USE_XYZIN \
      label "Reference file is coordinate file (PDB) not MTZ" \
      toggle_display USE_XYZIN  open 1

    CreateLine line \
      message "Reference file MTZ or PDB" \
      widget USE_XYZIN \
      label "Reference file is reflection file (MTZ) not PDB" \
      toggle_display USE_XYZIN open 0

    OpenSubFrame frame2 -toggle_display USE_XYZIN open 0
      CreateInputFileLine line \
        "Enter input reference MTZ file name (HKLREF)" \
        "Reference MTZ" \
        HKLREF DIR_HKLREF \
        -command "PointlessDetermineMerged $arrayname HKLREF MERGED_REF ; PointlessMtzLabels $arrayname HKLREF F_REF"
       # Label assignments if merged
      CreateLabinLine line \
        "Choose either intensities, or amplitudes (which will be squared to intensities) (LABREF)" \
        HKLREF "I or F label" F_REF { * } \
        -toggle_display  MERGED_REF open { 1 }
    CloseSubFrame
    OpenSubFrame frame2 -toggle_display USE_XYZIN open 1
      CreateInputFileLine line \
        "Enter input reference PDB file name (XYZIN)" \
        "Reference PDB" \
        XYZIN DIR_XYZIN

    CloseSubFrame

  CloseSubFrame
  # <<< files for Pointless

  UniqueifyFrame2

  CreateOutputFileLine line \
      "Enter name of output files (HKLOUT)" \
      "HKLOUT   " \
      HKLOUT DIR_HKLOUT
  
#-----------------------------------------------------Resolution and batch exclusions

  OpenFolder 1

  CreateLine line \
    message "Resolution exclusion criteria applied to all data (RESOLUTION) " \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Exclude data resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    widget EXCLUDE_BATCH \
    label "Exclude selected batches"

  OpenSubFrame frame -toggle_display EXCLUDE_BATCH open 1

  CreateExtendingFrame N_EXCLUDE_BATCH PointlessExcludeBatch \
    "Select batches from the input file to be excluded altogether" \
    "Add batches" \
    [list EXCLUDE_BATCH_DEFINE \
          EXCLUDE_BATCH_LIST \
          EXCLUDE_BATCH_FIRST \
          EXCLUDE_BATCH_LAST ]

  CloseSubFrame
#------------------------------------------------------------------Choose Solution
  OpenFolder 2  POINTLESS_OPTIONS open 1 hide

  OpenSubFrame frame -toggle_display CHOOSE open 1
  CreateLine line \
      label "Choice of Laue or space group from POINTLESS:" -italic
  PointlessChooseSolution $arrayname
  CloseSubFrame

  OpenSubFrame frame -toggle_display LAUE_MODE open  1
  CreateLine line \
      message "Choose setting option: CELL-BASED or SYMMETRY-BASED" \
      widget SET_SETTING -toggleon \
      widget SETTING_CHOICE 
  CloseSubFrame

#---------------------------------------------------------scaling protocols

  OpenFolder 3 MULTI_RUNS open 1 hide
    OpenSubFrame frame -toggle_display SHOW_SCALE_MODEL open 1 

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
	     SECONDARY_LMAX \
	     SURFACE_LMAX \
	     SURFACE_POLE \
	     SCALES_RUN \
	     SCALES_MODE \
	     SCALES_BFACTOR \
	     SCALES_BROTATION \
	     SCALES_BFACTOR_TIME \
	     SCALES_ROTATION \
	     SCALES_ROTATION_ROT \
	     SECONDARY_LMAX \
	     SURFACE_LMAX \
	     SURFACE_POLE \
	    ]
    CloseSubFrame

  OpenFolder 4 MULTI_RUNS open 0 hide
    OpenSubFrame frame -toggle_display SHOW_SCALE_MODEL open 1

      ScalaDefineScales $arrayname 1 0
    CloseSubFrame

  CreateLine line \
      label "No scaling, only merge" -italic \
      toggle_display SHOW_SCALE_MODEL open 0


#------------------------------------------------------------------Define runs
  OpenFolder 5 closed

  CreateLine line \
    message "User-specified runs" \
    widget RUN_SET  \
    label "Override automatic definition of 'runs' to mark discontinuities in data"    

  CreateToggleFrame NRUNS ScalaDefineRun \
        "Add definition of another run of reflections" "Define run" \
         "Add Run Definition"  \
      [ list RUN_DEFS ]  \
	-child ScalaRunOperator \
	-edit scala_set_run_menus

#------------------------------------------------------------------Exclude data
  OpenFolder 6 closed
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

  CreateLine line \
     help ACCEPT \
     message "Set cut-off BG gradient for accepting observations previously rejected by MOSFLM (ACCEPT BGGRADIENT)" \
     widget ACCEPT_BGGRADIENT \
            -toggleon \
     label "Accept observations with BG gradient less than" \
     widget BGGRADIENT

  CreateLine line \
     help ACCEPT \
     message "Accept observations on detector edgepreviously rejected by MOSFLM (ACCEPT OVERLOADS)" \
     widget ACCEPT_EDGE \
     label "Accept observations on edge of detector"

  # Excluded Datasets
#  CreateLine line \
#    label "Exclude datasets from scaling:    " -italic \
#    help exclude_dname \
#    message "Select a dataset from the input file to be excluded altogether" \
#    widget EXCLUDE_DATASET \
#    label "Exclude selected datasets"

#  OpenSubFrame frame -toggle_display EXCLUDE_DATASET open 1

#  CreateExtendingFrame N_EXCLUDE_DATASETS ScalaExcludeDataset \
#    "Select datasets from the input file to be excluded altogether" \
#    "Add dataset" \
#    [list EXCLUDE_DATASET_NAME]

#  CloseSubFrame

#----------------------------------------------------Reject outliers

  OpenFolder 7 closed

  CreateLine line \
    message "Exclude very large E values(EXCLUDE EMAX)" \
    label Exclude \
    widget REJECT_EMAX \
    widget REJECT_EMAX_EMAX \
    toggle_display REJECT_EMAX open

    CreateLine line \
      message "Reject outliers during scaling stage (REJECT)" \
      help "reject" \
      widget REJECT_SCALE \
      label "Override default criteria for rejecting outliers in scaling" 

    CreateLine line \
      message "Reject outliers during scaling stage (REJECT)" \
      help "reject" \
      label "Scaling" \
	-italic \
      label ": Reject Is >" \
      help reject_sdrej \
      widget REJECT_SDMAX \
	-width 3 \
        -command "ScalaActivateRejectScale $arrayname" \
      label "SDs from mean or" \
      help reject_sdrej2 \
      widget REJECT_SDMAX2 \
	-width 3 \
        -command "ScalaActivateRejectScale $arrayname" \
      label "SDs if two observations  " \
      widget REJECT_COMBINE \
        -command "ScalaActivateRejectScale $arrayname" \
      label "Comparison across all datasets"


  CreateLine line \
      message "Reject outliers during final merging  stage (REJECT)" \
      help "reject" \
      label "Final merge" \
	-italic \
      label ": Reject Is >" \
      help reject_sdrej \
      widget MERGE_REJECT_SDMAX \
	-width 3 \
        -command "ScalaActivateRejectMerge $arrayname" \
      label "SDs from mean or" \
      help reject_sdrej2 \
      widget MERGE_REJECT_SDMAX2 \
	-width 3 \
        -command "ScalaActivateRejectMerge $arrayname" \
      label "SDs if two observations or"

   CreateLine line \
      message "Reject outliers during final merging  stage (REJECT)" \
      label "    " \
      widget MERGE_REJECT_ALL \
        -command "ScalaActivateRejectMerge $arrayname" \
      label "SDs for all data" \
      help reject_byrun \
      widget MERGE_REJECT_COMBINE \
        -command "ScalaActivateRejectMerge $arrayname" \
      label "Comparison across all datasets"

#-------------------------------------------------------SD corrections

  OpenFolder 8 closed

  CreateLine line \
      message "Set SD correction options" \
      widget SD_REFINE -command "UpdateSdCorrections $arrayname"\
      label "Refine SD correction parameters" \
      widget SD_SAME  -command "UpdateSdCorrections $arrayname"\
      label "Use same parameters for all runs" \
      message "Fix all SdB parameters" \
      widget SD_FIXSDB  -command "UpdateSdCorrections $arrayname"\
      label "Fix SdB"

  CreateLine line \
      widget SD_DAMP_SET -toggleon \
      widget SD_DAMP  -command "UpdateSdCorrections $arrayname" \
      label "damp factor for SD refinement" \
      widget SD_TIE_SDB -toggleon \
      label "tie SdB to" \
      widget SD_TIE_SDB_TARGET -command "UpdateSdCorrections $arrayname"\
      label " with SD" \
      widget SD_TIE_SDB_SD -command "UpdateSdCorrections $arrayname"

 CreateToggleFrame NSDS ScalaSdCorrections \
        "Define SD correction" "Define SD correction" \
        "Add SD Correction Protocol"   \
      [ list SD_RUNS \
	    SD_APPLY \
		SD_FAC \
		SD_B \
		SD_ADD
       ]

##-------------------------------------------------------Observations Used

  OpenFolder 9 closed

  SetProgramHelpFile "aimless"
  CreateLine line \
    message "Choose how to use partial reflections (INTENSITIES)" \
    help "intensities" \
    label "Use" \
    widget IS_MODE -command "AimlessSetImode $arrayname" \
    toggle_display IS_MODE hide COMBINE 

  CreateLine line \
    message "Choose how to use partial reflections (INTENSITIES)" \
    help "intensities" \
    label "Use" \
    widget IS_MODE -command "AimlessSetImode $arrayname" \
    label " mid-intensity" \
    widget IS_COMBINE_IMID -command "AimlessSetImid $arrayname" \
    label " power " \
    widget IS_COMBINE_POWER -command "AimlessSetIpower $arrayname" \
    toggle_display IS_MODE open COMBINE 


  CreateLine line \
    message "Only accept partials with total fraction between (INTENSITIES (NO)TEST" \
    help "partials_notest" \
    widget IS_TEST -toggleon -command "AimlessSetPartial $arrayname"\
    label "Only accept partials with total fraction between" \
    widget IS_TEST_MIN -command "AimlessSetPartial $arrayname"\
    label "and" \
    widget IS_TEST_MAX

  CreateLine line \
    message "Check consistency of MPART flag (INTENSITIES (NO)CHECK)" \
    help "partials_nocheck" \
    widget IS_CHECK -command "AimlessSetPartial $arrayname"\
    label "Apply fraction test if MPART flag present but inconsistent"

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((INTENSITIES (NO)CORRECT)" \
    help "partials_correct" \
    widget IS_CORRECT -toggleon -command "AimlessSetPartial $arrayname"\
    label "Scale partials in range" \
    widget IS_CORRECT_LIMIT -command "AimlessSetPartial $arrayname"\
    label "to lower acceptance limit" \
    toggle_display IS_CORRECT open 1

  CreateLine line \
    message "Scale partials in range from specified limit to rejection minimum ((INTENSITIES (NO)CORRECT)" \
    help "partials_correct" \
    widget IS_CORRECT -command "AimlessSetPartial $arrayname"\
    label "Scale partials outside rejection range" \
    toggle_display IS_CORRECT open 0

  CreateLine line \
    message "Use partials which have missing part? (INTENSITIES (NO)GAP" \
    help "partials_nogap" \
    widget IS_GAP -command "AimlessSetPartial $arrayname"\
    label "Accept partials with gaps  " \


#--------------------------------------------------------scaling details
  OpenFolder 10 closed

  CreateLine line \
    message "Set number of cycles of refinement (CYCLES)" \
    help "cycles" \
    widget CYCLES_FLAG -toggleon \
    label "Refine scale factors for" \
    widget CYCLES \
    label "cycles"

  CreateLine line \
      widget SELECT -toggleon \
      widget SELECT_IOVSDMIN \
      label "minimum I/sd for 1st round scaling" \
      widget SELECT2 -toggleon \
      widget SELECT_EMIN \
      label "minimum E for 2nd round scaling"

  CreateLine line \
    message "Tie primary beam scaling factors together if they vary too wildly (TIE)" \
    help "tie" \
    widget TIE_ROTATION \
	-toggleon \
    label "Restrain neighbouring scale factors on rotation axis to SD" \
    widget TIE_ROTATION_SD \
    toggle_display SCALES_MODE closed CONSTANT

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
    message "Tie B factors to zero (TIE)" \
    help "tie" \
    widget TIE_ZEROB \
        -toggleon \
    label "Restrain Bfactors to zero with SD" \
    widget TIE_ZEROB_SD


#-----------------------------------------------------------truncate

  OpenFolder 11 closed
  SetProgramHelpFile "truncate"

  CreateLine line \
    message "Calculate an approximate atom composition based on the number of residues" \
    label "Estimated number of residues in the asymmetric unit" \
    help nresidue \
    widget CONTENTS_NRES -oblig \
    toggle_display TRUNCATE_PROG open TRUNCATE


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


#----------------------------------------------Miscellaneous jobs on startup

# Update the dataset info from the file if there is one
# already set
# PJX this seems to delete existing settings? so comment it out for now
##  if [file exists [GetFullFileName0 $arrayname HKLIN]] {
##    ScalaGetDatasets $arrayname
##  }
}

#=END=======================================================================


