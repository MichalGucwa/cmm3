#############################################################
#
# dbccp4i_test_client.tcl
#
# Client application that tests the various database functions
# via the Tcl client API.
#
# CVS_Id $Id: dbccp4i_test_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " dbccp4i_test_client"
puts " Test database functions via the Tcl client API"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Procedures
proc exit_test { status } {
    # Do cleanup and exit
    global test_project_dir
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
    puts -nonewline " dbccp4i_test_client: finished"
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
set connectCmd [list DbHandlerConnect dbccp4i_test_client]
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

# List projects
puts -nonewline "Acquiring listing of projects..."
if { [catch { set projects [ListProjects] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done"

# Check that data is consistent
puts -nonewline "Acquiring NProjects..."
if { [catch { set nprojects [GetNProjects] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done: $nprojects"
if { [llength $projects] != $nprojects } {
    puts "*** NProjects inconsistent with number of projects listed ***"
    exit 1
}

# Generate a unique project name for the tests
set test_project "TEST_[clock format [clock seconds] -format %G%j%H%M%S]"
set test_project_dir [file join $env(CCP4_SCR) $test_project]
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
# Verify that the project exists
if { [lsearch [ListProjects] $test_project] < 0 } {
    puts "*** Test project not in the list of projects ***"
    exit_test 1
}
# List jobs
puts -nonewline "Checking job list..."
if { [catch { set job_list [ListJobs $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    if { [llength $job_list] != 0 } {
	puts "failed: non-zero length for job list (should be empty)"
	exit_test 1
    } else {
	puts "done"
    }
}
# Add a new job
puts -nonewline "Creating new job in project $test_project..."
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
# Check that new job is in the list and is the only job
puts -nonewline "Verifying new job..."
if { [catch { set new_job_list [ListJobs $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    # 1. Job list should contain the new job id
    if { [lsearch $new_job_list $jobid] < 0 } {
	puts "failed: job id $jobid not in list ($new_job_list)"
	exit_test 1
    }
    # 2. Job list should contain exactly one job
    if { [llength $new_job_list] != 1 } {
	puts "failed: job list contains [llength $new_job_list] jobs now ($new_job_list)"
	exit_test 1
    }
    puts "done"
}
# Set data items for the job
puts -nonewline "Setting a single data item for job $jobid..."
if { [catch { set status [SetData $test_project $jobid TASKNAME test] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}
puts -nonewline "Setting multiple data items for job $jobid..."
if { [catch { set status [SetData $test_project $jobid STATUS \
			      FINISHED TITLE "Test job"] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done"
}

# Fetch data from the job
puts -nonewline "Getting a single data item for job $jobid..."
if { [catch { set data [GetData $test_project $jobid TASKNAME] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done: got back \"$data\""
}
puts -nonewline "Getting multiple data items for job $jobid..."
if { [catch { set data [GetData $test_project $jobid TASKNAME TITLE STATUS] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    puts "done: got back \"$data\""
    if { [llength $data] != 3 } {
	puts "Error: GetData returned wrong number of data items"
	exit_test 1
    }
}

# Add a subjob to the job
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

# Check the subjob data
puts -nonewline "Getting title data for subjob $subjobid..."
if { [catch { set data [GetData $test_project $subjobid TITLE] } err] } {
    puts "failed: error message \"$err\""
    exit_test 1
} else {
    if { $data != "This is a test" } {
	puts "failed: API returned title as \"$data\""
	exit_test 1
    } else {
	puts "done: got back \"$data\""
    }
}

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

# Verify that the project has been removed
if { [lsearch [ListProjects] $test_project] > -1 } {
    puts "*** Test project still in the list of projects ***"
    exit_test 1
}

# Finished
puts -nonewline "Disconnecting from handler..."
if { [catch { DbHandlerDisconnect } err] } {
    puts "failed: disconnection error \"$err\""
    exit_test 1
}
puts "done"

# Exit everything ok
exit_test 0