#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# CCP4 Interface local.tcl
#
#
#
# 'Local' Utilities
# Utitlities which interact with the operating system or other packages
# and which might need local customisation
#
#====================================================================

#CCP4i_cvs_Id $Id: local.tcl,v 1.36 2012/07/03 15:44:38 gxg60988 Exp $

#d_index_title Interaction with Operating System & Local Packages(src/local.tcl)
#d_intro_title Interaction with Operating System & Local Packages(src/local.tcl)
#d_intro The following procedures might need local customisation. \
In practice the only procedure that I know to have been changed on \
any site is RunBatchJob which needs customising of the local \
batch system.

#----------------------------------------------------------------
proc  SendMail { subject tmp_file mail_address } {
#----------------------------------------------------------------
#d_sum Send email using system Mail utility
#d_arg subject Subject of mail message
#d_arg tmp_file Temporary file containing the text of the message
#d_arg mail_address Mail addressee

return [expr {1 - [catch \
   "exec Mail -s \"$subject\" $mail_address < $tmp_file"  ]}]
}

#d_index_title Interaction with Netscape
#d_intro_title Interaction with Netscape
#d_intro It is assumed that Netscape is used as a browser. CCP4i uses the \
browser to display documentation and uses commands normally invoked from \
the command line to send commands to Netscape to display the required file. \
See the Netscape documentation 
#d_ref REMOTE www.netscape.com/newsref/std/x-remote.html Netscape Docs
#d_intro I (Liz) have found some of the commands documented here do not \
seem to work on SGIs or through the Tcl exec command.
#d_intro Another major problem is that if Netscape is not already running it \
can be tricky to start it and then specify the name of the file to display \
as there is a significant wait as Netscape starts up and is not listening \
to input. The poll_netscape procedure was an attempt to tackle this problem.

#---------------------------------------------------------------------
proc start_netscape { } {
#---------------------------------------------------------------------
#d_sum Start the Netscape program
#d_desc Uses the Tcl exec command to run the command line defined in \
configure(START_NETSCAPE)
#d_desc The use of this procedure is deprecated - use \
start_hypertext_viewer instead.

  global configure

  PleaseWait  "Starting Netscape .."
  set netscape_status [ \
    catch "exec $configure(START_NETSCAPE) &" ]
}

#---------------------------------------------------------------------
proc start_hypertext_viewer { { viewer {} } } {
#---------------------------------------------------------------------
#d_sum Start the hypertext viewer program defined in configure
#d_desc Uses the Tcl exec command to start the hypertext viewer defined in \
configure(HYPERTEXT_VIEWER).
#d_desc This is a generic version of the start_netscape command, and should \
be used instead.
#d_arg viewer (optional) Specify a viewer command to use in preference to \
that defined in configure(HYPERTEXT_VIEWER).

   global configure

   if { $viewer == "" } {
     set hypertext_viewer $configure(HYPERTEXT_VIEWER)
     if { $hypertext_viewer == "" } {
       WarningMessage "No hypertext viewer is defined
Check your CCP4i configuration"
       return
     }
   } else {
     set hypertext_viewer $viewer
   }
   PleaseWait  "Starting hypertext viewer \"$hypertext_viewer\" .."
   set status [ catch "exec \"$hypertext_viewer\" &" ]
   return $status
}

#---------------------------------------------------------------------
proc open_url { url args } {
#---------------------------------------------------------------------
#d_sum Open a specified file in a browser window
#d_desc  Open a specified file in a currently open browser window
#d_arg url	full path name of file
#d_arg target	optional target within file
#d_opt0 -remote
#d_opt1 The url is not a local file     
  global configure
  global system
  global tcl_platform

  # Check that a viewer is set in configure
  if { [regexp "^\[ \t\]*$" $configure(HYPERTEXT_VIEWER)] } {
    WarningMessage "Cannot open requested URL:

\"$url\"

The hypertext viewer command is not set in
the CCP4i configuration window."
    return
  }

  set target {}
  set remote 0

  # Process optional arguments 
  set nargs [llength $args]; set n 0; while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    targ {
      incr n; set target [lindex $args $n]
    } remo {
      set remote 1
    }
    incr n
  }

  if { !$remote && ![file exists $url] } {
    WarningMessage "Can not find help file $url"
    return
  }
  if { $target != "" &&  $configure(HYPERTEXT_VIEWER) != "start" } {
      append  url "#" $target
  }

  TkBusy .

  switch $system(OPSYS) \
  WINDOWS {
    # new in 6.3: "start" and "default" open default browser
    if { $configure(HYPERTEXT_VIEWER) == "start" } {
      eval exec [auto_execok start] [list $url] &
    } elseif { $configure(HYPERTEXT_VIEWER) == "default" } {
      package require registry
      set root HKEY_CLASSES_ROOT
      set appKey [registry get $root\\.html ""]
      set appCmd [registry get $root\\$appKey\\shell\\open\\command ""]
      if { !$remote } { set url "file://$url" }
      regsub {%1} $appCmd  "$url" appCmd
      regsub -all {\\} $appCmd  {\\\\} appCmd
      eval exec $appCmd &
    # This seems to work okay for Windows
    } elseif { [catch "exec \"$configure(HYPERTEXT_VIEWER)\" \"$url\" &" message ]
      && ![regexp warning: "$message"] } {
        warning_no_netscape $url $message
    }
  } default {
    # For UNIX

    # Are we using Netscape?
    if { [regexp "netscape" $configure(HYPERTEXT_VIEWER) ] } {

       if { $tcl_platform(os) == "Linux" } {
         # Linux only
         # Start a new netscape for each help request
         set viewer_cmd "exec $configure(HYPERTEXT_VIEWER) $url &"
       } else {
         # Other Unices
         # Check if netscape is already running
         if { [catch "file lstat ~/.netscape/lock tt" ] } {
           # No netscape - fire it up
           set status [start_hypertext_viewer]
           # PJX: After trying to start netscape ideally we would like
           # to check that it is ready to receive commands
           # However I don't know how to do this easily - checking for
           # the creation of a lock file doesn't work, because this is
           # the first thing that happens.
           # Instead, just wait for 10 seconds ...
           after 5000
         }
         # Command to open requested URL in netscape
         if { $remote } {
           set viewer_cmd "poll_netscape remote 500 0 $url"
         } else {
           set viewer_cmd "poll_netscape file 500 0 $url"
         }
      }

    } elseif { $tcl_platform(os) == "Darwin" } {
      # for IE on make open only opens pages
      set viewer_cmd "exec open -a {$configure(HYPERTEXT_VIEWER)} [lindex [split $url # ] 0 ]"

    } elseif { [regexp "mozilla" $configure(HYPERTEXT_VIEWER) ] || \
	    [regexp "firefox" $configure(HYPERTEXT_VIEWER)] } {
      # This seems to be necessary for Mozilla
      if { !$remote } { set url "file://$url" }
      # Check if browser already open cf. Netscape version above
      catch { exec $configure(HYPERTEXT_VIEWER) -remote ping() } mozilla_message
      if { [regexp "Error" $mozilla_message ] } {
        # Command to open requested URL in new Mozilla browser
        set viewer_cmd "exec $configure(HYPERTEXT_VIEWER) $url &"
      } else {
        # Command to open requested URL in existing Mozilla browser
        set viewer_cmd "exec $configure(HYPERTEXT_VIEWER) -remote openURL($url) &"
      }
    } elseif { [regexp "konqueror" $configure(HYPERTEXT_VIEWER) ] } {
      # This seems to be necessary for Konqueror
      if { !$remote } { set url "file://$url" }
      set viewer_cmd "exec $configure(HYPERTEXT_VIEWER) $url &"
    } else {
      # Command to open requested URL in other browser
      set viewer_cmd "exec $configure(HYPERTEXT_VIEWER) $url &"
    }
  }

  # Attempt to open the URL if not windows system
  if { ![regexp WINDOWS $system(OPSYS)] } {
    if { [catch $viewer_cmd message] } {
       warning_no_hypertext_viewer $configure(HYPERTEXT_VIEWER) $url $message
    }
  } 


  PleaseWait
  TkBusy . 1
}

#------------------------------------------------------------------------
proc warning_no_netscape { url message } {
#------------------------------------------------------------------------
#d_sum Output warning message when fail to open page in Netscape
#d_desc This procedure is superseded by the generic \
warning_no_hypertext_viewer command.
#d_arg url	name of file which could not open
#d_arg message  the message returned by the opening mechanism

     WarningMessage "Apparently failed to open page in hypertext viewer
$url

$message
Check the CCP4I configuration?
Look for Hypertext Viewer under the Configure Interface options in the
System Administration menu"

}

#------------------------------------------------------------------------
proc warning_no_hypertext_viewer { hypertext_viewer url message } {
#------------------------------------------------------------------------
#d_sum Output warning message when there is a failure to open a URL
#d_desc When CCP4i fails to open a URL in the specified hypertext viewer \
then display a warning with the error message returned by the opening \
mechanism.
#d_desc This is a generic version of the warning_no_netscape procedure \
and should be used instead.
#d_arg url     Name of the file which couldn't be opened
#d_arg message The message text returned by the opening mechanism

     WarningMessage "Apparently failed to open page
$url
in hypertext viewer \"$hypertext_viewer\"

Last error message:
$message

Check the CCP4I configuration
Look for Hypertext Viewer under the Configure Interface options in the
System Administration menu"

}

#------------------------------------------------------------------------
proc poll_netscape { mode delay netscape_npolls url { message {} } } {
#------------------------------------------------------------------------
#d_sum Make repeat attempts to load page into Netscape
#d_desc After Netscape has been started there is a delay before it will \
respond to system commands to load a page.  This procedure works by \
recursively  calling itself and incrementing netscape_npolls until it \
equals some maximal value (currently hardcoded).
#d_arg mode     either remote (url is on a remote machine) or file (url is \
a local file)
#d_arg delay	the pause between each attempt to load a page
#d_arg netscape_npolls	number of attempts that have been made to load page
#d_arg url	page to be loaded into Netscape
#d_arg message	Error message to be output to user

  global configure

  # Have we exceeded the maximum number of polls?
  incr netscape_npolls
  if { $netscape_npolls > 100 } {
    WarningMessage "After starting Netscape, apparently failed to open page.
$url

Last error message:
$message
Check the CCP4I configuration?
Look for Netscape under the Configure Interface options in the
System Administration menu"
    return
  }

  # Remote or file mode?
  if { [regexp "remote" $mode] } {
    set remote 1
  } else {
    set remote 0
  }

  # Set the command for opening the URL
  if { $remote } {
    set netscape_cmd "exec $configure(HYPERTEXT_VIEWER) -remote openURL($url)"
  } else {
    set netscape_cmd "exec $configure(HYPERTEXT_VIEWER) -remote openFile($url)"
  }

  if { [catch $netscape_cmd message] && ![regexp -nocase warning: $message] } {
     after $delay
     poll_netscape $mode $delay $netscape_npolls $url $message
  } else {
     PleaseWait
     TkBusy . 1
  }

}

#d_index_title Running Program Scripts
#d_intro_title Running Program Scripts
#d_intro Most of the code for running scripts is in the runjob.tcl file. \
The procedures in this section are those which might possibly \
require some installation dependent modification.
#d_intro Provided ccp4i is properly configured the user has the option to \
run program scripts on remote machines or in batch queues.  \
The necessary configuring is described in
#d_ref CCP4I general/configure.html#remote_machine Configuring Running on Remote Machines
#d_intro RunRemote uses one of the unix system command rsh or ssh to run \
jobs on other machines on the same local network.  The necessary commands \
to run in batch (RunBatchJob) may be installation dependent.  \
For either of these modes ccp4i creates a com file (CreateBatchCom) \
which is a short *nix shell script to setup ccp4 and to start a ccp4i \
process with the appropriate command line arguments which will run it in \
'run' mode for running the program scripts.

#----------------------------------------------------------------------------
proc RunBatchJob { job_id com_file batch_queue batch_type batch_options } {
#----------------------------------------------------------------------------
#d_sum Submit a job to a local batch queue
#d_desc Uses a simple Tcl exec command to submit a job to a local batch queue. \
and handles failures cleanly.
#d_arg  job_id	The job number (see database documentation)
#d_arg	com_file A command file which will be run on the batch machine (see CreateBatchCom)
#d_arg  batch_queue  The name of the batch queue 
#d_arg  batch_options Any additional arguments to the batch system

    if { $batch_type == "SGE" } {
      set job_command "$batch_queue $batch_options $com_file"
    } elseif { $batch_type == "Condor" } {
      set job_command "$batch_queue $batch_options $com_file"
    } else {
      set job_command "$batch_queue $batch_options source $com_file"
    }

    set status [ catch \
      "exec $job_command" message ]
    if { $status } {
      WarningMessage "Failed to submit batch job.\n $message"
      DbSetJobData $job_id STATUS FAILED
      db_cleanup_handler $job_id database
    } else {
      DbSetJobData $job_id STATUS REMOTE
    }
    Report 1 $message

}

#-------------------------------------------------------------------
proc RunRemote { job_id com_file machine args } {
#-------------------------------------------------------------------
#d_sum Start a job on a remote machine
#d_arg	job_id	job number 
#d_arg	com_file  Command script to run on the remote machine (see CreateBatchCom)
#d_arg  machine   Name of remote machine
#d_opt0 -time time
#d_opt1 Use the Unix at command to run the job at time. This is a text string with an appropriate format for the at command
#d_opt0 -protocol protocol
#d_opt1 Protocol to use for remote connection (e.g. rsh, ssh). Otherwise the default is taken from configure.def

  global configure
  set protocol $configure(REMOTE_PROTOCOL)

  set time now
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
  switch -regexp -- [lindex $args $n] {
    time {
      incr n; set time [lindex $args $n]
    }
    protocol {
      incr n; set protocol [lindex $args $n]
    }
  }
  incr n }


  Report 1 "Sending remote job"
  if { $time == "" || $time == "now" } {
    set status [catch {exec $protocol $machine -n source "$com_file" & } message ]
  } else {
    set status [catch {exec $protocol $machine -n at $time < "$com_file" } message ]
  }

  if {$status} {
    WarningMessage "Unable to execute 
$protocol $machine at $time < $com_file "
  } else {
    Report 1 $message
    DbSetJobData $job_id STATUS "REMOTE"
    DbSetJobData $job_id MACHINE $machine
  }

  return [expr {1- $status}]

}

#-------------------------------------------------------------------------
proc RunServer { job_id script_file server_name server_host server_port } {
#-------------------------------------------------------------------------
#d_sum Procedure not fully implemented. Start a job on a server

  if { ![set status [catch \
      "socket $server_host $server_port" sockid]] } {
    set status [catch { fconfigure $sockid -buffering line
          puts $sockid "runjob $script_file [GetCurrentProject]"
          close $sockid }]
  }
  if { $status } { WarningMessage "Unable to connect to server $server_name" 
    DbSetJobData $job_id STATUS FAILED
    db_cleanup_handler $job_id database
  }

}

#-------------------------------------------------------------------------
proc CreateBatchCom { format def_file script_file com_fileVar } {
#-------------------------------------------------------------------------
#d_sum Create a command file to start a job on a remote machine or batch queue
#d_desc The command file will normally contain a command to setup CCP4 as \
defined by configure(CCP4_SETUP_COMMAND) and a command to run non-graphical \
ccp4i in script mode with the appropriate script file name as input.
#d_arg def_file	 def file containing parameters to run script (is in the project database directory).
#d_arg  com_fileVar the name of a command file is generated from the script \
file name by adding the extension .com and changing the directory to the \
the TEMPORARY directory.  The command file name is returned as com_fileVar

  global system
  upvar  $com_fileVar com_file
  global configure

  if { [file exists [set directories_file  \
	[FileJoin [GetCurrentDir] directories.def]] ] } {
    set runargs " -dir $directories_file"
  } else { set runargs "" }

# make sure script file name has no path - will be assumed to be 
# in the TEMPORARY directory
  set name [file tail $def_file] 
# SGE at least doesn't accept job names beginning with numerical character
  set name "ccp4_$name"

# Com file name is script name with '.com' appended
  set com_file [ FileJoin [GetDefaultDirPath TEMPORARY] $name.com ]

  switch $format \
  tcl {
    set comd "$configure(RUN_CCP4I) -r $def_file"
  } py {
    set comd "$configure(RUN_CCP4I_PY) $script_file -r $def_file"
  }
  return [WriteFile $com_file  "$configure(CCP4_SETUP_COMMAND) 
$comd $runargs" -overwrite ]

}

#-------------------------------------------------------------
proc KillScript { script_pid { nretry 0} } {
#-------------------------------------------------------------
#d_sum Kill a non-graphical ccp4i process
#d_desc Kill the ccp4i script which is running the ccp4 program(s) by \
killing any child process (i.e. the ccp4 program). The script should \
then fail cleanly.  If it can not find a child process then the KillScript \
process will call itself again recursively and try again.  The limit \
on retries is currently set in the procedure to 3 and after this it will \
try to kill the ccp4i process.
#d_desc Not currently implemented for the Windows operating system
#d_desc A potential problem on *nix systems is the use of the system command \
ps -ef to find the ids of processes and the ids of their parents.  The output \
from this can have variable format.
#d_arg script_pid	Process id for ccp4i process (this information is \
returned to the main graphical ccp4i process when the job start) \
#d_arg nretry	Number of retries that have been made.  This is optional \
argument which should not usually be set when the procedure is first called - \
it is used when KillScript recursively calls itself to keep track of \
the number of tries.

  global system
  global env

#  puts "KillScript script_pid $script_pid $env(HOST)"

  if { [regexp WINDOWS $system(OPSYS) ] } { 
#   WarningMessage "Sorry - Kill Job not yet implemented for NT"
#   return 0
#   Let's try this:
    set status [catch {exec taskkill /F /T /PID $script_pid} errmsg]
    set unit [open [file join [GetEnvPath CCP4_SCR] test_kill.log] "w"]
    puts $unit "Forcedly terminating script id=$script_pid"
    puts $unit "Status=$status"
    puts $unit "$errmsg"
    close $unit
    if { $status } { return 0 } else { return 1 }
  }

  # Check that the supplied pid is valid
  if { $script_pid == "" || $script_pid < 0 } {
    WarningMessage "Sorry cannot kill this job.
The script process id appears to be invalid."
    return 0
  }

# The script process id is $script_pid 
# There are potential problems in interpreting the output
# of the ps -ef command.
# No chance if not Unix!

# If can not find child process try again after delay milli-secs
# Retry max_retry times
# If still fails then kill the script if kill_script is true

  set delay 3000
  set max_retry 3
  set kill_script 1

# Run Unix ps -ef

  set process_list [GetProcessList]
  if { [llength $process_list] == 0 } {
     WarningMessage "Sorry can not kill job.  
Failed to run Unix ps -ef command."
     return 0
  }

#First line should be column headers

  set pid_column [lsearch -exact [lindex $process_list 0] PID]
  set ppid_column [lsearch -exact [lindex $process_list 0] PPID]
  if { $ppid_column < 0 || $pid_column < 0 }  { 
    WarningMessage "Sorry can not kill job.
Can not parse output from Unix ps -ef command.
Please inform CCP4 - mention the machine you are using and send 
an example of the output when you type 'ps -ef' on your terminal"
    return  0
  }

# Check that we can find a process with the specified pid

  set pid_exists 0
  foreach process [lrange $process_list 1 end] {
    catch {
	if { [lindex $process $pid_column] == $script_pid } { set pid_exists 1 }
    }
  }

# Don't try and kill a process which no longer exists

  if { $pid_exists == 0 } {
    WarningMessage "Sorry could not kill script process $script_pid
Process not found"
    return 0
  }

# Loop over all processes looking for those with parent $script_pid

  foreach process [lrange $process_list 1 end] {
    set ppid ""
    catch { set ppid [lindex $process $ppid_column] }
    if { $ppid == $script_pid } {
	# Found a child process of script_pid
	set child_pid [lindex $process $pid_column]
	# Now kill children of this process
	PleaseWait "Attempting to kill all subprocesses"
	if { [KillChildProcesses $child_pid $delay] } {
	    Report 3 "Killed process $child_pid"
	    PleaseWait
	    return 1
	}
	PleaseWait
    }
  }

# Failed to kill child - probably no child process running - wait and try again 

  incr nretry
  if { $nretry <= $max_retry } {
    after $delay [list KillScript $script_pid $nretry ]
    return 0
  } else {

# Failed to kill child after retrys - check the script process is
# still running
# Get an updated list of processes
  after $delay
  set process_list [GetProcessList]
  if { [llength $process_list] == 0 } {
    WarningMessage "Sorry can not kill job.  
Failed to run Unix ps -ef command."
    return 0
  }
# Look for the process id
  set pid_exists 0
  foreach process [lrange $process_list 1 end] {
     if { [lindex $process $pid_column] == $script_pid } { set pid_exists 1 }
  }
# The process existed when we started - assume that it died as a result
# of the child processes being killed
  if { $pid_exists == 0 } {
    WarningMessage "Script process $script_pid\nProcess has been terminated"
    return 1
  }

# Process still exists so kill it
 
    if { ![KillProcess $script_pid] } {
      WarningMessage "Sorry could not kill script process $script_pid"
      return 0
    } else {
      WarningMessage "Could not kill any programs being run by the 
script with process id $script_pid  so have killed the script.
This may mean the task has not finished cleanly."
      return 1
    }
  }
}

#-------------------------------------------------------------
proc GetProcessList { } {
#-------------------------------------------------------------
#d_sum Return the process information from the Unix ps command
#d_desc Determine the possible forms of the "ps" command for the current \
operating system, then execute using the get_process_list command to \
return the output as a list (with each line of output as an element of \
the list). Returns an empty string on error.
  # Determine the possible ps commands for this system
  global tcl_platform
  # Ideally I would prefer to put the tcl_platform(os) value into
  # e.g. the "system" array, cf system(OPSYS) for tcl_platform(platform) 
  # But this is the only place at present that the o/s name is required
  # so this should be sufficient for the time being
  if { $tcl_platform(os) == "Darwin" } {
    # MacOs (Darwin) ps command
    set cmd_list [list "|ps lax"]
  } elseif { $tcl_platform(os) == "SunOS" } {
    # SunOS ps command(s)
    # Depends whether you are using BSD ps or not
    set cmd_list [list "|ps -ef" "|ps lax"]
  } else {
    # Default
    set cmd_list [list "|ps -ef"]
  }
  # Call get_process_list for each possible command
  # Stop when you find one that works - or run out of possibilities
  foreach ps_command $cmd_list {
    set process_list [get_process_list $ps_command]
    if { $process_list != "" } {
      # Got a non-blank list of process info - return
      return $process_list
    }
  }
  # All commands failed
  return ""
}

#-------------------------------------------------------------
proc get_process_list { ps_command } {
#-------------------------------------------------------------
#d_sum Execute and return the output of Unix command ps ...
#d_desc Internal command called from GetProcessList. Executes the \
supplied "ps" command and returns the output as a list, with each \
line of output as an element of the list. Returns an empty string \
on error.
#d_arg ps_command The ps ... command appropriate to this system \
(normally ps -ef)
  # Try to execute the process list command
  if {[catch {set input [open "$ps_command" r]
             set process_list [split [read $input] \n]
             close $input } ]} {
     return ""
  }
  return $process_list
}

#-------------------------------------------------------------
proc KillProcess { pid } {
#-------------------------------------------------------------
#d_sum Kill a system process
#d_desc Kill a system process with the specified pid, by issuing the \
kill -9 command to it.
#d_desc Returns 1 on success, 0 on failure.
#d_arg pid The process id number for the process to be killed.
    if {![catch {exec kill -9 $pid}]} {
	return 1
    } else {
	return 0
    }
}

#-------------------------------------------------------------
proc KillChildProcesses { process_id delay } {
#-------------------------------------------------------------
#d_sum Kill a system process id and all its child processes
#d_desc Kill all the child processes of the specified system process (if \
any, by calling KillChildProcesses recursively) and then try to kill \
the process itself (if it is still active).
#d_desc Returns 1 on success, 0 on failure.
#d_desc After killing the child processes KillChildProcesses pauses \
for the specified delay, to allow the system to update, before checking to \
see if the parent process is still active. If not then it is assumed that \
it has died due to the kill signals sent to its children, and success status \
is returned.
#d_arg process_id pid of the system process to be killed
#d_arg delay delay in milliseconds after killing child processes and before \
checking whether the parent process is still active

# Get the process list

  set process_list [GetProcessList]
  if { [llength $process_list] == 0 } {
      puts "ERROR failed to get list of processes in KillChildProcess"
      return 0
  }

# First line should be column headers

  set pid_column [lsearch -exact [lindex $process_list 0] PID]
  set ppid_column [lsearch -exact [lindex $process_list 0] PPID]
  if { $ppid_column < 0 || $pid_column < 0 }  {
      puts "ERROR can't read output of ps -ef in KillChildProcesses"
      return  0
  }

# Loop over processes looking for those with parent parent process
# proc_id

  foreach process [lrange $process_list 1 end] {
      set parent_id ""
      set proc_id ""
      catch {
	  set parent_id [lindex $process $ppid_column]
	  set proc_id   [lindex $process $pid_column]
	  if { $parent_id == $process_id } {
	      # Found a process with a matching parent
	      # Kill _its_ child processes
	      KillChildProcesses $proc_id $delay
	  }
      }
  }

# Assume we've killed all the child processes (and their children)
# Now check if this process is still running
# Wait a little bit before checking however to let the system update
# itself

  after $delay

  set process_list [GetProcessList]
  if { [llength $process_list] == 0 } {
      puts "ERROR failed to get process list in KillChildProcess"
      return 0
  }
  foreach process [lrange $process_list 1 end] {
      catch {
	  set proc_id [lindex $process $pid_column]
	  if { $proc_id == $process_id } {
	      if {[KillProcess $process_id]} { 
		  return 1
	      } else {
		  puts "ERROR unable to kill process $process_id"
		  return 0
	      }
	  }
      }
  }

# Couldn't find the process so assume it died as a result of
# losing its children
  return 1
}

#--------------------------------------------------------------------------
proc KillRemoteScript { job_id } {
#--------------------------------------------------------------------------
#d_sum Kill a ccp4i non-graphical script running on a remote machine
#d_desc This uses a *nix system command (either ssh or rsh) to start \
another ccp4i process on the remote machine.  The new process has a \
-k(ill) argument and will just use the KillScript procedure to kill \
the target process before terminating itself.
#d_arg job_id Job number of job to be killed.
  global system
  global configure

# Kill a remote job by sending an rsh/ssh command to "ccp4ish -k $job_id"
  set protocol $configure(REMOTE_PROTOCOL)

#  puts "KillRemoteScript $job_id"

# Make sure it is a remote job - still running and we can see 
# the log file

  if { ![regexp REMOTE [DbGetJobData $job_id STATUS ]] } { return 0 }

  if { ![ReadLogPid $job_id pid ] } {
    WarningMessage "Sorry can not kill job.  Can not read PID from log file"  
    return 0
  }
  set machine [DbGetJobData $job_id MACHINE ]
#  puts "machine $machine"

# Write a com script for the rsh/ssh to run
  set comfile [ FileJoin [GetDefaultDirPath TEMPORARY] kill_remote.com ]
  DeleteFile $comfile

  if { ![WriteFile $comfile  "$configure(CCP4_SETUP_COMMAND)
$configure(RUN_CCP4I) -k $pid"] } {
     WarningMessage "Sorry can not kill job. Failed to create $protocol command file"
     return 0
  }

  if {[catch {exec $protocol $machine -n source "$comfile" & } message ]} {
    WarningMessage "Sorry can not kill job. Failed to $protocol the kill command script"
    return 0
  }
  return 1
}

#--------------------------------------------------------------------------
proc ReadLogPid { job_id pidVar } {
#--------------------------------------------------------------------------
#d_sum Read log file header to get process id
#d_desc  All ccp4i scripts write an identifier to the top of the output \
log file.  One item of information is the process id.
#d_desc When ccp4i starts a job it usually saves the process id in the project \
database but this information is lost if the main ccp4i job is stopped and \
restarted.  The best way to recover the process id is from the log file. \
The only current use for the information is to kill a job.
#d_arg job_id	Job number
#d_arg pidVar	Return the process id for the job

  upvar $pidVar pid


  if  {![file exists [set log [GetLogFileName $job_id ]]]  \
        || ![OpenFile $log f r] } { return 0 }

# just read first 15 lines of the log file the prcess pid should be there
  set pid ""; set machine ""
  for { set n 1 } { $n <= 15 } { incr n } {
    if {[catch {gets $f line} ]} {
      CloseFile $f
      return 0
    }
    if { [regexp {^#CCP4I } $line] && [regexp PID $line] } {
#      set machine [lindex $line 3]
      set pid [lindex $line 2]
      CloseFile $f
      return 1
    }
  }
#  puts "pid $pid"
  CloseFile $f
  return 0
}


#d_index_title Server-Side Socket Handling
#d_intro_title Server Side Socket Handling
#d_intro See the Tcl documentation on the socket command and also the \
client side procedures in 
#d_ref PROGDOCS system.html#Socket_Handling Socket Handling
#d_intro In CCP4i the main \
graphical process acts as the server which has a permanently open port \
to which the non-graphical processes (which run the programs) can connect. \
The main use for the sockets is to return information on job status \
and output files to the main ccp4i process.
#d_intro The server port is opened at CCP4i startup  by \
OpenServerPort.  There are then two processes ServerAcceptSocket which \
accepts new socket connections from a client and ServerAcceptInput which \
accepts input via a socket. The input to ServerAcceptInput is usually in the \
form of a command which is the name of a ccp4i procedure and some arguments. \
For obvious security reasons only a very limited number of commands are \
recognised and these are explicitly listed in ServerAcceptInput. 
#d_intro The activities of the socket handlers are reported in the session log
#d_ref PROGDOCS system.html#CreateSessionLog Session Log


#------------------------------------------------------------------------------
proc OpenServerPort { } {
#------------------------------------------------------------------------------
#d_sum Open a port in the CCP4i server i.e. the main graphical process
#d_desc This procedure called as part of ccp4i initialisation. \
The port id is one in the range defined by configure(GUI_PORT).  \
This should be a list of two elements - the first and last in the range \
of permissible port ids.  The number of ports required may exceed the number \
available if there are a large number of ccp4i processes on one machine.  \
This procedure reports to the user if it fails and warns that inter-process \
communication will fail.

  global system
  global configure

  if { ![ElementExists configure GUI_PORT] || 
	[llength $configure(GUI_PORT)] <= 0 } {
    WarningMessage "There are no communications sockets defined in your configure file.
Job status updates (eg RUNNING and FINISHED) will not work.

This may be because you have a configure file for and old version of CCP4I
You could try deleting or moving .CCP4_configure from your home directory 
so you will then use the default file for your site.

Use the help button to get installation information" \
     -help [SearchPath HELP general ccp4i_installation.html] -target sockets

    return 0
  }


  for { set port [lindex $configure(GUI_PORT) 0] } \
	{ $port <= [lindex $configure(GUI_PORT) end] } { incr port } {
    set status [catch {socket -server ServerAcceptSocket $port } socket_id ]
    Report 3 "OpenServerPort $port $status $socket_id"
    if { !$status } { 
      set system(SERVER_PORT) $port
      set system(SERVER_SOCKET) $socket_id
#      puts "SERVER_PORT $port SERVER_SOCKET $socket_id"
      return 1
    }
  }
# Hum did not manage to open a socket
  set nsockets [expr {[lindex $configure(GUI_PORT) 1] -  \
		[lindex $configure(GUI_PORT) 0] +1}]
  WarningMessage "Could not open communication socket.

Job status updates (eg RUNNING and FINISHED) will not work.

This may be because other CCP4Is are running on the same 
machine and have used all $nsockets sockets.
Use the Help button to see the installation help file." \
  -help [SearchPath HELP general ccp4i_installation.html] -target sockets
  set system(SERVER_SOCKET) 0
  set system(SERVER_PORT) ""

  return 0
}

#------------------------------------------------------------------------------
proc ServerAcceptSocket { newSock addr port } {
#------------------------------------------------------------------------------
#d_sum Accept a socket connection from a client
#d_arg newSock the id for the new socket
#d_arg addr Address (as domain style name of ip address) for the client machine
#d_arg port Port id for the client side of the connection

  global system
  Report 2 "Accepting $newSock from $addr port $port"
  set system(socket,$newSock) [list $addr $port]
  fconfigure $newSock -buffering line
  fileevent $newSock readable [list ServerAcceptInput $newSock]
}

#------------------------------------------------------------------------------
proc ServerAcceptInput { sock } {
#------------------------------------------------------------------------------
#d_sum Accept input from a client
#d_desc  The input should be in the form of one of the recognised commands: \
DbReceive, EditComFile, DbAddOutputFile or LGServerReceive.  Or an eof marker \
will indicate that the socket is being closed from the client side and so \
should be closed by the server.
  global system

  if { [eof $sock ] || [catch { gets $sock line } ] } {
    close $sock
    Report 2 "Close $sock $system(socket,$sock)"
    unset system(socket,$sock)
  } else {
    Report 1 "ServerAcceptInput $line"
    switch [lindex $line 0] {
	DbReceive {
	    eval [concat DbReceive [lrange $line 1 end] ]
	}
	DbAddOutputFile {
	    eval [concat DbAddOutputFile [lrange $line 1 end] ]
	}
	EditComFile  {
	    set comline [lindex $line 1]
	    set comfile [lindex $line 2]
	    set edit_status [EditComFile comline $comfile]
	    puts $sock [list $edit_status "$comline"]
	}
	RunAborted {
	    eval [concat RunAborted [lrange $line 1 end] ]
	}
	RunCompleted {
	    eval [concat RunCompleted [lrange $line 1 end] ]
	}
	LGServerReceive { 
	    eval [concat LGServerReceive -sock $sock [lrange $line 1 end] ]
	}
    }
  }
}

#---------------------------------------------------------------
proc PrintFile { printer file } {
#---------------------------------------------------------------
#   puts "printer $printer file $file"
   set cmd "exec $printer \"$file\""
   if {[catch "$cmd"]} {
     WarningMessage "Unable to execute print command $printer"
   }
}
