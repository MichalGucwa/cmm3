#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - execute.tcl
#
#
# Utilities called from Run Scripts
#
# Liz Potterton May97
#
#====================================================================

#CCP4i_cvs_Id $Id$

source [SearchPath TOP src job_utils.tcl]

#d_index_title Utilities called from Run Scripts (src/execute.tcl)
#d_intro_title Utilities called from Run Scripts
#d_intro These utilities are mostly used in the run scripts which run the \
programs and are in the directory $CCP4I_TOP/scripts

#---------------------------------------------------------------------------
proc ExecuteScript { deffilein args } {
#---------------------------------------------------------------------------
#d_sum Read the def file and source the run script.
#d_desc To run a job a ccp4ish process is started. This is tclsh \
(with no Tk so no graphics) and some of the basic utilities from \
src/system.tcl and src/utils.tcl.  The bin/ccp4ish.tcl script calls \
ExecuteScript which reads the def file for the job and then sources the \
appropriate script script/taskname.script.  Note that the script is sourced \
and is not called as a separate procedure.  Because the run script \
is effectively part of the ExecuteScript procedure it can see the same \
variables. There is a potential danger in this: \
that the variables in the procedure and those in the run script might \
get mixed up \
To avoid this some variables are unset before sourcing the run script.
#d_desc ExecuteScript reads the def file and sets the parameters listed \
in the file to the values given in the file. \
The parameters from the header section of the def file are loaded \
into a global array job_params which can be accessed by other utility \
procedures to get information such as the project name or  job id.
#d_arg deffilein Name of the def file

  global job_params

#  puts "ExecuteScript deffilein $deffilein $args"
  set autotest 0
  set project {}
  set ref_dir {}

  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
  switch -regexp -- [lindex $args $n] \
  project {
    incr n; set project [lindex $args $n]
  } autotest { 
    set autotest 1
  }
  incr n }

  set deffile $deffilein
  if { ![file exists $deffile] } {
      set deffile [FileJoin [GetDbDirPath $project] $deffilein]
    if { ![file exists $deffile] } {
      set deffile [FileJoin [GetDefaultDirPath TEMPORARY] $deffilein]
      if { ![file exists $deffile] } {
        puts "CCP4I ERROR:Def file does not exist $deffilein"
        return 0
      }
    }
  }

# Read the input def file containing the paramters for this job
  if { ![ReadFile $deffile deftext -split] } {
    puts "CCP4I ERROR: Can not read def file $deffile"
    return 0
  }
# Parse the input def file - assign values to variables
  set filelist {}
  foreach line $deftext {
    if { [regexp {^#CCP4I} $line] } {
      set job_params([lindex $line 1]) [lrange $line 2 end]
    } elseif { [llength $line] >= 2 }  {
      if { [regexp {([^,]*),([^,]*)} [lindex $line 0] element root indx] } {
        regsub _ $indx , indx0
        if { [lindex $line 1] == {} } {
          set [subst $root]([subst $indx0]) ""
        } else {
          set [subst $root]([subst $indx0]) "[lindex $line 1]"
        }
        if { [regexp {^DIR_([^$]*)} $root dummy filename ] } {
          lappend filelist [subst $filename]([subst $indx0])
        }
      } else {
        if { [lindex $line 1] == {} } {
#          puts "setting [lindex $line 0] to null"
          set [lindex $line 0] ""
        } else {
#          puts "setting [lindex $line 0] to [lindex $line 1]"
          # If a parameter changes type then there may be an error when
          # rerunning old parameter files, trap for the error
          if { [catch { set [lindex $line 0] "[lindex $line 1]" } errmsg] } {
            puts "ExecuteScript: failed to set [lindex $line 0]: \"$errmsg\" (ignored)"
          }
        }
        if {  [regexp {^DIR_([^$]*)} [lindex $line 0] dummy filename ] } {
           lappend filelist $filename
         }
      }

    }
  }
#  puts "job_params [array names job_params]"
#  puts "filelist $filelist"

# Reset the current project directory
  SetCurrentProject $job_params(PROJECT)

# Reinitialise the access method for the job
  ResetDatabaseAccess

# Derive the full pathname for files
  if { [llength $filelist] > 0 } { 
    foreach filename $filelist {
       eval "set status [catch {set f \$[subst $filename]} ]"
       if { !$status && $f != "" } {
         eval "set d \$DIR_[subst $filename]"
         eval "set $filename \[GetFullFileName1 $f $d]"
       }
    }
    unset f; unset d; unset filename
  }

# unset parameters or we'll be getting very confused running the scripts
  unset filelist
  unset line
  unset deftext
  unset deffile


# Notify GUI that job is running
  if { $autotest } {
    DbSetJobData $job_params(JOB_ID) STATUS RUNNING
  } else {
    RunNotification
  }


# Initialise the log file
  set job_params(LOG_FILE) [GetFullFileName $job_params(LOG_FILE) $job_params(PROJECT)]
  set LOG_FILE $job_params(LOG_FILE)
  InitialiseLog 

# Source (and run) the task script
  set scriptfile [FileJoin [SearchPath TOP scripts $job_params(TASKNAME).script]]
  set status [expr {1 - [catch { source $scriptfile } errmsg ]}]

# Creating report directory and generating xrt, xml (from log) and inp for qtrview
  source [SearchPath TOP src qtrview.tcl]
  qtrview::onScriptFinished

  if { $status == 0 } {
      # Failure - exit with error message
      append report "Error from script $scriptfile: " $errmsg
      TerminateScript $status -report $report
  }

# Terminate cleanly
  TerminateScript $status 

}

#------------------------------------------------------------------------
proc GetJobid {} {
#------------------------------------------------------------------------
#d_sum Return the job id
  global job_params
  return $job_params(JOB_ID)
}

#--------------------------------------------------------------
proc SetOutputFileRoot { args } {
#--------------------------------------------------------------
#d_sum Return a root file name which identifies the job that created the file
#d_desc The usual form of the returned file name is:
#d_desc project_dir/project_jobid
#d_opt0 -tmp
#d_opt1 Give file name for file in the temporary directory
#d_opt0 -map
#d_opt1 Give file name for file in the user's choice of output directory \
for maps this is either the temporary directory or the project directory

  global job_params
  global preferences
# Set root name for output files
  append file $job_params(PROJECT) _ $job_params(JOB_ID)
  if { [lsearch $args -tmp ] >= 0 } {
    set file [FileJoin [GetDefaultDirPath TEMPORARY] $file]
  } elseif {  [lsearch $args -map] >= 0 &&
      $preferences(MAP_OUTPUT_DEFDIR) == "TEMPORARY" } {
    set file [FileJoin [GetDefaultDirPath TEMPORARY] $file]
  } else {
    set file [FileJoin [GetDefaultDirPath $job_params(PROJECT) ] $file]
  }
  return $file
}


#----------------------------------------------------------------------
proc Execute {  command script statusout reportout args } {
#----------------------------------------------------------------------
#d_sum Execute a command and handle editting of command script and program failure.
#d_desc
#d_opt0 -success
#d_opt1 Give exit code of command script that corresponds to success. This \
defaults to 0. There is a special value "999" which means don't trap for failure.

  global job_params
  upvar $statusout status
  upvar $reportout report

  set log 1
  set logfile $job_params(LOG_FILE)
  set program_success 0
  set comments 1
  set exit_on_err 1
  set edit_script 0
  if { [ElementExists job_params EDIT_SCRIPT] } { set edit_script $job_params(EDIT_SCRIPT) }

#  puts "Running: $command < $script"
  set nargs [expr {[llength $args] - 1} ]
  if { $nargs >= 0 } {
    set n -1
    while { $n < $nargs } {
      incr n; set comd [lindex $args $n ]
      switch -regexp -- $comd \
      success {
	 incr n; set program_success [lindex $args $n ]
      } edit_script {
	 set edit_script 1
      } copy_log {
         set log 2
         incr n; set copy_log [lindex $args $n ]
      } nolog {
         set log 0
      } log {
        incr n; set logfile [lindex $args $n ]
      } nocomments {
         set comments 0
      } noexit {
         set exit_on_err 0
      }
    }
  }

  if { $edit_script && $script != "" } {

    if { [NotifyEditComFile "$command" $script edit_return] } {
      set edit_status [lindex $edit_return 0]
      set command [lindex $edit_return 1]
      switch -- $edit_status \
      -1  {
        set return_status 0
        set report "Aborting from editing script"
        set cmd [list TerminateScript $return_status  \
              -report \"$report\" -status ABORTED ]
        eval "$cmd"
      } 0 {
        set job_params(EDIT_SCRIPT) 0
      }
    }
  }


  if { $comments && $script != "" } { AppendCommand "$command" $script }

  set cmd "set status \[catch \{exec $command"
  if { $script != "" && $script != " " } { append cmd " < " $script }
  switch $log {
  1 {
    if { [file exists $logfile ]} {
      append cmd " >> \"$logfile\" "
    } else { 
      append cmd " > \"$logfile\" "
    }
  } 2 {
    append cmd " > \"$copy_log\""
  }}
  append cmd "\} report \]"

# If in environment with Report function then just put
# out a diagnostic level report

#  if { [info procs "Report" ] == "Report" } { 
#       Report 0 "Running: $command "
#  }

  eval "$cmd"

  if { $log == 2 } {
#    puts "Copying $copy_log $logfile"
    TranscribeFile $copy_log $logfile 
  }

# status is the value returned by catch and 0 means command
# successful 

  if {$program_success != 999 && $status != $program_success } {
    WriteToLog "The program run with command: $command 
has failed with error message
$report"
    set return_status 0
    if { $exit_on_err } {
      set cmd [list TerminateScript $return_status  -report \"$report\" ]
      if { $log == 2 } { lappend cmd -copy_log $copy_log }
      eval "$cmd"
    }
  } else {
    set return_status 1
  }
  return $return_status
}

#-------------------------------------------------------------------------
proc ResetDatabaseAccess { } {
#-------------------------------------------------------------------------
#d_sum Reset the database access mode for running jobs
#d_desc This function should be invoked by a running job. It determines \
whether it is necessary to reset the database connection, and then attempts \
to do so if required. This should only be necessary for jobs that are \
being run on a different machine to that running the parent CCP4i process.
    global job_params
    DbReport 3 "ResetDatabaseAccess invoked"
    DbReport 3 "SERVER_HOST          $job_params(SERVER_HOST)"
    DbReport 3 "SERVER_PORT          $job_params(SERVER_PORT)"
    DbReport 3 "DATABASE_SERVER      $job_params(DATABASE_SERVER)"
    DbReport 3 "DATABASE_SERVER_HOST $job_params(DATABASE_SERVER_HOST)"
    DbReport 3 "DATABASE_SERVER_PORT $job_params(DATABASE_SERVER_PORT)"

    if { $job_params(SERVER_HOST) == "localhost" } {
	# Job is running on same host as parent CCP4i
	# So there's nothing to do
	return
    }
    # Job was started on a remote machine
    if { ! $job_params(DATABASE_SERVER) } {
	# Remote (originating) machine not using the database handler
	if { [using_dbccp4i] } {
	    # Need to switch to using direct access
	    switch_to_direct_db
	}
    } else {
	# Remote (originating) machine is using the handler
	if { [using_dbccp4i] } {
	    # Local machine is also accessing the handler
	    # but we need to switch to the remote handler
	    if { ! [switch_to_remote_db $job_params(DATABASE_SERVER_HOST) \
			$job_params(DATABASE_SERVER_PORT)] } {
		# Failed to switch
		# Revert to direct access
		switch_to_direct_db
	    }
	}
    }
    return
}

#--------------------------------------------------------------------
proc AppendCommand { command script } {
#--------------------------------------------------------------------
#d_sum Append the command line as a comment to input script
#d_arg command The command line to run the program
#d_arg script The name of the script file
  if {[OpenFile $script f a]} {
    puts $f \
"## This script run with the command   ##########
# $command
################################################"
    CloseFile $f
  }
}
#---------------------------------------------------------------------
proc TerminateScript { status args } {
#---------------------------------------------------------------------
#d_sum Cleanly terminate a run script process and notify the main CCP4i process
#d_desc
  global job_params

# If the script is been run internal to the interface then set internal 
# flag to 1 and DO NOT EXIT

  set logfile $job_params(LOG_FILE)

  set report {}
  set internal 0
  set status_text ""
  set exit_on_err 1
  set copy_log ""
  set autotest 0
  set nargs [llength $args] ; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ] \
    internal {
      set internal 1
    } report {
      incr n; set report [lindex $args $n ]
    } copy_log {
       incr n; set copy_log [lindex $args $n ]
    } noexit {
      set exit_on_err 0
     } status {
      incr n; set status_text [lindex $args $n ]
    } autotest {
      set autotest 1
    }
    incr n
  }

# Write termination status to log file

# Put all the report text on one line or things screw up later
  set tt [regsub -all \n $report " " reportout]

  if {$job_params(HTML_LOG)} { WriteHtml beg pre }


  set textout "\n#CCP4I TERMINATION STATUS $status $reportout\n"
  append textout "#CCP4I TERMINATION TIME [GetDate]\n"
  if {[ElementExists job_params OUTPUT_FILES ]} {
    append textout "#CCP4I TERMINATION OUTPUT_FILES $job_params(OUTPUT_FILES)\n"
  }
  if {$status} {
   append textout "#CCP4I MESSAGE Task completed successfully\n"
  } else {
   append textout "#CCP4I MESSAGE Task failed\n"
  }

  if {$job_params(HTML_LOG)} { WriteHtml end pre }

  WriteFile $logfile $textout
  if { $copy_log != "" } { WriteFile $copy_log $textout }

# Send signal to database handler to update database - currently database
# handler is part of main GUI but this may change

  if { $status_text != "" } {
    set ret_status $status_text
  } elseif { $status == 1 } {
    set ret_status FINISHED
  } else {
    set ret_status FAILED
  }

  if { $autotest } {
    DbSetJobData $job_params(JOB_ID) STATUS $ret_status
    DbSetJobData $job_params(JOB_ID) DATE [clock seconds]
  } else {
    if { $ret_status == "ABORTED" } {
	# Remove the logfile
	puts "Deleting logfile $logfile"
	DeleteFile $logfile
	# Notify CCP4i that the run was aborted
	NotifyRunAborted
    } else {
	# Use baubles to generate an annotated html logfile
	CreateAnnotatedLogfile $logfile
        # Notify the database and main CCP4i that the run finished
        NotifyDatabase UpdateStatus $ret_status
        NotifyRunCompleted $ret_status
    }
  }

  if { ![ElementExists job_params AUTOTEST]  && $exit_on_err } { exit }
}

#-------------------------------------------------------------------------
proc InitialiseLog { } {
#-------------------------------------------------------------------------
#d_sum Write ccp4i header to the log file for the job
  global system
  global job_params
  global env

  if {$job_params(HTML_LOG)} { append logtext "<!-- CCP4 HTML LOGFILE -->\n<pre>" }

  append logtext [WriteIdentifier {} "LOG $job_params(TASKNAME)" \
	PROJECT $job_params(PROJECT) \
	JOB_ID $job_params(JOB_ID) \
	SCRATCH [GetEnvPath CCP4_SCR] \
	HOSTNAME [GetHostname] \
	PID [GetPid] ]

  if {$job_params(HTML_LOG)} { append logtext "</pre>\n" }

  return [WriteFile $job_params(LOG_FILE) $logtext]
}

#-------------------------------------------------------------------------
proc WriteTerminationToLog { status {report "" } } {
#-------------------------------------------------------------------------
#d_sum Write ccp4i footer to the log file
#d_arg status Termination status: 1=finished, 0=failed
#d_arg report (Optional) Termination report - usually output from last run program
  global job_params

  set tt [regsub -all \n $report " " reportout]

  set logtext "#CCP4I TERMINATION STATUS $status $reportout
#CCP4I TERMINATION TIME [GetDate]\n"
  if {$status} {
     append logtext "#CCP4I MESSAGE Task completed successfully\n"
  } else {
    append logtext "#CCP4I MESSAGE Task failed\n"
  }

  return [WriteFile $job_params(LOG_FILE) $logtext]
}

#----------------------------------------------------------------------
proc WriteToLog {  textline args } {
#----------------------------------------------------------------------
#d_sum Write comments to log file with wrappers to indicate that comments are from ccp4i script.
#d_arg textline The text to write to the log file
#d_opt0 -noheader
#d_opt1 Do not write the header of the wrapper
#d_opt0 -nofooter
#d_opt1 Do not write the footer of the wrapper

  global job_params
  set header 1
  set footer 1

  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    nohead {
      set header 0
    } nofoot {
      set footer 0
    }
    incr n
  }
  if { $header } { append logtext \
"***************************************************************************
* Information from CCP4Interface script
***************************************************************************\n" }

  append logtext "$textline\n"

  if { $footer } { append logtext \
"***************************************************************************\n" }
  return [WriteFile $job_params(LOG_FILE) $logtext]
}

#--------------------------------------------------------------
proc WriteHtml { mode name args } {
#--------------------------------------------------------------
#d_sum Write an html tag to log file
#d_arg mode  beg/end  Create the opening or closing tag
#d_arg name Name of tag

# Maintain a list of currently open tags - this will
# only allow tag to to opened once and must be opened before
# it is closed
# i.e. the right things for pre but probably not for anything else!

  set open_tags [GetSystemVar html_open_tags]
  set open_number [lsearch $open_tags $name]
  if { $open_number >= 0 } {
    if {[regexp b $mode]} {return 0}
    set open_tags [lreplace $open_tags $open_number $open_number]
  } else {
    if { ![regexp b $mode] } {return 0}
    lappend open_tags $name
  }
  SetSystemVar html_open_tags $open_tags

# Work out the text to go in the log file
  switch $name  \
  pre {
    if {[regexp b $mode]} {
      set text "<pre>"
    } else {
      set text "</pre>"
    }
  }
# Write to log file
  set logfile [GetSystemVar task_log_file]
  WriteFile $logfile $text
  return 1

}


#---------------------------------------------------------------------------
proc WriteTable { arrayname data ncol nrow title clabelin  \
		rlabelin wrlabel wcol dformat textVar args } {
#---------------------------------------------------------------------------
#d_sum Write a neatly formatted table to log file or other summary file
#d_desc This is used for the scaleit summary file which is more of a \
'crossword' table and not suitable for the usual loggraph format.
#d_arg arrayname Name of data array
#d_arg data Root name of array elements containing the data e.g. array(data,i,j)
#d_arg ncol Number of columns
#d_arg nrow Number of rows
#d_arg title Title for table
#d_arg clabelin List of column labels
#d_arg rlabelin List of row labels
#d_arg wrlabel Maximum allowed length of row label (as number of characters)
#d_arg wcol Width of each column (as number of characters)
#d_arg dformat Data format  (suitable for Tcl format command). This can either be one value which is applied to all columns or a list with one value per column.
#d_arg textVar Output. text string containing the table.

  upvar #0 $arrayname array
  upvar $textVar text

# stick and extra item at beginning of row & column label list to make it easy to 
# handle later
  set clabel [concat [list 0] $clabelin ]
  set rlabel [concat [list 0] $rlabelin ]
#
# check input args -nodiag = no diagonal element
  set nodiag 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    set comd [lindex $args $n]
    if {[regexp nodi $comd]} {
      set nodiag 1
    }
    incr n 
  }
#
# If input is just one dformat then output all columns of data in same format
# but expand dformat ot a list to simplify handling
  if { [llength $dformat] == 1 } {
    set dd $dformat
    for { set n 2 } { $n <= $ncol } { incr n } {
      lappend dformat $dd
    }
  }
  set dformat [concat [list 0] $dformat]
#  puts "dformat $dformat"

  append text \n " "

# column titles line
  append text [format %-[subst $wrlabel]s $title] "|"
  for { set m 1 } { $m <= $ncol } { incr m } {
    append text [format %-[subst $wcol]s [lindex $clabel $m]]
  }
# row of "-"
  append text \n " "
  for { set i 1 } { $i <= [expr {1 + $wrlabel + $ncol * $wcol} ] } { incr i } {
    append text "-"
  }

# loop over all rows
  for { set n 1 } { $n <= $nrow } { incr n } {

# set the row label 
    append text \n " " [format %-[subst $wrlabel]s [lindex $rlabel $n]] "|"

# loop over all columns in the row
    for { set m 1 } { $m <= $ncol } { incr m } {
      if { $nodiag && $n == $m || 
        [catch {set tt [format %-[lindex $dformat $m] $array($data,$n,$m)]}] } { 
        append text [format %-[subst $wcol]s " " ]
      } else {
        append text [format %-[subst $wcol]s $tt]
      }
    }
  }
  append text \n
}

#d_intro_title Creating the Program Command Script
#d_intro The command scripts are written to a temporary file with a name \
$CCP4_SCR/project_jobid_n_com.tmp where n is incremented for each temporary \
file create for the job.  This file can be written using WriteComFile or \
created  from a template using CreateComScript.
#d_intro CreateComScript has several support procedures which handle \
stacks and which act as mediators between the different levels in the \
procedure stack.

#------------------------------------------------------------------------
proc WriteComFile { fileVar text args } {
#------------------------------------------------------------------------
  upvar $fileVar file
  set file [GetTmpFileName -ext _com ]
  return [WriteFile $file "$text"]
}

#------------------------------------------------------------------------
proc WriteLine { lineVar args }  {
#------------------------------------------------------------------------
  upvar $lineVar line

  set linetmp {}

  set nargs [expr {[llength $args] - 1}]
  set n -1
  while { $n < $nargs } {
    incr n; set comd [lindex $args $n]
    if { $comd == "-init" } {
      set line {}
    } else {
      append linetmp $comd
    }
  }
  append line $linetmp
}

#------------------------------------------------------------------
proc CreateComScript { template fileVar args} {
#------------------------------------------------------------------
#d_sum Create the program command script using a template.
#d_desc Beware - this is probably the most complex bit of code in ccp4i! It \
is not always robust when the input com file is misformatted.  To find \
the error in the com file use the -diag option to list the lines from the \
com file as they are processed.  
#d_desc The main problem here is to access the parameters which are defined \
in the context of the run script (which is the calling procedure \
for this procedure).  The parameters should not be visible in the context \
of this procedure unless they are explicitly passed to the procedure.  \
The trick here is \
to use the Tcl uplevel command which evaluates an expression at a different \
level in the procedure stack.  The next problem is then to return a status \
flag to this procedure so that it knows the outcome of any given function. \
his is achieved by using the the set_control_status procedure to set a global \
parameter and then using get_control_status to read that global parameter.
#d_desc The syntax of the com file (program command template) is defined
#d_ref CCP4I programmers/command_template.html Programmers Docs
#d_desc The procedure interprets the com file on a line by line basis. If \
there is an error in interpreting any feature of a line then nothing from \
the line will be written to the output command script.  This interpreter \
will handle references to undefined variables but the entire line containing \
the undefined variable will be ignored.
#d_desc There are two types of syntax in the com file - the interpretable lines \
and the control structures.  On reading a new line the interpreter first \
tests to see if contains any recognised control statement - and it not \
then it attempts to interpret the line.
#d_desc Note that there is a problem with the AT command in certain \
circumstances, which is recorded in the Programmers Docs.
#d_opt0 -diag
#d_opt1 Diagnostic. Print out the lines of the com file as they are processed
  upvar $fileVar file

  set template_file [SearchPath CCP4I_TOP templates $template.com ]

  set diag 0
  set nocontinue 0
  set cont_char -
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    noco {
      set nocontinue 1
    } cont {
      incr n; set cont_char [lindex $args $n]
    } slash {
      set cont_char "\\"
    } ampersand {
      set cont_char "&"
    } diag {
      set diag 1
    }
    incr n
  }

  if { ![ReadFile $template_file com_text0 -split] } {
    puts "ERROR reading command template file $template_file"
    return 0 
  }
  foreach line $com_text0 {
    if { ![regexp ^# $line ] } { lappend com_text $line }
  }
  
# Initialise the stacks
  set stream ""
  init_com_stack
  init_if_stack
  init_loop_stack
  set if_level 0
  set start_line(0) {}
  set last(0) {}
  set first 1

# How many lines in the com file?
  set nl_com_text [llength $com_text]
#  puts "nl_com_text $nl_com_text"
  set skipping 0
  set nl 0

# Read the next line of command template -also get its level and
#  its length (number of elements)
  while { [ getcomline "$com_text" $nl_com_text \
			nl line level llen control ] } {
    if { $diag } { puts "com line $line" }

    if { $level == 0 } {
# We are at control level 
      init_control_status

      switch $control \
      IF  {

        eval "uplevel 1 { set_control_status \[ catch { \
		push_if_stack \[expr [lindex $line 1] \] } \] }"
        if { ![get_control_status ] } { push_if_stack 0 }

      } ELSE  {

        set status [pop_if_stack]
        push_if_stack [expr {1 - $status}]

      } ENDIF  {

        pop_if_stack
        get_if_stack if_level skipping

      } LOOP  {

        set loop_var [lindex $line 1]
        push_loop_stack $loop_var
        eval "uplevel 1 { set_control_status \[ catch { \
                 set_loop_start \[expr [lindex $line 2] \]  } \] }"
        eval "uplevel 1 {  set_control_status \[ catch { \
                 set_loop_end \[expr [lindex $line 3]  \] } \] }"
#        puts "LOOP get_control_status [ get_control_status ]"
        if { [ get_control_status ] } {
          set loop_index($loop_var)  [get_loop_start]
          UpsetVar 2 $loop_var $loop_index($loop_var)
          set last($loop_var) [get_loop_end]
          if { $loop_index($loop_var)  <= $last($loop_var)  } {
            push_if_stack 1
          } else {
            push_if_stack 0
          }
        } else {
          set loop_index($loop_var) 0
          UpsetVar 2 $loop_var 0
          set last($loop_var) -1
          push_if_stack 0
        }
        set start_line($loop_var) $nl

      } ENDLOOP {

        incr loop_index($loop_var)
        if { $loop_index($loop_var)  <= $last($loop_var)  } {
          UpsetVar 2 $loop_var $loop_index($loop_var)
          set nl $start_line($loop_var)
        } else {
          pop_loop_stack loop_var
          pop_if_stack
        }

      } CASE {

        set case_var [lindex $line 1]
        push_if_stack 0
      } ENDCASE {
        pop_if_stack
      } CASEMATCH {
        pop_if_stack
        eval "uplevel 1 { set_control_status \[ catch { \
          push_if_stack \[StringSame $case_var \"[lindex $line 1 ]\" \] } \] }"
        if { ![get_control_status ] } { push_if_stack 0 }

      } LABELLINE {
        if { !$skipping && [llength $line ] > 2} {
          switch [llength $line ] \
          3 {
            eval "uplevel 1 { set_control_status \[ catch { \
             set_label_stack [lindex $line 1] \"[lindex $line 2]\" } \] }"
          } 4  {
            eval "uplevel 1 { set_control_status \[ catch { \
             set_label_stack [lindex $line 1] \"[lindex $line 2]\" \
               [lindex $line 3] } \] }"
          } 5 {
            eval "uplevel 1 { set_control_status \[ catch { \
             set_label_stack [lindex $line 1] \"[lindex $line 2]\" \
               [lindex $line 3] [lindex $line 4] } \] }"
          }
          if { [get_control_status ] } {
            append stream "[get_label_stack]"
            set first 0
          }
        }
      } AT {
        eval "uplevel 1 { set_control_status \[ catch { \
	    set_at_filename [lindex $line 1]  } \] }"
	if { [get_control_status]  && [ReadFile [get_at_filename] tmp_com_text -split] } {
          set com_text [concat [lrange $com_text 0 $nl] $tmp_com_text \
		[lrange $com_text [expr {$nl +1}] end] ]
	  set nl_com_text [llength $com_text]
        }
      }
      get_if_stack if_level skipping 
#      puts "if_level $if_level skipping $skipping"

# do nothing if skipping through body of an if statement which is false
# otherwise handle command templates
    } elseif { ! $skipping }  {
      init_control_status

# Handling a template command line

# set logical print which determines whether this level (& everything
# at 'deeper' level) gets printed
# The second element in the string might be variable or script which
# can only be evaluated at calling level

       eval "uplevel 1 { set_control_status \[ catch { \
         update_com_stack $level \[expr [lindex $line 0] \] } \] }"
       if { ![get_control_status] } { update_com_stack  $level 0 }

# If all the com stack is true then print this stuff out
# Do necessary continuation or next-line and then print 
# the keyword
      get_com_stack higher current
      init_xparam_list
      set els [lsearch $line "\|" ]

      if { $higher && ( $current || $els > 0 ) }  {
        if { $current } {
          set ff 1
          if { $els > 0 } { set ll [expr {$els - 1} ] } else { set ll end }
        } elseif { $els > 0 }  {
          set ff [expr {$els + 1} ] 
          set ll end
        }
        foreach param [lrange $line $ff $ll] { 
           eval "uplevel 1 { set_control_status \[ catch { \
            append_xparam_list \[ set LLOUT $param \] } \] }"
        }
        if {  [get_control_status] }  { 
          set xparam [get_xparam_list ]
          if { $first } {
            append stream "$xparam"
            set first 0
          } elseif { $level == 1 } {
            append stream "
$xparam"
          } else {
            append stream " $cont_char
    $xparam"
          }
        } else {
           update_com_stack $level 0
        }
      }
    }
    incr nl
  }
  unset start_line; unset last; unset com_text

# remove any continuation lines from the script
  if {$nocontinue} {
    set tt [split $stream \n ]; set stream ""; set out ""
    foreach line $tt {
      append out "$line"
      if { ![regsub (-$) $out " " out ] } { 
        append stream "$out\n"
        set out ""
      }
    }
  }

# Write the script to file

  if { ![info exists file] || $file == "" } {
    set file [GetTmpFileName -ext _com ]
  }
  if { ![WriteFile $file $stream -overwrite ] } {
    puts "ERROR writing to temporary command file $file"
    return 0
  }

  return 1
}

#-------------------------------------------------------------------------------
proc UpsetVar { level var value } {
#-------------------------------------------------------------------------------
#d_sum Set a variable at a higher level in the procedure calling stack
#d_arg level Level in procedure calling stack
#d_arg var Variable name
#d_arg value Value to set variable

  set cmd "uplevel $level { set $var $value } "
  eval "$cmd"
}

#-------------------------------------------------------------------------------
proc set_at_filename { in } {
#-------------------------------------------------------------------------------
#d_sum Handle the AT command in a com file - save the name of a file to be sourced
#d_arg in The name of the file
  global at_filename
  set at_filename  $in
}

#-------------------------------------------------------------------------------
proc get_at_filename { } {
#-------------------------------------------------------------------------------
#d_sum Return the name of the 'AT' file
  global at_filename
  return $at_filename
}


#-------------------------------------------------------------------------------
proc set_label_stack { command labellist args } {
#-------------------------------------------------------------------------------
#d_sum Handling the LABELLINE keyword for MTZ LABIN/LABOUT
#d_arg command 'LABIN' or 'LABOUT' or continuation character ('-' or '&')
#d_arg labellist Program label list
  global label_line

  set index ""
# flag if to put the index number on the program label
  set index_prog 1
  if { [llength $args ] > 0 } { set index "[lindex $args 0]" }
  if { [llength $args ] > 1 && [regexp noprog [lindex $args 1]]} {
    set index_prog 0
  }

# flag for continuation mark
# This is needed in case the line after the continuation
# mark is blank
  if { $command != "-" && $command != "&" } {
    set label_line "\n$command "
    set newline_flag 0
  } else {
    set label_line ""
    set newline_flag 1
  }

  foreach prog_label $labellist {
    if { $index != "" } {
      upvar $prog_label array
      set label $array($index)
    } else {
      upvar $prog_label label
    }

    if { $label != "" && $label != "Unassigned" } {
      set term {}
      if {[regsub p$ $prog_label {} tt]} { append term "(+)" }
      if {[regsub m$ $tt {} prog_label]} { append term "(-)" }

      if { $newline_flag } {
        if { $command == "-" } {
          append label_line " -\n  "
        }
	if { $command == "&" } {
	  append label_line " &\n  "
	}
	set newline_flag 0
      }

      if { $index_prog } {
        append label_line " " $prog_label $index $term =  $label
      } else {
        append label_line " " $prog_label $term =  $label
      }
    }
  }
}

#-------------------------------------------------------------------------------
proc get_label_stack {} {
#-------------------------------------------------------------------------------
  global label_line
  return $label_line
}

#-------------------------------------------------------------------------------
proc init_xparam_list { } {
#-------------------------------------------------------------------------------
  global xparam_list
  set xparam_list {}
}

#-------------------------------------------------------------------------------
proc append_xparam_list { var } {
#-------------------------------------------------------------------------------
  global xparam_list
  if { [string length $xparam_list] > 0 } {
    append xparam_list " $var"
  } else {
    append xparam_list "$var"
  }
}

#-------------------------------------------------------------------------------
proc get_xparam_list { } {
#-------------------------------------------------------------------------------
  global xparam_list
  return "$xparam_list"
}

#-------------------------------------------------------------------------------
proc init_control_status { } {
#-------------------------------------------------------------------------------
   global control_status
   set control_status 1
}

#-------------------------------------------------------------------------------
proc set_control_status { catch_status } {
#-------------------------------------------------------------------------------
  global control_status
  set control_status [expr {1 - $catch_status}]
#  if { $catch_status == 1 } { set control_status 0 }
}

#-------------------------------------------------------------------------------
proc get_control_status { } {
#-------------------------------------------------------------------------------
  global control_status
  return $control_status
}

#-------------------------------------------------------------------------------
proc set_loop_start  { var } {
#-------------------------------------------------------------------------------
  global loop_start
  set loop_start $var
}

#-------------------------------------------------------------------------------
proc set_loop_end  { var } {
#-------------------------------------------------------------------------------
  global loop_end
  set loop_end $var
}

#-------------------------------------------------------------------------------
proc get_loop_start {} {
#-------------------------------------------------------------------------------
  global loop_start
  return $loop_start
}

#-------------------------------------------------------------------------------
proc get_loop_end {} {
#-------------------------------------------------------------------------------
  global loop_end
  return $loop_end
}

#-------------------------------------------------------------------------------
proc append_text { level stream text  } {
#-------------------------------------------------------------------------------
  set cmd "uplevel $level { append $stream \"$text\" } "
#   puts "append_text cmd $cmd"
   eval "$cmd"
}
#-------------------------------------------------------------------------------
proc append_var {  level stream var } {
#-------------------------------------------------------------------------------
   set cmd "uplevel $level { append $stream \$[subst $var] } "
#   puts "append_var cmd $cmd"
   eval $cmd
}

#-------------------------------------------------------------------------------
proc  init_loop_stack { } {
#-------------------------------------------------------------------------------
  global loop_stack
  global loop_stack_level
  set loop_stack {}
  set loop_stack_level 0
}

#-------------------------------------------------------------------------------
proc push_loop_stack { loop_var } {
#-------------------------------------------------------------------------------
  global loop_stack
  global loop_stack_level
  push loop_stack loop_stack_level $loop_var
}

#-------------------------------------------------------------------------------
proc pop_loop_stack { loop_varVar } {
#-------------------------------------------------------------------------------
  global loop_stack
  global loop_stack_level
  upvar $loop_varVar loop_var
  pop loop_stack loop_stack_level
  if { $loop_stack > 0 } {
    set loop_var [lindex $loop_stack [expr {$loop_stack_level - 1} ] ]
  } else {
    set loop_var ""
  }
}

#-------------------------------------------------------------------------------
proc init_if_stack {} {
#-------------------------------------------------------------------------------
  global if_stack
  global if_stack_level
  set if_stack {}
  set if_stack_level 0
}

#-------------------------------------------------------------------------------
proc push_if_stack { status } {
#-------------------------------------------------------------------------------
  global if_stack
  global if_stack_level
  push if_stack if_stack_level $status
}

#-------------------------------------------------------------------------------
proc pop_if_stack { } {
#-------------------------------------------------------------------------------
  global if_stack
  global if_stack_level
  return [ pop if_stack if_stack_level ]
}

#-------------------------------------------------------------------------------
proc get_if_stack { levelVar skipVar } {
#-------------------------------------------------------------------------------
  global if_stack
  global if_stack_level
  upvar $levelVar level
  upvar $skipVar skip
#  puts "get_if_stack if_stack $if_stack"
  if { $if_stack_level == 0 } { 
    set skip 0
  } elseif { [lsearch $if_stack 0] >= 0 } {
    set skip 1
  } else {
    set skip 0
  }
  return
}


#-------------------------------------------------------------------------------
proc init_com_stack {} {
#-------------------------------------------------------------------------------
  global com_stack
  global com_stack_level
  set com_stack {}; set com_stack_level 0;
}

#-------------------------------------------------------------------------------
proc update_com_stack { level print } {
#-------------------------------------------------------------------------------
  global com_stack
  global com_stack_level

# Pop stack back to current level
    for { set n $com_stack_level } { $n >= $level } { incr n -1 } {
       pop com_stack com_stack_level
    }
# Push up to current level onto stack
    for { set n [expr {$com_stack_level + 1} ] } { $n <= $level } { incr n } {
        push com_stack com_stack_level $print
    }
#    puts "com_stack $com_stack"
}

#-------------------------------------------------------------------------------
proc get_com_stack { higherVar currentVar } {
#-------------------------------------------------------------------------------
  global com_stack
  global com_stack_level
  upvar $higherVar higher
  upvar $currentVar current
  set current [lindex $com_stack end ]
  if { $com_stack_level == 1 } {
    set higher 1
  } elseif { [lsearch [lreplace $com_stack end end ] 0 ] >= 0 } {
    set higher 0
  } else {
    set higher 1
  }
#  puts "com_stack $com_stack higher $higher current $current"
}

#------------------------------------------------------------------
proc getcomline { input nlmax nlVar \
            lineVar levelVar nelementsVar commandVar } {
#------------------------------------------------------------------
#d_sum Read the next line from the 'com' template file
#d_desc The returned level is 0 for the control level and 1 for \
command line level and >1 for every nesting of continuation lines
#d_arg input the text of the com file
#d_arg nlmax Maximum number of lines in com file
#d_arg nlVar in/output The current line number
#d_arg levelVar output The nesting level of the current line
#d_arg nelementsVar output The number of words in the line
#d_arg commandVar output The control keyword if level=0
  upvar $nlVar nl
  upvar $levelVar level
  upvar $lineVar line
  upvar $nelementsVar nelements
  upvar $commandVar command

  set line0 {}
  incr nl -1
  while { $line0 == "" } {
    incr nl
    if { $nl > $nlmax } { return 0 }
    set line0 [string trim [lindex $input $nl] ]
  }
  set level 0
  set command [lindex $line0 0]
  if { [lsearch { LOOP ENDLOOP IF ELSE ENDIF CASE ENDCASE CASEMATCH LABELLINE AT } \
		$command] < 0 } {
    while { [string index $line0 $level] == "-" } { incr level }
    set line [string trimleft "$line0" "-" ]
    incr level
  } else {
    set line "$line0"
  }
  set nelements [llength $line]
#  puts "$nl $line"
  return 1
}


#d_intro_title Automatic Test Mode
#d_intro In this mode ccp4ish will repeat a range of jobs in one project \
and put newly created files, and a new project database, in a sub-directory \
of the original project directory.


#--------------------------------------------------------------------------
proc ExecuteAutoTest { work_subdir project } {
#--------------------------------------------------------------------------
#d_sum Execute a script in autotest mode
#d_arg work_subdir The name of the sub-directory of project directory to contain test output
#d_arg project The name of the project
  global job_params
  global database

  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src database.tcl]

#  WarningMessage "ExecuteAutoTest $work_subdir $project"

# Sort out the new 'working' project and add this temporarily to the list
# of projects
  set project_dir [GetDefaultDirPath $project]
  set work_project [subst $project]_$work_subdir
  set work_dir [FileJoin [GetDefaultDirPath $project] $work_subdir]

  AddProject $work_project $work_dir
  SetCurrentProject $work_project

# Initialise the database from the working project
# NB this replicates much of what is done in projectdb.tcl's DbLoadFile
# It might make more sense to invoke that instead via DbOpenDatabase?
  InitialiseArray [SearchPath TOP etc database.def] \
               database CCP4_Project_Database
  InitialiseArray [FileJoin [GetDbDirPath $work_project] database.def] \
               database CCP4_Project_Database
  SetProjectDatabase [GetDbDirPath $work_project]


# Run through all jobs in the working project - update the def file to
# pick up and put files in the working project
# And execute each script
# Keep the database up to date on progress and save after each job

  for { set job_id 1 }  { $job_id <= $database(NJOBS) } { incr job_id } {
  if { [ElementExists database STATUS,$job_id] } {
    set job_params(JOB_ID) $job_id
    set deffile [subst $job_id]_$database(TASKNAME,$job_id).def
    UpdateAutoTestDef $project $work_subdir $deffile  $database(TASKNAME,$job_id) $job_id
    if { [catch {ExecuteScript $deffile -project $work_project -autotest}] } {
     puts "Job number $job_id failed"
    }
    puts "finished $job_id"
    DbSaveFile [GetCurrentProject] [GetProjectDatabase]
  } }
  exit

}

#------------------------------------------------------------------------------
proc UpdateAutoTestDef { project work_subdir deffile taskname job_id} {
#------------------------------------------------------------------------------
#d_sum Copy def file to working test directory and update the def file header and file names
#d_arg project The name of the original master project
#d_arg work_subdir The name of the working test directory
#d_arg deffile The original def file
#d_arg taskname  The name of the task
#d_arg job_id The job id
#
  global temp

  set work_project [subst $project]_$work_subdir
  set olddef [FileJoin [GetDbDirPath $project] $deffile]
  set newdef [FileJoin [GetDbDirPath $work_project] $deffile]

  set status [ReadFile $olddef deftext -split]

#  WarningMessage "olddef $olddef newdef $newdef status $status"

  set n 0; while { [regexp {^\#CCP4I} [lindex $deftext $n]] }  {
    set line [lindex $deftext $n]
    set temp_params([lindex $line 1]) [lrange $line 2 end]
    incr n
  }

  InitialiseArray [FileJoin [GetDbDirPath $project] $deffile] \
	temp $taskname

  set in_files {}
  set in_dirs {}
  foreach filevar $temp(INPUT_FILES) {
    if { [StringSame $project $temp(DIR_$filevar)] &&
     [file exists [FileJoin [GetDefaultDirPath $work_project] $temp($filevar)]] } {
      set temp(DIR_$filevar) $work_project
    } 
    append in_files $temp($filevar) " "
    append in_dirs $temp(DIR_$filevar) " "
  }
  set out_files {}
  set out_dirs {}
  foreach filevar $temp(OUTPUT_FILES) {
    if { [StringSame $temp(DIR_$filevar) $project TEMPORARY] } {
      set temp(DIR_$filevar) $work_project
    }
    append out_dirs $temp(DIR_$filevar) " "
    append out_files $temp($filevar) " "
  }
  DbSetJobData $job_id INPUT_FILES [string trimright $in_files]
  DbSetJobData $job_id INPUT_FILES_DIR [string trimright $in_dirs]
  DbSetJobData $job_id OUTPUT_FILES [string trimright $out_files]
  DbSetJobData $job_id OUTPUT_FILES_DIR [string trimright $out_dirs]

  set header [WriteIdentifier {} "DEF $taskname" \
                JOB_ID $job_id \
                PROJECT [subst $project]_$work_subdir \
                AUTOTEST $project \
                TASKNAME $taskname \
                LOG_FILE [subst $job_id]_$taskname.log \
                EDIT_SCRIPT 0 \
                HTML_LOG $temp_params(HTML_LOG) ]

#
  WriteFile $newdef $header

  SaveArray $taskname $newdef temp -silent -no_ident -append -notype

  unset temp
  unset temp_params
}

#d_intro_title Procedures for Communications to the Database

#------------------------------------------------------------------------------
proc NotifyDatabase { command args } {
#------------------------------------------------------------------------------
#d_sum Communicate with the job database
#d_desc Send a communication to the process controlling access to the \
job database, to update the job status.
#d_desc Available commands are UpdateStatus and AddOutput file:
#d_desc UpdateStatus <new_status> -pid <script_pid>
#d_desc AddOutputFile <filelist>
#d_desc The communication is sent via a socket that is closed immediately \
afterwards i.e. the connection is not persistent.
#d_arg command The request to be executed (UpdateStatus or AddOutputFile)
#d_arg args    Arguments specific to the command
  global job_params

  if { $job_params(DATABASE_SERVER) } {
     # Running job talks directly to the database handler
     if { [eval dbccp4i_notify_database $command $args] } {
	return
     }
  }

  # Construct the request and send to CCP4i to handle
  set dbrequest {}
  set job_id  $job_params(JOB_ID)
  set project $job_params(PROJECT)
  switch $command {
      "UpdateStatus" {
	  # UpdateStatus <new_status> [-pid <script_pid>]
	  # -> DbReceive <job_id> <project> STATUS <new_status> 
	  append dbrequest "DbReceive $job_id $project"
	  if { [llength $args] > 0 } {
	      # First argument is the new status
	      append dbrequest " STATUS [lindex $args 0]"
	      # If remaining args contains -pid then
	      # also append the supplied process id
	      if { [set k [lsearch $args "-pid"]] > 0 } {
		  incr k
		  append dbrequest " PID [lindex $args $k]"
	      }
	  } else {
	      # Couldn't construct the request
	      set dbrequest {}
	  }
      }
      "AddOutputFile" {
	  # AddOutputFile <filelist>
	  # -> DbAddOutputFile <job_id> <project> <filelist>
	  append dbrequest "DbAddOutputFile $job_id $project"
	  # First argument is the filelist
	  if { [llength $args] > 0 } {
	      append dbrequest " [lindex $args 0]"
	  } else {
	      # Couldn't construct the request
	      set dbrequest {}
	  }
      }
      default {
	  # Unrecognised command
	  set dbrequest {}
      }
  }

  # If the request isn't valid then quit
  if { $dbrequest == "" } {
      puts "ERROR sending communication in NotifyDatabase $job_id $project:"
      puts "Arguments: $command $args"
      return
  }

  # Open socket connect to CCP4i process
  if { [ElementExists job_params SERVER_PORT] } {
      if { ![catch { socket $job_params(SERVER_HOST) \
			 $job_params(SERVER_PORT) } sockid] } {
	  # Send the message to CCP4i
	  fconfigure $sockid -buffering line
	  if { [catch { puts $sockid $dbrequest } err] } {
	      # Error occurred
	      puts "ERROR sending communication in NotifyDatabase $job_id $project:"
	      puts "Arguments: $command $args"
	      puts "Request: \"$db_request\""
	      puts "Error  : \"$err\""
	  }
	  # Close the socket connection
	  close $sockid
	  return
      } else {
	  # Failed to open socket connection
	  puts "ERROR opening socket connection in NotifyDatabase:"
	  puts "Arguments: $job_id $project $command $args"
	  puts "SERVER_HOST: $job_params(SERVER_HOST)"
	  puts "SERVER_PORT: $job_params(SERVER_PORT)"
	  puts "Error  : \"$sockid\""
	  return
      }
  } else {
      puts "ERROR opening socket connection in NotifyDatabase:"
      puts "SERVER_PORT is not defined"
  }
}

#------------------------------------------------------------------------------
proc dbccp4i_notify_database { command args } {
#------------------------------------------------------------------------------
#d_sum Communicate with the job database via the database handler
#d_desc Send a communication to the process controlling access to the \
job database, to update the job status.
#d_desc Available commands are UpdateStatus and AddOutput file:
#d_desc UpdateStatus <new_status> -pid <script_pid>
#d_desc AddOutputFile <filelist>
#d_desc The communication is sent via a socket that is closed immediately \
afterwards i.e. the connection is not persistent.
#d_arg command The request to be executed (UpdateStatus or AddOutputFile)
#d_arg args    Arguments specific to the command
  global job_params
  global system

  # Set the debugging output level
  DbXMLSetDebug 0

  # Flag indicating whether connection to the handler is only
  # local to this procedure
  set local_connection 0

  # Open a connection
  DbReport 3 "Running job: $command $args"
  DbReport 3 "Running job: checking for database connection..."
  if { [ ::dbClientAPI::DbVerifyConnection ] } {
      DbReport 3 "Running job: already connected ([::dbClientAPI::DbInfo])"
  } else {
      DbReport 3 "Running job: open a connection to handler"
      if { ! [::dbClientAPI::DbHandlerConnect "$system(VERSION)" \
		  -host $job_params(DATABASE_SERVER_HOST) ] } {
	  DbReport 3 "Running job: failed to make connection with database handler"
	  return 0
      } else {
	  DbReport 3 "Running job: local connection to database opened"
          set local_connection 1
      }
  }

  # Get parameters
  set status 1
  set job_id  $job_params(JOB_ID)
  set project $job_params(PROJECT)
  
  # Open the project
  if { ![::dbClientAPI::OpenProject $project] } {
      DbReport 3 "Running job: failed to get access to $project"
      set status 0
  }
  # Send database request
  if { $status } {
      switch $command {
	  "UpdateStatus" {
	      # UpdateStatus <new_status> [-pid <script_pid>]
	      # -> DbReceive <job_id> <project> STATUS <new_status>
	      # Check the current status
	      set old_status [::dbClientAPI::GetData $project $job_id STATUS]
	      DbReport 3 "Running job: currently status is $old_status"
	      if { ![StringSame $old_status KILLED] } {
		  set new_status [lindex $args 0]
		  DbReport 3 "Running job: setting job status to $new_status"
		  if { [catch { set status \
				    [::dbClientAPI::SetData $project $job_id \
					 STATUS $new_status] } err] } {
		      # Some failure
		      DbReport 3 "Running job: failed to set job status"
		      DbReport 3 "Error: $err"
		      set status 0
		  }
	      }
	  }
	  "AddOutputFile" {
	      # AddOutputFile <filelist>
	      # -> DbAddOutputFile <job_id> <project> <filelist>
	      if { [llength $args] > 0 } {
		  set filelist [lindex $args 0]
	      } else {
		  set filelist {}
	      }
	      for { set i 0 } { $i < [llength $filelist] } { incr i 2 } {
		  set filen [lindex $filelist $i]
		  set alias [lindex $filelist [expr $i+1]]
		  if { [catch { eval \
				    ::dbClientAPI::AddOutputFile \
				    $project $job_id $filen $alias } err ] } {
		      # At least one file failed to be added
		      DbReport 3 "Running job: failed to add $filen to job $job_id"
		      DbReport 3 "Error: $err"
		      set status 0
		  }
	      }
	  }
	  default {
	  # Unrecognised command
	      DbReport 3 "Running job: unrecognised request \"$command\""
	      set status 0
	  }
      }
      # Finished - close the project
      ::dbClientAPI::CloseProject $project
      DbReport 3 "Running job: closed project $project"
  }
  # Close any local connection
  if { $local_connection } {
      DbReport 3 "Running job: closing the local connection to the database"
      ::dbClientAPI::DbHandlerDisconnect
  }
  # Always return ok - only failure to get a connection
  # should return an error
  return 1
}

#d_intro_title Procedures for Communications with the Main CCP4i Process

#------------------------------------------------------------------------------
proc NotifyEditComFile { command script edit_returnVar } {
#------------------------------------------------------------------------------
#d_sum Send command script to main CCP4i process for user to inspect/edit
#d_desc This opens a socket connection to the main CCP4i process and \
passes the command script to be inspected and edited by the user via \
CCP4i's EditComFile procedure.
#d_desc The procedure returns 1 if the request successfully returned \
a result from the main CCP4i process, and 0 otherwise. On success the \
variable in the calling procedure that is referenced by edit_returnVar \
will contain the result.
#d_arg command The command line to be executed
#d_arg script  The script to be executed
#d_arg edit_returnVar Name of a variable to return the result in    
    global job_params
    upvar $edit_returnVar edit_return

    set edit_return {}

    if { ![ElementExists job_params SOCKET] } {
	# First open a socket and set SOCKET in job_params
	if { ![OpenSocket -silent] } {
	    # Failed to open socket
	    return 0
	}
    }
    # Send the request to CCP4i
    if { ![catch { puts $job_params(SOCKET) \
		       [list EditComFile "$command" $script]} err] } {
	# Fetch the response
	set edit_return [gets $job_params(SOCKET)]
	return 1
    } else {
	# Error occurred: failed to send edit request
	return 0
    }
}

#------------------------------------------------------------------------------
proc NotifyRunAborted { } {
#------------------------------------------------------------------------------
#d_sum Notify main CCP4i process that the run has been aborted
#d_desc This opens a socket connection to the main CCP4i process \
to trigger the RunAborted command, which performs clean up of the \
job.
    global job_params

    if { ![ElementExists job_params SOCKET] } {
	# First open a socket and set SOCKET in job_params
	if { ![OpenSocket -silent] } {
	    # Failed to open socket
	    return 0
	}
    }
    # Send the notification to CCP4i
    if { ![catch { puts $job_params(SOCKET) \
		       [list RunAborted $job_params(JOB_ID) $job_params(PROJECT)]} \
	       err] } {
	return 1
    } else {
	# Error occurred: failed to send abort notification
	return 0
    }
}

#------------------------------------------------------------------------------
proc NotifyRunCompleted { status } {
#------------------------------------------------------------------------------
#d_sum Notify main CCP4i process that the run has completed
#d_desc This opens a socket connection to the main CCP4i process \
to trigger the RunCompleted command, which performs post-run operations \
such as running any review scripts.
#d_arg status  The final status of the job on completion e.g. FINISHED
    global job_params

    if { ![ElementExists job_params SOCKET] } {
	# First open a socket and set SOCKET in job_params
	if { ![OpenSocket -silent] } {
	    # Failed to open socket
	    return 0
	}
    }
    # Send the notification to CCP4i
    if { ![catch { puts $job_params(SOCKET) \
		       [list RunCompleted $job_params(JOB_ID) \
			    $job_params(PROJECT) $status] } err] } {
	return 1
    } else {
	# Error occurred: failed to send completion notification
	return 0
    }
}

#------------------------------------------------------------------------------
proc RunNotification { } {
#------------------------------------------------------------------------------
#d_sum Send message to main CCP4i process to say this process is running
#d_desc 
  global job_params

  set status RUNNING
  if { [ElementExists job_params REMOTE] && $job_params(REMOTE) } { set status REMOTE }

  set script_pid [pid]

  NotifyDatabase UpdateStatus $status -pid $script_pid
}

#------------------------------------------------------------------------------
proc FailNotification { } {
#------------------------------------------------------------------------------
#d_sum Send message to main graphical CCP4i process to say this process has failed
#d_desc
  global job_params
  NotifyDatabase UpdateStatus FAILED
  NotifyRunCompleted FAILED
}

#----------------------------------------------------------------------
proc AddOutputDir { args } {
#----------------------------------------------------------------------
#d_sum Notify the main CCP4i process of additional output dirs
#d_desc Silently register an output directory for a job - the directory \
will not appear in the list of output files seen by the user, but will \
be removed by any subsequent clean-up
#d_desc This is just a wrapper for AddOutputFile
#d_desc Note that PROJECT is not a valid argument to AddOutputDir, and \
will be ignored.
#d_arg args list of directories to register
  set newargs ""
  foreach arg $args {
    if { $arg != "PROJECT" } {
      lappend newargs "" $arg
    }
  }
  if { [llength $newargs] > 0 } {
    eval AddOutputFile $newargs
  }
}

#----------------------------------------------------------------------
proc AddOutputFile { args } {
#----------------------------------------------------------------------
#d_sum Notify the main CCP4i process of additional output files
#d_desc
  global job_params
  global preferences

# Handle cases where the directory is the MAP_DEFAULT
  while { [set l [lsearch -exact $args MAP_DEFAULT] ] >= 0 } {
    if { $preferences(MAP_OUTPUT_DEFDIR) == "TEMPORARY" } {
      set args [lreplace $args $l $l TEMPORARY]
    } else {
      set args [lreplace $args $l $l $job_params(PROJECT)]
    }
  }

# Handle cases where the directory is the PROJECT
  foreach arg $args {
    if { $arg == "PROJECT" } {
      lappend filelist $job_params(PROJECT)
    } else {
      lappend filelist $arg
    }
  }


  if { ![ElementExists job_params OUTPUT_FILES] } {
    set job_params(OUTPUT_FILES) ""
  }
  foreach file $filelist { append job_params(OUTPUT_FILES) " $file" }

  # Send update to the database
  NotifyDatabase AddOutputFile $filelist
}


#d_intro_title Communication between Script not written in Tcl and CCP4i
#d_intro  Most CCP4i scripts to run programs are written in Tcl - \
this information is for use with those scripts which are not Tcl. \
Normally the non-Tcl script will have been started from a standard Tcl \
script called taskname.script.  It would be possible to leave this process \
running and return the name of output files to this script \
when the main non-Tcl script completes.  Alternatively the Tcl process can be \
terminated and the necessary communication with the main CCP4i process \
done from the non-Tcl script.  \
Ideally the communication functionality would be \
provided by a library in the appropriate scripting language but, failing that, \
the non-Tcl script starts a Tcl/CCP4i process and passes it the appropriate \
parameters to do the communication. 
#d_intro The command from the non-Tcl script must be a Unix shell type command:
#d_intro $CCP4I_TOP/bin/ccp4ish -socket $CCP4I_DEFFILE ccp4i_command
#d_intro where $CCP4I_TOP  is the standard CCP4i environment variable
#d_intro $CCP4I_DEFFILE is the name of the CCP4i def file for this job. \
 This file is read by the ccp4ish process and \
contains the necessary information about sockets and job ids for communication \
with the main CCP4i process.  This file is in the user's project database \
directory i.e.
#d_intro project_directory/CCP4_DATABASE/jobid_taskname.def
#d_intro it is easiest if the full path name for this file is passed \
into the non-Tcl \
script as an argument.  The path name can be defined in the Tcl script as
#d_intro set deffile [FileJoin [GetDbDirPath] $job_params(JOB_ID)_$job_params(TASKNAME).def ]
#d_intro ccp4i_command is the command which the ccp4ish process is required \
to execute.  The currently supported commands are AddOutputFile and \
TerminateScript which are described in the CCP4i Programmers Documentation.


#------------------------------------------------------------------------------
proc ExecuteSocket { args }  {
#------------------------------------------------------------------------------
#d_sum  Use ccp4ish to communicate to CCP4i main process from a non-Tcl script
#d_desc  This procedure is called from ccp4ish.tcl and \
is used when the main work is been done by a non-Tcl script (eg arp/warp \
in csh) and this script needs to communicate status & output file info.
#d_opt0 -deffile deffile
#d_opt1 The name of the def file for the job - the header contains info on the server socket
#d_opt0 -project project_dir
#d_opt1 The name of the current project
#d_opt0 -command command
#d_opt1 Text string with the command to send to the main CCP4i - must begin with the name of an allowed command: RunNotification, FailNotification, AddOutputFile, AddOutputDir or TerminateScript
#d_opt0 -silent
#d_opt1 Suppress echoing of the commands and warnings to stdout

  global system
  global job_params

  set deffilein ""
  set project ""
  set command ""
  set verbose 1

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
  switch -regexp -- [lindex $args $n] \
  deffile {
    incr n; set  deffilein [lindex $args $n]
  } project {
    incr n; set project [lindex $args $n]
  } command {
    incr n; set command [lindex $args $n]
  } silent {
    set verbose 0
  }
  incr n }

  if { $verbose } { puts "ExecuteSocket $args" }

#  puts "command $command"

  if { [file exists $deffilein] } {
    set deffile $deffilein
  } else {
    set deffile [FileJoin [GetDbDirPath $project] $deffilein]
    if { ![file exists $deffile] } {
      set deffile [FileJoin [GetDefaultDirPath TEMPORARY] $deffilein]
      if { ![file exists $deffile] } {
	puts "CCP4I ERROR:Def file does not exist $deffilein"
        return 0
      }
    }
  }

# Read the input def file containing the paramters for this job
  if { ![ReadFile $deffile deftext -split] } {
    puts "CCP4I ERROR: Can not read def file $deffile"
    return 0
  }

  foreach line $deftext {
    if { [regexp {^#CCP4I} $line] } {
      set job_params([lindex $line 1]) [lrange $line 2 end]
    }
  }

  set open_socket_cmd "OpenSocket"
  if { ! $verbose } { lappend open_socket_cmd "-silent" }
  if { ![eval $open_socket_cmd] } {
    # Failed to open socket - buffer the commands for later
    if { $verbose } {
      puts "CCP4I MESSAGE: ExecuteSocket cannot open socket, buffering command"
    }
    BufferSocketCommand $job_params(PROJECT) $command $deffile
    return
  }

  switch [lindex $command 0] \
  RunNotification {
    RunNotification
  } FailNotification {
    FailNotification
  } AddOutputFile {
    eval $command
  } AddOutputDir {
    eval $command
  } TerminateScript {
    eval $command
  }

}

#-----------------------------------------------------------------------------
proc BufferSocketCommand { project command { deffile {} } } {
#-----------------------------------------------------------------------------
#d_sum Add a command to the buffer for execution later
#d_desc Writes the command to a command buffer file for the appropriate \
project. BufferSocketCommand should be called if a socket cannot be opened \
to the process controlling access to the database to execute the command \
immediately. The contents of the buffer can be flushed by \
DbFlushCommandBuffer, which will execute the commands via ExecuteSocket at \
that point.
#d_arg project Project alias for the database to be communicated with
#d_arg command Socket command to be buffered
#d_arg deffile (optional) Def file name associated with the job sending the \
socket command
    # First determine buffer file
    set bufferfile [GetBufferFile $project]
    # Open the file for appending and write the command
    set buffer [open $bufferfile "a"]
    puts $buffer "[list $project $deffile $command]"
    close $buffer
    return
}

#-----------------------------------------------------------------------------
proc GetBufferFile { project } {
#-----------------------------------------------------------------------------
#d_sum Return the name of the database command buffer file
#d_desc Clone of DbGetBufferFile in database.tcl
#d_arg project Project alias for the database to be communicated with
    return [FileJoin [GetDbDirPath $project] database.BUFFER]
}

#----------------------------------------------------------------------------
proc OpenSocket { args } {
#----------------------------------------------------------------------------
#d_sum Open a client side socket to connect to the server in the main CCP4i process
#d_desc Return 1 if socket was successfully opened, 0 if not.
#d_opt0 -silent
#d_opt1 Do not report failure to open socket
global job_params

  set verbose 1

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
  switch -regexp -- [lindex $args $n] \
  silent {
    set verbose 0
  }
  incr n }

  set server_port [GetServerPort]
  if { $server_port != "" } { set job_params(SERVER_PORT) $server_port }

  if { [ElementExists job_params SERVER_PORT]  &&
    ![catch { socket $job_params(SERVER_HOST) $job_params(SERVER_PORT) } sockid] } {
    set job_params(SOCKET) $sockid
    fconfigure $job_params(SOCKET) -buffering line
    return 1
  } else {
    # Failed to open socket - most likely the original CCP4i server has
    # been shut down
    if { $verbose } {
      puts "ERROR running script can not connect to server port (OpenSocket)"
      if { [ElementExists job_params SERVER_PORT] } {
        puts "SERVER_HOST  $job_params(SERVER_HOST) SERVER_PORT $job_params(SERVER_PORT)"
        puts "Message: \"$sockid\""
      } else {
        puts "SERVER_PORT  is not defined"
      }
    }
    return 0
  }
}

#----------------------------------------------------------------------------
proc GetServerPort { } {
#----------------------------------------------------------------------------
#d_sum Return server port for CCP4i process associated with current project
#d_desc The server port number is stored in the database lock file for the \
current project. If the port number cannot be extracted then the number \
stored in the job_params array will be returned. If this value cannot be \
extracted then an empty string is returned.
global job_params

  if { [ElementExists job_params PROJECT] } {
    set dblockfile [file join [GetDbDirPath $job_params(PROJECT)] database.LOCK]
    if { [file exists $dblockfile] } {
	ReadFile $dblockfile text -split
	if { [llength $text] > 0 } {
	    foreach line $text {
		if { [regexp -- "^Server port" $line] } {
		    return [lindex $line end]
		}
	    }
	}
    }
  }
# Unable for whatever reason to extract port number from lock file
# Use preset value
  if { [ElementExists job_params SERVER_PORT] } {
    return $job_params(SERVER_PORT)
  }
# No value available
  return ""
}
