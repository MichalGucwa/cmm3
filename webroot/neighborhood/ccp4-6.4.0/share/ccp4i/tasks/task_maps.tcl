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
# task_maps.tcl --
#
# Create task-specific maps from previously run job
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc task_maps_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  set typedef(_task_maps_taskname) { menu { "Run Refmac" "Run Refmac5" \
			"NCS Phased Refinement"
		"Run DM" "Run Solomon" } { refmac refmac5 ncsref dm solomon } }

  return 1
}


#-----------------------------------------------------------------------
proc task_maps_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [DbGetJobData $array(JOB_ID) STATUS] == "" } {
    WarningMessage "There is no task number $array(JOB_ID)"
    return 0
  }

  set old_taskname [DbGetJobData $array(JOB_ID) TASKNAME]
  if { [lsearch [list refmac5 refmac ncsref dm solomon ] $old_taskname ] < 0 } {
    WarningMessage "The job number $array(JOB_ID) is not one of appropriate tasks"
    return 0
  }

  set file [ DefFileName $array(JOB_ID)]
  if { ![file exists $file] } {
    WarningMessage "The data file for the job $file does not exist"
    return 0
  }

  set array(OLD_TASKNAME) $old_taskname

  InitialiseArray [SearchPath TOP tasks $old_taskname.def] $arrayname $old_taskname
  InitialiseArray  $file $arrayname $old_taskname -reportlabel

  set array(MAPOUT_FORMAT) $array(NEW_MAPOUT_FORMAT)
  set array(INPUT_FILES) ""
  set array(OUTPUT_FILES) ""
  set array(TITLE) "Create maps for [GetValue $arrayname OLD_TASKNAME] job number $array(JOB_ID)"

  return 1

}


#-----------------------------------------------------------------------
proc task_maps_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Create Task Maps" "TaskMaps" \
	 {} ] == 0 } return

  SetDefaultMapFormat $arrayname NEW_MAPOUT_FORMAT

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    message "Select job number" \
    label "Create maps for job number" \
    widget JOB_ID \
    message "Choose output map format" \
    label "in" \
    widget NEW_MAPOUT_FORMAT \
    label format

}

