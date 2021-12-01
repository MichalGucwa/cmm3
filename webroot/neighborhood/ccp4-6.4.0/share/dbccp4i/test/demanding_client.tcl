#############################################################
#
# demanding_client.tcl
#
# Client application that connects to the handler, creates a
# several new jobs and then makes lots of changes quickly
#
# CVS_Id $Id: demanding_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " demanding_client\n"
puts " Connect to the handler, creates a new job and then make"
puts " lots of changes quickly"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import ::dbClientAPI::*

# Get command line argument
if { [llength $argv] == 2 } {
    set project [lindex $argv 0]
    puts "Adding fake jobs to project \"$project\""
    set taskname [lindex $argv 1]
    puts "Jobs will have the taskname \"$taskname\""
} else {
    puts "Usage: tclsh demanding_client.tcl <project_name> <taskname>"
    exit 0
}

# Set the debugging output level
DbXMLSetDebug 0

# Set the time interval between creating new jobs
set time_interval 2000

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect] } {
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
    if { [file exists $lockfile] } {
	file delete $lockfile
    }
    DbHandlerDisconnect
    exit 1
}

# Make a new job and make a lot of changes using SetData
proc MakeANewJob { project taskname i } {
    set newjob [NewJob $project]
    puts "\nNew job = $newjob"
    if { $newjob == 0 } {
	puts "Failed!"
	return 0

    }
    SetData $project $newjob STATUS STARTING
    SetData $project $newjob TASKNAME "$taskname"
    SetData $project $newjob TITLE "Fake job from demanding_client"
    SetData $project $newjob LOGFILE "[subst $newjob]_faker.log"
    SetData $project $newjob STATUS RUNNING
    SetData $project $newjob STATUS FINISHED
    SetData $project $newjob TITLE "Updated fake job from demanding_client"
    # Add input and output files to link jobs
    AddOutputFile $project $newjob "fakefile_$i" $project
    if { [set j [expr $i-1]] > -1 } {
	AddInputFile $project $newjob "fakefile_$j" $project
    }
    return 1
}

# Make new jobs and update them
for { set i 0 } { $i < 10 } { incr i } {
    if { ![MakeANewJob $project $taskname $i] } {
	break
    }
    after $time_interval
}

# Close the database
CloseProject $project

# Finished
DbHandlerDisconnect

puts "=========================================================="
puts " demanding_client: finished"
puts "=========================================================="
exit 0