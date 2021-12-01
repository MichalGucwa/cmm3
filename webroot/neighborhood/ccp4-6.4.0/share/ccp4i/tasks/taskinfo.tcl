#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#-----------------------------------------------------------------------
proc taskinfo_load_db { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Test the data entered by the user is valid
  # Program name
  set program_name [string trim $array(PROGRAM_NAME)]
  if { "$program_name" == "" } {
      WarningMessage "You haven't entered a program name"
      return 0
  }
  set array(PROGRAM_NAME) $program_name
  # Title
  check_title_line $arrayname TITLE
  SetDefaultTitle $arrayname "\[No title given\]"

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1  "ERROR in taskinfo_load_db: process [GetPid] has lost the lock"
    WarningMessage "Database Access Warning

This instance of CCP4i no longer has control
of the current database. This is probably
because another CCP4i is running and has
taken control of the database over from this
one.

It is unsafe in these circumstances to alter
the job database and no changes have been
committed.

The safest action is to close this instance
of CCP4i and check that there are no other
CCP4is running before restarting."
    return 0
  }

  PleaseWait "Saving to database"

  if { $array(JOB_ID) == 0 } {
    set job_id [DbRegisterJob $arrayname "REPORTED"]
  } else {
    set job_id $array(JOB_ID)
  }
  DbSetJobData $job_id STATUS $array(JOB_STATUS)
  DbSetJobData $job_id TASKNAME $array(PROGRAM_NAME)
  DbSetJobData $job_id TITLE "$array(TITLE)"
  DbSetJobData $job_id LOGFILE $array(LOG_FILE)
  DbSetJobData $job_id RUNFILE $array(CONTROL_FILE)
  DbSetJobData  $job_id DATE $array(DATE)
  set files ""; set file_dirs ""; set file_format ""
  if { $array(N_INPUT_FILES) > 0 } { 
    for { set n 1 } { $n <= $array(N_INPUT_FILES) } { incr n } {
      lappend files $array(INPUT_FILE,$n)
      lappend file_dirs $array(DIR_INPUT_FILE,$n)
      lappend file_format $array(INPUT_FILE_FORMAT,$n)
    }
  }
  DbSetJobData $job_id INPUT_FILES $files
  DbSetJobData $job_id INPUT_FILES_DIR $file_dirs

  set files ""; set file_dirs ""; set file_format ""
  if { $array(N_OUTPUT_FILES) > 0 } {
    for { set n 1 } { $n <= $array(N_OUTPUT_FILES) } { incr n } {
      lappend files $array(OUTPUT_FILE,$n)
      lappend file_dirs $array(DIR_OUTPUT_FILE,$n)
      lappend file_format $array(OUTPUT_FILE_FORMAT,$n)
    }
  }
  DbSetJobData $job_id OUTPUT_FILES $files
  DbSetJobData $job_id OUTPUT_FILES_DIR $file_dirs
  DbUpdateList

  PleaseWait

  return 1
}

#-----------------------------------------------------------------------
proc taskinfo_input { arrayname counter } {
#-----------------------------------------------------------------------

   CreateInputFileLine line \
      "Enter name of input file" \
      "Input File" \
       INPUT_FILE DIR_INPUT_FILE

}

#-----------------------------------------------------------------------
proc taskinfo_output { arrayname counter } {
#-----------------------------------------------------------------------

   CreateInputFileLine line \
      "Enter name of outut file" \
      "Output File" \
       OUTPUT_FILE DIR_OUTPUT_FILE

}

#-----------------------------------------------------------------------
proc taskinfo_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  DefineMenu _job_status [list FINISHED FAILED STARTING RUNNING \
			KILLED REMOTE "ON HOLD" REPORTED ]

  return 1

}

#----------------------------------------------------------------------------
proc taskinfo_save { arrayname } {
#----------------------------------------------------------------------------
  # Performs "Save and Exit" operation
  # Exit is only performed if the taskinfo_load_db procedure (which
  # applies the operations) returns success
  upvar #0 $arrayname array
  if { [taskinfo_load_db $arrayname] } {
    DeleteTaskWindow $array(WINDOW) $arrayname $array(TASK)
  }
}

#----------------------------------------------------------------------------
proc taskinfo_task_window { arrayname  } {
#----------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  if { $array(JOB_ID) != 0 } {
    set title "Edit Job Info"
  } else { 
    set title "Report External Job" 
  }

  if { ![CreateTaskWindow  $arrayname \
      $title "taskinfo" \
	{} -action_buttons [list quit ] ] } return
 
  set button $array(WINDOW).buttons.exit
  button $button -text "Save&Exit"  \
        -font $configure(FONT_REGULAR) \
      -command "taskinfo_save $arrayname"
    pack $button -side left -expand 1
    SetMessage $arrayname $button "Exit and save to job database"


 OpenFolder protocol

  CreateTitleLine line TITLE

  if { $array(JOB_ID) == 0 } {
    CreateLine line \
      message "Enter one-word name of program used" \
      label "Program name" \
      widget PROGRAM_NAME  \
	-width 30
  } else {
    CreateLine line \
      message "Select most appropriate current job status" \
      label "current status" \
      widget JOB_STATUS
  }


#  CreateLine line \
#    message "Enter comments in notebook" \
#    widget ENTER_NOTEBOOK \
#    label "Enter comments in notebook for this task"

  OpenFolder file

   CreateInputFileLine line \
      "Enter name of control file" \
      "Control File" \
       CONTROL_FILE DIR_CONTROL_FILE

   CreateInputFileLine line \
      "Enter name of log file" \
      "Log File" \
       LOG_FILE DIR_LOG_FILE

  CreateLine line \
    label "Input files for the job" -italic

   CreateExtendingFrame N_INPUT_FILES taskinfo_input \
    "Enter name(s) of input files" "Add Input File" \
     [ list INPUT_FILE \
	DIR_INPUT_FILE \
	INPUT_FILE_FORMAT ]

  CreateLine line \
    label "Output files from the job" -italic

   CreateExtendingFrame N_OUTPUT_FILES taskinfo_output \
    "Enter name(s) of output files" "Add Output File" \
     [ list OUTPUT_FILE \
	DIR_OUTPUT_FILE \
	OUTPUT_FILE_FORMAT ]
}

