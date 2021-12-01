#############################################################
#
# dbitems_client.tcl
#
# Client application that connects to the handler and opens
# a project, then does various checks on the availability of
# data items.
#
# CVS_Id $Id: dbitems_client.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " dbitems_client\n"
puts " Connect to the handler, open a project and check for the"
puts " availability of data items."
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Get command line argument
if { [llength $argv] == 1 } {
    set project [lindex $argv 0]
    puts "Running checks using project \"$project\"\n"
} else {
    puts "Usage: tclsh dbitems_client.tcl <project_name>"
    exit 0
}

# Preliminary: locate database.def file and read data items
# from it directly
set dbdeffile [file join $env(DBCCP4I_TOP) etc database.def]
if { ![file exists $dbdeffile] } {
    puts "Test failed: $dbdeffile not found"
    exit 1
}
set fileitems {}
set fp [open $dbdeffile "r"]
while { [gets $fp line] > 0 } {
    if { [regexp -- "^(\[A-Za-z_\]*)," $line m item] } {
	lappend fileitems $item
    }
}
close $fp
if { [llength $fileitems] == 0 } {
    puts "Test failed: no data items retrieved from database.def"
    exit 1
}
puts "Expect to find the following data items:"
foreach item $fileitems {
    puts "\t$item"
}

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect dbitems_client] } {
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

# Open the project
if { ![OpenProject $project msg] } {
    puts "Test failed: second open succeeded ($msg)\n"
    DbHandlerDisconnect
    exit 1
}

# Request a list of data items from the project
set dbitems [GetDbItems $project]
if { [llength $dbitems] == 0 } {
    puts "Test failed: no data items returned"
    DbHandlerDisconnect
    exit 1
}
puts "Handler returned the following data items:"
foreach item $dbitems {
    puts "\t$item"
}

# Cross-validate
set status 1
foreach item $dbitems {
    if { [lsearch $fileitems $item] < 0 } {
	set status 0
	puts "Error: item \"$item\" is in db but not in database.def?"
    }
}
if { ! $status } {
    puts "Test failed: inconsistency in data items"
    DbHandlerDisconnect
    exit 1
}
set status 1
foreach item $fileitems {
    if { [lsearch $dbitems $item] < 0 } {
	set status 0
	puts "Error: item \"$item\" is in database.def but not in db?"
    }
}
if { ! $status } {
    puts "Test failed: inconsistency in data items"
    DbHandlerDisconnect
    exit 1
}
puts "Success: data items consistent between database.def and db"

# Add a new job
set jobid [NewJob $project]
if { $jobid < 1 } {
    puts "Test failed: unable to create a new job in project \"$project\""
    DbHandlerDisconnect
    exit 1
}
puts "Created new job: $jobid"
SetData $project $jobid STATUS   "REPORTED"
SetData $project $jobid TASKNAME "test"
SetData $project $jobid TITLE    "Artificial job"

# Check that data items exist for this job
set status 1
foreach item $dbitems {
    if { ![ItemExists $project $jobid $item] } {
	set status 0
	puts "Error: ItemExists can't find item \"$item\""
    }
}
if { ! $status } {
    puts "Test failed: can't find one or more data items for a new job"
    DeleteJob $project $jobid
    DbHandlerDisconnect
    exit 1
}
puts "Success: all data items exist for this job"

# Check USER_AGENT for the job
if { [lsearch $dbitems USER_AGENT] > -1 } {
    set user_agent [GetData $project $jobid USER_AGENT]
    if { $user_agent != "dbitems_client" } {
	puts "Test failed: USER_AGENT returned as \"$user_agent\" for job $jobid" 
	DeleteJob $project $jobid
	DbHandlerDisconnect
	exit 1
    }
    puts "USER_AGENT set correctly for job $jobid ($user_agent)"
} else {
    puts "USER_AGENT not in database, skipping check"
}

# Add a subjob
set subjobid [AddSubJob $project $jobid "test" "Artificial subjob"]
if { $subjobid == 0 } {
    puts "Test failed: unable to create a subjob for job $jobid in project \"$project\""
    DeleteJob $project $jobid
    DbHandlerDisconnect
    exit 1   
}
puts "Created new subjob: $subjobid"
SetData $project $subjobid STATUS   "REPORTED"

# Check that data items exist for this subjob
set status 1
foreach item $dbitems {
    if { ![ItemExists $project $subjobid $item] } {
	set status 0
	puts "Error: ItemExists can't find item \"$item\""
    }
}
if { ! $status } {
    puts "Test failed: can't find one or more data items for a new subjob"
    DeleteJob $project $subjobid
    DeleteJob $project $jobid
    DbHandlerDisconnect
    exit 1
}
puts "Success: all data items exist for this subjob"

# Check USER_AGENT for the subjob
if { [lsearch $dbitems USER_AGENT] > -1 } {
    set user_agent [GetData $project $subjobid USER_AGENT]
    if { $user_agent != "dbitems_client" } {
	puts "Test failed: USER_AGENT returned as \"$user_agent\" for subjob $subjobid"
	DeleteJob $project $subjobid
	DeleteJob $project $jobid
	DbHandlerDisconnect
	exit 1
    }
    puts "USER_AGENT set correctly for job $subjobid ($user_agent)"
} else {
    puts "USER_AGENT not in database, skipping check"
}

# Finished
puts "Removing subjob $subjobid..."
DeleteJob $project $subjobid
puts "Removing job $jobid..."
DeleteJob $project $jobid
puts "Closing project $project..."
CloseProject $project
puts "Disconnecting from handler..."
DbHandlerDisconnect
puts "Finished."
exit 0