#############################################################
#
# check_saves.tcl
#
# Client application that checks for updates to the
# database.def file for a specified project
#
# CVS_Id $Id: check_saves.tcl,v 1.9 2008/08/12 10:48:37 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " check_saves\n"
puts " Monitor the database.def file for a project and report"
puts " updates as the file is saved."
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import ::dbClientAPI::*

# Reset the debugging diagnostics in DbXML
DbXMLSetDebug 0

# Get command line argument
if { [llength $argv] == 1 } {
    set project [lindex $argv 0]
    puts "Monitoring saves to database in project \"$project\"\n"
} else {
    puts "Usage: tclsh check_saves.tcl <project_name>"
    exit 0
}

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect check_saves] } {
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

set dir [GetProjectDir $project]
puts "Directory for project \"$project\" is \"$dir\"\n"

# Locate the database.def file
set dbfile [file join $dir CCP4_DATABASE database.def]
puts "Checking for database.def: $dbfile\n"
if { ![file exists $dbfile] } {
    puts "Test aborted: database.def not found"
    DbHandlerDisconnect
    exit 1
}

# Wait for changes and report them
set run 1
set mtime [file mtime $dbfile]
puts "Modification time initially [clock format $mtime]\n"
while { $run } {
    after 500
    set new_mtime [file mtime $dbfile]
    if { $new_mtime > $mtime } {
	puts "$dbfile:\n*** Updated at: [clock format $new_mtime]\n"
	set mtime $new_mtime
    }
    # Exit when the handler does
    if { ![DbVerifyConnection] } {
	puts "Handler no longer active\n"
	set run 0
    }
}

# Finished
puts "Stopped."