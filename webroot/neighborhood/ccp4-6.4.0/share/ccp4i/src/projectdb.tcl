#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - database.tcl
#
#
#
# Database handling utilities
#
# Liz Potterton Jan97
# Peter Briggs  Dec02
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Core Database Functions (src/projectdb.tcl)
#d_intro_title Core Database Functions
#
#d_intro The database of user's jobs is stored in the array called 'database'  and \
this saved to a file project_directory/CCP4_DATABASE/database.def in a standard \
def format file.  It is strongly discouraged to access the database array directly \
from any procedure outside of this file.  An empty database is defined in the file \
$CCP4I_TOP/etc/database.def.  Each job in a project is given a job id which is an \
integer which is incremented, from 1, for every new job.\
  The currently supported database parameters are NJOBS (the number of the highest \
job id in the database) and then parameters *,$n where n is the job id and the \
required values of * are given below.  These parameters are written to the project\
 database file, there are additional parameters may be saved in the database array \
but not be saved to file.

#d_intro TASKNAME	The name of the type of task 
#d_intro DATE		The date that the job started (if still running)\
 or finished saved as the machine time.
#d_intro STATUS		A one-word job status
#d_intro LOGFILE	The file name of the log file (NOT the full path name)
#d_intro TITLE		A text string of the job title provided by the user
#d_intro INPUT_FILES	A list of the input file names \
(not paths UNLESS the user has specified Full path rather than used a directory alias)
#d_intro INPUT_FILES_DIR A list of the project/directory aliases for the input files
#d_intro INPUT_FILES_STATUS Currently unused
#d_intro OUTPUT_FILES    A list of the output file names (not paths UNLESS the\
 user has specified Full path rather than used a directory alias)
#d_intro INPUT_FILES_DIR A list of the project/directory aliases for the output files
#d_intro OUTPUT_FILES_STATUS Currently unused

#d_intro Each project that the user creates will have its own database.def \
file and the appropriate file is loaded whenever the user changes between \
projects.  The database.def file is updated from memory after every significant \
change.  The time taken to read a database.def file is significant for projects\
 with many jobs.

#d_index_title Commands for Handling Database Files
#d_intro_title Commands for Handling Database Files
#
#d_intro These commands deal with loading and saving the job \
database information from the persistent storage on disk i.e. \
the database.def file.
#d_intro They are specific to CCP4i handling the database.def \
files directly by itself.

#-----------------------------------------------------------
proc DbLoadFile { project args } {
#-----------------------------------------------------------
#d_sum Load a database.def file into the database array
#d_desc Returns 1 for success, 0 for failure, -1 if project \
is already locked by another process.
#d_desc In the event of a lock not being overriden, the user and \
time information can be retrieved ysing the DbGetMessage command.
#d_arg project Alias of project to load
#d_opt0 -grablock
#d_opt1 Override and grab the lock from another process (if necessary)

  # Using the database handler
  if { [using_dbccp4i] } {
      return [eval dbccp4i_open_project $project $args]
  }

  # Direct access
  global database

  # Initialise array by loading an 'empty' database.def
  InitialiseArray [SearchPath TOP etc database.def] \
                 database CCP4_Project_Database

  # Acquire the database directory
  set db [GetProjectDBPath $project]
  set file [FileJoin $db database.def]

  # Deal with any locking issues
  if { ! [DbLockStatus $project user time] } {
      # There is a lock
      if { [lsearch $args "-grablock"] > -1 } {
	  # Override the lock
	  Report 2 "DbLoadFile: deleting lock on project \"$project\""
	  DbDeleteLock $project -force
      } else {
	  # Return -1 indicating failure due to lock
          Report 2 "DbLoadFile: database for project $project is locked"
	  DbSetMessage [list Lock $user $time]
	  return -1
      }
  }

  # Make a lock and open the database
  if { [file exists $file] } {
    if { [DbCreateLock $project] } {
      Report 2  "Loading Project Database information from $file"
      InitialiseArray $file database "CCP4_Project_Database"
      set njobs 0
      for { set n 1 } { $n <= $database(NJOBS) } { incr n } {
        if { [ElementExists database STATUS,$n] } { incr njobs }
      }
      Report 2 "Current database has record of $njobs jobs"
      DbFlushCommandBuffer $project
      # Return 1 on success
      return 1
    } else {
      # Failed to make a lockfile
      Report 2 "Failed to make lockfile for project $project"
      DbSetMessage "DbLoadFile: Failed to make lockfile for project $project"
      set database(NJOBS) 0
      # Return 0 on failure
      return 0
    }
  } else {
      # The database file is missing
      # This is surely an error
      Report 2 "DbLoadFile: database file $file for project $project does not exist"
      DbSetMessage "DbLoadFile: database file $file for $project is missing"
      set database(NJOBS) 0
      # Return 0 on failure
      return 0
  }
}

#-----------------------------------------------------------
proc DbSaveFile { project args } {
#-----------------------------------------------------------
#d_sum Save the current contents of the database to database.def
#d_desc This procedure contains a messy bit of code to set the status of jobs \
in the output file to 'ON_HOLD' without changing the status in the \
loaded database.  This is used for creating regression test directories \
and databases in db_autotest_handler
#d_desc Return 1 if save was successful, 0 if not
#d_arg project Alias of the project for which the database is to be saved
#d_opt0 -hold
#d_opt1 Set job status in output file to ON_HOLD
#d_opt0 -range first last
#d_opt1 if -hold also set, set job status of jobs in range first to last to ON_HOLD

  # Using the database handler
  if { [using_dbccp4i] } {
      # FIXME for now do nothing, but need to deal with
      # -hold and -range options in future
      return 1
  }

  # Direct access
  global database

  if { ![array exists database] } {
    return 0
  }

  # Get the database directory for the current project
  set db [GetProjectDBPath $project]

  # Is the database locked by a different process?
  if { [DbLockStatus $project user time pid] != 0 } {
    Report 2 "DbSaveFile: this project is not locked - it is unsafe to save database"
    return 0
  }
  Report 2 "DbSaveFile: pid of lock is $pid"
  Report 2 "DbSaveFile: pid of current process is [GetPid]"
  if { [GetPid] != $pid } {
    Report 2 "DbSaveFile: lock is no longer held by this process, cannot save database"
    return 0
  }

  set on_hold 0
  set range_first 1
  set range_last $database(NJOBS)

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    range {
      incr n; set range_first [lindex $args $n]
      incr n; set range_last [lindex $args $n]
    } hold {
      set on_hold 1
    }
    incr n
  }

  if { $db == "NO_DATABASE" || $db == "" } return
  set dbfile [FileJoin $db database.def]
  set tmpfile [FileJoin $db tmp_database.def]

  set text [WriteIdentifier {} \
	"DEF CCP4_Project_Database" \
	PROJECT "$project $db" ]

  append text "[format  %-25s%-40s NJOBS $database(NJOBS)]\n" 

  set job_list [array names database STATUS,* ]
  foreach job $job_list {
  if { ![StringSame $database($job) closed] } {
    regexp {,([^,]*)} $job ff n
    if { $n >= $range_first && $n <= $range_last } {
      if { $on_hold } {
        append text "STATUS,$n                  ON_HOLD\n"
      } else {
        append text "STATUS,$n                  $database(STATUS,$n)\n"
      }
      foreach item [ list DATE LOGFILE SCRATCH TASKNAME RUNFILE ] {
        catch {
          set lvalue [string length $database($item,$n)]
	  if { [string trim $database($item,$n)] == "" } {
            # Wrap blank values in quotes
            append text "[format  %-25s%-1s%-[subst $lvalue]s%-1s \
		$item,$n "\"" $database($item,$n) "\""]\n" 
          } else {
            append text "[format  %-25s%-[subst $lvalue]s \
		$item,$n $database($item,$n)]\n" 
          }
        }
      }

      foreach item [ list TITLE INPUT_FILES INPUT_FILES_DIR INPUT_FILES_STATUS \
    	OUTPUT_FILES OUTPUT_FILES_DIR OUTPUT_FILES_STATUS ] {

        catch {
          set lvalue [string length $database($item,$n)]
          append text "[format  %-25s%-1s%-[subst $lvalue]s%-1s $item,$n "\"" \
  			$database($item,$n) "\""]\n" 
        }
      }
    }
  } }

  # Safety feature: write a temporary database file first
  WriteFile $tmpfile $text -overwrite

  # Copy the temporary file to overwrite the actual database
  # file
  # The reasoning is that if an error occurs then it is less
  # likely to completely corrupt the database file
  CopyFile $tmpfile $dbfile -overwrite
  return 1
}

#d_index_title Commands for handling messages and callbacks
#d_intro_title Commands for handling messages and callbacks
#
#d_intro These functions provide a mechanism for getting additional \
information back from the underlying database functions, particularly \
in the event of a failure or other problem.
#d_intro Functions call DbSetMessage to record details in addition \
to the status or other values that they might return. Higher level \
functions can then fetch the message using DbGetMessage in the event \
of an error.
#d_intro An example of this is when a database fails to load because \
of a lock, DbLoadFile records the user and time from the lock file \
using DbSetMessage. The calling function can retrieve this data using \
DbGetMessage in order to report it to the end user.
#d_intro This isn't a particularly pretty way of doing things but it \
should work.
#d_intro The DbRegisterCallback function provides a way for the \
top-level application to bind one or more commands which are invoked \
each time the database is updated by a write operation.

#-------------------------------------------------------------------------
proc DbSetMessage { message } {
#-------------------------------------------------------------------------
#d_sum (Re)set the internal message from the core database functions.
#d_arg message The message to be reported
    global db_admin
    set db_admin(_DB_MESSAGE) $message
}

#-------------------------------------------------------------------------
proc DbGetMessage {} {
#-------------------------------------------------------------------------
#d_sum Fetch and clear the last internal message from the core db functions.
#d_desc This returns the last message that was recorded by a call to \
DbSetMessage, and then clears the stored message.
    global db_admin
    if { [info exists db_admin(_DB_MESSAGE)] } {
	set message $db_admin(_DB_MESSAGE)
    } else {
        set message ""
    }
    set db_admin(_DB_MESSAGE) {}
    return $message
}

#-------------------------------------------------------------------------
proc DbRegisterCallback { callbackProc } {
#-------------------------------------------------------------------------
#d_sum Specify a procedure that will be invoked on save
#d_desc This allows a callback procedure to be specified, so that whenever \
the database is saved to persistent storage the callback will be invoked \
immediately afterwards.
#d_desc See also the DbSave procedure.
#d_arg callbackProc Name of the command to be invoked.
    global db_admin
    if { ![info exists db_admin(_DB_CALLBACK_PROCS)] } {
	# First time that this function has been called
	# Initialise the list of callback functions
	set db_admin(_DB_CALLBACK_PROCS) {}
    }
    # Add the callback procedure if it isn't already
    # in the list
    if { [lsearch $db_admin(_DB_CALLBACK_PROCS) $callbackProc] < 0 } {
	lappend db_admin(_DB_CALLBACK_PROCS) $callbackProc
    }
}

#d_index_title Commands for Handling Automatic Database Saves
#d_intro_title Commands for Handling Automatic Database Saves
#
#d_intro These commands are used internally by the database functions \
to manage scheduling automatic saves of the job database to persistent \
storage as required.
#d_intro DbModified is called by 'write' operations (e.g. adding or \
deleting jobs, and modifying the value of data items). This schedules \
calls to DbSave, which manages the actual saving operation.

#-------------------------------------------------------------------------
proc DbModified { { broadcast {} } } {
#-------------------------------------------------------------------------
#d_sum Register that the database has been modified.
#d_desc This command is called by the database 'write' operations. It \
sets a flag to indicate that the database needs saving to file, and \
schedules a call to DbSave to perform the operation (if one is not \
currently scheduled).
#d_desc This is an internal command and should not normally be called \
directly.
#d_arg broadcast (Optional) The "broadcast" data received from the \
database handler
    # Called when the database is modified by a "write"
    # operation
    if { [using_dbccp4i] && [llength $broadcast] == 5 } {
	dbccp4i_update_cache $broadcast
    }
    global db_admin
    if { [info exists db_admin(_DB_NEEDS_SAVE)] } {
	if { ! $db_admin(_DB_NEEDS_SAVE) } {
	    # Schedule a save
	    after idle DbSave
	    # Set the save flag to indicate that 
	    # a save is scheduled
	    set db_admin(_DB_NEEDS_SAVE) 1
	}
    } else {
	# First time this function was called
	# Schedule a save
	after idle DbSave
	# Initialise the save flag
	set db_admin(_DB_NEEDS_SAVE) 1
    }
}

#-------------------------------------------------------------------------
proc DbSave { } {
#-------------------------------------------------------------------------
#d_sum Save the currently open project database within CCP4i
#d_desc This command is used internally and should not normally be called \
directly. Instead a save of the data to persistent storage is scheduled \
by a call to the DbModified command - typically this is done automatically \
by the 'write' database operations.
#d_desc The actual save of the data is done by a call to DbSaveFile. The \
save operation will only be performed if the DB_NEEDS_SAVE flag is set, \
to reduce the overhead of redundant saves that might be incurred otherwise.
#d_desc Each time DbSave is called it checks for and invokes any callback \
procedures that were previously specified using the DbRegisterCallback \
command. The callbacks are invoked regardless of whether the database \
was saved.
    global db_admin
    if { [info exists db_admin(_DB_NEEDS_SAVE)] } {
	if { $db_admin(_DB_NEEDS_SAVE) } {
	    # Save the database to persistent storage
	    DbGetCurrentProject project
	    DbSaveFile $project
	    # Reset the save flag
	    set db_admin(_DB_NEEDS_SAVE) 0
	}
    } else {
	# First time this function was called
	# Initialise the save flag
	set db_admin(_DB_NEEDS_SAVE) 0
    }
    # If there are any callbacks specified then invoke them
    if { [info exists db_admin(_DB_CALLBACK_PROCS)] } {
	foreach callback $db_admin(_DB_CALLBACK_PROCS) {
	    # Use catch to trap any failures
	    catch { eval $callback }
	}
    }
    return
}

#d_index_title Commands for Handling Database Locking
#d_intro_title Commands for Handling Database Locking
#
#d_intro These commands handle creating, interrogating and removing \
lock files associated with CCP4i project database.def files.

#-------------------------------------------------------------------------
proc DbLockFileName { project } {
#-------------------------------------------------------------------------
#d_sum Return the lock file name
#d_desc Lock file name is database.LOCK
#d_arg project Alias of project
    return [FileJoin [GetProjectDBPath $project] database.LOCK]
}

#--------------------------------------------------------------------------
proc DbLockStatus { project userVar timeVar { pidVar "" } } {
#--------------------------------------------------------------------------
#d_sum Return status of lock file
#d_desc Return 0 is lock file exists and 1 (i.e. OK to open \
database file) if it does not.
#d_arg project Alias of project
#d_arg userVar Return name of user who created lock file
#d_arg timeVar Return time of creation of lock file
#d_arg pidVar  (Optional) Return id of process which owns the lock file
  upvar $userVar user
  upvar $timeVar time
  if { $pidVar != "" } {
    upvar $pidVar pid
  }

  set lockfile [DbLockFileName $project]
  if { [file exists $lockfile] } {
    Report 2 "DbLockStatus: project $project: lockfile exists"
    OpenFile  $lockfile f r
    gets $f line; gets $f line; set user [lindex $line 2]
    gets $f line; set time [lrange $line 1 end]
    gets $f line; set pid [lindex $line end] 
    CloseFile $f
    Report 2 "DbLockStatus: project $project: $user $time $pid"
    return 0
  } else {
    Report 2 "DbLockStatus: project $project: lockfile doesn't exist"
    set user ""
    set time ""
    set pid  ""
    return 1
  }
}

#-------------------------------------------------------------------------
proc DbCreateLock { project } {
#-------------------------------------------------------------------------
#d_sum Create a lock file
#d_desc Returns 1 if lock was created, 0 otherwise
#d_arg project Alias of project
  global system

  if { [DbLockStatus $project user time ] == 0 } {
    return 0
  }
  set lockfile [DbLockFileName $project]
  set status [OpenFile $lockfile f w ]
  if { $status } {
    puts $f "Lock file for $project"
    puts $f "Created by [GetUserId]"
    puts $f "Date [GetDate]"
    puts $f "Owned by pid [GetPid]"
    puts $f "Server port $system(SERVER_PORT)"
    CloseFile $f
    return 1
  } else {
    return 0
  }
}

#----------------------------------------------------------
proc DbDeleteLock { project args } {
#----------------------------------------------------------
#d_sum Delete lock file for specified project database
#d_opt0 -force
#d_opt1 Force deletion of the lock even if not owned by the current \
process

  set force 0
  if { [lsearch $args "-force"] > -1 } { set force 1 }

  # Only delete the lock if this process actually owns it
  if { [DbLockStatus $project user time pid] != 0 } {
    Report 2 "DbDeleteLock: no lock file found"
    return
  }
  if { [GetPid] == $pid } {
    DeleteFile [DbLockFileName $project]
  } elseif { $force } {
    Report 2 "DbDeleteLock: lock is not owned by this process, forcing removal"
    DeleteFile [DbLockFileName $project]
  } else {
    Report 2 "DbDeleteLock: lock is not owned by this process, not removed"
  }
  return
}

#d_index_title Commands for Opening and Closing the Job Database
#d_intro_title Commands for Opening and Closing the Job Database
#
#d_intro These commands handle opening and closing of the job \
database for a project.

#-----------------------------------------------------------
proc DbOpenDatabase { project args } {
#-----------------------------------------------------------
#d_sum Open a project database
#d_desc Returns status from DbLoadFile: 1 for success, 0 for \
failure, -1 if project is already locked by another process.
#d_arg project Project name (i.e. alias) for project
#d_opt0 -grablock
#d_opt1 Grab the lock from another process

  # Attempt to open the database
  if { [lsearch $args "-grablock"] > -1 } {
      set status [DbLoadFile $project -grablock]
  } else {
      set status [DbLoadFile $project]
  }

  # Set some internal parameters
  if { $status == 1 } {
      # Success
      SetProjectDatabase [GetProjectDBPath $project]
  } else {
      # Failed for some reason, nothing loaded
      SetProjectDatabase "NO_DATABASE"
  }

  return $status
}

#-----------------------------------------------------------
proc DbCloseDatabase { project } {
#-----------------------------------------------------------
#d_sum Close the current database
#d_desc If there is a current 'open' database then make sure it \
is up to date and then unset the database array
#d_arg project Alias for project

  # Using the database handler
  if { [using_dbccp4i] } {
      SetProjectDatabase "NO_DATABASE"
      return [dbccp4i_close_project $project]
  }

  # Direct access
  global database

  DbSaveFile $project
  DbDeleteLock $project
  if { [ array exists database ] } { unset database }
  SetProjectDatabase "NO_DATABASE"
  return
}

#d_index_title Core Database Functions
#d_intro_title Core Database Functions
#
#d_intro These functions handle direct interactions with the database \
information stored in the global database array.

#-----------------------------------------------------------------------
proc DbNewRecord { taskname  { status "STARTING" } } {
#-----------------------------------------------------------------------
#d_sum Creates a new record in the database and returns handle (=job id)

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [dbccp4i_new_job $project $taskname $status]
  }

  # Direct access
  global database

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1  "WARNING DbNewRecord: process [GetPid] has lost the db lock"
    return 0
  }

  if { [ElementExists database NJOBS] == 0 } { set database(NJOBS) 0 }
  set job_id [incr database(NJOBS)]

  # Initialise the job data
  DbSetJobData $job_id DATE [GetDate -format seconds ]
  DbSetJobData $job_id STATUS $status
  DbSetJobData $job_id TITLE "\[No title given\]"
  DbSetJobData $job_id LOGFILE ""
  DbSetJobData $job_id TASKNAME $taskname
  DbSetJobData $job_id INPUT_FILES ""
  DbSetJobData $job_id INPUT_FILES_DIR ""
  DbSetJobData $job_id INPUT_FILES_STATUS ""
  DbSetJobData $job_id OUTPUT_FILES ""
  DbSetJobData $job_id OUTPUT_FILES_DIR ""
  DbSetJobData $job_id OUTPUT_FILES_STATUS ""

  # Register that the database is changed
  DbModified

  return $database(NJOBS)
}

#----------------------------------------------------------------------
proc DbJobExists { job_id } {
#----------------------------------------------------------------------
#d_sum Check whether a job exists in the database
#d_desc Checks for the existence of the specified job and returns \
1 if found, 0 if not.
#d_desc Currently just a wrapper for DbItemExists job_id STATUS.
#d_arg job_id Job id
  return [DbItemExists $job_id STATUS]
}

#----------------------------------------------------------------------
proc DbItemExists { job_id type } {
#----------------------------------------------------------------------
#d_sum Check whether a data item is defined in the database
#d_arg job_id Job id (Ignored if type = NJOBS)
#d_arg type The type of data to be checked -  see 
#d_ref CURRENT "Database Utilities" Introduction

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [dbccp4i_item_exists $project $job_id $type]
  }

  # Direct access
  global database

  if { $type == "NJOBS" } { return [ElementExists database NJOBS] }

  return [ElementExists database [subst $type],$job_id]
}

#----------------------------------------------------------------------
proc DbSetJobData { job_id args } {
#----------------------------------------------------------------------
#d_sum Assign a value to database item(s)
#d_desc There is no content checking in this procedure - the user is \
responsible for sensible input.  There can be one or more pairs of \
input param_name/param_value arguments.
#d_arg job_id Job id
#d_arg param_name Name of database parameter - see
#d_ref CURRENT "Database Utilities" Introduction
#d_arg param_value Value for database parameter

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [eval dbccp4i_set_data $project $job_id $args]
  }

  # Direct access
  global database

  # Check that this instance of CCP4i has the lock on
  # the database
  if { ![DbVerifyLock] } {
    Report 1  "WARNING DbSetJobData: unable to set data, process [GetPid] has lost the lock on the db"
    return 0
  }

  if { $job_id < 1 || $job_id > $database(NJOBS) } {

    Report 1  "ERROR Updating database: invalid job id $job_id"
    return 0

  } else  {

    set i 0; while { $i < [llength $args] } {
      set var [lindex  $args $i]; incr i
      set value "[lindex  $args $i]" ; incr i
      set database([Indxv $var $job_id]) "$value"
    }
  }

  # Register that the database is changed
  DbModified
}

#----------------------------------------------------------------------
proc DbGetNJOBS { } {
#----------------------------------------------------------------------
#d_sum Return the value of the NJOBS parameter
#d_desc NJOBS is an integer value corresponding to the highest assigned \
job id in the current project. If zero is returned then there are no \
jobs currently assigned to the project.

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [dbccp4i_get_njobs $project]
  }

  # Direct access
  global database

  if { ![ElementExists database NJOBS ] } {
      return 0
  } else {
      return $database(NJOBS)
  }
}

#----------------------------------------------------------------------
proc DbGetJobData { job_id args } {
#----------------------------------------------------------------------
#d_sum Return a data item from the database
#d_arg job_id Job id (Ignored if type = NJOBS)
#d_arg type The type of data to be returned - see 
#d_ref CURRENT "Database Utilities" Introduction

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [eval dbccp4i_get_data $project $job_id $args]
  }

  # Direct access
  global database

  if { ![ElementExists database NJOBS ] } { return 0 }

  if { $job_id < 1 || $job_id > $database(NJOBS) } {

    Report 1  "ERROR retreiving from database: invalid job id $job_id"
    return ""

  } else {

    set result {}
    foreach type $args {

       if { $type == "NJOBS" } {
	   lappend result "$database(NJOBS)"
       } elseif { [ElementExists database [Indxv $type $job_id] ]} {
	   lappend result "$database([Indxv $type $job_id])"
       } elseif { [ElementExists database [Indxv $type $job_id 1]] } {
           lappend result "$database([Indxv $type $job_id 1 ])"
       } else {
	   append result ""
       }
    }
    if { [llength $args] == 1 } {
	# Don't return a list for a single item request
	set result [lindex $result 0]
    }
  }
  return $result
}

#-----------------------------------------------------------------------
proc DbJobHasSubjobs { job_id } {
#-----------------------------------------------------------------------
#d_sum Check if a job has any associated subjobs
#d_desc Returns 1 if the specified job has a subjob database associated \
with it, and zero otherwise.
#d_desc Subjob databases can only be accessed if the database handler \
is being used. Otherwise subjob databases cannot be accessed, even if \
they exist.
#d_arg project Name of the project
#d_arg job_id Job number

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [eval dbccp4i_job_has_subjobs $project $job_id]
  }
  # Direct access
  # No way to check for subjobs - always false
  return 0
}

#-----------------------------------------------------------------------
proc DbGetNotebookFile { job_id } {
#-----------------------------------------------------------------------
#d_sum Return the filename for the notebook file associated with a job
#d_desc This command returns the full path and filename for a notebook \
file associated with the specified job in the current project.
#d_desc Note that the file may not actually exist.
#d_arg job_id Job for which the notebook is requested

  # FIXME we should get this directly from the handler?
  DbGetCurrentProject project
  set db [GetProjectDBPath $project]
  return [FileJoin $db [append name $job_id "_notebook.txt" ] ]
}

#-----------------------------------------------------------------------
proc DbSelectJobs { type pattern } {
#-----------------------------------------------------------------------
#d_sum Return list of jobs based on selection criteria
#d_desc By default the jobs are sorted on job number in descending \
order.
#d_arg type Name of data item to select on
#d_arg pattern Regular expression pattern to match against

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [dbccp4i_select_jobs $project $type $pattern]
  }

  # Direct access
  global database

  set sortkey "" 
  set return_list ""
  set type_list [array names database [subst $type],* ]

  foreach type_item $type_list {
    if { [regexp -- $pattern $database([subst $type_item])] } {
        GetIndx $type_item root job_id c2
        if { $job_id != 0 } {
          lappend return_list $job_id
        }
    }
  }

  # Sort the list into descending order on job id number
  set return_list [lsort -integer $return_list]

  return $return_list
}

#----------------------------------------------------------------------
proc DbJobDescription { project job_id db_display db_display_format } {
#----------------------------------------------------------------------
#d_sum Append all database information for one job into one string for display
#d_arg project The alias for the project to access
#d_arg job_id  Job id
#d_arg db_display A list of the database parameters to be displayed
#d_arg db_display_format A list of the field widths (as integers) to \
use for displaying the items in the db_display list.  
# NB project is not currently used in this implementation

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_job_description $project [list $job_id] $db_display \
		  $db_display_format]
  }

  # Direct access
  global database

  set dummy " "
  set TASKNAME ""
  set TITLE ""

  set line_format ""
  foreach item $db_display_format {
    append line_format "%-" $item "s"
  }
  set cmd "set line \[ format \$line_format "
  foreach item $db_display {
    if { $item == "JOB_ID" } {
      append cmd " $job_id"
    } elseif { $item == "DATE" } {
      append cmd " \"[GetDate -format brief -clock $database(DATE,$job_id)]\""
    } elseif { $item == "TASKNAME" || $item == "TITLE" } {
      append [subst $item] $database($item,[subst $job_id]) " "
      append cmd " \$[subst $item]"
    } elseif { ![ElementExists database "$item,$job_id" ] || 
                 $database([subst $item ],$job_id) == "" } {
      append cmd " \$dummy"
    } else {
      append cmd  " \$database(" $item "," $job_id ")"
    }
  }
  append cmd "\]"
  eval "$cmd"
  return $line
}

#--------------------------------------------------------------------------
proc DbDeleteJob { job_id } {
#--------------------------------------------------------------------------
#d_sum Remove the record of a job from the database
#d_arg job_id id for the job record to be removed

  # Using the database handler
  if { [using_dbccp4i] } {
      DbGetCurrentProject project
      return [dbccp4i_delete_job $project $job_id]
  }

  # Direct access
  global database

  foreach item [array names database "*,$job_id"] {
    unset database($item)
  }
  foreach item [array names database "*,[subst $job_id]_*" ] {
    unset database($item)
  }
  if { $database(NJOBS) == $job_id } { incr database(NJOBS) -1 }

  # Register that the database is changed
  DbModified

  return
}

#--------------------------------------------------------------------------
proc DbVerifyLock { } {
#--------------------------------------------------------------------------
#d_sum Verify that the current process owns the lock on the database
#d_desc Returns 1 if the lockfile has the same process id (pid) as the \
current process (in which case it is assumed that this process owns the \
database lock) and 0 if the lockfile has a different pid (in which case \
it is assumed that a different process owns the lock).
#d_desc If no lock is found then assume that the current process cannot \
access the project i.e. it doesn't own the lock.

  # Using the database handler
  if { [using_dbccp4i] } {
    DbGetCurrentProject project
    return [dbccp4i_project_is_writable $project]
  }

  # Direct access
  DbGetCurrentProject project

  if { [DbLockStatus $project user time pid] == 0 } {
    # Lock exists - check the pid
    if { $pid == [GetPid] } {
	# Pid's are the same
	return 1
    } else {
	# Pid's differ
        return 0
    }
  }
  # No lock
  return 0
}

#d_index_title Internal functions for interacting with the database handler
#d_intro_title Internal functions for interacting with the database handler
#
#d_intro These are internal functions used to keep information on the \
current project that CCP4i is operating with.

#-------------------------------------------------------------------------
proc dbccp4i_open_project { project args } {
#-------------------------------------------------------------------------
#d_sum Open an existing project via the database handler.
#d_desc Projects must exist and must be opened before they can be accessed. \
This command is a wrapper for the OpenProject client API command and so \
accepts the same arguments as that command, see below.
#d_desc Return values are 1 (the project was opened successfully), 0 (the \
open operation failed for some reason), or -1 (the project wasn't opened \
because another process has a lock on it and the -force, -grablock or \
-readonly operations weren't specified).
#d_desc This command will always try to open the project with both read \
and write access privileges. If the project is opened successfully but \
does not have write access, and the -readonly option was not specified, \
then an attempt will be made to acquire write privileges automatically.
#d_arg project Name of the project to open
#d_opt0 -grablock
#d_opt1 Forces the handler to open a locked database
#d_opt0 -force
#d_opt1 An alias for -grablock
#d_opt0 -readonly
#d_opt1 Open project with read only mode

    set msg ""
    # Attempt to open the project
    set status [eval ::dbClientAPI::OpenProject $project msg $args]
    if { ! $status } {
	# Check for lock
	if { [regexp -- "locked" $msg] } {
	    set status -1
	}
    } else {
      dbccp4i_populate_cache $project
    }
    # It is possible that the project was already opened as readonly
    # by another client application
    # Try to acquire the lock automatically
    if { $status && ![dbccp4i_project_is_writable $project] && \
         [lsearch -regexp $args readonly] < 0 } {
      set result [::dbClientAPI::ReacquireProject $project]
    }
    return $status
}

#-------------------------------------------------------------------------
proc dbccp4i_close_project { project } {
#-------------------------------------------------------------------------
#d_sum Close access to an open project.
#d_desc Once the project has been closed, read/write operations will not \
work. The project must already be open in order to close it.
#d_arg project Name of the project to close

    return [::dbClientAPI::CloseProject $project]
}

#-------------------------------------------------------------------------
proc dbccp4i_project_is_writable { project } {
#-------------------------------------------------------------------------
#d_sum Check whether write access is available for a project.
#d_desc Returns 1 if write operations can be performed (i.e. creating \
or deleting jobs and setting job data) and 0 if not.
#d_arg project Name of the project to check

    return [eval ::dbClientAPI::ProjectWriteable $project]
}

#-------------------------------------------------------------------------
proc dbccp4i_new_job { project taskname status } {
#-------------------------------------------------------------------------
#d_sum Create a new job record in a project.
#d_desc If successful, this command creates a new job record in the \
specified project and returns the job id number for that job. Otherwise \
a job id of zero is returned, indicating that the operation failed.
#d_arg project Name of the project
#d_arg taskname Task being run
#d_arg status Status to assign to the job

    set job_id [::dbClientAPI::NewJob $project]
    if { $job_id > 0 } {
	dbccp4i_set_data $project $job_id TASKNAME $taskname STATUS $status
    }
    return $job_id
}

#-------------------------------------------------------------------------
proc dbccp4i_item_exists { project job_id item } {
#-------------------------------------------------------------------------
#d_sum Check whether a data item is defined for a given job.
#d_desc Returns 1 if both the job and the specified data item are found \
in the specified project, or 0 otherwise.
#d_arg project Name of the project
#d_arg job_id Job number
#d_arg item The data item of interest

    global dbcache

    # Error indicator
    set status 0

    # Try getting the data from the cache
    if { [info exists dbcache(LOADED)] && $dbcache(LOADED) } {
	if { $dbcache(PROJECT) == $project } {
	    set status 1
	    set result {}
	    if { [info exists dbcache([subst $item],$job_id)] } {
		set result 1
	    } else {
		set result 0
	    }
	}
    }

    if { $status } {
	# Successfully retrieved data
	return $result
    } else {
	return [::dbClientAPI::ItemExists $project $job_id $item]
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_set_data { project job_id args } {
#-------------------------------------------------------------------------
#d_sum Set the value of one or more data items for a job.
#d_desc Given a set of one or more item-value pairs, this attempts to set \
the value of each item.
#d_arg project Name of the project
#d_arg job_id Job number
#d_opt0 item
#d_opt1 The name of a data item in the project database e.g. TASKNAME, \
TITLE, STATUS etc
#d_opt0 value
#d_opt1 The new value to set the data item to.

    return [eval ::dbClientAPI::SetData $project $job_id $args]
}

#-------------------------------------------------------------------------
proc dbccp4i_get_njobs { project } {
#-------------------------------------------------------------------------
#d_sum Return the highest job id number for the project.
#d_desc This returns the highest job id number, not the number of jobs in \
the project.
#d_arg project Name of the project

    return [::dbClientAPI::GetNJOB $project]
}

#-------------------------------------------------------------------------
proc dbccp4i_get_data { project job_id args } {
#-------------------------------------------------------------------------
#d_sum Fetch the value of one or more data items associated with a job.
#d_desc Given a list of one or more data items, this attempts to fetch \
the value of each.
#d_desc If a single data item is requested then the return value will also \
be a single item, otherwise the command returns a list with each list \
item corresponding to the value of the requested data item.
#d_arg project Name of the project
#d_arg job_id Job number
#d_opt0 item
#d_opt1 The name of a data item in the project database e.g. TASKNAME, \
TITLE, STATUS etc

    global dbcache

    # Error indicator
    set status 0

    # Try getting the data from the cache
    if { [info exists dbcache(LOADED)] && $dbcache(LOADED) } {
	if { $dbcache(PROJECT) == $project } {
	    set status 1
	    set result {}
	    if { [llength $args] == 1 } {
		# Single item requested
		set item "[lindex $args 0],$job_id"
		if { [info exists dbcache($item)] } {
		    set result $dbcache($item)
		} else {
		    # Error indicator
		    set status 0
		}
	    } else {
		# Multiple items - build a list
		foreach arg $args {
		    set item "[subst $arg],$job_id"
		    if { [info exists dbcache($item)] } {
			lappend result $dbcache($item)
		    } else {
			# Error indicator
			set status 0
		    }
		}
	    }
	}
    }
    if { $status } {
	# Successfully retrieved data
	return $result
    } else {
	Report 1 "dbccp4i_get_data: unable to acquire data from cache:"
	Report 1 "Project $project Jobid $job_id Items $args"
	Report 1 "Requesting data from handler"
	return [eval ::dbClientAPI::GetData $project $job_id $args]
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_job_has_subjobs { project job_id } {
#-------------------------------------------------------------------------
#d_sum Check if a job has associated subjobs
#d_desc Returns 1 if the specified job has a subjob database associated \
with it, and zero otherwise.
#d_arg project Name of the project
#d_arg job_id Job number

   return [::dbClientAPI::HasSubJobs $project $job_id]
}

#-------------------------------------------------------------------------
proc dbccp4i_select_jobs { project item pattern } {
#-------------------------------------------------------------------------
#d_sum Return a list of jobs where data items match a regular expression.
#d_desc Given a regular expression pattern and the name of a data item \
this command returns a list of jobs where the value of the data item \
matches that pattern.
#d_desc Note that this command expects Python regular expression syntax \
which may differ in details from Tcl for more complex expressions.
#d_arg project Name of the project
#d_arg job_id Job number
#d_arg pattern A regular expression pattern

    return [::dbClientAPI::SelectJobs $project $item $pattern]
}

#-------------------------------------------------------------------------
proc dbccp4i_job_description { project job_list db_display db_display_format } {
#-------------------------------------------------------------------------
#d_sum Return a formatted description of a list of jobs.
#d_desc Given a list of jobs, a set of data items and a format descriptor \
this command returns a list where each item corresponds to one of the \
jobs in the original list, and consists of a string with values of \
each of the data items specified in db_display formatted using field widths \
given in db_display_format.
#d_arg project Name of the project
#d_arg job_list List of one or more job ids to get the description for
#d_arg db_display List of database items
#d_arg db_display_format List of field widths corresponding to the items in \
db_display

    global dbcache
    if { [info exists dbcache(LOADED)] && $dbcache(LOADED) } {
	if { $dbcache(PROJECT) == $project } {
	    if { ![catch {
		# Deal with input from DbJobDescription
		set job_id [lindex $job_list 0]
		# FIXME Duplicates code from DbJobDescription, which
		# should be abstracted to a single shared procedure
		set dummy " "
		set TASKNAME ""
		set TITLE ""
		set line_format ""
		foreach item $db_display_format {
		    append line_format "%-" $item "s"
		}
		set cmd "set line \[ format \$line_format "
		foreach item $db_display {
		    if { $item == "JOB_ID" } {
			append cmd " $job_id"
		    } elseif { $item == "DATE" } {
			append cmd " \"[GetDate -format brief -clock $dbcache(DATE,$job_id)]\""
		    } elseif { $item == "TASKNAME" || $item == "TITLE" } {
			append [subst $item] $dbcache($item,[subst $job_id]) " "
			append cmd " \$[subst $item]"
		    } elseif { ![ElementExists dbcache "$item,$job_id" ] || 
			       $dbcache([subst $item ],$job_id) == "" } {
			append cmd " \$dummy"
		    } else {
			append cmd  " \$dbcache(" $item "," $job_id ")"
		    }
		}
		append cmd "\]"
		eval "$cmd"
	    } err] } {
		return $line
	    } else {
		Report 1 "ERROR acquiring description from cache:"
		Report 1 "$err"
	    }
	}
    }

    return [::dbClientAPI::GetDescription $project $job_list \
		$db_display $db_display_format]
}

#-------------------------------------------------------------------------
proc dbccp4i_delete_job { project job_id } {
#-------------------------------------------------------------------------
#d_sum Deletes the specified job record from the project.
#d_desc This removes a job from the project database. Note that any \
associated input or output files are NOT removed by this command - \
only the record of the job.
#d_arg project Name of the project
#d_arg job_id Job record to be deleted

    return [::dbClientAPI::DeleteJob $project $job_id]
}

#d_index_title Database cache for database handler
#d_intro_title Database cache for database handler
#d_intro The commands in this section are used to set up and maintain a \
cache of data for the current database, to speed up interactions with the \
job database (particularly for updating the job list).

#-------------------------------------------------------------------------
proc dbccp4i_populate_cache { project } {
#-------------------------------------------------------------------------
#d_sum Initialise the job data in the database cache
#d_desc This clears any current contents of the cache and repopulates \
it with data for the specified project from the handler.
#d_desc Once the cache is populated, individual job records should be \
kept up-to-date automatically in response to broadcasts received from \
the handler.
#d_arg project Name of the project to cache
    global dbcache

    # Clear the cache contents
    array unset dbcache *

    # Start over
    set dbcache(PROJECT) $project
    set dbcache(DBITEMS) {}
    set dbcache(LOADED) 0

    # Load the job data
    set joblist [::dbClientAPI::ListJobs $project]
    # Define the data items that will be cached
    # Other data items will be fetched directly from the handler
    # when requested
    set items [list DATE \
		   TASKNAME \
		   TITLE \
		   STATUS \
		   LOGFILE \
		   INPUT_FILES INPUT_FILES_DIR \
		   OUTPUT_FILES OUTPUT_FILES_DIR]
    set nitems [llength $items]

    # Grab in blocks
    # nblock determines the number of records to get in a block
    set nblock 500
    set last [expr $nblock - 1]
    while { [llength $joblist] > 0 } {
	# Get the subset of jobs up to the block size
	if { [llength $joblist] > $nblock } {
	    set jobs [lrange $joblist 0 [expr $nblock - 1]]
	    set joblist [lrange $joblist $nblock end]
	} else {
	    set jobs $joblist
	    set joblist {}
	}
	# Fetch the data
	set records [::dbClientAPI::GetListofRecords $project $jobs $items]
	if { [llength $jobs] != [llength $records] } {
	    puts "ERROR dbccp4i_populate_cache: requested [llength $jobs] records, got back [llength $records]"
	}
	set njobs [llength $jobs]
	for { set i 0 } { $i < $njobs } { incr i } {
	    set job [lindex $jobs $i]
	    set record [lindex $records $i]
	    for { set j 0 } { $j < $nitems } { incr j } {
		set element "[lindex $items $j],$job"
		set value [lindex $record $j]
		set dbcache($element) $value
	    }
	}
    }
    set dbcache(DBITEMS) $items
    set dbcache(LOADED) 1
}

#-------------------------------------------------------------------------
proc dbccp4i_update_cache { broadcast } {
#-------------------------------------------------------------------------
#d_sum Update the cache in response to a broadcast from the handler
#d_desc Given a broadcast message from the handler, this command \
determines which job has been updated and the operation that has been \
performed. It then calls the appropriate command to perform the update \
on the cache data.
#d_arg broadcast Broadcast message received from the database handler

    global dbcache

    set project [lindex $broadcast 1]
    set job [lindex $broadcast 2]
    set operation [lindex $broadcast 3]
    # Wrap with catch since this is normally invoked by a
    # callback
    ##puts "dbccp4i_update_cache $project $job $operation"
    if { [catch {
	switch $operation {
	    DbNewJob {
		# Job was added
		dbccp4i_cache_addjob $project $job
	    }
	    DbDeleteJob {
		# Job was removed
		dbccp4i_cache_deletejob $project $job
	    }
	    DbSetData {
		# Data for job changed
		dbccp4i_cache_updatejob $project $job
	    }
	    AddOutputFile {
		# Output file was added to job
		dbccp4i_cache_updatejob $project $job
	    }
	    AddInputFile {
		# Input file was added to job
		dbccp4i_cache_updatejob $project $job
	    }
	    DirectoriesReadonly|NewProject|DeleteProject|ImportProject {
		# Ignore
	    }
	    AddDataDirRef|DeleteDataDirRef {
		# Ignore
	    }
	    DbReadonly {
		# Ignore
	    }
	    AddSubJob {
		# Ignore
	    }
	    default {
		# No idea but should keep an eye on it
		# Report to log
		Report 1 "dbccp4i_update_cache: operation \"$operation\" ignored"
	    }
	}
    } err] } {
	puts "ERROR caught in dbccp4i_update_cache: \"$err\""
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_updatejob { project job } {
#-------------------------------------------------------------------------
#d_sum Update the data for a single job in the cache
#d_desc This command retrieves the latest data for the specified job \
from the handler and inserts it into the cache. The job doesn't need \
to exist before it is updated - it will exist afterwards (if it also \
exists in the persistent database).
#d_arg project The name of the project which has been changed
#d_arg job The id of the job to be updated

    global dbcache
    if { ! $dbcache(LOADED) || $dbcache(PROJECT) != $project } {
	return
    }
    set records [::dbClientAPI::GetListofRecords $dbcache(PROJECT) \
		 [list $job] $dbcache(DBITEMS)]
    set record [lindex $records 0]
    for { set j 0 } { $j < [llength $dbcache(DBITEMS)] } { incr j } {
	set element "[lindex $dbcache(DBITEMS) $j],$job"
	set value [lindex $record $j]
	set dbcache($element) $value
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_addjob { project job } {
#-------------------------------------------------------------------------
#d_sum Add a new job to the database cache
#d_desc This is a wrapper to dbccp4i_cache_updatejob. It is possible \
that in future additional data may need to be associated with new jobs, \
in which case it should be done here. 
#d_arg project The name of the project which has been changed
#d_arg job The id of the job to be added
    # Just a wrapper for update at the moment

    dbccp4i_cache_updatejob $project $job
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_deletejob { project job } {
#-------------------------------------------------------------------------
#d_sum Delete a job from the database cache
#d_desc Remove the data stored for the specified job, essentially \
removing the record from the cache.
#d_arg project The name of the project which has been changed
#d_arg job The id of the job to be deleted

    global dbcache
    if { ! $dbcache(LOADED) || $dbcache(PROJECT) != $project } {
	return
    }
    foreach item $dbcache(DBITEMS) {
	if { [info exists dbcache([subst $item],$job)] } {
	    unset dbcache([subst $item],$job)
	} else {
	    Report 1 "Cannot delete item $item for job $job from db cache
Data not cached for this job"
	}
    }
}
