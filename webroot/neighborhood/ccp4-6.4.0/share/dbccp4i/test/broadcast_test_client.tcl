#############################################################
#
# broadcast_test_client.tcl
#
# Client application that tests the broadcast messages received
# from the handler via the Tcl client API.
#
# CVS_Id $Id: broadcast_test_client.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " broadcast_test_client"
puts " Test handler broadcasts via the Tcl client API"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Procedures
proc exit_test { status } {
    # Do cleanup and exit
    global test_project
    global test_project_dir
    # Issue the close command (don't worry if it fails)
    catch { CloseProject $test_project }
    # Delete the project (don't worry if it fails)
    catch { DeleteProject $test_project }
    # Shut down the handler
    if { [DbVerifyConnection] } {
	puts -nonewline "Issuing the shutdown command to the handler..."
	DbShutdown
	puts "done"
    }
    # Pause for a second
    after 1000
    # Remove the test directory from this run
    if { [file exists $test_project_dir] &&  [file isdirectory $test_project_dir] } {
	puts -nonewline "Removing test directory $test_project_dir..."
	file delete -force $test_project_dir
	puts "done"
    }
    puts ""
    puts "=========================================================="
    puts -nonewline " broadcast_test_client: finished"
    if { ! $status } {
	puts " (OK)"
    } else {
	puts " (ERROR)"
    }
    puts "=========================================================="
    exit $status
}

proc report_result { } {
    # Print last data from handler
    set data [db_client_response_data]
    if { [llength $data] == 2 } {
	puts "Last status: [lindex $data 0]"
	puts "Last result: [lindex $data 1]"
    }
}

proc generate_project_name { { prefix TEST } } {
    # Generate a project name based on a prefix (assumed
    # to be "TEST" if not otherwise supplied) plus the date and
    # time expressed as a string

    # Pause for 1 second (this is resolution of the time format)
    after 1000
    # Build the project name string
    return "[subst $prefix]_[clock format [clock seconds] -format %G%j%H%M%S]"
}

proc generate_project_dir { projectname } {
    global env
    return [file join $env(CCP4_SCR) $projectname]
}

########################################################################
# Support procedures for checking locks and access
########################################################################

proc modify_database { project_dir } {
    # Update the modification time on the database.def file
    set dbfile [file join $project_dir CCP4_DATABASE database.def]
    update_file_mtime $dbfile
}

proc update_file_mtime { filen } {
    # Update the modification time of a file
    # This is very crude - it copies the file and then
    # overwrites the original with the copy.
    puts "Updating $filen: mtime = [file mtime $filen]"
    if { ![file exists $filen] || ![file isfile $filen] } {
	# Nothing to do
	puts "Error: file not found, or is not a file"
	return
    }
    set filen_copy "[subst $filen].copy"
    after 1000
    set fdf [open $filen "r"]
    set fcp [open $filen_copy "w"]
    while { [gets $fdf line] >= 0 } {
	puts $fcp $line
    }
    close $fdf
    close $fcp
    file rename -force $filen_copy $filen
    puts "$filen: final mtime = [file mtime $filen]"
    return
}

########################################################################
# Procedures for checking the broadcasts
########################################################################

# Globals used for broadcast checking
set expected_broadcast {}
set valid_broadcast {}

proc receive_broadcast { broadcast } {
    # Handler procedure which is invoked by the client API
    # when a broadcast message is recieved from the handler
    global expected_broadcast
    global valid_broadcast
    puts "Broadcast received:"
    foreach item $broadcast {
	puts "\t$item"
    }
    set project [lindex $broadcast 1]
    set job [lindex $broadcast 2]
    set operation [lindex $broadcast 3]
    if { $expected_broadcast == "" } {
	puts "\t-> Nothing expected, received \"$operation\" (ignored)"
	set valid_broadcast 1
    } elseif { $expected_broadcast != $operation } {
	puts "\t-> *** Invalid broadcast ***"
	puts "\t-> Expected \"$expected_broadcast\", got \"$operation\""
	set valid_broadcast 0
    } else {
	puts "\t-> Broadcast ok"
	set valid_broadcast 1
    }
}

proc expect_broadcast { message } {
    # Call this before issuing a command to the client
    # API where a broadcast message is expected to result
    # and specify what the broadcast message is expected
    # to look like
    global expected_broadcast
    global valid_broadcast
    set expected_broadcast $message
    set valid_broadcast -1
}

proc validate_broadcast { } {
    # Call this after issuing a command to the client API
    # It checks the expected broadcast message against
    # the one actually received
    global expected_broadcast
    global valid_broadcast
    # Enter the event loop
    # "valid_broadcast" will be set by the broadcast handler
    if { $valid_broadcast < 0 } {
	# Still waiting for broadcast
	puts "...waiting for broadcast"
	set timeout [after 120000 { puts "...timed out" ; set valid_broadcast 0 } ]
	vwait valid_broadcast
	after cancel $timeout
    }
    if { $valid_broadcast } {
	# Reset the expected broadcast
	set expected_broadcast {}
    }
    return $valid_broadcast
}

########################################################################
# Top level test script
########################################################################

# Set the debugging output level
DbXMLSetDebug 0

# Arguments
set dirsfile ""
set i 0
while { $i < [llength $argv] } {
    set arg [lindex $argv $i]
    switch -- $arg {
	"-directories" {
	    # Use non standard directories.def file
	    incr i
	    set dirsfile [lindex $argv $i]
	}
    }
    incr i
}

# Connect to the handler
puts -nonewline "Connecting to handler..."
set connectCmd [list DbHandlerConnect broadcast_test_client \
		    -broadcastHandler receive_broadcast]
if { $dirsfile != "" } {
    puts "\nUsing non-standard directories.def file: $dirsfile ..."
    lappend connectCmd -directories $dirsfile
}
if { ![eval $connectCmd] } {
    puts "failed: couldn't connect to the handler"
    exit 1
}
puts "done"

# Report settings
puts "Handler information:"
puts "\t[DbInfo]"
puts "Supported database backends:"
puts "\tDef file: [DbSupported def]"
puts "\tSqlite  : [DbSupported sqlite]"

########################################################################
# TEST: Create a new project
########################################################################

# List projects
puts -nonewline "Acquiring listing of projects..."
if { [catch { set projects [ListProjects] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done"

# Generate a unique project name for the tests
set test_project [generate_project_name]
set test_project_dir [generate_project_dir $test_project]
puts "Test project name: $test_project"
puts "Test project dir : $test_project_dir"

# Check whether test project name already exists
if { [lsearch $projects $test_project] > -1 } {
    puts "Test project name already in use"
    exit 1
}

# Check whether test project directory already exists
if { [file exists $test_project_dir] } {
    puts "*** Directory $test_project_dir already exists ***"
    exit_test 1
}

# Create the test project
puts -nonewline "Creating test project $test_project..."
expect_broadcast "NewProject"
if { [catch { set status [CreateProject $test_project $test_project_dir msg] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$msg\""
	exit_test 1
    } else {
	puts "done"
    }
}
if { ![validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: Create a new job
########################################################################

# Add a new job
puts -nonewline "Creating new job in project $test_project..."
expect_broadcast "DbNewJob"
if { [catch { set jobid [NewJob $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    if { $jobid < 1 } {
	puts "failed: API returned job id as $jobid"
	exit_test 1
    } else {
	puts "done"
    }
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: set data items for a job
########################################################################

# Set data items for the job
expect_broadcast "DbSetData"
puts -nonewline "Setting a single data item for job $jobid..."
if { [catch { set status [SetData $test_project $jobid TASKNAME test] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

expect_broadcast "DbSetData"
puts -nonewline "Setting multiple data items for job $jobid..."
if { [catch { set status [SetData $test_project $jobid STATUS \
			      FINISHED TITLE "Test job"] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: add subjob
########################################################################

# Add a subjob to the job
expect_broadcast "AddSubJob"
puts -nonewline "Adding a subjob for job $jobid..."
if { [catch { set subjobid [AddSubJob $test_project $jobid test "This is a test"] } \
	  err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    if { $jobid < 1 } {
	puts "failed: API returned subjob id as $subjobid"
	exit_test 1
    } else {
	puts "done"
    }
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: set data items for a subjob
########################################################################

# Set data items for the subjob
expect_broadcast "DbSetData"
puts -nonewline "Setting a single data item for job $subjobid..."
if { [catch { set status [SetData $test_project $subjobid TASKNAME test] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

expect_broadcast "DbSetData"
puts -nonewline "Setting multiple data items for job $subjobid..."
if { [catch { set status [SetData $test_project $subjobid STATUS \
			      FINISHED TITLE "Test job"] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: delete a subjob
########################################################################

# Set data items for the subjob
expect_broadcast "DbDeleteJob"
puts -nonewline "Deleting subjob $subjobid..."
if { [catch { set status [DeleteJob $test_project $subjobid] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: delete a job
########################################################################

# Set data items for the subjob
expect_broadcast "DbDeleteJob"
puts -nonewline "Deleting job $jobid..."
if { [catch { set status [DeleteJob $test_project $jobid] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: Remove project
########################################################################

# Close the test project
puts -nonewline "Closing test project $test_project..."
if { [catch { set status [CloseProject $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$status\""
	exit_test 1
    } else {
	puts "done"
    }
}

# Remove the test project
expect_broadcast "DeleteProject"
puts -nonewline "Deleting test project $test_project..."
if { [catch { set status [DeleteProject $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$status\""
	report_result
	exit_test 1
    } else {
	puts "done"
    }
}
if { ! [validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# TEST: Project reloaded as readonly
########################################################################

# Generate a unique project name and directory
set test_project [generate_project_name]
set test_project_dir [generate_project_dir $test_project]
puts "Test project name: $test_project"
puts "Test project dir : $test_project_dir"

# Check whether test project name already exists
if { [lsearch $projects $test_project] > -1 } {
    puts "Test project name already in use"
    exit_test 1
}

# Check whether test project directory already exists
if { [file exists $test_project_dir] } {
    puts "*** Directory $test_project_dir already exists ***"
    exit_test 1
}

# Create the test project
puts -nonewline "Creating test project $test_project..."
if { [catch { set status [CreateProject $test_project $test_project_dir msg] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$msg\""
	exit_test 1
    } else {
	puts "done"
    }
}

# Modify the database.def file
expect_broadcast "DbReadonly"
modify_database $test_project_dir
if { ![validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

# Reacquire, close and delete the project
puts -nonewline "Reacquiring project $test_project..."
ReacquireProject $test_project
puts "done"
puts -nonewline "Closing project $test_project..."
catch { CloseProject $test_project }
puts "done"
puts -nonewline "Deleting project $test_project..."
catch { DeleteProject $test_project }
puts "done"
# We need to pause to allow time for the handler to save
# the directories data before the next test
puts -nonewline "Waiting for save..."
after 60000
puts "ok"

########################################################################
# TEST: Directories reloaded as readonly
########################################################################

# Change the modification time of the directories.def file
puts "Changing mtime on directories.def"
set dir_file [file join [GetDotCCP4] \
		  [string tolower $tcl_platform(platform)] \
		  directories.def]
expect_broadcast "DirectoriesReadonly"
update_file_mtime $dir_file
puts -nonewline "Fetching project listing..."
ListProjects
puts "done"
if { ![validate_broadcast] } {
    puts "*** Invalid broadcast ***"
    exit_test 1
}

########################################################################
# End of tests
########################################################################

puts -nonewline "Disconnecting from handler..."
if { [catch { DbHandlerDisconnect } err] } {
    puts "failed: disconnection error \"$err\""
    exit_test 1
}
puts "done"

# Exit everything ok
exit_test 0