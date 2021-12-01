#############################################################
#
# opendb_client.tcl
#
# Client application that connects to the handler, fakes a
# lock file on a database and then attempts to open it.
#
# CVS_Id $Id: opendb_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " opendb_client\n"
puts " Connect to the handler, make a fake lock file on a"
puts " project and then try to open it"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Get command line argument
if { [llength $argv] == 1 } {
    set project [lindex $argv 0]
    puts "Making fake lock on database in project \"$project\"\n"
} else {
    puts "Usage: tclsh opendb_client.tcl <project_name>"
    exit 0
}

# Set the debugging output level
DbXMLSetDebug 0

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect opendb_client] } {
    puts "Test failed: couldn't connect to the handler"
    exit 1
}

# List the available projects
set projects [ListProjects]
puts "Projects: $projects"
if { [lsearch $projects $project] < 0 } {
    puts "Test failed: can't find project called \"$project\""
    DbHandlerDisconnect
    exit 1
}

# Make a fake lock on a project
set projectdir [GetProjectDir $project]
set lockfile [file join $projectdir CCP4_DATABASE database.LOCK]
if { [file exists $lockfile] } {
    puts "Test failed: $project already has a lockfile"
    DbHandlerDisconnect
    exit 1
}
set fp [open $lockfile "w"]
puts $fp "Lock file for $project"
puts $fp "Created by nobody"
puts $fp "Date 31 Oct 2006  16:02:27"
puts $fp "Owned by pid 0"
close $fp

# Attempt to open the database
if { ![OpenProject $project msg] } {
    puts "Test succeeded: open failed ($msg)\n"
} else {
    puts "Test failed: open succeeded"
    if { [file exists $lockfile] } {
	file delete $lockfile
    }
    DbHandlerDisconnect
    exit 1
}

# Second attempt to open the database by overriding
# the lock
if { ![OpenProject $project msg -grablock] } {
    puts "Test failed: open failed ($msg)\n"
    if { [file exists $lockfile] } {
	file delete $lockfile
    }
    DbHandlerDisconnect
    exit 1
} else {
    puts "Open reported success ($msg)\n"
    # Try to obtain and verify data
    set njobs [GetNJOB $project]
    puts "NJOBS: $njobs\n"
    if { $njobs < 0 } {
	# NJOBS should be zero or greater in an open project
	puts "Test failed: njobs is less than zero"
    } else {
	set joblist [ListJobs $project]
	puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
	if { $njobs > 0 && [llength $joblist] == 0 } {
	    puts "Test encountered inconsistency in data!"
	}
    }
    # Close the database
    CloseProject $project
}

# Finished
DbHandlerDisconnect
if { [file exists $lockfile] } {
    file delete $lockfile
}
puts "=========================================================="
puts " opendb_client: finished"
puts "=========================================================="
exit 0