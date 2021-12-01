#
#
#     Copyright (C) 2005-2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - dbClientAPI.tcl
#
# API functions to allow a client application to communicate with
# the database handler
# 
# Peter Briggs and Wanjuan Yang
# Based on code originally written by Liz Potterton
#====================================================================

#CCP4i_cvs_Id $Id: dbClientAPI.tcl,v 1.11 2008/09/10 14:53:42 pjx Exp $

##################################################################

#
#d_index_title Database Handler Client API (ClientAPI/dbClientAPI.tcl)
#d_intro_title Functions for applications interacting with the DB server
#
#d_intro These are the commands that can be invoked by a client of \
the database server in order to communicate with it. The commands map \
onto the commands provided in the database server.
#d_intro The commands are provided with a Tcl namespace called \
"dbClientAPI" in order to avoid potential name clashes with procedures \
that might be defined within the client application using the API. In \
order to use the client API functions, either:
#d_intro 1) specify the fully-qualified names e.g. \
::dbClientAPI::DbStartHandler, or
#d_intro 2) use the "namespace import" command in order to make the API \
functions available without the leading ::dbClientAPI:: qualification - \
e.g. namespace import ::dbClientAPI::DbStartHandler will enable the client \
application to invoke "DbStartHandler" directly.
#d_intro It is possible to use namespace import ::dbClientAPI::* in order \
to import all the procedures in the client API. However it is possible \
in this case that you may encounter a clash of names.

# Load the pseudo-XML handling functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbxml.tcl]
# Load copies of the core CCP4i commands
source [file join $env(DBCCP4I_TOP) ClientAPI ccp4ilite.tcl]

# dbClientAPI_nsExists
# This is a workaround for missing "namespace exists" command in
# Tcl 8.3 and earlier

if { [package vcompare [package provide Tcl] 8.4] < 0 } {
    proc dbClientAPI_nsExists { ns } {
	return [ expr { ![catch { namespace parent $ns }] } ]
    }
} else {
    proc dbClientAPI_nsExists { ns } {
	return [ namespace exists $ns ]
    }
}

if { ![dbClientAPI_nsExists ::dbClientAPI] } {
    # Only declare the namespace if it hasn't previously
    # been defined

    namespace eval ::dbClientAPI:: {
	# Declare globals within the dbClientAPI namespace
	variable handler
	set handler(RUN_DBSERVER) [list python \
                         [file join $env(DBCCP4I_TOP) dbccp4i dbccp4i.py]]
	set handler(DIRECTORIES) ""
	set handler(DB_PORT) ""
	set handler(DB_HOST) ""
	set handler(DB_SOCKET) ""
	set handler(DB_BROADCAST_CALLBACK) {}
	set handler(DB_HANDLER_STATUS) 0
	set handler(DB_CONNECTION_STATUS) 0
	set handler(DB_TIMEOUT) 30000
	set handler(DB_LOG) 0
	
	#set cachedProject
	set handler(CACHED_PROJECT) ""
	set handler(CACHED_ITEMS) {}

	set handler(RESPONSE_STATUS) ""
	set handler(RESPONSE_RESULT) ""

	# Exported procedures - export everything
	namespace export *
    }
}

# This file contains the database primitives
# The primitives hide the implementation details i.e. nothing about
# the handler process should be visible from outside this file.

# Commands for talking to the database handler

#d_index_title Interacting With The Database Handler
#d_intro_title Interacting With The Database Handler
#d_intro These commands are for initiating, interrogating and stopping \
the database handler process, and for setting up a connection from the \
application to the process in order to add, fetch and manipulate the \
stored data.

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbStartHandler { { directories "" } } {
#-----------------------------------------------------------------------
#d_sum Start a database handler, or connect to one already running
#d_desc This command opens a server socket and starts a new handler \
process in background. The handler process sends back a port number \
for the client application to use when connecting to the handler.
#d_desc As this command is now called from within DbHandlerConnection \
it is not necessary to call it explicitly.

  variable handler
  set status 0

  if { $directories != "" } {
      set $handler(DIRECTORIES) $directories
  }

  # Commands to check the port and start the handler
  set portCmd [list db_get_handler_port]
  set startCmd [concat exec $handler(RUN_DBSERVER)]
  if { $directories != "" } {
      lappend portCmd "-directories" "$directories"
      lappend startCmd "-directories" "$directories"
  }
  set portNoWaitCmd $portCmd
  lappend portNoWaitCmd "-nowait"

  # Check whether a handler is already running
  set port [eval $portNoWaitCmd]
  if { $port > -1 } {
      db_client_report 1 "DbStartHandler: handler already running using port number $port"
      set handler(DB_PORT) $port
      set status 1
  } else {
      # Start the handler in background
      if { ![ catch { eval $startCmd & } err ] } {
	  # Wait for the port number to be updated
	  db_client_report 1 "DbStartHandler: waiting for update"
	  set port [eval $portCmd]
	  db_client_report 1 "DbStartHandler: update received"
	  if { $port > -1 } {
	      db_client_report 1 "DbStartHandler: handler using port number $port"
	      set handler(DB_PORT) $port
	      set status 1
	  } else {
	      db_client_report 1 "DbStartHandler: Bad port number returned"
	  }
      }
  }
  set handler(DB_HANDLER_STATUS) $status
  db_client_report 1 "DbStartHandler: status = $handler(DB_HANDLER_STATUS)"
  return $status
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbHandlerConnect { userAgent args } {
#-----------------------------------------------------------------------
#d_sum Open socket and connect to (register with) database handler
#d_desc This command should only be invoked by the client application \
after DbStartHandler, which establishes the correct port number to use \
to communicate with the database server process.
#d_desc It sets up a client socket with a callback procedure \
(db_handler_processResponse) which is invoked whenever the socket becomes \
readable (corresponding to data being sent from the handler). This \
command then connects to the handler, allowing the other database \
requests to be made via the appropriate API commands.
#d_desc Optionally the calling process can specify its own callback \
procedure which will be invoked each time a broadcast message is \
received from the handler. The callback function must be defined in \
the application.
#d_desc By default the connection is made to a handler process on the \
local machine, and a new handler will automatically be started if \
necessary. However a connection can also be made to an existing handler \
process on a remote machine, provided that the name of the machine and \
the port number are explicitly specified.
#d_desc Return 1 on success and 0 on failure
#d_arg useragent     The application name which connects to the handler
#d_opt0 -broadcastHandler
#d_opt1 Name of a callback function that will be invoked whenever a \
broadcast message is received from the handler.
#d_opt0 -host
#d_opt1 The name of the host that the handler process is running on. If \
the host is not specified then localhost is assumed.
#d_opt0 -port
#d_opt1 The port number to connect to the handler on. If the host is \
not set, or is set to localhost, then the command will try to acquire \
the port number automatically. For remote machines the port number \
must be specified explicitly.
#d_opt0 -directories
#d_opt1 Name of a file containing the directories data which will be \
used instead of the default directories.def file.

  variable handler
  db_client_report 1 "DbHandlerConnect: connection request"

  # Trap for the client trying to connect more than once
  if { $handler(DB_CONNECTION_STATUS) } {
      db_client_report 1 "DbHandlerConnect: already connected"
      return 0
  }

  # Process the arguments
  set broadcastCmd ""
  set hostname "localhost"
  set port ""
  set dirsfile ""
  set nargs [llength $args]
  for { set i 0 } { $i < $nargs } { incr i } {
      set option [lindex $args $i]
      switch -exact -- $option {
	  "-broadcastHandler" {
	      incr i
	      set broadcastCmd [lindex $args $i]
	  }
	  "-host" {
	      incr i
	      set hostname [lindex $args $i]
	  }
	  "-port" {
	      incr i
	      set port [lindex $args $i]
	  }
	  "-directories" {
	      incr i
	      set dirsfile [lindex $args $i]
	  }
	  default {
	      db_client_report 1 "DbHandlerConnect: unrecognised argument: $option"
	      puts "DbHandlerConnect: unrecognised argument: $option"
	      return 0
	  }
      }
  }

  # Register the callback function
  if { $broadcastCmd != "" } {
      set handler(DB_BROADCAST_CALLBACK) $broadcastCmd
      set broadcastFlag 1
  } else {
      set broadcastFlag 0
  }

  # Get the port of a running handler
  if { $hostname == "localhost" && $port =="" } {
      if { ![DbStartHandler $dirsfile] } {
	  db_client_report 1  "DbHandlerConnect: failed to start the handler"
	  return 0
      }
  } else {
      # Use the port number previously provided
      set handler(DB_PORT) $port
  }

  # Set up the socket connection
  if { [catch { set sock [socket $hostname $handler(DB_PORT)] } err] } {
      db_client_report 1 "DbHandlerConnect: failed to connect to $hostname $port"
      db_client_report 1 "DbHandlerConnect: $err"
      return 0
  }
  set handler(DB_SOCKET) $sock
  set handler(DB_HOST) $hostname

  # Set the socket to operate asynchronously (i.e. non-blocking)
  fconfigure $sock -buffering line -blocking 0
  fileevent $sock readable "::dbClientAPI::db_handler_processResponse $sock"

  # Initialise the handler array for dealing with sending
  # requests and receiving responses
  set handler(REQUEST_NUMBER) 0
  set handler(REQUEST_LIST) {}
  set handler(ERROR_MESSAGE) {}

  # Register with handler
  set handler(DB_CONNECTION_STATUS) 1
  set status [db_handler_request message "DbRegister" [GetUserId] \
		$userAgent $broadcastFlag ]
  db_client_report 1 "DbHandlerConnect: got back status \"$status\" message \"$message\""

  if { [regexp "^failed\$" $status] } {
      set handler(DB_CONNECTION_STATUS) 0
      return 0
  } else {      
  }
  return $handler(DB_CONNECTION_STATUS)
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbHandlerDisconnect { } {
#-----------------------------------------------------------------------
#d_sum Disconnect socket from the database handler
  variable handler
  db_client_report 1 "DbHandlerDisconnect:  disconnection request"
  if { ! $handler(DB_CONNECTION_STATUS) } {
    db_client_report 1 "DbHandlerDisconnect: currently no connection to handler"
    return 0
  } else {
    db_handler_request message "DbDisconnect"
    db_client_report 1 "DbHandlerDisconnect: got back $message"
    close_db_connection
    return 1
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbHandlerPort { args } {
#-----------------------------------------------------------------------
#d_sum Return the port number that the handler is using
#d_desc This returns the port number, or -1 if a port number cannot \
be acquired.
#d_desc It is a wrapper for db_get_handler_port and takes the same \
arguments as that command.
    return [eval ::dbClientAPI::db_get_handler_port $args]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbVerifyConnection { } {
#-----------------------------------------------------------------------
#d_sum Check whether the connection to the handler is active
#d_desc Return 1 if the connection exists and is working, return 0 \
otherwise.
#d_desc Wrapper for DbRequestStatus command in the handler.
    if { [regexp "^OK$" [db_handler_request msg "DbRequestStatus"]] } {
	return 1
    } else {
	return 0
    }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbInfo { } {
#-----------------------------------------------------------------------
#d_sum Get version and other info about the handler
#d_desc This should return a list of key-value pairs as a simple \
list of strings.
#d_desc e.g. "Version 1.3-dev" indicates the handler version number.
    if { [regexp "^OK$" [db_handler_request msg "DbInfo"]] } {
	return $msg
    } else {
	return {}
    }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbSupported { DB } {
#-----------------------------------------------------------------------
#d_sum Check whether a particular database backend is supported
#d_desc For a particular database backend type, this function returns \
1 if that backend is supported in the handler, and 0 if not.
#d_desc The backends can be "def" and "SQLite".
#d_arg DB The database backend type being checked for
# Use eval to invoke the command, to stops the arglist concatenated
# into a single argument
  if { ![regexp ^OK$ [eval db_handler_request message "DbSupported" $DB]] } {
      db_client_report 1 "ERROR Updating database: $message"
      return 0
  } else {
      if { [regexp -- "True" $message] } {
	  # Backend is supported
	  return 1
      } else {
	  # Backend is not supported
	  return 0
      }
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbShutdown { } {
#-----------------------------------------------------------------------
#d_sum Issue shutdown request to the handler
   variable handler
   db_client_report 1 "DbShutdown: shutdown request"
   if { ! $handler(DB_CONNECTION_STATUS) } {
       db_client_report 1 "DbShutdown: currently no connection to handler"
       return 0
   } else {
       db_handler_request message "ShutDown"
       db_client_report 1 "DbShutdown: got back $message"
       close_db_connection
       set handler(DB_HANDLER_STATUS) 0
       return 1
   }
}

#d_index_title Cache project and update cache
#d_intro_title Cache project and update cache
#d_intro These commands are used for cache a project, update the cache and get data from cache.

#----------------------------------------------------------------------
proc ::dbClientAPI::cacheProject { project } {
#----------------------------------------------------------------------
#d_sum store project data in a database array
    variable handler
    variable dbclient_database

    set handler(CACHED_PROJECT) $project
   
    # get joblist & itemlist
    set joblist [ ListJobs $project ]
    set itemlist [ GetDbItems $project ]

    set handler(CACHED_ITEMS) $itemlist

    # unset the array
    if { [array exists dbclient_database] } {
	array unset dbclient_database *
    }

    if { $joblist != {} } {
	# get a list records from handler
	set records [ GetListofRecords $project $joblist $itemlist ]
   
	# store the records in database array
	foreach id $joblist {
	    # get index of item
	    set i [lsearch $joblist $id]

	    # get record for the jobid 
	    set record [lindex $records $i]
	    foreach item $itemlist {
		# get index of id
		set j [lsearch $itemlist $item]
		# get the item from the record
		set dbclient_database($item,$id) [lindex $record $j]
	    }
	}
    }
}

#--------------------------------------------------------------------
proc ::dbClientAPI::updateCachedJob { id } {
#--------------------------------------------------------------------
#d_sum update the database array

    variable dbclient_database
    variable handler

    set record [ GetListofRecords $handler(CACHED_PROJECT) $id $handler(CACHED_ITEMS) ]
   
    # get the first and only one record
    set record [lindex $record 0]
    foreach item $handler(CACHED_ITEMS) {
	set j [lsearch $handler(CACHED_ITEMS) $item]

	set dbclient_database($item,$id) [ lindex $record $j ] 
	
    }
}

#---------------------------------------------------------------------
proc ::dbClientAPI::deleteCachedJob { id } {
#---------------------------------------------------------------------
#d_sum delete a job in the database array

    variable dbclient_database
    variable handler
    
    foreach item $handler(CACHED_ITEMS) {
	set j [lsearch $handler(CACHED_ITEMS) $item]
	unset dbclient_database($item,$id)
    }
}

#---------------------------------------------------------------------
proc ::dbClientAPI::getCachedData { id item } {
#---------------------------------------------------------------------
#d_sum get the data from cached project
    variable dbclient_database
    return $dbclient_database([subst $item],$id)
}


#d_index_title Projects and Directories
#d_intro_title Projects and Directories
#d_intro These are commands for requesting information about the \
available projects and default directories.

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListProjects { } {
#-----------------------------------------------------------------------
#d_sum Fetch a list of project names from the database handler

  if { [regexp ^OK [::dbClientAPI::db_handler_request message "ListProjects" ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list projects: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetNProjects { } {
#-----------------------------------------------------------------------
#d_sum Request the number of projects
#d_desc This returns the number of projects currently defined in the \
user's database.

  if { [regexp ^OK [db_handler_request message "GetNProjects" ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list projects: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListDataDirs { } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to list user's default directories
#d_desc Returns a list of aliases for the user's data directories.

  if { [regexp ^OK [db_handler_request message "ListDataDirs" ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list def dirs: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteProject { project } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to delete a project reference
#d_desc This removes the project reference from the user's database, but \
the project directory, files and job database are not removed. The \
project can be restored using the ImportProject command.
#d_arg project Alias for the project being deleted

  if { [regexp ^OK [db_handler_request message "DeleteProject" $project ]] } {
      return 1
  } else {
      db_client_report 1 "ERROR delete project: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::ImportProject { alias path } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to add a reference to an existing project
#d_desc This adds a reference to the specified project to the user's \
database. The project directory and job database must already exist.
#d_arg Alias the project being added
#d_arg path the project directory

  if { [regexp ^OK [db_handler_request message "ImportProject" $alias $path ]] } {
      return 1
  } else {
      db_client_report 1 "ERROR import project: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::AddDataDirRef { def_dir path } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to add default directory reference
#d_arg def_dir the default directory name
#d_arg path the full path of the default directory 

  if { [regexp ^OK [db_handler_request message "AddDataDirRef" $def_dir $path ]] } {
      return 1
  } else {
      db_client_report 1 "ERROR add default directory reference: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteDataDirRef { def_dir } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to delete default directory reference
#d_arg def_dir the default directory name

  if { [regexp ^OK [db_handler_request message "DeleteDataDirRef" $def_dir ]] } {
      return 1
  } else {
      db_client_report 1 "ERROR delete default directory reference: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetProjectDir { project } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to get a project's directory name
#d_arg project Alias for the project which the directory contains

  if { [regexp ^OK [db_handler_request message "GetProjectDir" $project ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Get project dir: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetProjectDBDir { project } {
#-----------------------------------------------------------------------
#d_sum Fetch the database directory for the specified project
#d_arg project Alias for the project which the directory contains

  if { [regexp ^OK [db_handler_request message "GetProjectDBDir" $project ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Get project db dir: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::IsProjectDir { dirn } {
#-----------------------------------------------------------------------
#d_sum Fetch the project name that matches the supplied directory
#d_desc Return the name of the project for which the supplied directory \
path corresponds to the project directory, or an empty string if no \
match is found.
#d_arg dirn Path to the directory that is being looked up

  if { [regexp ^OK [db_handler_request message "IsProjectDir" $dirn ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Get project from dir: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::IsDataDir { dirn } {
#-----------------------------------------------------------------------
#d_sum Fetch the data dir name that matches the supplied directory
#d_desc Return the name of the data dir for which the supplied directory \
path corresponds to the data directory, or an empty string if no \
match is found.
#d_arg dirn Path to the directory that is being looked up

  if { [regexp ^OK [db_handler_request message "IsDataDir" $dirn ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Get data dir from dir: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetDataDir { def_dir } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to get the directory corresponding to a default directory name
#d_arg def_dir the default directory name

  if { [regexp ^OK [db_handler_request message "GetDataDir" $def_dir ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Get def dir: $message"
      return {}
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetDirectoriesData { args } {
#-----------------------------------------------------------------------
#d_sum Fetch multiple directories data items in one request
#d_desc This command allows the client to retrieve many data items \
related to several different projects and data dirs in one call.
#d_desc The syntax is GetDirectoriesData keyword alias [keyword alias ...]
#d_desc Each pair of arguments consists of a project or data dir \
alias name following a keyword indicating the data that is to be \
fetched:
#d_desc ProjectDir: the path to the directory corresponding to the \
alias, if it's a project
#d_desc ProjectDBDir: the path to the database directory for the project
#d_desc DataDir: the path to the directory corresponding to the alias \
if it's a data dir
#d_desc Returns a list with one item resulting from each alias-keyword \
pair that was supplied.
#d_opt0 alias
#d_opt1 The name of a project or defdir
#d_opt0 keyword
#d_opt1 A keyword to indicate the data to retrieve (see above)

  if { [regexp ^OK$ \
	    [eval db_handler_request value "GetDirectoriesData" $args]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#d_index_title Creating, Opening and Closing Projects
#d_intro_title Creating, Opening and Closing Projects
#d_intro These functions allow project databases to be created, opened \
for reading and writing, and closed again.

#-----------------------------------------------------------------------
proc ::dbClientAPI::OpenProject { project args } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to open a project database
#d_desc If the first argument doesn't start with a hyphen then it's \
assumed to be the name of a variable in the calling procedure in which \
to report any message returned from the handler. All other options \
must come after this and must start with a hyphen.
#d_desc Return 1 on success and 0 on failure.
#d_arg project Alias for the project being opened
#d_opt messageVar (Optional) Name of a variable to return any messages in
#d_opt -grablock Forces the handler to open a locked database
#d_opt -force An alias for -grablock
#d_opt -readonly Open project with read only mode

  # Process the command arguments to see if a variable name
  # was supplied as the first argument
  set i 0
  set messageVar ""
  if { [llength $args] > 0 } {
      set opt [lindex $args $i]
      if { ![regexp -- "^-(.*)\$" $opt] } {
	  set messageVar $opt
	  incr i
      }
  }
  if { $messageVar != "" } {
      upvar $messageVar message
  }

  # Pass the remaining arguments to the handler request
  # mechanism
  set new_args [lrange $args $i end]

  # Send the request and convert the return value
  set status [eval db_handler_request message "DbOpen" $project $new_args]
  return [regexp -- "^OK\$" $status]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::CreateProject { project db messageVar args } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to create a project database
#d_arg project Alias for the project being created
#d_arg db The full directory path of the project database
#d_arg messageVar Name of a variable to return any messages in
    upvar $messageVar message
    set status [eval db_handler_request message "NewDb" $project $db $args]
    return [regexp -- "^OK\$" $status]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::CloseProject { project } {
#-----------------------------------------------------------------------
#d_sum Close a currently open project database
#d_desc The client must previously have opened the project using \
the OpenProject command, otherwise an error will be returned.
#d_arg project Alias for the project being closed

  if { [regexp ^OK [db_handler_request message "DbClose" $project]] } {
      return 1
  } else {
      db_client_report 1 "ERROR closing database: $message"
      return 0
  }
}

#----------------------------------------------------------------------
proc ::dbClientAPI::ProjectWriteable { project } {
#----------------------------------------------------------------------
#d_sum Check if is possible to write to the database
#d_desc Return 1 if the connection has write access to the job database \
for the project, zero otherwise.
#d_desc -1 is returned in the event of an error.
#d_arg project Name of the project
    
    if { [regexp ^OK [db_handler_request message \
          "ProjectWriteable" $project ]] } {
      # The handler returns "True" or "False"
      # Convert these to 1 or 0
      return [regexp -- "^True\$" $message]
  } else {
      db_client_report 1 "ERROR ProjectWriteable: $message"
      return -1
  }
}

#----------------------------------------------------------------------
proc ::dbClientAPI::ProjectReadable { project } {
#----------------------------------------------------------------------
#d_sum Check if it is possible to read from the database
#d_desc Return 1 if the connection has read access to the job database \
for the project, zero otherwise.
#d_desc -1 is returned in the event of an error.
#d_arg project Name of the project
    
    if { [regexp ^OK [db_handler_request message \
          "ProjectReadable" $project ]] } {
      # The handler returns "True" or "False"
      # Convert these to 1 or 0
      return [regexp -- "^True\$" $message]
  } else {
      db_client_report 1 "ERROR ProjectReadable: $message"
      return -1
  }
}

#----------------------------------------------------------------------
proc ::dbClientAPI::ReacquireProject { project } {
#----------------------------------------------------------------------
#d_sum Reload the job database to regain read and write access
#d_desc This command forces the handler to reacquire the lock on the \
job database for the specified project. This is useful in the case that \
the handler has lost write access to the project.
#d_desc Return 1 if the reacquisition was successful, 0 in the case of \
failure, and -1 if there was an error.
#d_arg project Name of the project
    
    if { [regexp ^OK [db_handler_request message \
          "ReacquireProject" $project ]] } {
      return [regexp -- "^True\$" $message]
  } else {
      db_client_report 1 "ERROR ReacquireProject: $message"
      return -1
  }
}

#d_index_title Job History
#d_intro_title Job History
#d_intro These are commands for requesting information about the \
links between the jobs in a project.

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetAllFileLinks { project } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to get a project's history link between jobs

  if { [regexp ^OK [db_handler_request message "GetAllFileLinks" $project ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetFileLinks { project jobs } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to get a project's history link between jobs

  if { [regexp ^OK [db_handler_request message "GetFileLinks" $project -list $jobs]] } {
      return $message
  } else {
      db_client_report 1 "ERROR: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetNextJobList { project jobid } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to a job's next job list of a given project

  if { [regexp ^OK [db_handler_request message "GetNextJobList" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list jobs: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetAllChildren { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return all the jobs which are decendent of this job.

  if { [regexp ^OK [db_handler_request message "GetAllChildren" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR GetAllChildren: $message"
      return 0
  }
}

#---------------------------------------------------------------------------
proc ::dbClientAPI::GetChildren { project jobid } {
#----------------------------------------------------------------------
#d_sum Return a job's next job list

     if { [regexp ^OK [db_handler_request message "GetChildren" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetAllParents { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return all the anscendent of a job.

  if { [regexp ^OK [db_handler_request message "GetAllParents" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list jobs: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetParents { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return a job's previous job list

  if { [regexp ^OK [db_handler_request message "GetParents" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR: $message"
      return 0
  }
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetAllParentsChildren { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return all the jobs that related to the given job.

  if { [regexp ^OK [db_handler_request message "GetAllParentsChildren" $project $jobid]] } {
      return $message
  } else {
      Report 1 "ERROR list jobs: $message"
      return 0
  }
}

#d_index_title Requesting and Manipulating Job Data
#d_intro_title Requesting and Manipulating Job Data
#d_intro These commands provide functions for creating and deleting \
job records, and for setting and fetching data associated with the \
jobs.

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetNJOB { project } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to get the NJOB of the database

  if { [regexp ^OK [db_handler_request NJOB "GetNJOB" $project]] } {
      return $NJOB
  } else {
      db_client_report 1 "ERROR GetNJOB: $NJOB"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListJobs { project { jobid "" } } {
#-----------------------------------------------------------------------
#d_sum Request a list of job ids in a project, or subjobs in a job
#d_desc ListJobs invoked with just a project name returns a list of all \
"top-level" job ids in that project. If a job id is also specified then \
a list of the subjob ids associated with that job is returned instead.
#d_arg project Name of the project
#d_arg jobid (Optional) Job id for which subjobs should be returned

    # check whether a jobid was specified
   if { $jobid == "" } {
	set result [db_handler_request message "ListJobs" $project]
    } else {
	set result [db_handler_request message "ListJobs" $project $jobid]
    }    
    if { [regexp ^OK $result] } {
	return $message
    } else {
	db_client_report 1 "ERROR list jobs: $message"
	return 0
    }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetDbItems { project } {
#-----------------------------------------------------------------------
#d_sum Ask the database handler to list items store in database

  if { [regexp ^OK [db_handler_request message "GetDbItems" $project ]] } {
      return $message
  } else {
      db_client_report 1 "ERROR list jobs: $message"
      return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::NewJob { project } {
#-----------------------------------------------------------------------
#d_sum Create a new record in a CCP4i project database
#d_desc Creates a new job in the specified job database and returns \
the job id.
#d_arg project Alias for the project in which the job is being created
  if { [regexp ^OK$ [db_handler_request njobs "DbNewJob" $project ]] } {
    return $njobs
  } else {
    return 0
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteJob { project job_id } {
#-----------------------------------------------------------------------
#d_sum Delete a record (job) from a CCP4i project database
#d_desc Removes the specified job id and associated data from the \
specified project database.
#d_arg project Alias for the project from which the job is being removed
#d_arg job_id  Number of the job being removed
  if { [regexp ^OK$ \
	  [db_handler_request message "DbDeleteJob" $project $job_id] ] } {
      return 1
  }
  db_client_report 1 "ERROR deleting record: $message"
  return 0
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::Updatetime { project job_id } {
#-----------------------------------------------------------------------
#d_sum update a record(job) time.
#d_arg project project name
#d-arg job_id job number
    if { [regexp ^OK$ \
	  [db_handler_request message "Updatetime" $project $job_id] ] } {
      return 1
  }
  db_client_report 1 "ERROR update time: $message"
  return 0
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ItemExists { project job_id item } {
#-----------------------------------------------------------------------
#d_sum Test for the existence of a data item
#d_desc Returns 1 if the specified data item exists for the named job \
and project database, and 0 if not.
#d_arg project Alias of the project
#d_arg job_id  Number of the job being interrogated
#d_arg item    Name of the data item being queried
  set result [db_handler_request status "DbItemExists" $project $job_id $item]
  db_client_report 1 "ItemExists: result = $result"
  if { ![regexp "^OK\$" $result] } {
      db_client_report 1 "ItemExists: error: $result $status"
      set status 0
  } else {
      # DbItemExists returns True or False
      if { $status == "True" } {
	  set status 1
      } else {
	  set status 0
      }
  }
  return $status
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::SetData { project job_id args } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the server.
#d_arg project Alias of the project database
#d_arg job_id  Number of the job for which the data is being set
#d_arg item1   Item name to set the value of
#d_arg value1  Corresponding value to set "item1" to be
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request message "DbSetData" \
	       $project $job_id $args]] } {
      db_client_report 1 "ERROR Updating database: $message"
      return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetData { project job_id args } {
#-----------------------------------------------------------------------
#d_sum Return the values of one or more data items
#d_desc This returns the values of multiple data items for a particular \
job in the specified project database. The argument list should consist \
of keys. A list of the corresponding values will be returned.
#d_desc Retrieving multiple data items in a single GetData command is \
recommended as this minimises the number of socket transactions required \
to fetch the data from the server.
#d_arg project Alias of the project database
#d_arg job_id  Number of the job for which the data is being fetched
#d_arg item1   Item name to get the value of
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { [regexp ^OK$ \
	  [eval db_handler_request value "DbGetData" \
	       $project $job_id $args]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::SelectJobs { project item pattern } {
#-----------------------------------------------------------------------
#d_sum Return a list of jobs matching a regular expression
#d_desc This command returns a list of job numbers where the values of \
the specified item matches the supplied regular expression pattern.
#d_arg project Alias of the project database
#d_arg item    Item name being searched on
#d_arg pattern Regular expression pattern to search on
  if { [regexp ^OK$ \
	  [db_handler_request job_list "DbSelectJobs" \
	       $project $item $pattern]] } {
      return $job_list
  }
  db_client_report 1 "ERROR Extracting data: $job_list"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetDescription { project job_list db_display db_display_format } {
#-----------------------------------------------------------------------
#d_sum Return a formatted list of jobs in report format
#d_desc This command takes a list of job numbers, a list of item names \
and a format description, and returns a report as a Tcl list with one \
job description (generated according to the lists of items and formats) \
per item.
#d_desc This can be used to append all database information into one \
string for display.
#d_arg project The alias for the project to access
#d_arg job_list List of job ids
#d_arg db_display A list of the database parameters to be displayed
#d_arg db_display_format A list of the field widths (as integers) to \
use for displaying the items in the db_display list.
  if { [regexp ^OK$ [db_handler_request desc_list \
	  "DbReturnJobs" $project -list $job_list -list $db_display \
			 -list $db_display_format]] } {
      return $desc_list
  }
  db_client_report 1 "ERROR Extracting data: $desc_list"
  return ""
}

#----------------------------------------------------------------------
proc ::dbClientAPI::GetNotebook { project jobid } {
#----------------------------------------------------------------------
#d_sum Return notebook path 
    
    if { [regexp ^OK [db_handler_request message \
          "GetNotebook" $project $jobid]] } {
      return $message
  } else {
      db_client_report 1 "ERROR Extracting data: $message"
      return ""
  }
}

#d_index_title Input and Output Files For Jobs
#d_intro_title Input and Output Files For Jobs
#d_intro Commands for adding, listing and removing references to \
the input and output files for jobs.

#-----------------------------------------------------------------------
proc ::dbClientAPI::AddInputFile { project job_id filen { alias "" } } {
#-----------------------------------------------------------------------
#d_sum Add a file to the list of input files for a job
#d_desc This command wraps the AddFile command.
#d_arg project Alias of the project database
#d_arg job_id  Number of the job for which the data is being updated
#d_arg filen   Name of the file to add
#d_arg alias   (optional) Name of a project alias to associate with the file
    if { [regexp ^OK$ \
	       [db_handler_request value "AddInputFile" \
		    $project $job_id $filen $alias ]] } {
	 return $value
     }
    db_client_report 1 "ERROR Extracting data: $value"
    return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::AddOutputFile { project job_id filen { alias "" } } {
#-----------------------------------------------------------------------
#d_sum Add a file to the list of output files for a job
#d_desc This command wraps the AddFile command.
#d_arg project Alias of the project database
#d_arg job_id  Number of the job for which the data is being updated
#d_arg filen   Name of the file to add
#d_arg alias   (optional) Name of a project alias to associate with the file
    if { [regexp ^OK$ \
	       [db_handler_request value "AddOutputFile" \
		    $project $job_id $filen $alias ]] } {
	 return $value
     }
    db_client_report 1 "ERROR Extracting data: $value"
    return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetListofRecords { project joblist itemlist } {
#-----------------------------------------------------------------------
#d_sum Return a list of records
#d_desc This returns the values of multiple data items for a list of given jobs in the specified project database. The argument list should consist of keys. A list of the corresponding values will be returned.
#d_desc Retrieving multiple data items of multiple jobs in a single GetData command is recommended as this minimises the number of socket transactions required to fetch the data from the server.
#d_arg project Alias of the project database
#d_arg job_id  Number of the job for which the data is being fetched
#d_arg item1   Item name to get the value of
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { [regexp ^OK$ \
	  [db_handler_request value "DbGetListofRecords" \
	       $project -list $joblist -list $itemlist]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetFileList { project jobid type } {
#-----------------------------------------------------------------------
#d_sum Return a list of files associated with a job. type can be 'INPUT' or 'OUTPUT'
#d_arg project Alias of the project database
#d_arg jobid Number of the job
#d_arg type 'INPUT' or 'OUTPUT'
    if { [regexp ^OK$ \
	  [eval db_handler_request value "GetFiles" \
	       $project $jobid $type]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListInputFiles { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return a list of input files for a given job.
#d_arg project Alias of the project database
#d_arg jobid Number of the job

    if { [regexp ^OK$ \
	  [eval db_handler_request value "ListInputFiles" \
	       $project $jobid ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListOutputFiles { project jobid } {
#-----------------------------------------------------------------------
#d_sum Return a list of output files for a given job.
#d_arg project Alias of the project database
#d_arg jobid Number of the job

    if { [regexp ^OK$ \
	  [eval db_handler_request value "ListOutputFiles" \
	       $project $jobid ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}


#d_index_title Storing and retrieving subjobs
#d_intro_title Storing and retrieving subjobs
#d_intro These commands dealing with subjobs

#-----------------------------------------------------------------------
proc ::dbClientAPI::AddSubJob { project jobid taskname title } {
#-----------------------------------------------------------------------
#d_sum Add a subjob to an existing job in the project
#d_arg project Alias of the project database
#d_arg jobid Number of the parent job
#d_arg taskname Name of the task or application associated with the job
#d_arg title User-readable title

    if { [regexp ^OK$ \
	      [eval db_handler_request value [list "AddSubJob" \
		   $project $jobid $taskname $title]]] } {
      return $value
  }
  db_client_report 1 "ERROR Creating subjob: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::SelectSubJobs { project jobid item pattern} {
#-----------------------------------------------------------------------
#d_sum Return a list of jobs matching a regular expression.
#d_arg project Alias of the project database
#d_arg jobid Number of the job
#d_arg item    Item name being searched on
#d_arg pattern Regular expression pattern to search on

    if { [regexp ^OK$ \
	  [eval db_handler_request value "SelectSubJobs" \
	       $project $jobid $item $pattern]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::HasSubJobs { project jobid } {
#-----------------------------------------------------------------------
#d_sum Check if a job has sub jobs.
#d_desc This command returns 1 if the specified job has an associated \
subjob database, and 0 if there are no subjobs or if an error occurred.
#d_arg project Alias of the project database
#d_arg jobid Number of the job

    if { [regexp ^OK$ \
	  [eval db_handler_request value "HasSubJobs" \
	       $project $jobid ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return 0
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::ListJobswithsubjobs { project } {
#-----------------------------------------------------------------------
#d_sum Return a list of jobs which have subjobs
#d_arg project Alias of the project database


    if { [regexp ^OK$ \
	  [eval db_handler_request value "ListJobswithsubjobs" \
	       $project ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#d_index_title Generic commands for interacting with a SQL Database for a particular project
#d_intro_title Generic commands for interacting with a SQL Database for a particular project
#d_intro These commands allow interactions with the SQLite database \
backend which stores knowledge base data.

#-----------------------------------------------------------------------
proc ::dbClientAPI::NewTableRecord { project table args} {
#-----------------------------------------------------------------------
#d_sum Insert a new record in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg args attribute-value pairs of the table


 if { [regexp ^OK$ \
	  [eval db_handler_request value "NewTableRecord" \
	       $project $table $args ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteTableRecord { project table recordid} {
#-----------------------------------------------------------------------
#d_sum Insert a new record in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg args attribute-value pairs of the table


 if { [regexp ^OK$ \
	  [eval db_handler_request value "DeleteTableRecord" \
	       $project $table $recordid ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteTableRecords { project table condition} {
#-----------------------------------------------------------------------
#d_sum Insert a new record in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg args attribute-value pairs of the table


 if { [regexp ^OK$ \
	  [db_handler_request value "DeleteTableRecords" \
	       $project $table $condition ]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::SetTableData { project table tableid attribute value} {
#-----------------------------------------------------------------------
#d_sum Update a record in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg tableid the id of the record in the table
#d_arg attribute the attribute of the value
#d_arg value

 if { [regexp ^OK$ \
	  [eval db_handler_request result "SetTableData" \
	       $project $table $tableid $attribute $value]] } {
      return $result
  }
  db_client_report 1 "ERROR Extracting data: $result"
  return ""
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetTableData { project table tableid attribute } {
#-----------------------------------------------------------------------
#d_sum Get value of an attribute in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg tableid the id of the record in the table
#d_arg attribute the attribute of the value

 if { [regexp ^OK$ \
	  [eval db_handler_request result "GetTableData" \
	       $project $table $tableid $attribute]] } {
      return $result
  }
  db_client_report 1 "ERROR Extracting data: $result"
  return ""
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetAllTableRecords { project table attributes } {
#-----------------------------------------------------------------------
#d_sum Get value of an attribute in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg attributes list of attributes

 if { [regexp ^OK$ \
	  [db_handler_request value "GetAllTableRecords" \
	       $project $table -list $attributes]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""

}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetTableRecords { project table attributes condition} {
#-----------------------------------------------------------------------
#d_sum Get value of an attribute in a table
#d_arg project Alias of the project database
#d_arg table table name
#d_arg attributes list of attributes

 if { [regexp ^OK$ \
	  [db_handler_request value "GetTableRecords" \
	       $project $table -list $attributes $condition]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""

}


#-----------------------------------------------------------------------
proc ::dbClientAPI::GetTablePrimaryKey { project table condition } {
#-----------------------------------------------------------------------
#d_sum Get the primary key of a record in a table
#d_arg table table name
#d_arg condition the where clause of SQL  

 if { [regexp ^OK$ \
	  [db_handler_request result "GetTablePrimaryKey" \
	       $project $table $condition]] } {
      return $result
  }
  db_client_report 1 "ERROR Extracting data: $result"
  return ""
}


#d_index_title  commands for Knowledge base
#d_intro_title  commands for Knowledge base
#d_intro These commands allow interactions with Knowledge base table \
backend which stores knowledge base data.

#---------------------------------------------------------------------
proc ::dbClientAPI::DefineDataset { project DatasetName MTZfile Fmean SigFmean args } {
#---------------------------------------------------------------------
#d_sum Make a new dataset record with values set for each data item.
#d_arg project project alias
#d_arg DatasetName An identifier for the dataset
#d_arg MTZfile The name of the source MTZ file that holds the reflection data for the dataset
#d_arg Fmean MTZ column label indicates the column that holds the mean structure factors
#d_arg SigFmean MTZ column label indicates the column with sigmas corresponding to the Fmean values
#-dano <Dano><SigDano> 
#     <Dano> MTZ column label with anomalous difference data
#     <SigDano> MTZ column label with the sigmas for the anomalous difference data
#-mtz <MTZCrystalName> <MTZDatasetName>
#     <MTZCrystalName> The name of the crystal that the data belong to in the MTZ file
#     <MTZDatasetName> The name of the dataset that the data belong to in the MTZ file

    # Process the arguments
    set n [llength $args]
    set j 0

    while { $j < $n } {
	switch -- [lindex $args $j] {
	    "-dano" {
		incr j
		set Dano [lindex $args $j]
		incr j
		set SigDano [lindex $args $j]
	    }
	    "-mtz" {
		incr j
		set MTZCrystalName [lindex $args $j]
		incr j
		set MTZDatasetName [lindex $args $j]
	    }
	}
	incr j
    }
   
    if { [lsearch $args "-dano"] > -1 && [lsearch $args "-mtz" ] > -1  } {
	return [NewTableRecord $project Dataset DatasetName $DatasetName MTZfileProject $project MTZfileName $MTZfile Fmean $Fmean SigFmean $SigFmean Dano $Dano SigDano $SigDano MTZCrystalName $MTZCrystalName MTZDatasetName $MTZDatasetName]   } elseif { [lsearch $args "-dano" ] >-1 && [lsearch $args "-mtz"] == -1  } {	    return [NewTableRecord $project Dataset DatasetName $DatasetName MTZfileProject $project MTZfileName $MTZfile Fmean $Fmean SigFmean $SigFmean Dano $Dano SigDano $SigDano]
	} elseif  { [lsearch $args "-dano"] == -1 && [lsearch $args "-mtz"] > -1 } { return [NewTableRecord $project Dataset DatasetName $DatasetName MTZfileProject $project MTZfileName $MTZfile Fmean $Fmean SigFmean $SigFmean MTZCrystalName $MTZCrystalName MTZDatasetName $MTZDatasetName]
	} else {
	    return [NewTableRecord $project Dataset DatasetName $DatasetName MTZfileProject $project MTZfileName $MTZfile Fmean $Fmean SigFmean $SigFmean]
	}
}

#----------------------------------------------------------------------
proc ::dbClientAPI::ListDatasets { project } {
#----------------------------------------------------------------------
#d_sum Return a list of the DatasetNames in the knowledge base
#d_arg project alias of the project
    return [GetAllTableRecords $project Dataset DatasetName ]    
}

#----------------------------------------------------------------------
proc ::dbClientAPI::GetDatasetId { project DatasetName } {
#----------------------------------------------------------------------
#d_sum get the dataset id 
#d_arg project alias of project
#d_arg DatasetName 
    set condition "where DatasetName = '$DatasetName'"
    return [GetTablePrimaryKey $project Dataset $condition]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DeleteDataset { project DatasetName } {
#-----------------------------------------------------------------------
#d_sum Remove a dataset 
#d_arg project alias of the project
#d_arg DatasetName 

    set tableid [GetDatasetId $project $DatasetName]
    DeleteTableRecord $project Dataset $tableid
    set condition "where DatasetId = $tableid"
    DeleteTableRecords $project HA $condition
    # return what??
} 

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetDatasetAttribute { project DatasetName itemName } {
#-----------------------------------------------------------------------
#d_sum Return the value of a specified data item in the Dataset table for a particular dataset, or of the current HA substructure associated with the dataset.
#d_arg project alias of the project
#d_arg DatasetName
#d_arg itemName attribute of Dataset table

    set tableid [GetDatasetId $project $DatasetName]
    return [GetTableData $project Dataset $tableid $itemName]
}

#--------------------------------------------------------------------------
proc ::dbClientAPI::GetHAAttribute { project HAid itemName } { 
#---------------------------------------------------------------------------
#d_sum Return the value of a specified data item in the HA table    
#d_arg project alias of project
#d_arg HAid record id in HA table
#d_arg itemName attribute of HA table
    return [GetTableData $project HA $HAid $itemName]
}

#--------------------------------------------------------------------------
proc ::dbClientAPI::NewHASubstructure { project HAfile DatasetName args } {
#---------------------------------------------------------------------------
#d_sum Defines a new HA substructure, with values set for each data item
#d_arg HAfile name of the file containing the data for the current heavy atom substructure in CCP4i's .ha format.
#d_arg DatasetName
#d_arg 
# -job jobnumber the number of a job in the tracking database from which this file was generated.
    set datasetid [GetDatasetId $project $DatasetName]
    if { [lsearch $args "-job"] >-1 } {
	set jobnumber [lindex $args 1]
	return [NewTableRecord $project HA HAfileProject $project HAfileName $HAfile JobNumber $jobnumber DatasetId $datasetid]
    } else {
    return [NewTableRecord $project HA HAfileProject $project HAfileName $HAfile DatasetId $datasetid]
    }
}

#--------------------------------------------------------------------------
proc ::dbClientAPI::ListDatasetHASubstructures { project DatasetName } { 
#--------------------------------------------------------------------------
#d_sum Return a list of the HA substructure ids associated with a particular dataset.
#d_arg project alias of the project
#d_arg DatasetName 

    set datasetid [GetDatasetId $project $DatasetName]
    set condition "where DatasetId = $datasetid"
    return [GetTableRecords $project HA HA_Id $condition ] 
}

#-------------------------------------------------------------------------
proc ::dbClientAPI::UpdateHAForDataset { project DatasetName HAid } {
#-------------------------------------------------------------------------
#d_sum Update current HA for a specified dataset 
#d_arg project alias of the project
#d_arg DatasetName
#d_arg HAid 
    set datasetid [GetDatasetId $project $DatasetName]
    return [SetTableData $project Dataset $datasetid CurrentHA $HAid]
}


#d_index_title Interacting with an SQL Database for a particular project
#d_intro_title Interacting with an SQL Database for a particular project
#d_intro These commands allow interactions with the SQLite database \
backend which store addional job data.


#-----------------------------------------------------------------------
proc ::dbClientAPI::SetJobQuality { project jobid quality} {
#-----------------------------------------------------------------------
#d_sum Set Job quality data
#d_arg project Alias of the project database
#d_arg jobid Number of the job
#d_arg quality the value could be 1, 0 or -1 which indicates good, marginal and bad.

 if { [regexp ^OK$ \
	  [eval db_handler_request value "SetJobQuality" \
	       $project $jobid $quality]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetJobQuality { project jobid } {
#-----------------------------------------------------------------------
#d_sum Get Job quality data
#d_arg project Alias of the project database
#d_arg jobid Number of the job

    return [GetSQLdbData $project $jobid JobQuality]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::HasSQLdb { project } {
#-----------------------------------------------------------------------
#d_sum Check if a project has an associated SQL database
#d_desc Query whether there is an SQLite database associated with the \
named project. Returns 1 if there is an associated SQLite db, and zero \
otherwise. Zero is also returned in the event that the request failed \
for some other reason (e.g. the project hasn't been opened yet).
#d_arg project Alias of the project database

 if { [regexp ^OK$ [eval db_handler_request value "HasSQLdb" $project]] } {
     if { [regexp -- "True" $value] } {
	 # There is an associated SQLite database
	 return 1
     } else {
	 # No associated SQLite database
	 return 0
     }
  }
  # Handler reported an error
  db_client_report 1 "ERROR Extracting data: $value"
  return 0
}

#----------------------------------------------------------------------
proc ::dbClientAPI::GetAllSQLdbData { project itemlist} {
#-----------------------------------------------------------------------
#d_sum Get all data from sql db
#d_arg project Alias of the project database
#d_arg itemlist the attributes of tables

 if { [regexp ^OK$ \
	  [db_handler_request value "GetAllSQLdbData" \
	       $project -list $itemlist]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}

#----------------------------------------------------------------------
proc ::dbClientAPI::GetSQLdbData { project jobid items} {
#-----------------------------------------------------------------------
#d_sum Get all data from sql db
#d_arg project Alias of the project database
#d_arg jobid Number of the job
#d_arg items item for the job

 if { [regexp ^OK$ \
	  [eval db_handler_request value "GetSQLdbData" \
	       $project $jobid $items]] } {
      return $value
  }
  db_client_report 1 "ERROR Extracting data: $value"
  return ""
}




#d_index_title Interacting with a central SQL Database
#d_intro_title Interacting with a central SQL Database
#d_intro These commands allow interactions with the SQLite database \
backend.

#-----------------------------------------------------------------------
proc ::dbClientAPI::OpenDBsql { dbname dir } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the serve
#d_arg job_id  Number of the job for which the data is being s
# Use eval to invoke the command, to stops the arglist concatenated
# into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request message "OpenDB" \
	       $dbname $dir]] } {
      db_client_report 1 "ERROR Updating database: $message"
      return 0
  }
  return 1
}


#-----------------------------------------------------------------------
proc ::dbClientAPI::SetJobDatasql { job_id args } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the serve
#d_arg job_id  Number of the job for which the data is being s
# Use eval to invoke the command, to stops the arglist concatenated
# into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request message "SetJobData" \
	       $job_id $args]] } {
      db_client_report 1 "ERROR Updating database: $message"
      return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::NewProjectsql { projectname } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the server.
#d_arg dbname Alias of the project database
#d_arg dir  Number of the job for which the data is being set
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request pid "NewProject" \
	       $projectname]] } {
      db_client_report 1 "ERROR Updating database: $pid"
      return 0
  }
  return $pid
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::NewJobsql { projectname } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the server.
#d_arg dbname Alias of the project database
#d_arg dir  Number of the job for which the data is being set
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request jobid "NewJob" \
	       $projectname]] } {
      db_client_report 1 "ERROR Updating database: $jobid"
      return 0
  }
  return $jobid
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::GetJobDatasql { jobid args } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the server.
#d_arg dbname Alias of the project database
#d_arg dir  Number of the job for which the data is being set
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request value "GetJobData" \
	       $jobid $args]] } {
      db_client_report 1 "ERROR Updating database: $value"
      return 0
  }
  return $value
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::CloseDBsql { } {
#-----------------------------------------------------------------------
#d_sum Set the values of one or more data items
#d_desc This sets the values of multiple data items for a particular job \
in the specified project database. The argument list should consist of \
key-value pairs.
#d_desc Setting multiple data items in a single SetData command is \
recommended as this minimises the number of socket transactions required \
to send the data to the server.
#d_arg dbname Alias of the project database
#d_arg dir  Number of the job for which the data is being set
  # Use eval to invoke the command, to stops the arglist concatenated
  # into a single argument
  if { ![regexp ^OK$ \
	  [eval db_handler_request message "CloseDB" \
	       ]] } {
      db_client_report 1 "ERROR Updating database: $message"
      return 0
  }
  return 1
}

#d_index_title Client API Configuration
#d_intro_title Client API Configuration
#d_intro These are commands for configuring attributes of the client API.

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbGetTimeout { } {
#-----------------------------------------------------------------------
#d_sum Returns the timeout used in db_handler_request
#d_desc The timeout is the length of time that the client API will wait \
after sending a request to the handler, before giving up and returning \
control to the client application.
#d_desc The timeout is a number of milliseconds, with a minimum value \
of zero.
    variable handler
    return $handler(DB_TIMEOUT)
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::DbSetTimeout { timeout } {
#-----------------------------------------------------------------------
#d_sum Set the timeout used in db_handler_request
#d_arg timeout Length of the timeout in milliseconds
    variable handler
    if { $timeout < 0 } {
	set handler(DB_TIMEOUT) 0
    } else {
	set handler(DB_TIMEOUT) $timeout
    }
    return $handler(DB_TIMEOUT)
}

#d_index_title Internal Procedures
#d_intro_title Internal Procedures
#d_intro Functions used internally to the client API.

#-----------------------------------------------------------------------
proc ::dbClientAPI::close_db_connection { } {
#-----------------------------------------------------------------------
#d_sum Internal procedure
#d_desc Remove socket connection and reset internal parameters
  variable handler
  if { $handler(DB_CONNECTION_STATUS) } {
    catch { close $handler(DB_SOCKET) }
  }
  set handler(DB_SOCKET) ""
  set handler(DB_CONNECTION_STATUS) 0
  return
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_handler_request { messageVar command args } {
#-----------------------------------------------------------------------
#d_sum Send a request to the database handler and return the response.
#d_desc The request consists of the all arguments in args, excluding the \
After the request is sent to the handler this procedure waits \
until a response is recieved i.e. it operates in a pseudo-synchronous \
manner.
#d_desc Responses from the handler consist of Tcl lists - the first \
element in the list is the return value of this procedure, the \
remainder is returned in the variable named by the last argument in \
args.
#d_desc In case of failure, ERROR will be returned.
#d_arg messageVar Name of variable used to return output to the \
calling procedure
#d_arg command Command to be sent to the handler

  global ::dbClientAPI::handler

  # Echo input
  db_client_report 1 "db_handler_request:"
  db_client_report 1 "messageVar: $messageVar"
  db_client_report 1 "command   : $command"
  db_client_report 1 "args      : $args"

  # Determine the variable to send any messages back in
  upvar 1 $messageVar message
  set message ""

  # Check for connection
  if { ! $handler(DB_CONNECTION_STATUS) } {
    db_client_report 1 "db_handler_request: currently no connection to handler"
    return 0
  }

  # Set up an id for the request
  # This will be sent back by the handler as part of a response
  set id ""
  incr ::dbClientAPI::handler(REQUEST_NUMBER)
  append id "request\#" "$::dbClientAPI::handler(REQUEST_NUMBER)"
  db_client_report 1 "Request   : $::dbClientAPI::handler(REQUEST_NUMBER)"
  # Add to the list of requests
  lappend ::dbClientAPI::handler(REQUEST_LIST) $id
  db_client_report 1 "db_handler_request: current request list: $::dbClientAPI::handler(REQUEST_LIST)"

  # Build the request and wrap it in pseudo-XML
  set request [eval WrapDbRequest $id $command $args]
  db_client_report 1 "db_handler_request: request is \"$request\""
  # Store the command for reporting elsewhere
  set ::dbClientAPI::handler(REQUEST_CMD) $request

  # Check we have a connection to the handler
  if { ![info exists ::dbClientAPI::handler(DB_SOCKET)] } {
    db_client_report 1 "db_handler_request: no connection to handler"
    set message "No connection to handler"
    return "ERROR"
  }
  set client $::dbClientAPI::handler(DB_SOCKET)
  set timeout $::dbClientAPI::handler(DB_TIMEOUT)

  set line ""

  # Send the request to the server
  ##puts "db_handler_request: request \"$request\""
  if { ![catch { puts $client $request } msg] } {
    db_client_report 1 "db_handler_request: request sent ok"
    # Wait for response
    # This is done by waiting for an update on handler(REQUEST_STATUS)
    # We also set up a timeout to prevent waiting forever e.g. if
    # there is some problem
    set ::dbClientAPI::handler(REQUEST_ID) $id
    set ::dbClientAPI::handler(REQUEST_STATUS_$id) 1
    after $timeout set ::dbClientAPI::handler(REQUEST_STATUS_$id) "TIMEOUT"
    db_client_report 1 "db_handler_request: waiting for response ..."
    vwait ::dbClientAPI::handler(REQUEST_STATUS_$id)
    after cancel set ::dbClientAPI::handler(REQUEST_STATUS_$id) "TIMEOUT"
    if { $::dbClientAPI::handler(REQUEST_STATUS_$id) == "TIMEOUT" } {
       db_client_report 1 "db_handler_request: ... timed out waiting for response to $id"
       set message "Handler response timed out waiting for $id"
       set status ERROR
    } else {
       db_client_report 1 "db_handler_request: ... response received for $id"
       set message $::dbClientAPI::handler(REQUEST_RESPONSE_$id)
       set status $::dbClientAPI::handler(REQUEST_RESPONSE_STATUS_$id)
       db_client_report 1 "db_handler_request: got back status \"$status\" \"$message\""
    }
    return $status
  } else {
    db_client_report 1 "db_handler_request: failed to send request"
    set message "Failed to send request: $msg"
    return "ERROR" 
  }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_handler_processResponse { client } {
#-----------------------------------------------------------------------
#d_sum Handler for messages recieved from the database server.
#d_desc This processes messages recieved from the handler process via \
the socket connection. Messages should fall into two catergories, \
either: 1. responses to requests sent via db_handler_request, or \
2. unsolicited "broadcast" messages from the handler.
#d_arg client Socket id
    # Handle messages from the server back to the client
    global ::dbClientAPI::handler

    db_client_report 1 "db_handler_processResponse: invoked with client $client"
    db_client_report 1 "*** REQUEST_LIST: $handler(REQUEST_LIST)"

    # Called whenever the socket is readable
    set line ""
    if { ![catch { set count [gets $client line] } msg] } {
	db_client_report 1 \
	    "db_handler_processResponse: from server: \"$line\" msg: $msg"

	# Check for count from gets less than zero
        # If varName is specified and an empty string is returned in
        # varName  because of end-of-file or because of insufficient
        # data in nonblocking mode, then the  return  count  is  -1.
	# Note also that at EOF gets returns a blank string but doesn't
	# consume any input, so it is possible to end up in an
	# infinite loop in these situations
	if { $count < 0 } {
	    # Check for eof
	    if { [eof $client] } {
		db_client_report 1 "db_handler_processResponse: end of file"
		db_client_report 1 "*** Connection to the server has been lost ***"
		# FIXME: this should invoke some catastrophe handling
		# procedure
		close_db_connection
	    }
	    db_client_report 1 \
		"db_handler_processResponse: count < 0, discarding"
	    return
	}

	# Are we waiting for a response?
        if { [llength $handler(REQUEST_LIST)] > 0 } {
	    # Attempt to unwrap the response and check if the ids match
	    if { [UnwrapDbResponse $line status result response_id] } {
		# We are expecting a message from the server in
		# response to a request
		db_client_report 1 \
		    "db_handler_processResponse: id of response = $response_id"
		if { [set k [lsearch $handler(REQUEST_LIST) $response_id]] > -1 } {
		    # The id is in the list
		    set handler(REQUEST_RESPONSE_$response_id) $result
		    set handler(REQUEST_RESPONSE_STATUS_$response_id) $status
		    set handler(REQUEST_STATUS_$response_id) 0
		    # Store the data for retrieval
		    set handler(RESPONSE_STATUS) $status
		    set handler(RESPONSE_RESULT) $result
		    # Remove the request from the list
		    set handler(REQUEST_LIST) [lreplace $handler(REQUEST_LIST) $k $k]
		    return
		} else {
		    # Id not in the list
		    db_client_report 1 \
			"db_handler_processResponse: response id not in list"
		}
	    } else {
		db_client_report 1 \
		    "db_handler_processResponse: this doesn't appear to be a response"
	    }
	} else {
	    db_client_report 1 "db_handler_processResponse: no requests pending"
	}

	# Test for broadcast message
	if { [UnwrapDbBroadcast $line message] } {
	    db_client_report 1 \
		"db_handler_processResponse: broadcast message from the handler"
	    # call updateProject
	    if { $handler(CACHED_PROJECT) != "" } {
		if { [lindex $message 1] == $handler(CACHED_PROJECT) && [regexp "^Update" [lindex $message 0]] } {
		    set id [lindex $message 2]
		    if { [lindex $message 3] == "job deleted" } {
			deleteCachedJob $id
		    } else {
			updateCachedJob $id
		    }
		}
	    }
	    
	    if { $handler(DB_BROADCAST_CALLBACK) != "" } {

		# Issue callback
		db_client_report 1 \
		    "db_handler_processResponse: invoking callback \"$handler(DB_BROADCAST_CALLBACK)\""
		if { [catch { $handler(DB_BROADCAST_CALLBACK) "$message" } errmsg] } {
		    # Callback failed
		    db_client_report 1 \
			"db_handler_processResponse: callback failed: $errmsg"
		}
		# Drop out now
		return
	    }
	} else {
	    db_client_report 1 "db_handler_processResponse: not a broadcast message"
	}

	# At this point we don't know what the message is
	db_client_report 1 "db_handler_processResponse: unrecognised message"
	return

    } else {
	# The initial read caught an error
	db_client_report 1 "db_handler_processResponse: error: $msg"
        set handler(ERROR_MESSAGE) $msg
	return
    }
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_client_requestsPending { } {
#-----------------------------------------------------------------------
#d_sum Returns the number of pending requests within the client API
#d_desc This procedure allows the wait status of the API to be \
determined by the calling application.
#d_desc It returns the number of requests queued up and waiting for \
responses from the database server.
  variable handler
  return [llength $handler(REQUEST_LIST)] 
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_client_error { } {
#-----------------------------------------------------------------------
#d_sum Return the last error message from inside the client API
#d_desc This returns the error message (blank if no error occurred since \
last time the error was read) and resets the message.
  variable handler
  set msg $handler(ERROR_MESSAGE)
  set handler(ERROR_MESSAGE) {}
  return $msg
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_client_response_data { } {
#-----------------------------------------------------------------------
#d_sum Return the results from the last handler response.
#d_desc This returns a list with two elements.
#d_desc The first element is the status returned from the handler in \
response to the last request sent via the client API.
#d_desc The second element is the result for that request.
  variable handler
  return [list $handler(RESPONSE_STATUS) $handler(RESPONSE_RESULT)]
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_get_handler_port { args } {
#-----------------------------------------------------------------------
#d_sum Return the port number for the active database handler process
#d_desc This is a fast and dirty way to acquire the port number for \
the database handler process - it looks at the handler lock file and \
tries to read the port number from it.
#d_desc The lockfile is called dbccp4i.LOCK and has the following content:
#d_desc port number is:4090
#d_desc The procedure will try multiple attempts to get the port number \
unless the -nowait option is specified (in which case it will try just \
once). Multiple tries are used when the handler is starting up and the \
lock file is not immediately available.
#d_desc The procedure returns the port number, or -1 if a port number \
cannot be acquired.
#d_opt0 -nowait
#d_opt1 Only try once to get the port number
#d_opt0 -directories
#d_opt1 Name of the (non-default) directories data file

    set port -1
    set thistry 0
    set ntries 1000
    set wait_time 10

    if { [lsearch $args "-nowait" ] > -1 } {
	set ntries 1
	set wait_time 0
    }
    if { [set k [lsearch $args "-directories"]] > -1 } {
	incr k
	set dirsfile [lindex $args $k]
	set lockfile "[file join [GetDotCCP4] [file tail [file rootname $dirsfile]]]_dbccp4i.LOCK"
    } else {
	set lockfile [file join [GetDotCCP4] dbccp4i.LOCK]
    }

    while { $thistry < $ntries } {
	if { [file exists $lockfile] } {
	    # Open and read the lockfile contents
	    db_client_report 1 "db_get_handler_port: opening lockfile"
	    set fp [open $lockfile "r"]
	    if { [gets $fp line] > 0 } {
		db_client_report 1 "db_get_handler_port: line from lockfile is $line"
		set port [lindex [split $line ":"] end]
	    }
	    close $fp
	    db_client_report 1 "db_get_handler_port: port $port"
	    # Test the port
	    # This is a little messy but does the job for now
	    if { ![catch { set sock [socket localhost $port] } err] } {
		# Connected - issue status request
		fconfigure $sock -buffering line
		set request [eval WrapDbRequest 0 "DbRequestStatus"]
		db_client_report 1 "Request is: $request"
		puts $sock $request
		gets $sock line
		db_client_report  1 "Response is $line"
		if { [UnwrapDbResponse $line status result response_id] } {
		    if { [regexp "^OK$" $status] } {
			# Verified that the server is active
			# Close socket and return port number
			db_client_report 1 "Socket opened and server is active - ok"
			## Before close socket, disconnect handler
			set request [eval WrapDbRequest 0 "DbDisconnect"]
			db_client_report 1 "Request is: $request"
			puts $sock $request
			close $sock
			return $port
		     }
		}
		# No verification
		db_client_report 1 "Socket opened but server is inactive?"
		close $sock
	    }
	    # Failed to open socket
	    db_client_report 1 \
		"db_get_handler_port: failed to open socket, retry \#$thistry..."
	}
	# Wait for a while then retry
	after $wait_time
	incr thistry
    }
    db_client_report 1 "db_get_handler_port: timed out waiting for lockfile \"$lockfile\""
    return -1
}

#-----------------------------------------------------------------------
proc ::dbClientAPI::db_client_report { code message } {
#-----------------------------------------------------------------------
#d_sum Report an error or message from the API layer
#d_desc The reporting function resets the log file for each new invocation \
of the client API.
#d_arg code A code number, not currently used
#d_arg message The message to echo to the logfile
    variable handler
    if { ! $::dbClientAPI::handler(DB_LOG) } {
	set ::dbClientAPI::handler(DB_LOG) 1
	# Reset the file
	if { [catch {
	    set logfile [open [file join [GetDotCCP4] dbclientapi.log] "w"]
	} err] } {
	    puts "ERROR unable to make logging file [file join [GetDotCCP4] dbclientapi.log]"
	    return
	}
	puts $logfile "Log from dbClientAPI.tcl: reset [clock format [clock seconds]]"
	close $logfile
    }
    # Write the message
    catch {
	set logfile [open [file join [GetDotCCP4] dbclientapi.log] "a"]
	puts $logfile $message
	close $logfile
    }
    return
}







