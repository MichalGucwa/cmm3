#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================
# CCP4 Interface runjob.tcl
#
#
#
# Routines to kick off an external job
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Starting Jobs (src/runjob.tcl)
#d_intro_title Starting Jobs
#d_intro The procedures in runjob.tcl will initiate the running of a job \
after the user has clicked the 'Run' button on a task interface.

#---------------------------------------------------------------------
proc run_command { mode taskname arrayname0 } {
#---------------------------------------------------------------------
#d_sum Create a def file, add new job to database and  run a job
#d_desc This procedure checks that a script file script/taskname.tcl exists \
and will fail if it is not found unless running in interactive mode. In \
future it is feasible that scripts could be written in other \
languages and run_command would need to be intelligent about this \
to ensure the script was started appropriately.  There is currently some \
unused code to handle the case of csh script.
#d_arg mode can be: \
background: run in background as separate process on same machine, \
edit:  as background but show user program scripts to edit, \
remote: Give user options to choose to run remote/batch, \
interactive: create the database entry but return control to the task interface to run the job interactively, \
#d_arg taskname The name of the task
#d_arg arrayname Task interface array


# Create a def file with parameters to run a job
# Exact function depends on mode
# mode = background write task procedure for input taskname and run script
# mode = remote write task procedure for input taskname 
# mode = edit - as background but set up so user is shown com file before execution
# mode = remote write task procedure for input taskname and run remote/batch
# mode = internal running one task internally (not currently used!)
# mode = interactive  - action is performed by the task_run procedure
#		
  global system
  global database
  global configure
  upvar #0 $arrayname0 array0

# Lock the interface to prevent exit partway through
# We must unlock it when we've finished
  LockInterface

# Clone the input array
# We do this in case the original array is deleted by the user
# closing the task window before run_command has finished with
# the data

  set arrayname [CreateNewArray runjob]
  SimpleCopyArray $arrayname0 $arrayname
  upvar \#0 $arrayname array

# Check that a run script exists for this task

  if {[file exists \
    [set script_file [SearchPath TOP scripts $taskname.script]]]} {
    set format tcl
  } elseif { [file exists \
    [set script_file [SearchPath TOP scripts $taskname.cscript]]] } {
    set format csh
  } elseif { [file exists \
    [set script_file [SearchPath TOP scripts $taskname.py]]] } {
    set format py
  } elseif { ![regexp intera $mode] } {
    WarningMessage "ERROR no script found: [SearchPath TOP scripts $taskname.*]"
    unset array
    UnlockInterface
    return 0
  }

# Check there is a database to write to
  set project_dir [GetDefaultDirPath]
  if { ![file isdirectory $project_dir] } {
    WarningMessage "ERROR no project directory:

$project_dir

Please set up a project directory
using the Directories&ProjectDir window
from the main CCP4i interface, and then
rerun this job."
    unset array
    UnlockInterface
    return 0
  }
  set db_dir [GetDbDirPath]
  if { ![file isdirectory $db_dir] } {
    WarningMessage "ERROR no project database directory:

$db_dir

Please set up a project directory
using the Directories&ProjectDir window
from the main CCP4i interface, and then
rerun this job."
    unset array
    UnlockInterface
    return 0
  }

# Run the script associated with each task interface which allows
# application programmer to make any final fiddles before task 
# script is written

  set task_runtime_script [subst $taskname]_run
  if {[regexp $task_runtime_script [info procs $task_runtime_script] ]} {
    if { [catch { set status [$task_runtime_script $arrayname] } err ] } {
	# The run procedure crashed
	WarningMessage "The run procedure \"$task_runtime_script\" failed with
the following error:

\"$err\"

Sorry about that - please report this error to the
CCP4i maintainers so we can try and fix it."
	set status 0
    }
    if { ! $status } { 
# If the run mode is interactive then register failure so it can
# be investigated
      if {[regexp interactive $mode ]} { 
       set job_id [DbRegisterJob $arrayname $taskname FAILED]
       set logfile ""
       if { [file exists $array(LOGFILE)] } {
         set logfile [DbGetJobFileRoot $job_id].log
         MoveFile $array(LOGFILE) [FileJoin [GetDefaultDirPath] $logfile]
         DbSetJobData $job_id LOGFILE $logfile
         CreateAnnotatedLogfile [FileJoin [GetDefaultDirPath] $logfile]
       }
       # Generate a def file for this job so that the
       # parameters can be restored by rerun job in future
       set def_file [FileJoin [GetDefaultDirPath] CCP4_DATABASE \
			 [subst $job_id]_$taskname.def ]
       set header [WriteIdentifier {} "DEF $taskname" \
		       JOB_ID $job_id \
		       PROJECT [GetCurrentProject] \
		       TASKNAME $taskname \
		       LOG_FILE $logfile ]
       WriteFile $def_file $header -overwrite
       SaveArray $taskname $def_file $arrayname -silent -no_ident -append
      }
      unset array
      UnlockInterface
      return 0 
    }
  }

# If the run mode is interactive then the task_run procedure 
# should have done the business and we don't need to do anything else
# except add to database
  if {[regexp interactive $mode ]} { 
     set job_id [DbRegisterJob $arrayname $taskname FINISHED]
     set logfile ""
     if { [file exists $array(LOGFILE)] } {
       set logfile [DbGetJobFileRoot $job_id].log
       MoveFile $array(LOGFILE) [FileJoin [GetDefaultDirPath] $logfile]
       DbSetJobData $job_id LOGFILE $logfile
       CreateAnnotatedLogfile [FileJoin [GetDefaultDirPath] $logfile]
     }
     # Generate a def file for this job so that the
     # parameters can be restored by rerun job in future
     set def_file [FileJoin [GetDefaultDirPath] CCP4_DATABASE \
		       [subst $job_id]_$taskname.def ]
     set header [WriteIdentifier {} "DEF $taskname" \
		JOB_ID $job_id \
                PROJECT [GetCurrentProject] \
                TASKNAME $taskname \
                LOG_FILE $logfile ]
     WriteFile $def_file $header -overwrite
     SaveArray $taskname $def_file $arrayname -silent -no_ident -append
     unset array
     UnlockInterface
     return 
  }

# Procedure to do various checks on job parameters, e.g. title, symmetry
  RunParameterCheck $arrayname

  PleaseWait "Checking file names"

  if { [ElementExists $arrayname INPUT_FILES ] &&
       [ElementExists $arrayname OUTPUT_FILES ] } {
    if { ![RunFileCheck $arrayname $array(INPUT_FILES) $array(OUTPUT_FILES)] \
              } { 
	PleaseWait
	unset array
	UnlockInterface
	return
    }
  }

  TkBusy .
  PleaseWait "Creating run script"

# Register job with the database and get a job_id

  set job_id [DbRegisterJob $arrayname $taskname]

  if { $job_id == 0 } {
    # Failed to register a new job
    PleaseWait
    WarningMessage "Database Access Failure

This instance of CCP4i no longer has control
of the current database. This is probably
because another CCP4i is running and has
taken control of the database over from this
one.

It is unsafe in these circumstances to alter
the job database and so a new job has not
been created.

The safest action is to close this instance
of CCP4i and check that there are no other
CCP4is running before restarting."
    Report 1 "run_command: process [GetPid] failed to register a new job with the db"
    TkBusy . 1
    # Abort the run in this case
    unset array
    UnlockInterface
    return 0
  }

# Build log file name and delete any existing file of same name

  set logfile [DbGetJobFileRoot $job_id].log
  DeleteFile [FileJoin [GetDefaultDirPath] $logfile]

# Derive name for def file
  set def_file [FileJoin [GetDbDirPath] [subst $job_id]_$taskname.def ]

# Write the header to the script file
  set html_log 0
  if {[ElementExists $arrayname HTML_LOG]} { set html_log $array(HTML_LOG) }
  if { $mode == "remote" } { 
    set gui_host [GetHostname]
  } else { 
    set gui_host localhost 
  }
  if { [using_dbccp4i] } {
      set db_port [::dbClientAPI::DbHandlerPort]
  } else {
      set db_port 0
  }

  set header [WriteIdentifier {} "DEF $taskname" \
		JOB_ID $job_id \
                PROJECT [GetCurrentProject] \
                TASKNAME $taskname \
                LOG_FILE $logfile  \
                EDIT_SCRIPT [regexp edit $mode ] \
                HTML_LOG $html_log \
                REMOTE [regexp remote $mode]	\
		SERVER_HOST $gui_host \
                SERVER_PORT $system(SERVER_PORT) \
                DATABASE_SERVER [using_dbccp4i] \
                DATABASE_SERVER_HOST $gui_host \
		DATABASE_SERVER_PORT $db_port ]

  WriteFile $def_file $header -overwrite

# Write all parrams to the def file
	
  SaveArray $taskname $def_file $arrayname -silent -no_ident -append

  if { [ElementExists $arrayname SUBSIDUARY_ARRAY] && \
         [llength $array(SUBSIDUARY_ARRAY)] > 0 } {
# need to save additional data from a subsiduary array
    foreach subsid $array(SUBSIDUARY_ARRAY) {
      SaveArray $subsid $def_file $subsid -silent -append -no_ident
    }
  }

  DbSetJobData $job_id LOGFILE $logfile

# OK run it
  RunScript $mode $format $def_file $script_file $job_id

# Put report in session log
  Report 2 "Running $format task, log file: $logfile"

  PleaseWait
  TkBusy . 1

  unset array
  UnlockInterface
  return
}


#--------------------------------------------------------------------------
proc RunScript { mode format def_file script_file job_id } {
#--------------------------------------------------------------------------
#d_sum Run a job - start a new ccp4i process and pass it the def file name
#d_desc The command to run start a ccp4i process is taken from the configure \
array - inappropriate setting of this value is a likely cause for jobs \
not running.  The RunRemote procedure is invoked to run jobs remotely.
#d_desc Note regarding the "mode" argument: this is a list that can contain \
between one and three elements. The first element indicates the mode of use \
(either "background" or "remote"). If the mode of use is "remote" then there \
must be a second element which is the name of the remote machine, and there \
may also be an optional third element that indicates the protocol to use to \
connect to that machine (either "rsh" or "ssh").
#d_arg mode = background or remote
#d_arg def_file Name of def file containing parameters for job
#d_arg script_file Script file - usually only required for running Python
#d_arg job_id The project database id for the job

  global system
  global configure
# Run the script def_file according to mode:
# mode = background - run immediately as separate process
# mode = remote     - run remotely or in batch

  switch $format \
  tcl {
    set comd "$configure(RUN_CCP4I) -r \"$def_file\""
  } py {
    set comd "$configure(RUN_CCP4I_PY) \"$script_file\" -r \"$def_file\""
  }

  switch [lindex $mode 0] \
  abort { 
    return 

  } background {

    set status [expr {1 - \
      [ catch { eval exec $comd & } ]}  ]

  } edit {

    set status [expr {1 - \
      [catch { eval exec $comd & } ]} ]

  } internal {

    set status [expr {1 - \
       [catch { eval exec $comd } ]}  ]

  } remote {

    if { [llength $mode] > 1 } {
      CreateBatchCom $format $def_file $script_file com_file
      if { [llength $mode] > 2 } {
        set status [RunRemote $job_id $com_file [lindex $mode 1] \
		-protocol [lindex $mode 2]]
      } else {
        set status [RunRemote $job_id $com_file [lindex $mode 1] ]
      }
    } else {
      set status [ChooseRunMode $def_file $job_id] 
    }

  }

  if { !$status } {
    WarningMessage "ERROR running script $def_file
Probably due to having RUN_CCP4I not set correctly 
See the Configure Interface window"
    Report 3 "ERROR running script $def_file" 
    db_cleanup_handler $job_id database
  }
  return $status

}


#----------------------------------------------------------------
proc RunFileCheck { arrayname input_files output_files }  {
#----------------------------------------------------------------
#d_sum Before running a task check input files exist and output files do not.
#d_desc A list of array elements for the names of input and output files \
are keep in the array elements INPUT_FILES and OUTPUT_FILES respectively.
#d_arg arrayname Task interface array
#d_arg input_files List of array elements containing the names of input files
#d_arg output_files List of array elements containing the names of output files

  foreach file $input_files { 
    if { [InputFileCheck $arrayname $file ] == 0 } { return 0 }
  }
  foreach file $output_files {
    if { [OutputFileCheck $arrayname $file ] == 0 } { return 0 }
  }
  return 1
}

#-----------------------------------------------------------------------
proc InputFileCheck { arrayname file } {
#-----------------------------------------------------------------------
#d_sum Check task input file exists and warn user if not
#d_arg arrayname Task interface array
#d_arg filename Name of one input file
  upvar #0 $arrayname array

  if { $array($file) == "" } {

   set action [ ChooseOptionDialog "File Does Not Exist" "File Exists" \
    "There is no file name for parameter $file. Do you want to abort this task run and enter the file name before rerunning?" \
    [list "Continue" "Abort Run" ]  \
    -help [SearchPath HELP general file_info.html] \
    -default 1 ]

  } elseif { ![ CheckFileInput $arrayname $file read ] } {

    set action [ ChooseOptionDialog "File Does Not Exist" "File Exists" \
    "$array($file)
Does not exist.
You should abort this task run and change the file name before rerunning." \
    [list "Continue" "Abort Run" ]  \
    -help [SearchPath HELP general file_info.html] \
    -default 1 ]

  } else {
    return 1
  }
  if { "$action" == "Abort Run" } { return 0 } 
}


#-----------------------------------------------------------------------
proc OutputFileCheck { arrayname file } {
#-----------------------------------------------------------------------
#d_sum Check if task output file does not exist and offer to delete or abort
#d_arg arrayname Task interface array
#d_arg filename Name of one output file

  upvar #0 $arrayname array

  if { $array($file) == "" } { 
    WarningMessage "There is no file name for parameter $file
The CCP4 program is liable to fail. Please enter a file name and Run again" -stop
    return 0
  }

# Check there are no spaces in the filename
  set filename [GetFullFileName0 $arrayname $file]
  if { [regexp "\[ \t\n\]" [file tail $filename]] } {
    WarningMessage "The file name [file tail $filename] contains spaces
The CCP4 program is liable to fail. Please enter a valid file name and Run again" -stop
    return 0
  }

  switch -- [CheckFileInput $arrayname $file save ] \
  -1 {
# The directory does not exist
    set filename [GetFullFileName0 $arrayname $file]
    WarningMessage \
	"Aborting job.\nThe directory for output file:\n$filename\ndoes not exist."
    return 0
  } 0 {
# The file already exists or is a directory
    set filename [GetFullFileName0 $arrayname $file]

    if { [file isdirectory $filename] } {
    WarningMessage \
	"Aborting job.\nThe output file: $filename\n is actually a directory."
    return 0
    }

    set ccp4_open [GetEnvPath CCP4_OPEN]
    if { $ccp4_open  == "NEW" } {
      set warning "The CCP4 program is liable to fail. Do you want to delete the existing file"
      set button_text "Delete File"
    } else {
      set warning "This file will be overwritten. Do you want to continue"
      set button_text "Continue"
    }

    set action [ ChooseOptionDialog   "File Exists" "File Exists" \
    "File exists: $filename
$warning or abort this task run and change the file name before rerunning?" \
    [list "Abort Run" "$button_text" ] \
    -help [SearchPath HELP general file_info.html] \
    -default 1 ]

    if { "$action" == "Abort Run" } {
      return 0
    } else {
      if { [DeleteFile $filename ] == 0 } {
        WarningMessage "Can not delete file $filename
Do you have write permission to delete it?
Aborting run" -title "Can not delete file"
        return 0
      } else {
        DbHandleOverwrite $array($file)
        return 1
      }
    }
  }
  if { [llength [set jobid_list  \
	[DbCheckOutputFiles $array($file) -running ]]] > 0 } {
    WarningMessage "There is already a job running,($jobid_list),
which will create a file called 
$array($file)
You MUST give an alternative file name."
    return 0
     
  }
}

#----------------------------------------------------------------------------
proc RunParameterCheck { arrayname } {
#----------------------------------------------------------------------------
#d_sum 
#d_desc 
#d_arg arrayname Task interface array
  upvar #0 $arrayname array

# Set an insulting default title. This is too late for interactive
# jobs, but if we put this before the task_run procedure then we
# may pre-empt any calls from there.
  SetDefaultTitle $arrayname "\[No title given\]"

# Add quotes to symmetry names which contain whitespace
  foreach element $array(PARAM_LIST) {
    if { [GetType $arrayname $element] == "_space_group" ||
         [GetType $arrayname $element] == "_laue_space_group" } {
      set spgrp $array($element)
      set front_quote [regexp -- "^'" $spgrp]
      set back_quote  [regexp -- "'$" $spgrp]
      set quoted [expr {$front_quote * $back_quote}]
      # If there are unmatched quotes then remove them
      if { $front_quote && ! $back_quote } {
        set spgrp [string trimleft $spgrp "'"]
      } elseif { ! $front_quote && $back_quote } {
        set spgrp [string trimleft $spgrp "'"]
      }
      # Then check if an unquoted name contains spaces
      if { !$quoted && [regexp -- " " $spgrp] } {
        # The name contains spaces - wrap in quotes
        set array($element) "\'$spgrp\'"
      }
    }
  }
  return
}

#----------------------------------------------------------------------------
proc RunAborted { job_id project } {
#----------------------------------------------------------------------------
#d_sum Invoke the cleanup handler to deal with an aborted job
#d_desc When a job is aborted by the user, this command will be invoked by \
a message received by ServerAcceptInput in order to perform clean up of the \
job by invoking the cleanup handler.
#d_arg job_id  Number of the aborted job
#d_arg project Name of the project that the job was running in

    if { $project != "NO_DATABASE" && $project != [GetCurrentProject] } {
	# This job is not one for the current open database file
	Report 2 "RunAborted: report for different project received $project $job_id"
	return
    }
    # Do cleanup of the aborted job
    db_cleanup_handler $job_id database
    return
}

#----------------------------------------------------------------------------
proc RunCompleted { job_id project status } {
#----------------------------------------------------------------------------
#d_sum Trigger post-run operations once a running job has finished
#d_desc When a job finishes running, this command will be invoked by \
a message received by ServerAcceptInput in order to perform any post-run \
operations - for example, running the task review procedures defined in the \
task file and finalising the status of the output files.
#d_desc Completion in this context includes both successful and failed jobs.
#d_arg job_id  Number of the aborted job
#d_arg project Name of the project that the job was running in
#d_arg status  Status of the job on completion e.g. FINISHED or FAILED.

    if { $project != "NO_DATABASE" && $project != [GetCurrentProject] } {
	# This job is not one for the current open database file
	Report 2 "RunCompleted: report for different project received $project $job_id"
	return
    }

    if { [StringSame $status FINISHED FAILED ] } {
	# Update the job timestamp
	set start_time [ DbGetJobData $job_id DATE ]
	DbSetJobData $job_id DATE [GetDate -format seconds]
   
	# Run through any task review procedures
	set tasklist [ DbGetJobData $job_id TASKNAME ]
	foreach taskname $tasklist {
	    if { [llength [ info procs [subst $taskname]_review ]] > 0 } {
		set review [subst $taskname]_review
		# Reload the parameters into a new array
		set arrayname "[subst $taskname]_[subst $job_id]_[GetCurrentProject]"
                set deffile [DefFileName $job_id]
		global $arrayname
		if { [file exists $deffile] } {
		    InitialiseArray $deffile $arrayname $taskname
		} else {
		    puts "RunCompleted: can't find def file $deffile for job $job_id"
		}
		# Run the review procedure
		eval [list set status [ $review $arrayname $job_id ]]
	    }
	}
    }

    # update the list of output files
    DbUpdateOutFiles $job_id $start_time
    return
}

#----------------------------------------------------------------------------
proc SetDefaultTitle { arrayname text } {
#----------------------------------------------------------------------------
#d_sum Set a task title if user has not entered one
#d_desc only used in few tasks so far
#d_arg arrayname Task interface array
#d_arg text text to insert in task title
  upvar #0 $arrayname array
  # Some tasks don't have a title - just to check...
  if { [info exists array(TITLE)] } {
      if { $array(TITLE) == "" } {  set array(TITLE) "$text" }
  }
}

#----------------------------------------------------------------------
proc ChooseRunMode { script_file job_id args } {
#----------------------------------------------------------------------
#d_sum Present 'Remote' window for user to choose remote/batch mode
#d_arg script_file Name of def file containing task parameters
#d_arg job_id The project database id for the job
#d_opt0 -machine machine
#d_opt1 Set a default remote machine

 global remote
 global typedef
 global configure

# Run job remotely or in batch - the options will be installation dependent
# Make a dialog box to query the user

  set machine {}
  set mode {}

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
  switch -regexp -- [lindex $args $n] \
  machine {
    incr n; set machine [lindex $args $n]
  } mode {
    incr n; set mode [lindex $args $n]
  }
  incr n }
  set w .remote
  if { ![OpenWindow $w  "Run Job Remotely/Later $script_file" "Remote"  \
    -help  [SearchPath HELP general runjob.html]  \
        -message remote ] } { return 0 }
  SetProgramHelpFile [SearchPath HELP general runjob.html]
  CreateFrame  $w remote -noscroll

# A frame for buttons has been created at bottom - put in Abort and Run
# When user clicks on either of these the handle_remote procedure is invoked
  CreateButton $w dismiss "Abort" \
        "handle_chooserunmode $w remote abort $script_file $job_id"
  CreateButton $w run "Run" \
        "handle_chooserunmode $w remote run $script_file $job_id" -default

# Define the parameters used in the dialog box

  if { ![info exists remote(MACHINE)] } {

# Whether you have remote/batch options depends if machines/queues have
# been defined in the system configuration
    if {$configure(N_REMOTE_MACHINES) > 0 } {
      lappend mode_list "on remote machine"
      lappend mode_alias_list REMOTE
      DefineVariable remote MACHINE _machines $configure(REMOTE_MACHINE,1)
    }
    if {$configure(N_BATCH_QUEUES) > 0 } {
      lappend mode_list "in batch queue"
      lappend mode_alias_list BATCH
      DefineVariable remote BATCH_QUEUE_NAME _batch_queues2 $configure(BATCH_QUEUE_NAME,1)
      DefineVariable remote BATCH_OPTIONS _text {}
    }
    if {$configure(N_SERVERS) > 0 } {
      lappend mode_list "on CCP4I remote server"
      lappend mode_alias_list SERVER
      DefineVariable remote SERVER_NAME _servers $configure(SERVER_NAME,1)
    }
    lappend mode_list "later"
    lappend mode_alias_list LATER
    DefineMenu _remote_mode $mode_list $mode_alias_list
    DefineVariable remote MODE _remote_mode [lindex $mode_list 0]
    DefineVariable remote TIME _text now
    DefineVariable remote REMOTE_PROTOCOL _remote_protocol $configure(REMOTE_PROTOCOL)
  }

  DefineVariable remote EDIT _logical 0

# User to chose remote/batch/later

  CreateLine line \
     help remote \
     label "Run" \
     widget MODE

# Options dependent on remote/batch/later


  if {$configure(N_REMOTE_MACHINES) > 0 } {

   OpenSubFrame frame -toggle_display MODE open REMOTE
   CreateLine line \
     help remote \
     label "Run job on" \
     message "Select machine to run job" \
     widget MACHINE \
     label "at" \
     message "Enter time in format HH:MM (Day) eg 22:00 Thursday" \
     widget TIME -width 30

   CreateLine line \
     help remote \
     label "Use" \
     widget REMOTE_PROTOCOL \
     label "to connect to the remote machine"

   CreateLine line \
     help remote \
     widget EDIT \
     label "View and edit the command file"

   CloseSubFrame
  }

  if {$configure(N_BATCH_QUEUES) > 0 } {
   CreateLine line \
     help remote \
     label "Batch queue" \
     widget BATCH_QUEUE_NAME \
     label "with options" \
     widget BATCH_OPTIONS -width 40 \
     toggle_display MODE open BATCH
  }

  if {$configure(N_SERVERS) > 0 } {
   CreateLine line \
     help remote \
     label "Server" \
     widget SERVER_NAME \
     toggle_display MODE open SERVER
  }

  CreateLine line \
     help remote \
     label "Run at" \
     message "Enter time in format HH:MM (Day) eg 22:00 Thursday" \
     widget TIME -width 20 \
     toggle_display MODE open LATER

# Command to get window displayed
   update idletasks
#   CloseFrame

   return 1

}

#-----------------------------------------------------------------------------
proc handle_chooserunmode { w arrayname action def_file job_id args } {
#-----------------------------------------------------------------------------
#d_sum Run remote/batch after user clicks 'Run' in 'Remote' window
#d_desc There is a fragment of code to run in 'SERVER' mode - this would \
be an implementation to allow running 'remotely' on the Windows platform.
#d_arg w The id of the window
#d_arg arrayname 'Remote' window array
#d_arg action User selection: 'abort' or 'run'
#d_arg def_file Name of def file containing task parameters
#d_arg job_id The project database id for the job

  upvar #0 $arrayname array
  global tcl_version
# To understand how to run the jobs first look at the command to
# run a normal background job:

# exec ccp4i -r $def_file &

# exec          the tcl procedure to make a call to the operating system
# ccp4i -r       invokes a 'shell' which is the tcl/tk wish shell plus some
#               extra ccp4 specific functionality from $CCP4I_TOP/src/system.tcl
# $def_file     is the name of a def. file with parameters to run the the job 
# &             has the usual shell meaning that the job should be detached

# It is safest to wrap a command like this in the catch procedure which
# will 'catch' error conditions and returns values
# 0 => the operation was  success
# 1 => the operation failed
# (This is perversely the reverse of usual tcl convention which returns
# 1 = success )
# So have command:
#  set status [catch "exec ccp4i -r $def_file &" ]
# Put a copy of the script on TEMPORARY directory
  set remote_def_file [DbGetJobFileRoot $job_id TEMPORARY].def
  CopyFile $def_file $remote_def_file -overwrite

# Generate a com file
  if { $action == "run" } {
    set remote_script_file ""
    if { ![set status [CreateBatchCom "tcl" \
         $remote_def_file $remote_script_file com_file ]] } {
      WarningMessage "Could not create command script for remote machine" }
  }

# User opted to abort or program
# failed to create com file - just clean up and return
  if { $action == "abort" || !$status } {
    PleaseWait "Aborting job"
    CloseWindow $arrayname -unset
    DbUnregisterJob $job_id
    PleaseWait
    return 0
  }

  switch [GetValue $arrayname MODE] \
  BATCH {

    set local_batch_queue [lrange [GetValue $arrayname BATCH_QUEUE_NAME] 1 end]
    set local_batch_type [lindex [GetValue $arrayname BATCH_QUEUE_NAME] 0]
    RunBatchJob $job_id $com_file $local_batch_queue $local_batch_type \
	 $array(BATCH_OPTIONS)

  } REMOTE  {

    if { $array(EDIT)  &&
      [ReadFile $def_file script_text_list -split ]  &&
      [set f [lsearch -regexp $script_text_list "EDIT_SCRIPT" ]] > 0 } {
        set script_text_list [lreplace $script_text_list $f $f \
                "#CCP4I EDIT_SCRIPT  1" ]
        set script_text [lindex $script_text_list 0]
        foreach line [lrange $script_text_list 1 end] { append script_text "\n$line" }
        WriteFile $def_file "$script_text" -overwrite
    }

    RunRemote $job_id $com_file [GetValue $arrayname MACHINE] \
	-time [GetValue $arrayname TIME] \
	-protocol [GetValue $arrayname REMOTE_PROTOCOL]

  } LATER {
    set time [GetValue $arrayname TIME]
    if {[regexp now $time]} { set time "now + 1 minute" }
    if { [regexp "^8\.\[01234\]" $tcl_version] } { 
      # platform with Tcl/Tk 8.4 or earlier
      set status [catch {exec at $time < "$com_file"} message ]
    } else {
      # Unix platform with Tcl/Tk 8.5 or greater
      set status [catch {exec -ignorestderr at $time < "$com_file"} message ]
    }
    if { $status && ( [regexp error $message] || $message == "" ) } {
      WarningMessage "Unable to execute
at $time < $com_file
$message"
    } else {
      Report 1 $message
      DbSetJobData $job_id STATUS "ON HOLD"
    }

  } SERVER {
    for { set n 1 } { $n <= $configure(N_SERVERS) } { incr n } {
      if  { [StringSame "$array(SERVER_NAME)" "$configure(SERVER_NAME,$n)"] } { set nn $n }
    }

    RunServer $job_id $def_file $array(SERVER_NAME) $configure(SERVER_HOST,$nn) \
		$configure(SERVER_PORT,$nn)

  }

  CloseWindow $arrayname -unset
}

#------------------------------------------------------------------
proc StartLoggraph {  } {
#------------------------------------------------------------------
  global system
  global configure
# Used in sfanal and baverage tasks to start up loggraph
# If the socket id of loggraph has not been set then
# start the loggraph process before running sftools - hopefully
# should be ready by time we need it

# Loggraph will send back a message to LGServerReceive

  if { ![ElementExists system LOGGRAPH_SOCKET] ||
       ![TestSocket -socket $system(LOGGRAPH_SOCKET)] } {
    set cmd "$configure(RUN_LOGGRAPH) -p $system(SERVER_PORT)"
    eval "exec $cmd &"
  }

  return 1
}

#--------------------------------------------------------------------------
proc LGServerReceive { args } {
#--------------------------------------------------------------------------
  global system

# When loggraph opens socket it sends back message to be handled by
# LGServerReceive (this is controlled by the procedure ServerAcceptInput
# in src/local.tcl and it appends the arguments "-sock $socket_id"
# so that sfanal/baverage tasks now knows the socket id in order to send commands
# to loggraph

  set nargs [llength $args]; set n 0
#  puts "LGServerReceive $args"
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    sock {
      incr n;set system(LOGGRAPH_SOCKET) [lindex $args $n]
#      puts "LOGGRAPH_SOCKET $system(LOGGRAPH_SOCKET)"
    }
    incr n
  }
}

#--------------------------------------------------------------------------
proc UpdateLoggraph { file delay increment max_delay} {
#--------------------------------------------------------------------------
  global system
# Open a new file in loggraph
# Allow loggraph max_delay time to open a socket connection
  if { [ElementExists system LOGGRAPH_SOCKET] &&
       [TestSocket -socket $system(LOGGRAPH_SOCKET)] } {
    PutsSocket "LGClientReceive -open \"$file\"" -socket $system(LOGGRAPH_SOCKET)
  } elseif { $delay < $max_delay } {
    incr delay $increment
    UpdateLoggraph $file $delay $increment $max_delay
  } else {
# give up - warn user
    WarningMessage "Unable to update loggraph with log file"
  }
}
