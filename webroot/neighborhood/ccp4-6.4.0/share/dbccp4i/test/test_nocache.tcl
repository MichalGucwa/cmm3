# This test script doesn't use the cache machanism

source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import ::dbClientAPI::*

global project

#----------------------------------------------------------------
proc handlebroadcast { broadcast } {
#----------------------------------------------------------------
    # Handle broadcast message from the database handler
    global project
    puts "******************************************************"
    puts "Received broadcast message:\n\n$broadcast"
    puts "******************************************************"
    set joblist [ListJobs $project]
    set itemlist [GetDbItems $project]
   
    foreach job $joblist {
	foreach item $itemlist {
	    # get data directly from handler
	    puts [GetData $project $job $item]
	}
    }
}

if { [llength $argv] < 1 } {
    puts "Usage: tclsh test_cache.tcl project"
    exit 1
}

# Start/connect to the database server
if { ![DbStartHandler handlebroadcast] } {
    WarningMessage "Failed to start the handler"
    exit 1
}

if { ![DbHandlerConnect "test_nocache" True] } {
    WarningMessage "Failed to connect to the handler"
    exit 1
}

# get project from input
set project [lindex $argv 0]

# open project
OpenProject $project

puts "Waiting for broadcasts..."

# Enter the event loop
vwait termination

CloseProject $project   

DbHandlerDisconnect