#############################################################
#
# setup_test_project.tcl
#
# Client application that sets up a temporary project based
# on the name and directory supplied via the input arguments
#
# CVS_Id $Id: setup_test_project.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " setup_test_project"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Arguments
puts "setup_test_project: $argv"
if { [llength $argv] != 2 } {
    puts "Usage: setup_test_project <alias> <dir>"
    exit 1
}
set test_project [lindex $argv 0]
set test_project_dir [lindex $argv 1]

# Connect to the handler
puts -nonewline "Connecting to handler..."
set connectCmd [list DbHandlerConnect setup_test_project]
if { ![eval $connectCmd] } {
    puts "failed: couldn't connect to the handler"
    exit 1
}
puts "done"

# Check whether test project name already exists
puts -nonewline "Acquiring listing of projects..."
if { [catch { set projects [ListProjects] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done"
if { [lsearch $projects $test_project] > -1 } {
    puts "*** Test project name already in use ***"
    exit 1
}

# Check whether test project directory already exists
if { [file exists $test_project_dir] } {
    puts "*** Directory $test_project_dir already exists ***"
    exit 1
}

# Create the test project
puts -nonewline "Creating test project $test_project..."
if { [catch { set status \
		  [CreateProject $test_project $test_project_dir msg] \
	      } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$msg\""
	exit 1
    } else {
	puts "done"
    }
}

# Populate the project with some jobs
puts -nonewline "Populating test project..."
for { set i 0 } { $i < 10 } { incr i } {
    if { [catch { set jobid [NewJob $test_project] } err] } {
	puts "failed\nError message \"$err\""
    } else {
	if { $jobid < 1 } {
	    puts "failed\nAPI returned job id as $jobid"
	} else {
	    puts -nonewline " $jobid"
	}
    }
    SetData $test_project $jobid TASKNAME "test" \
	TITLE "Dummy job $i" STATUS "FINISHED"
}
puts "done"

# Add a new job

# Close the test project
puts -nonewline "Closing test project $test_project..."
if { [catch { set status [CloseProject $test_project] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    if { ! $status } {
	puts "failed: API returned \"$status\""
	exit 1
    } else {
	puts "done"
    }
}

# Finished
puts -nonewline "Disconnecting from handler..."
if { [catch { DbHandlerDisconnect } err] } {
    puts "failed: disconnection error \"$err\""
    exit 1
}
puts "done"

# Exit everything ok
exit 0
