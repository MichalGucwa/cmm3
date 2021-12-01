#############################################################
#
# teardown_test_project.tcl
#
# Client application that removes a temporary project based
# on the name and directory supplied via the input arguments
#
# CVS_Id $Id: teardown_test_project.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " teardown_test_project"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Arguments
if { [llength $argv] != 2 } {
    puts "Usage: setup_test_project <alias> <dir>"
    exit 1
}
set test_project [lindex $argv 0]
set test_project_dir [lindex $argv 1]

# Connect to the handler
puts -nonewline "Connecting to handler..."
set connectCmd [list DbHandlerConnect teardown_test_project]
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
if { [lsearch $projects $test_project] < 0 } {
    puts "*** Test project not found ***"
    exit 1
}

# Check whether test project directory already exists
if { ![file isdirectory $test_project_dir] } {
    puts "*** Directory $test_project_dir not found ***"
    exit 1
} else {
    puts -nonewline "Deleting project directory $test_project_dir..."
    file delete -force $test_project_dir
}

# Remove the test project
puts -nonewline "Deleting test project $test_project..."
if { [catch { set status [DeleteProject $test_project] } err] } {
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

# Verify that the project has been removed
if { [lsearch [ListProjects] $test_project] > -1 } {
    puts "*** Test project still in the list of projects ***"
    exit 1
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