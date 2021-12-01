#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - projectdirs.tcl
#
# Project directory handling utilities
#
# Liz Potterton Jan97
# Peter Briggs  Oct07
#
#====================================================================

#CCP4i_cvs_Id $Id$

source [FileJoin [GetEnvPath DBCCP4I_TOP] ClientAPI dbClientAPI.tcl]

#d_index_title Project Directory Utilities (src/projectdirs.tcl)
#d_intro_title Project Directory Utilities
#
#d_intro Within CCP4i the user's work is divided into 'project directories' \
with each directory being referenced by a 'project alias'. A project also \
has an associated job database.

#d_index_title Core Project Directory Functions
#d_intro_title Core Project Directory Functions
#
#d_intro These functions handle initialisation and saving of the overall \
project directory information. The data is stored in the global \
'directories' array.

#-------------------------------------------------------------------------
proc InitialiseDirectories { args } {
#-------------------------------------------------------------------------
#d_sum Initialise the directories data
#d_desc This is a wrapper for InitialisePreferences directories, with \
some additional functionality to initialise the user's projects if necessary.
#d_desc If the database handler is being used as the source of directories \
data then a connection is established with the handler, and status 1 is \
returned if there are no projects currently defined or 2 if there is at \
least one project already defined.
#d_desc If a connection to the handler is not requested, or if a connection \
cannot be made, then InitialisePreferences is called and the status from \
that call is returned.
#d_desc InitialiseDirectories accepts the same arguments as \
InitialisePreferences, although in the case of the database handler being \
used these are essentially ignored.
#d_opt0 -lock
#d_opt1 Check whether directories.def file is locked
#d_opt0 -host hostname
#d_opt1 Connect to a handler running on the specified host
#d_opt0 -port port_number
#d_opt1 Connect via a specific port number
    global system
    global directories

    if { [using_dbccp4i] } {
	# Attempt to use the database handler
	# Collect arguments
	set host {}
	set port {}
	if { [set k [lsearch $args "-host"]] > -1 } {
	    set host [lindex $args [incr k]]
	}
	if { $host != "" && [set k [lsearch $args "-port"]] > -1 } {
	    set port [lindex $args [incr k]]
	    # Connect to a remote database handler
	    set status [connect_to_dbccp4i -host $host -port $port]
	} else {
	    # Connect to a (local) database handler
	    set status [connect_to_dbccp4i]
	}
	if { ! $status } {
	    DbReport 1 "InitialiseDirectories: failed to connect to database handler"
	} else {
	    # Reset the status to conform to the expected
	    # values returned by InitialisePreferences
	    if { [llength [::dbClientAPI::ListProjects]] == 0 } {
		# Indicates success but no projects set
		set status 1
	    } else {
		# Indicates success and user has projects
		set status 2
	    }
	    # Explicitly initialise the directory menu
	    # This is done in InitialisePreferences otherwise
	    catch {update_defdir_menu directories}
	}
    }
    if { ![using_dbccp4i] } {
	# Direct access
	set status [eval InitialisePreferences directories directories $args]
	if { ! $status } {
	    DbReport 1 "InitialiseDirectories: error fetching directories data"
	    return $status
	}
    } else {
	# Initialise the cache of directories data
	dbccp4i_populate_dirs_cache
    }
    # Register callback on modification to update the menus
    # of directories
    DirectoriesRegisterCallback "update_defdir_menu directories"

    # Return the exit status of the InitialisePreferences call
    return $status
}

#d_index_title Accessing Project Directory Data
#d_intro_title Accessing Project Directory Data
#
#d_intro These functions handle interactions with the information about \
the project directories.

#-------------------------------------------------------------------------
proc ListProjects { } {
#-------------------------------------------------------------------------
#d_sum Return a list of project aliases
#d_desc This returns a list of all the available project names \
(aka aliases) that are currently defined. If there are no projects \
currently defined then an empty list is returned.
#d_desc Note that the projects are sorted into alphabetical \
(dictionary) order regardless of the order that they are retrieved \
from the database.

    # Using the database handler
    if { [using_dbccp4i] } {
	return [lsort -dictionary [dbccp4i_list_projects]]
    }
    # Direct access
    global directories
    set projects {}
    set n $directories(N_PROJECTS)
    for { set i 1 } { $i<=$n } { incr i } {
	lappend projects $directories(PROJECT_ALIAS,$i)
    }
    return [lsort -dictionary $projects]
}

#-------------------------------------------------------------------------
proc AddProject { alias dir } {
#-------------------------------------------------------------------------
#d_sum Add a new project to list of projects
#d_desc This adds a new project to the user's list, if necessary also \
creating a new directory and a database subdirectory.
#d_desc It returns 1 on success, 0 on failure.
#d_arg alias The one-word alias for the project
#d_arg dir The full path for the project directory

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_add_project $alias $dir]
  }
  global directories
  if { [get_indx_project $alias] != "" } {
      # Project name already defined
      DbReport 1 "AddProject: project name already defined: $alias"
      return 0
  }
  # Do checks on the target directory
  if { $dir == "" } {
      # Directory not defined
      Report 1 "AddProject: directory is blank"
      return 0
  }
  if { [file exists $dir] } {
      # Something already exists
      if { ![file isdirectory $dir] } {
	  # "Directory" is not a directory
	  Report 1 "AddProject: directory not a directory: $dir"
	  return 0
      }
      if { ![FileWritable $dir] } {
	  # Directory is not writeable
	  Report 1 "AddProject: directory is not writeable: $dir"
	  return 0
      }
  } else {
      # Directory doesn't exist
      # We'll try to make it now
      if { ![CreateDir $dir] } {
	  Report 1 "AddProject: failed to make directory: $dir"
	  return 0
      }
      DbReport 1 "AddProject: made directory: $dir"
  }
  # Test for the existence of a database
  set dbdir [FileJoin $dir CCP4_DATABASE]
  if { ![file exists $dbdir] } {
      # Create the database directory now
      if { ![CreateDir $dbdir] } {
	  Report 1 "AddProject: failed to make db dir: $dbdir"
	  return 0
      }
      DbReport 1 "AddProject: made db dir: $dbdir"
  }
  set dbfile [FileJoin $dbdir database.def]
  if { ![file exists $dbfile] } {
      # Create the database file now
      if { ![CreateNewProjectDb $dbfile database "CCP4_Project_Database"] } {
	  Report 1 "AddProject: failed to make db file: $dbfile"
	  return 0
      }
      DbReport 1 "AddProject: made db file: $dbfile"
  }
  # Add the new definition
  set n [incr directories(N_PROJECTS)]
  set directories(PROJECT_ALIAS,$n) $alias
  set directories(PROJECT_PATH,$n) $dir
  set directories(PROJECT_DB,$n) $dbdir

  # Register that the data has changed
  DirectoriesModified
  return 1
}

#-------------------------------------------------------------------------
proc DeleteProject { alias } {
#-------------------------------------------------------------------------
#d_sum Remove an existing project from list of projects
#d_desc Only the reference to the project is deleted - the project \
directory and contents are left intact.
#d_arg alias The one-word alias for the project

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_delete_project $alias]
  }
  # Direct access
  global directories
  set c1 [get_indx_project $alias]
  if { $c1 != "" } {
      # Move other project definitions down by one
      set n $directories(N_PROJECTS)
      if { $c1 != $n } {
	  for { set i $c1 } { $i < $n } { incr i } {
	      set j [expr $i+1]
	      set directories(PROJECT_ALIAS,$i) $directories(PROJECT_ALIAS,$j)
	      set directories(PROJECT_PATH,$i) $directories(PROJECT_PATH,$j)
	      set directories(PROJECT_DB,$i) $directories(PROJECT_DB,$j)
	  }
      }
      # Delete the last entry
      unset directories(PROJECT_ALIAS,$n)
      unset directories(PROJECT_PATH,$n)
      unset directories(PROJECT_DB,$n)
      incr directories(N_PROJECTS) -1

      # Register that the data has changed
      DirectoriesModified
      # Return success
      return 1
  }
  # Failed to locate the project being removed
  return 0
}

#-------------------------------------------------------------------------
proc GetProjectPath { project } {
#-------------------------------------------------------------------------
#d_sum Return the project directory corresponding to a project alias
#d_desc Returns the directory path associated with the project name \
or an empty string if the project is not defined.
#d_arg project Alias/name of the project

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_get_project_path $project]
  }
  # Direct access
    global directories
    set c1 [get_indx_project $project]
    if { $c1 != "" } {
	# Return the directory
	return $directories(PROJECT_PATH,$c1)
    }
    return ""
}

#-------------------------------------------------------------------------
proc GetProjectDBPath { project } {
#-------------------------------------------------------------------------
#d_sum Return the database directory corresponding to a project alias
#d_desc Returns the directory path for the database associated with the \
project name, or an empty string if the project is not defined.
#d_arg project Alias/name of the project

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_get_project_db_path $project]
  }
  # Direct access
    global directories
    set c1 [get_indx_project $project]
    if { $c1 != "" } {
	# Return the directory
	return $directories(PROJECT_DB,$c1)
    }
    return ""
}

#-------------------------------------------------------------------------
proc SetProjectPath { project dir } {
#-------------------------------------------------------------------------
#d_sum (Re)set the directory for the specified project.
#d_desc The project alias must already be defined.
#d_desc This command should be used with caution as it could have \
side effects for reviewing and rerunning jobs in this and other \
projects.
#d_arg project Alias/name of the project being updated
#d_arg dir The full path for the new directory

  # Using the database handler
  if { [using_dbccp4i] } {
      # We have to fake this by deleting the current project
      # reference and then adding it back with the new path
      if { ![DeleteProject $project] } {
	  return 0
      }
      if { ![AddProject $project $dir] } {
	  return 0
      }
      return 1
  }
  # Direct access
    global directories
    set c1 [get_indx_project $project]
    if { $c1 != "" } {
	# Set the directory
	set directories(PROJECT_PATH,$c1) $dir
	set directories(PROJECT_DB,$c1) [FileJoin $dir CCP4_DATABASE]

	# Register that the data has changed
	DirectoriesModified
	return 1
    }
    puts "SetProjectPath: project $project not found"
    return 0
}

#-------------------------------------------------------------------------
proc get_indx_project { project } {
#-------------------------------------------------------------------------
#d_sum Internal: get an index value for a project name
#d_desc This is an internal function that does a lookup of the array \
index value for a project name in the directories array.
#d_desc If the project name isn't defined then an empty string is \
returned.
#d_arg project Alias/name of the project being indexed
    global directories
    for { set i 1 } { $i <= $directories(N_PROJECTS) } { incr i } {
	if { [StringSame $directories(PROJECT_ALIAS,$i) $project] } {
	    return $i
	}
    }
    # Nothing found
    return ""
}

#d_index_title Accessing DefDir Data
#d_intro_title Accessing DefDir Data
#
#d_intro These functions handle interactions with the information about \
the 'default directories' (defdirs).
#d_intro 'Default directories' are directories with associated aliases \
which are not project directories - that is, that have no associated \
job database.

#-------------------------------------------------------------------------
proc ListDefdirs { } {
#-------------------------------------------------------------------------
#d_sum Return a list of defdir aliases
#d_desc This returns a list of all the available defdir names \
(aka aliases) that are currently defined. If there are no defdirs \
currently defined then an empty list is returned.
#d_desc The returned list will have TEMPORARY as the first def dir, \
if it exists.
#d_desc A 'defdir' is a data directory i.e. a directory that has a \
shortcut name/alias but doesn't have an associated project database.
#d_desc Note that the def dirs are sorted such that TEMPORARY will \
always be listed first (if it exists) and subsequent aliases will be \
in alphabetical (i.e. dictionary) order.

  # Using the database handler
  if { [using_dbccp4i] } {
      set def_dirs [dbccp4i_list_defdirs]
  } else {
  # Direct access
    global directories
    set def_dirs {}
    set n $directories(N_DEF_DIRS)
    for { set i 1 } { $i<=$n } { incr i } {
	lappend def_dirs $directories(DEF_DIR_ALIAS,$i)
    }
  }
  # Sort into dictionary order
  set def_dirs [lsort -dictionary $def_dirs]
  # Make TEMPORARY the first alias, if it exists
  if { [set k [lsearch $def_dirs TEMPORARY]] > -1 } {
    set def_dirs [linsert [lreplace $def_dirs $k $k] 0 TEMPORARY]
  }
  return $def_dirs
}

#-------------------------------------------------------------------------
proc AddDefdir { alias dir } {
#-------------------------------------------------------------------------
#d_sum Add a new defdir to list of default directories
#d_desc This adds a new defdir to the user's list. The directory doesn't \
have to exist when it is added.
#d_desc It returns 1 on success, 0 on failure.
#d_arg alias The one-word alias for the defdir
#d_arg dir The full path for the directory

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_add_defdir $alias $dir]
  }
  # Direct access
  global directories
  if { [get_indx_defdir $alias] != "" } {
      # Defdir name already defined
      puts "AddDefdir: def dir name already defined: $alias"
      return 0
  }
  set n [incr directories(N_DEF_DIRS)]
  set directories(DEF_DIR_ALIAS,$n) $alias
  set directories(DEF_DIR_PATH,$n) $dir

  # Register that the data has changed
  DirectoriesModified
  return 1
}

#-------------------------------------------------------------------------
proc DeleteDefdir { alias } {
#-------------------------------------------------------------------------
#d_sum Remove an existing def dir from list of def dirs
#d_desc Only the reference to the def dir is deleted - the \
directory and contents are left intact.
#d_arg alias The one-word alias for the def dir

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_delete_defdir $alias]
  }
  # Direct access
  global directories
  set c1 [get_indx_defdir $alias]
  if { $c1 != "" } {
      # Move other def dir definitions down by one
      set n $directories(N_DEF_DIRS)
      if { $c1 != $n } {
	  for { set i $c1 } { $i < $n } { incr i } {
	      set j [expr $i+1]
	      set directories(DEF_DIR_ALIAS,$i) $directories(DEF_DIR_ALIAS,$j)
	      set directories(DEF_DIR_PATH,$i) $directories(DEF_DIR_PATH,$j)
	  }
      }
      # Delete the last entry
      unset directories(DEF_DIR_ALIAS,$n)
      unset directories(DEF_DIR_PATH,$n)
      incr directories(N_DEF_DIRS) -1

      # Register that the data has changed
      DirectoriesModified
      # Return success
      return 1
  }
  # Failed to locate the def dir being removed
  return 0
}

#-------------------------------------------------------------------------
proc GetDefdirPath { defdir } {
#-------------------------------------------------------------------------
#d_sum Return the directory corresponding to a defdir alias
#d_desc Returns the directory path associated with the defdir name \
or an empty string if the defdir is not defined.
#d_arg defdir Alias/name of the defdir

    if { [using_dbccp4i] } {
	# Use the dbccp4i client API
	return [dbccp4i_get_defdir_path $defdir]
    }
    # Direct access
    global directories
    set c1 [get_indx_defdir $defdir]
    if { $c1 != "" } {
	# Return the directory
	return $directories(DEF_DIR_PATH,$c1)
    }
    return ""
}

#-------------------------------------------------------------------------
proc SetDefdirPath { defdir dir } {
#-------------------------------------------------------------------------
#d_sum (Re)set the directory for the specified defdir.
#d_desc The defdir alias must already be defined.
#d_desc This command is currently deprecated as it could have \
unpredictable results.
#d_arg defdir Alias/name of the defdir being updated
#d_arg dir The full path for the new directory

    # Using the database handler
    if { [using_dbccp4i] } {
	# We need to delete the defdir and then remake it
	DeleteDefdir $defdir
	AddDefdir $defdir $dir
	return
    }
    # Direct access
    global directories
    set c1 [get_indx_defdir $defdir]
    if { $c1 != "" } {
	# Set the directory
	set directories(DEF_DIR_PATH,$c1) $dir
	# Register that the data has changed
	DirectoriesModified
	return
    }
    Report 1 "SetDefdirPath: defdir $defdir not found"
}

#-------------------------------------------------------------------------
proc get_indx_defdir { defdir } {
#-------------------------------------------------------------------------
#d_sum Internal: get an index value for a defdir name
#d_desc This is an internal function that does a lookup of the array \
index value for a defdir name in the directories array.
#d_desc If the defdir name isn't defined then an empty string is \
returned.
#d_arg defdir Alias/name of the defdir being indexed
    # For internal use only
    global directories
    for { set i 1 } { $i <= $directories(N_DEF_DIRS) } { incr i } {
	if { [StringSame $directories(DEF_DIR_ALIAS,$i) $defdir] } {
	    return $i
	}
    }
    # Nothing found
    return ""
}

#d_index_title Project and DefDir Utility Functions
#d_intro_title Project and DefDir Utility Functions
#
#d_intro These functions provide simple interrogations of the project and \
default directory data.

#-------------------------------------------------------------------------
proc ProjectIsDefined { project } {
#-------------------------------------------------------------------------
#d_sum Check if a project is defined
#d_sum Return 1 if the project name is already defined, 0 if not.
#d_arg project Alias/name of the project

    # Using the database handler
    if { [using_dbccp4i] } {
        return [dbccp4i_project_is_defined $project]
    }
    # Direct access
    global directories
    if { [get_indx_project $project] == "" } {
	# No index returned, project not recognised
	return 0
    }
    return 1
}

#-----------------------------------------------------------------------
proc DirIsProject { dir } {
#-----------------------------------------------------------------------
#d_sum Check whether a directory is a project directory
#d_desc Returns 1 if dir is a project or default directory, 0 if not.
#d_arg dir Full path of the directory to check

  # Using the database handler
  if { [using_dbccp4i] } {
      return [dbccp4i_dir_is_project $dir]
  }
  # Direct access
  global directories

  # Check against Project Dirs
  set n $directories(N_PROJECTS)
  for { set i 1 } { $i <= $n } { incr i } {
    if { $dir == $directories(PROJECT_PATH,$i) } { return 1 }
  }
  # Check against Default Dirs
  set n $directories(N_DEF_DIRS)
  for { set i 1 } { $i <= $n } { incr i } {
    if { $dir == $directories(DEF_DIR_PATH,$i) } { return 1 }
  }
  # No matches
  return 0
}

#d_index_title Functions for handing default dir menus
#d_intro_title Functions for handing default dir menus
#
#d_intro These functions deal with the internal details of setting and \
getting the DEFDIR_MENU parameter.

#-------------------------------------------------------------------------
proc SetDefdirMenu { menu } {
#-------------------------------------------------------------------------
#d_sum Set the value of the DEFDIR_MENU internal parameter
#d_arg menu A list containing the items in the menu

    # FIXME not sure whether this is correct or not
    global directories
    set directories(DEFDIR_MENU) $menu
    return $directories(DEFDIR_MENU)
}

#-------------------------------------------------------------------------
proc GetDefdirMenu { } {
#-------------------------------------------------------------------------
#d_sum Return the value of the DEFDIR_MENU internal parameter
    global directories
    if { [ElementExists directories DEFDIR_MENU] } {
	return $directories(DEFDIR_MENU)
    }
    return {}
    
}

#d_index_title Functions for handling database specifics
#d_intro_title Functions for handling database specifics
#
#d_intro These functions handle the specifics of the job database \
implementation.

#---------------------------------------------------------------------
proc CreateNewProjectDb { dbfile utility_name identifier } {
#---------------------------------------------------------------------
#d_sum Create new database file
#d_desc This is a copy of the DbCreateNewFile command in database.tcl, \
and creates a new database.def file.
#d_arg dbfile Name of database file
#d_arg utility_name type of database - expect it to be 'database'
#d_arg identifier Identifier to write to file header - usually \
'CCP4_Project_Database' - this is equivalent to the taskname in \
the usual task def files. A more descriptive identifier is used \
here in attempt to explain the file to anyone who reads the file itself.

   set status [OpenFile $dbfile f w]
   if { $status <= 0 } { 
     Report 2  "ERROR can not open new file $dbfile"
     return $status 
   }
   
   WriteIdentifier $f "DEF $identifier"

   if { [OpenFile [SearchPath TOP etc $utility_name.def] f1 r] > 0 } {

      while { [gets $f1 linetmp ] >= 0 } {
         if { [string range $linetmp 0 5] != "#CCP4I" } { puts $f $linetmp }
      }
      CloseFile $f1
      CloseFile $f
      Report 2  "Creating new $utility_name file $dbfile "
      return 1

   } else {

      Report 2 "ERROR creating new $utility_name file - template file not found \
[SearchPath TOP etc $utility_name.def] "
      CloseFile $f
      return 0

  }
}

#-------------------------------------------------------------------------
proc DirectoriesRegisterCallback { callbackProc } {
#-------------------------------------------------------------------------
#d_sum Specify a procedure that will be invoked on save
#d_desc This allows a callback procedure to be specified, so that whenever \
the directories data is saved to persistent storage the callback will be \
invoked immediately afterwards.
#d_desc See also the SaveDirectories procedure.
#d_arg callbackProc Name of the command to be invoked.
    global dirs_admin
    if { ![info exists dirs_admin(_DIRS_CALLBACK_PROCS)] } {
	# First time that this function has been called
	# Initialise the list of callback functions
	set dirs_admin(_DIRS_CALLBACK_PROCS) {}
    }
    # Add the callback procedure if it isn't already
    # in the list
    if { [lsearch $dirs_admin(_DIRS_CALLBACK_PROCS) $callbackProc] < 0 } {
	lappend dirs_admin(_DIRS_CALLBACK_PROCS) $callbackProc
    }
}

#d_index_title Commands for Handling Automatic Directories Saves
#d_intro_title Commands for Handling Automatic Directories Saves
#
#d_intro These commands are used internally by the directories functions \
to manage scheduling automatic saves of the directories data to persistent \
storage as required.
#d_intro DirectoriesModified is called by 'write' operations (e.g. adding \
or deleting projects). This schedules calls to SaveDirectories, which \
manages the actual saving operation.

#-------------------------------------------------------------------------
proc DirectoriesModified { { broadcast {} } } {
#-------------------------------------------------------------------------
#d_sum Register that the directories data has been modified.
#d_desc This command is called by the directories 'write' operations. It \
sets a flag to indicate that the directories data needs saving to file, and \
schedules a call to SaveDirectories to perform the operation (if one is not \
currently scheduled).
#d_desc This is an internal command and should not normally be called \
directly.
#d_arg broadcast (Optional) The "broadcast" data received from the \
database handler
    # Called when the directories data is modified by a "write"
    # operation
    # Called when the database is modified by a "write"
    # operation
    if { [using_dbccp4i] && [llength $broadcast] == 5 } {
	dbccp4i_update_dirs_cache $broadcast
    }
    global dirs_admin
    if { [info exists dirs_admin(_DIRS_NEEDS_SAVE)] } {
	if { ! $dirs_admin(_DIRS_NEEDS_SAVE) } {
	    # Schedule a save
	    after idle "SaveDirectories -lock"
	    # Set the save flag to indicate that 
	    # a save is scheduled
	    set dirs_admin(_DIRS_NEEDS_SAVE) 1
	}
    } else {
	# First time this function was called
	# Schedule a save
	after idle "SaveDirectories -lock"
	# Initialise the save flag
	set dirs_admin(_DIRS_NEEDS_SAVE) 1
    }
}

#-------------------------------------------------------------------------
proc SaveDirectories { args } {
#-------------------------------------------------------------------------
#d_sum Save the directories data
#d_desc This is a wrapper for SavePreferences directories and takes \
the same arguments.
    global directories
    global dirs_admin

    set status 1

    if { [info exists dirs_admin(_DIRS_NEEDS_SAVE)] } {
	if { $dirs_admin(_DIRS_NEEDS_SAVE) } {
	    # Reset the save flag
	    set dirs_admin(_DIRS_NEEDS_SAVE) 0
	    if { ![using_dbccp4i] } {
		# Save the data to persistent storage
		set status [eval SavePreferences directories directories $args]
	    }
	}
    } else {
	# First time this function was called
	# Initialise the save flag
	set dirs_admin(_DIRS_NEEDS_SAVE) 0
    }
    # If there are any callbacks specified then invoke them
    if { [info exists dirs_admin(_DIRS_CALLBACK_PROCS)] } {
	foreach callback $dirs_admin(_DIRS_CALLBACK_PROCS) {
	    # Use catch to trap any failures
	    if { [catch { eval $callback } err] } {
		DbReport 2 "SaveDirectories: callback error (ignored)"
		DbReport 2 "Callback: \"$callback\" Error: \"$err\""
	    }
	}
    }
    return $status
}

#d_index_title Internal functions for dealing with the state of CCP4i
#d_intro_title Internal functions for dealing with the state of CCP4i
#
#d_intro These are internal functions used to keep information on the \
current project that CCP4i is operating with.

#-------------------------------------------------------------------------
proc SetProjectDatabase { project_database } {
#-------------------------------------------------------------------------
#d_sum Set the value of the PROJECT_DATABASE internal parameter
#d_arg project_database New value for PROJECT_DATABASE
    global user_directories
    set user_directories(PROJECT_DATABASE) $project_database
}

#-------------------------------------------------------------------------
proc GetProjectDatabase { } {
#-------------------------------------------------------------------------
#d_sum Fetch the value of the PROJECT_DATABASE internal parameter
    global user_directories
    if { [ElementExists user_directories PROJECT_DATABASE] } {
	return $user_directories(PROJECT_DATABASE)
    }
    return {}
}

#d_index_title Commands for switching the database access mode
#d_intro_title Commands for switching the database access mode
#
#d_intro These commands can be used to change the method that the \
interface is using to access the database. The choice of commands \
is dependent only on the target mode, and not on the current \
access mode.

#-------------------------------------------------------------------------
proc switch_to_direct_db { } {
#-------------------------------------------------------------------------
#d_sum Switch to CCP4i accessing the database directly
#d_desc Direct access is when CCP4i reads and writes the project database \
files directly.

    global user_directories
    DbReport 3 "Switching to direct database access"
    if { [using_dbccp4i] } {
	# Dispose of current connection
	if { [dbccp4i_verify_connection] } {
	    DbReport 3 "Disposing of existing connection first"
	    ::dbClientAPI::DbHandlerDisconnect
	    DbReport 3 "Done"
	}
    }
    # Reset the connection mode
    set user_directories(USE_DBCCP4I) 0
    set user_directories(DBCCP4I_CONNECTION) 0
    # Reinitialise directories again
    return [InitialiseDirectories]
}

#-------------------------------------------------------------------------
proc switch_to_remote_db { host port } {
#-------------------------------------------------------------------------
#d_sum Switch to using a database handler on a remote machine
#d_desc Resets the database connection mode to connect to a handler \
running on a remote machine. The handler must already be running on the \
remote machine.
#d_arg host The hostname of the remote machine with the handler instance 
#d_arg port The port number used by the remote handler

    global user_directories
    DbReport 3 "Switching to remote host: $host $port"
    if { [using_dbccp4i] } {
	# Dispose of current connection
	if { [dbccp4i_verify_connection] } {
	    DbReport 3 "Disposing of existing connection first"
	    ::dbClientAPI::DbHandlerDisconnect
	    DbReport 3 "Done"
	}
    }
    # Reset the connection mode
    set user_directories(DBCCP4I_CONNECTION) 0
    set user_directories(USE_DBCCP4I) 1

    # Reinitialise directories again
    return [InitialiseDirectories -host $host -port $port]
}

#-------------------------------------------------------------------------
proc switch_to_local_db { } {
#-------------------------------------------------------------------------
#d_sum Switch to using a database handler on the local machine
#d_desc This is the default mode for CCP4i when using the database \
handler to access the database.

    global user_directories
    DbReport 3 "Switching to local handler connection"
    if { [using_dbccp4i] } {
	# Dispose of current connection
	if { [dbccp4i_verify_connection] } {
	    DbReport 3 "Disposing of existing connection first"
	    ::dbClientAPI::DbHandlerDisconnect
	    DbReport 3 "Done"
	}
    }
    # Reset the connection mode
    set user_directories(DBCCP4I_CONNECTION) 0
    set user_directories(USE_DBCCP4I) 1

    # Reinitialise directories again
    return [InitialiseDirectories]
}

#-------------------------------------------------------------------------
proc InitialiseDatabaseOptions { } {
#-------------------------------------------------------------------------
#d_sum Reset database configuration options after startup.
#d_desc This command should be called after startup in graphical mode. It \
checks whether the current configuration for database access is consistent \
with the expected configuration when the database handler is being used.
#d_desc In the event that the interface is configured to use the handler \
but the actual operating mode has automatically switched to direct access \
it offers the user the option of updating the configuration to use this \
mode on startup in future.
    global user_directories
    global configure
    if { [ElementExists user_directories USE_DBCCP4I] && \
	     [ElementExists configure USE_DBCCP4I_ON_STARTUP] } {
	if { $user_directories(USE_DBCCP4I) != $configure(USE_DBCCP4I_ON_STARTUP) } {
	    if { $configure(USE_DBCCP4I_ON_STARTUP) } {
		set action [ChooseOptionDialog "Database Server Startup Error" \
				"Database Error" \
				"CCP4i is currently configured to use the database server \"dbccp4i\" to access
the job database, but has failed to either start or connect to the server this
time.

You can continue to use CCP4i and the interface should still operate normally,
although some advanced functions may not be available.

Next time you start CCP4i it will try again to use the database server. If you
wish to disable this behaviour then select the option to automatically disable
use of the server in future sessions." \
				[list "Don't use server in future" \
				     "Keep current setting"] ]
		if { [regexp "^Don't" $action] } {
		    # Switch off the handler for future start-ups
		    set configure(USE_DBCCP4I_ON_STARTUP) 0
		    SavePreferences configure configure
		    WarningMessage "Use of the database server has been disabled.
Some advanced functions may not be available.

Use the \"Database Configuration\" option under
CCP4i's \"System Administration\" menu to
re-enable the server in future."
		}
	    }
	}
    }
}

#d_index_title Internal functions for interacting with the database handler
#d_intro_title Internal functions for interacting with the database handler
#
#d_intro These are internal functions used to keep information on the \
current project that CCP4i is operating with.

#-------------------------------------------------------------------------
proc using_dbccp4i { } {
#-------------------------------------------------------------------------
#d_sum Determine if we're using the db handler as the database backend
#d_desc Returns 1 if the database handler is being used as the database \
source and 0 if CCP4i is accessing the database files directly (i.e. via \
the directories and database global arrays).
#d_desc Initially the preferred access mode is set according to the \
setting in configure.def.

    global user_directories
    global configure

    if { ![ElementExists user_directories USE_DBCCP4I] } {
	if { [ElementExists configure USE_DBCCP4I_ON_STARTUP] } {
	    set user_directories(USE_DBCCP4I) $configure(USE_DBCCP4I_ON_STARTUP)
	} else {
	    set user_directories(USE_DBCCP4I) 1
	}
    }
    return $user_directories(USE_DBCCP4I)
}

#-------------------------------------------------------------------------
proc connect_to_dbccp4i { args } {
#-------------------------------------------------------------------------
#d_sum Initialise the connection to the database handler
#d_desc Establishes a connection to the database handler using the \
client API commands. If the connection is successfully made then the \
internal parameter USE_DBCCP4I is set to one, otherwise it is set to \
zero (meaning that no connection is available). The return value of \
this command is the final setting of the USE_DBCCP4I parameter.
#d_desc By default the connection is made to a local handler instance \
i.e. one on the current machine. If the -host and -port arguments are \
specified then the connection will instead be made to a remote \
handler instance. Note that the -host and -port arguments must be \
used together.
#d_desc In either case if a connection has already been established \
then no action will be taken.
#d_opt0 -host host_name
#d_opt1 Connect to a handler running on hostname, rather than locally
#d_opt0 -port port_number
#d_opt1 Connect to port_number
    global user_directories
    global system

    # Maximum number of attempts to make to connect to the handler
    set maxtries 1

    # Set the debugging output level
    DbXMLSetDebug 0

    # Check whether we have a connection
    if { [ElementExists user_directories DBCCP4I_CONNECTION] } {
	set connection $user_directories(DBCCP4I_CONNECTION)
    } else {
	set connection [dbccp4i_verify_connection]
    }

    # Check command line arguments
    set hostname {}
    set port {}
    set i 0
    while { $i < [llength $args] } {
	set arg [lindex $args $i]
	switch -exact -- $arg {
	    "-host" {
		incr i
		set hostname [lindex $args $i]
	    }
	    "-port" {
		incr i
		set port [lindex $args $i]
	    }
	    default {
		# Unrecognised argument
		Report 1 "connect_to_dbccp4i: unrecognised argument $arg"
		return 0
	    }
	}
	incr i
    }

    set user_directories(USE_DBCCP4I) 1
    if { ! $connection } {
	set connectCmd [list "::dbClientAPI::DbHandlerConnect" \
			    "$system(VERSION)" \
			    "-broadcastHandler" \
			    "handle_dbccp4i_broadcast"]
	if { $hostname != "" && $port != "" } {
	    lappend connectCmd "-host" "$hostname" "-port" "$port"
	}
	set ntries 0
	set got_connection 0
	while { $ntries < $maxtries && ! $got_connection } {
	    if { ! [eval $connectCmd] } {
		# Failure to connect to the handler
		incr ntries
	    } else {
		set got_connection 1
	    }
	}
	if { ! $got_connection } {
	    Report 2 "CCP4i failed to connect to database server after $ntries attempt(s)" -notime
	    Report 2 "Accessing the project database directly for this session" -notime
	    set user_directories(USE_DBCCP4I) 0
	    set user_directories(DBCCP4I_CONNECTION) 0
	} else {
	    set user_directories(DBCCP4I_CONNECTION) 1
	}
    }

    # Reset the timeout to 30s
    ::dbClientAPI::DbSetTimeout 30000

    # Return the final setting
    return $user_directories(USE_DBCCP4I)
}

#-------------------------------------------------------------------------
proc handle_dbccp4i_broadcast { broadcast } {
#-------------------------------------------------------------------------
#d_sum Receive a broadcast from the handler and determine how to react
#d_desc This is invoked by the dbccp4i client API when the database \
changes. It shouldn't be invoked directly from within CCP4i.

    # For now ignore what the broadcast is and just
    # schedule updates for everything
    DbReport 3 "Received dbccp4i broadcast:"
    DbReport 3 "$broadcast"
    DirectoriesModified $broadcast
    DbModified $broadcast
    # FIXME the content of the broadcast message should be checked
    # and updates scheduled only if relevant
}

#-------------------------------------------------------------------------
proc dbccp4i_verify_connection { } {
#-------------------------------------------------------------------------
#d_sum Check there is a working connection to the database handler
#d_desc Returns 1 if the connection to the database handler is still \
active, and zero otherwise.

    return [eval ::dbClientAPI::DbVerifyConnection]
}

#-------------------------------------------------------------------------
proc dbccp4i_list_projects { } {
#-------------------------------------------------------------------------
#d_sum Return a list of projects from the database handler
#d_desc Returns a list of the project names that can be accessed using \
the database handler connection. Note that it is possible not to have \
any projects defined, in which case an empty list will be returned.

    global dirscache
    # Try getting the data from the cache
    if { [dbccp4i_dirs_is_cached] } {
	return $dirscache(PROJECTS_LIST)
    }
    # Otherwise get from the handler
    return [::dbClientAPI::ListProjects]
}

#-------------------------------------------------------------------------
proc dbccp4i_add_project { alias dir } {
#-------------------------------------------------------------------------
#d_sum Add a project to the list of projects in the handler.
#d_desc This command will first ask the database handler to create a \
new project with the supplied name and directory. If this fails it then \
attempts to import the project instead. If either of these steps \
succeeds then 1 is returned, otherwise zero is returned.
#d_arg alias Name of the project
#d_arg dir Full path of the project directory

    if { ![::dbClientAPI::CreateProject $alias $dir msg] } {
	# Failed to create the project
	# Try an import
	if { ![::dbClientAPI::ImportProject $alias $dir] } {
	    # Failed to import
	    return 0
	}
    } else {
	# Since the default behaviour of the handler is to open
	# the project upon creation, we must close it again
	dbccp4i_close_project $alias
    }
    # Assume that it worked
    return 1
}

#-------------------------------------------------------------------------
proc dbccp4i_delete_project { alias } {
#-------------------------------------------------------------------------
#d_sum Remove a project from the list of projects in the handler.
#d_desc This command attempts to remove the reference to a specified \
project from the list of all the projects that the handler currently \
knows about. It returns 1 on successful removal and zero on failure.
#d_desc Note that deleting the project reference doesn't remove the \
project directory or any of the files from the system. Deleted projects \
can therefore be added back later using the dbccp4i_add_project command.
#d_arg alias Name of the project

    return [::dbClientAPI::DeleteProject $alias]
}

#-------------------------------------------------------------------------
proc dbccp4i_get_project_path { project } {
#-------------------------------------------------------------------------
#d_sum Return the directory path for a project.
#d_desc Returns an empty string if the specified project isn't found.
#d_arg project Name of the project

    global dirscache

    # Error indicator
    set status 0

    # Try getting the data from the cache
    if { [dbccp4i_dirs_is_cached] } {
	for { set i 1 } { $i <= $dirscache(N_PROJECTS) } { incr i } {
	    if { $dirscache(PROJECT_ALIAS,$i) == $project } {
		set status 1
		set result $dirscache(PROJECT_PATH,$i)
	    }
	}
    }
    if { $status } {
	# Successfully retrieved data
	return $result
    } else {
	return [::dbClientAPI::GetProjectDir $project]
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_get_project_db_path { project } {
#-------------------------------------------------------------------------
#d_sum Return the directory path for a project database directory.
#d_desc Returns the path to the database directory associated with a \
project (typically /path/to/project/CCP4_DATABASE/), or an empty string \
if the project isn't found.
#d_arg project Name of the project

    global dirscache

    # Error indicator
    set status 0

    # Try getting the data from the cache
    if { [dbccp4i_dirs_is_cached] } {
	for { set i 1 } { $i <= $dirscache(N_PROJECTS) } { incr i } {
	    if { $dirscache(PROJECT_ALIAS,$i) == $project } {
		set status 1
		set result $dirscache(PROJECT_DB,$i)
	    }
	}
    }
    if { $status } {
	# Successfully retrieved data
	return $result
    } else {
	return [::dbClientAPI::GetProjectDBDir $project]
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_list_defdirs { } {
#-------------------------------------------------------------------------
#d_sum Return a list of "default" (data) directories from the db handler
#d_desc Returns a list of the data directory names that can be accessed \
using the database handler connection. Note that it is possible not to \
have any data directories defined, in which case an empty list will be \
returned.
    global dirscache
    # Try getting the data from the cache
    if { [dbccp4i_dirs_is_cached] } {
	return $dirscache(DEF_DIRS_LIST)
    }
    # Otherwise get from the handler
    return [::dbClientAPI::ListDataDirs]
}

#-------------------------------------------------------------------------
proc dbccp4i_add_defdir { alias dir } {
#-------------------------------------------------------------------------
#d_sum Add a "default" (data) directory to the list in the handler.
#d_desc This command associates an alias with a directory where data is \
normally stored. If the add operation succeeds then 1 is returned, \
otherwise zero is returned.
#d_arg alias Name of the data dir
#d_arg dir Full path of the data directory

    return [::dbClientAPI::AddDataDirRef $alias $dir]
}

#-------------------------------------------------------------------------
proc dbccp4i_delete_defdir { alias } {
#-------------------------------------------------------------------------
#d_sum Remove a "default" (data) directory from the handler.
#d_desc This command attempts to remove the reference to a specified \
data directory from the list of all data directories that the handler \
currently knows about. It returns 1 on successful removal and zero on \
failure.
#d_desc Note that deleting the directory reference doesn't remove the \
actual directory or any of the files from the system. Deleted data dirs \
can therefore be added back later using the dbccp4i_add_defdir command.
#d_arg alias Name of the data directory

    return [::dbClientAPI::DeleteDataDirRef $alias]
}

#-------------------------------------------------------------------------
proc dbccp4i_get_defdir_path { defdir } {
#-------------------------------------------------------------------------
#d_sum Return the directory path for a "default" (data) directory.
#d_desc Returns the path to the data directory associated with the \
specified name, or an empty string if the data dir isn't found.
#d_arg defdir Name of the data directory

    global dirscache

    # Error indicator
    set status 0

    # Try getting the data from the cache
    if { [dbccp4i_dirs_is_cached] } {
	for { set i 1 } { $i <= $dirscache(N_DEF_DIRS) } { incr i } {
	    if { $dirscache(DEF_DIR_ALIAS,$i) == $defdir } {
		set status 1
		set result $dirscache(DEF_DIR_PATH,$i)
	    }
	}
    }
    if { $status } {
	# Successfully retrieved data
	return $result
    } else {
	return [::dbClientAPI::GetDataDir $defdir]
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_dir_is_project { dir } {
#-------------------------------------------------------------------------
#d_sum Check whether a directory path is a project or data directory
#d_desc Returns 1 if the specified directory path corresponds to a \
known project directory or data directory, and zero if it doesn't.
#d_arg dir The directory path to check

    # Try the cache first
    global dirscache
    if { [dbccp4i_dirs_is_cached] } {
	# Check against Project Dirs
	set n $dirscache(N_PROJECTS)
	for { set i 1 } { $i <= $n } { incr i } {
	    if { $dir == $dirscache(PROJECT_PATH,$i) } { return 1 }
	}
	# Check against Default Dirs
	set n $dirscache(N_DEF_DIRS)
	for { set i 1 } { $i <= $n } { incr i } {
	    if { $dir == $dirscache(DEF_DIR_PATH,$i) } { return 1 }
	}
	# No matches
	return 0
    }
    # Cache not loaded - go to the handler
    if { [::dbClientAPI::IsProjectDir $dir] == "" } {
	if { [::dbClientAPI::IsDataDir $dir] == "" } {
	    return 0
	}
    }
    return 1
}

#-------------------------------------------------------------------------
proc dbccp4i_project_is_defined { project } {
#-------------------------------------------------------------------------
#d_sum Check whether a project name is already defined in the handler
#d_desc If the specified project name is already in the list of projects \
available to the handler then returns 1, otherwise returns 0.
#d_arg project Name of the project

    if { [lsearch [dbccp4i_list_projects] $project] > -1 } {
	return 1
    }
    return 0
}

#-------------------------------------------------------------------------
proc DbReport { level text } {
#-------------------------------------------------------------------------
#d_sum Handle reporting diagnostic messages for database code
#d_arg level A messaging level (with 0 being most serious)
#d_arg text Text to report
    if { $level > 0 || $text == "" } {
	return
    }
    catch { puts "DbReport $text" }
}


#d_index_title Database cache for database handler
#d_intro_title Database cache for database handler
#d_intro The commands in this section are used to set up and maintain a \
cache of data for the current database, to speed up interactions with the \
job database (particularly for updating the job list).

#-------------------------------------------------------------------------
proc dbccp4i_populate_dirs_cache { } {
#-------------------------------------------------------------------------
#d_sum Initialise the directories data in the cache
#d_desc This clears any current contents of the cache and repopulates \
it with data for the specified project from the handler.
#d_desc Once the cache is populated, data about individual projects and \
def dirs should be kept up-to-date automatically in response to broadcasts \
received from the handler.
#d_desc Based on the dbccp4i_populate_cache command in projectdb.tcl.
    global dirscache

    # Check whether the cache is already loaded
    if { [dbccp4i_dirs_is_cached] } {
	return
    }

    # Clear the cache contents
    array unset dirscache *

    # Start over
    set dirscache(LOADED) 0
    set dirscache(N_PROJECTS) 0
    set dirscache(N_DEF_DIRS) 0
    set dirscache(PROJECTS_LIST) {}
    set dirscache(DEF_DIRS_LIST) {}

    # Load the project data
    set projects [::dbClientAPI::ListProjects]
    
    # First try using the GetDirectoriesData command
    # Older versions of the handler and client API may not have this command
    set fetchCmd [list ::dbClientAPI::GetDirectoriesData]
    foreach project $projects {
        lappend fetchCmd ProjectDir $project ProjectDBDir $project
    }
    if { [catch { set projectData [eval $fetchCmd] } err] } {
	# Failed probably because the client API doesn't support
	# this command?
	# Acquire the data one item at a time...
	set projectData {}
	foreach project $projects {
	    lappend projectData \
		[::dbClientAPI::GetProjectDir $project] \
		[::dbClientAPI::GetProjectDBDir $project]
	}
    }
    foreach project $projects {
	set n [incr dirscache(N_PROJECTS)]
	set dirscache(PROJECT_ALIAS,$n) $project
	set dirscache(PROJECT_PATH,$n) [lindex $projectData [expr $n*2 - 2]]
	set dirscache(PROJECT_DB,$n) [lindex $projectData [expr $n*2 - 1]]
	lappend dirscache(PROJECTS_LIST) $project
    }

    # Load the defdir data in a similar way
    set defdirs [::dbClientAPI::ListDataDirs]
    set fetchCmd [list ::dbClientAPI::GetDirectoriesData]
    foreach defdir $defdirs {
        lappend fetchCmd DataDir $defdir
    }
    if { [catch { set defdirData [eval $fetchCmd] } err] } {
	# Failed probably because the client API doesn't support
	# this command?
	# Acquire the data one item at a time...
	set defdirData {}
	foreach defdir $defdirs {
	    lappend defdirData [::dbClientAPI::GetDataDir $defdir]
	}
    }
    foreach defdir $defdirs {
	set n [incr dirscache(N_DEF_DIRS)]
	set dirscache(DEF_DIR_ALIAS,$n) $defdir
	set dirscache(DEF_DIR_PATH,$n) [lindex $defdirData [expr $n - 1]]
	lappend dirscache(DEF_DIRS_LIST) $defdir
    }

    set dirscache(LOADED) 1
}

#-------------------------------------------------------------------------
proc dbccp4i_dirs_is_cached { } {
#-------------------------------------------------------------------------
#d_sum Check whether the directories data has been cached
#d_desc This returns 1 if the directories caches has been loaded \
indicating that the data is cached, and zero otherwise.
    global dirscache
    if { [info exists dirscache(LOADED)] } {
	return $dirscache(LOADED)
    } else {
	return 0
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_update_dirs_cache { broadcast } {
#-------------------------------------------------------------------------
#d_sum Update the directories cache in response to a handler broadcast
#d_desc Given a broadcast message from the handler, this command \
determines which project or defdir has been updated and the operation that \
has been performed. It then calls the appropriate command to update \
the cached data.
#d_arg broadcast Broadcast message received from the database handler

    set project [lindex $broadcast 1]
    set job [lindex $broadcast 2]
    set operation [lindex $broadcast 3]
    # Wrap with catch since this is normally invoked by a
    # callback
    ##puts "dbccp4i_update_dirs_cache $project $job $operation"
    if { [catch {
	switch $operation {
	    NewProject {
		# Project was added
		dbccp4i_cache_addproject $project
	    }
	    ImportProject {
		# Project was imported
		dbccp4i_cache_addproject $project
	    }
	    DeleteProject {
		# Project was removed
		dbccp4i_cache_deleteproject $project
	    }
	    AddDataDirRef {
		# Data dir (def dir) was added
		dbccp4i_cache_adddefdir $project
	    }
	    DeleteDataDirRef {
		# Data dir (def dir) was removed
		dbccp4i_cache_deletedefdir $project
	    }
	    default {
		# Ignore
	    }
	}
    } err] } {
	puts "ERROR caught in dbccp4i_update_dirs_cache: \"$err\""
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_addproject { project } {
#-------------------------------------------------------------------------
#d_sum Add the data for a new project into the cache
#d_desc This command retrieves the data for the specified project \
from the handler and inserts it into the cache.
#d_arg project The name of the project being cached
    global dirscache

    set project_path [::dbClientAPI::GetProjectDir $project]
    set project_db [::dbClientAPI::GetProjectDBDir $project]
   
    # Store the data
    set n [incr dirscache(N_PROJECTS)]
    set dirscache(PROJECT_ALIAS,$n) $project
    set dirscache(PROJECT_PATH,$n) $project_path
    set dirscache(PROJECT_DB,$n) $project_db
    lappend dirscache(PROJECTS_LIST) $project
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_deleteproject { project } {
#-------------------------------------------------------------------------
#d_sum Remove a project from the cache
#d_desc This command deletes the specified project from the cache.
#d_arg project The name of the project to be removed
    global dirscache

    for { set i 1 } { $i <= $dirscache(N_PROJECTS) } { incr i } {
	if { $dirscache(PROJECT_ALIAS,$i) == $project } {
	    set n $dirscache(N_PROJECTS)
	    if { $i != $dirscache(N_PROJECTS) } {
		# Overwrite this project with the last one
		set dirscache(PROJECT_ALIAS,$i) $dirscache(PROJECT_ALIAS,$n)
		set dirscache(PROJECT_PATH,$i) $dirscache(PROJECT_PATH,$n)
		set dirscache(PROJECT_DB,$i) $dirscache(PROJECT_DB,$i)
	    }
	    # Remove the last project from the list
	    unset dirscache(PROJECT_ALIAS,$n)
	    unset dirscache(PROJECT_PATH,$n)
	    unset dirscache(PROJECT_DB,$n)
            # Remove it from the list of projects
            if { [set k [lsearch $dirscache(PROJECTS_LIST) $project]] > -1 } {
		set dirscache(PROJECTS_LIST) [lreplace $dirscache(PROJECTS_LIST) $k $k]
	    }
	    # Decrease the number of projects
            incr dirscache(N_PROJECTS) -1
	    return
	}
    }
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_adddefdir { defdir } {
#-------------------------------------------------------------------------
#d_sum Add the data for a new def dir into the cache
#d_desc This command retrieves the data for the specified def dir \
from the handler and inserts it into the cache.
#d_arg defdir The name of the def dir being cached
    global dirscache

    set defdir_path [::dbClientAPI::GetDataDir $defdir]

    set n [incr dirscache(N_DEF_DIRS)]
    set dirscache(DEF_DIR_ALIAS,$n) $defdir
    set dirscache(DEF_DIR_PATH,$n) $defdir_path
    lappend dirscache(DEF_DIRS_LIST) $defdir
}

#-------------------------------------------------------------------------
proc dbccp4i_cache_deletedefdir { defdir } {
#-------------------------------------------------------------------------
#d_sum Remove a def dir from the cache
#d_desc This command deletes the specified def dir from the cache.
#d_arg defdir The name of the def dir to be removed
    global dirscache

    for { set i 1 } { $i <= $dirscache(N_DEF_DIRS) } { incr i } {
	if { $dirscache(DEF_DIR_ALIAS,$i) == $defdir } {
	    set n $dirscache(N_DEF_DIRS)
	    if { $i != $dbcache(N_DEF_DIRS) } {
		# Overwrite this project with the last one
		set dirscache(DEF_DIR_ALIAS,$i) $dirscache(DEF_DIR_ALIAS,$n)
		set dirscache(DEF_DIR_PATH,$i) $dirscache(DEF_DIR_PATH,$n)
	    }
	    # Remove the last project from the list
	    unset dirscache(DEF_DIR_ALIAS,$n)
	    unset dirscache(DEF_DIR_PATH,$n)
            # Remove it from the list of defdirs
            if { [set k [lsearch $dirscache(DEF_DIRS_LIST) $project]] > -1 } {
		set dirscache(DEF_DIRS_LIST) [lreplace $dirscache(DEF_DIRS_LIST) $k $k]
	    }
	    # Decrease the number of defdirs
            incr dirscache(N_DEF_DIRS) -1
	    return
	}
    }
}
