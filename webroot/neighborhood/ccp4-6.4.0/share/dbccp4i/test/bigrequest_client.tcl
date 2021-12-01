#############################################################
#
# bigrequest_client.tcl
#
# Client application that connects to the handler and sends
# increasingly large requests for data until there is an
# error from the handler
#
# CVS_Id $Id: bigrequest_client.tcl,v 1.9 2008/08/12 10:48:29 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " bigrequest_client\n"
puts " Connect to the handler, open a project and send requests"
puts " that increase in size until they fail"
puts " With -limit, test a single request with the specified"
puts " number of jobs"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Initialise internal flags
set nlimit -1
set adjust_timeout 0
set failed 0
set usage "Usage: tclsh bigrequest_client.tcl <project_name> \[-limit n\] \[-adjust_timeout\]\n       -limit n: stop when n jobs is reached or exceeded\n       -adjust_timeout: set the API timeout to match the number of requests"

# Get command line arguments
if { [llength $argv] < 1 } {
    puts "$usage"
    exit 0
}
set project [lindex $argv 0]
puts "Using database in project \"$project\"\n"
set i 1
while { $i < [llength $argv] } {
    switch -- [lindex $argv $i] {
	"-h" {
	    # Print usage information
	    puts "$usage"
	    exit 0
	}
	"-limit" {
	    # Set a limit to the number of jobs
	    incr i
	    set nlimit [lindex $argv $i]
	    puts "Iterate until number of jobs reaches $nlimit (or failure)"
	}
	"-adjust_timeout" {
	    # Adjust the timeout in the API
	    # to match the number of requests being sent
	    set adjust_timeout 1
	}
	default {
	    # Unrecognised argument
	    puts "Unrecognise argument: \"[lindex $argv $i]\""
	    puts "$usage"
	    exit 1
	}
    }
    # Next argument
    incr i
}

# Set the debugging output level
DbXMLSetDebug 0

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect "bigrequest_client"] } {
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

# Attempt to open the database
if { ![OpenProject $project msg] } {
    puts "Test failed: open failed ($msg)\n"
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
	CloseProject $project
	DbHandlerDisconnect
	exit 1
    } elseif { $njobs < 1 } {
	# We need at least one job in the project
	puts "Test abandoned: at least one job is needed"
	CloseProject $project
	DbHandlerDisconnect
	exit 1
    }
}

# Fetch the id of a single job
set joblist [ListJobs $project]
puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
set job_id [lindex $joblist end]
puts "Job $job_id selected for test purposes"

# Initialise the list of jobs
set one_hundred_jobs {}
for { set i 0 } { $i < 100 } { incr i } {
    lappend one_hundred_jobs $job_id
}

# Test for a limiting case
if { $nlimit > 0 } {
    # Assemble a request list with the requested number of jobs
    set request_list ""
    for { set i 0 } { $i < [expr $nlimit / 100] } { incr i } {
	set request_list [concat $request_list $one_hundred_jobs]
	##puts "[llength $request_list]"
    }
    for { set i 0 } { $i < [expr $nlimit % 100] } { incr i } {
	lappend request_list $job_id
	##puts "[llength $request_list]"
    }
    # Test it
    if { $adjust_timeout } {
	DbSetTimeout [llength $request_list]
    }
    set descr [GetDescription $project $request_list { DATE STATUS } { 10 10 }]
    # Number of items returned should be the same as the
    # number of jobs supplied (one description per job)
    if { [llength $descr] != [llength $request_list] } {
	set failed 1
    }
} else {
    # Cycle round trying longer and longer lists
    set request_list $one_hundred_jobs
    while { ! $failed } {
        if { [expr [llength $request_list] % 5000] == 0 } {
	    puts "\nTrying [llength $request_list] jobs..."
	}
	if { $adjust_timeout } {
	    DbSetTimeout [llength $request_list]
	}
	set descr [GetDescription $project $request_list { DATE STATUS } { 10 10 }]
	# Number of items returned should be the same as the
	# number of jobs supplied (one description per job)
	if { [llength $descr] != [llength $request_list] } {
	    set failed 1
	}
	# Add another hundred job ids
	set request_list [concat $request_list $one_hundred_jobs]
    }
}

# Script finished
puts "\n===================================================================="
if { $failed } {
    puts "\nTest result: list with [llength $request_list] jobs failed"
    puts "\nGetDescription returned \"$descr\""
} else {
    puts "\nTest result: longest list with [llength $request_list] jobs ok"
}
puts "\n====================================================================\n"

# Close the database
CloseProject $project

# Finished
DbHandlerDisconnect
if { $failed } {
    exit 1
} else {
    exit 0
}
