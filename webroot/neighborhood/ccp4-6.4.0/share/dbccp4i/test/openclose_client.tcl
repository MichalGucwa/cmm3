#############################################################
#
# openclose_client.tcl
#
# Client application that connects to the handler and opens
# a project, then attempts to open it again. It also attempts
# multiple close operations.
#
# CVS_Id $Id: openclose_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " openclose_client\n"
puts " Connect to the handler, open a project and then try to"
puts " open it again. Then attempt to close it twice."
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Get command line argument
if { [llength $argv] == 1 } {
    set project [lindex $argv 0]
    puts "Making multiple open/close attempts on project \"$project\"\n"
} else {
    puts "Usage: tclsh opendb_client.tcl <project_name>"
    exit 0
}

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect openclose_client] } {
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

# Attempt to close the project before opening it
if { [CloseProject $project] } {
    puts "Test failed: close before open worked\n"
    DbHandlerDisconnect
    exit 1
} else {
    puts "Test succeeded: close before open failed\n"
}

# Attempt to open the database
if { [OpenProject $project msg] } {
    puts "Initial open was successful ($msg)\n"
} else {
    puts "Initial open failed"
    DbHandlerDisconnect
    exit 1
}

# Try to obtain and verify data
set njobs [GetNJOB $project]
puts "NJOBS: $njobs\n"
if { $njobs < 0 } {
    # NJOBS should be zero or greater in an open project
    puts "Test failed: njobs is less than zero\n"
} else {
    set joblist [ListJobs $project]
    puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
    if { $njobs > 0 && [llength $joblist] == 0 } {
	puts "Test encountered inconsistency in data!"
    }
}

# Second attempt to open the database
if { [OpenProject $project msg] } {
    puts "Test failed: second open succeeded ($msg)\n"
    DbHandlerDisconnect
    exit 1
} else {
    puts "Test succeeded: second open attempt failed ($msg)\n"
}

# Close the database
if { [CloseProject $project] } {
    puts "Initial close was successful\n"
}

# Second attempt to close the database
if { [CloseProject $project] } {
    puts "Test failed: second close attempt was successful\n"
    DbHandlerDisconnect
    exit 1
} else {
    puts "Test succeeded: second close attempt failed\n"
}

# Finished
DbHandlerDisconnect
exit 0