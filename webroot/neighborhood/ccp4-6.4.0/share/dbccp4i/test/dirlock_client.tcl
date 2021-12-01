#############################################################
#
# dirlock_client.tcl
#
# Client application that makes a fake lock file for the
# directories.def file before connecting to the handler
#
# CVS_Id $Id: dirlock_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " dirlock_client\n"
puts " Make a fake lock file on the user's directories.def file"
puts " then try to connect to the handler"
puts "==========================================================\n"


# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Check for directories.LOCK file
set lock [file join [GetDotCCP4] [string tolower [GetOPSYS]] directories.LOCK]
puts "Checking for lock: $lock\n"
if { [file exists $lock] } {
    puts "Test aborted: directories.def already has a lock"
    exit 0
}
# Make a dummy lock file
set fp [open $lock "w"]
puts $fp "Dummy lock file created by test application"
close $fp
puts "Created fake lock: $lock\n"

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    if { [file exists $lock] } {
	file delete $lock
    }
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect dirlock_client] } {
    puts "Test failed: couldn't connect to the handler"
    if { [file exists $lock] } {
	file delete $lock
    }
    exit 1
}

# List the available projects
set projects [ListProjects]
puts "Projects: $projects"
if { [llength $projects] < 1 } {
    puts "Test failed: no projects returned"
    set project {}
} else {
    puts "Test succeeded: project data returned\n"
    set project [lindex $projects 0]
}

# Try to open a project
if { $project != "" } {
    puts "Attempt to open first project in list ($project)\n"
    if { ![OpenProject $project msg] } {
	puts "Test failed: open failed ($msg)\n"
    } else {
	puts "Test succeeded: open succeeded"
    }
}

# Disconnect
puts "Disconnecting\n"
DbHandlerDisconnect

# Remove the fake lock file
if { [file exists $lock] } {
    file delete $lock
}
exit 0