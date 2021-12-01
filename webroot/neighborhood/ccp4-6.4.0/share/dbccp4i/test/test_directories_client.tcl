#############################################################
#
# test_directories_client.tcl
#
# Client application that tests the various directories functions
# via the Tcl client API.
#
# CVS_Id $Id: test_directories_client.tcl,v 1.1 2008/08/14 07:17:16 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " test_directories_client"
puts " Test directories functions via the Tcl client API"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Procedures
proc exit_test { status } {
    # Shut down the handler
    if { [DbVerifyConnection] } {
	puts -nonewline "Issuing the shutdown command to the handler..."
	DbShutdown
	puts "done"
    }
    # Pause for a second
    after 1000
    puts ""
    puts "=========================================================="
    puts -nonewline " test_directories_client: finished"
    if { ! $status } {
	puts " (OK)"
    } else {
	puts " (ERROR)"
    }
    puts "=========================================================="
    exit $status
}

proc report_result { } {
    # Print last data from handler
    set data [db_client_response_data]
    if { [llength $data] == 2 } {
	puts "Last status: [lindex $data 0]"
	puts "Last result: [lindex $data 1]"
    }
}

# Set the debugging output level
DbXMLSetDebug 0

# Connect to the handler
puts -nonewline "Connecting to handler..."
set connectCmd [list DbHandlerConnect dbccp4i_test_client]
if { ![eval $connectCmd] } {
    puts "failed: couldn't connect to the handler"
    exit 1
}
puts "done"

# List projects
puts "-------------------------------------------"
puts " Project directory data"
puts "-------------------------------------------"
puts -nonewline "Acquiring listing of projects..."
if { [catch { set projects [ListProjects] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done"

# Collect data with one call
puts -nonewline "Fetching all project directory data at once..."
set dataCmd [list GetDirectoriesData]
foreach project $projects {
    lappend dataCmd ProjectDir $project ProjectDBDir $project
}
if { [catch { set projectdata [eval $dataCmd] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    puts "done"
}

# Collect data again with single calls
set projectdata1 {}
foreach project $projects {
    # Project directory
    puts -nonewline "Project dir for $project..."
    if { [catch { set projectdir [GetProjectDir $project] } err] } {
	puts "failed: error message \"$err\""
	exit 1
    } else {
	puts "$projectdir"
    }
    # Project database directory
    puts -nonewline "Project db dir for $project..."
    if { [catch { set projectdb [GetProjectDBDir $project] } err] } {
	puts "failed: error message \"$err\""
	exit 1
    } else {
	puts "$projectdb"
    }
    # Store for now
    lappend projectdata1 $projectdir $projectdb
}

# Check that data is consistent
puts -nonewline "Checking number of data items matches..."
if { [llength $projectdata] != [llength $projectdata1] } {
    puts "failed: mismatch in number of data items"
    exit_test 1
} else {
    puts "ok"
}
puts -nonewline "Checking that values are consistent..."
set n_unequal 0
for { set i 0 } { $i < [llength $projectdata] } { incr i } {
    if { [lindex $projectdata $i] != [lindex $projectdata1 $i] } {
	# Increment count of unequal data items
	incr n_unequal
    }
}
if { $n_unequal > 0 } {
    puts "failed: $n_unequal data item(s) had different values"
    exit_test 1
} else {
    puts "ok"
}

# List data dirs
puts "-------------------------------------------"
puts " Def dir directory data"
puts "-------------------------------------------"
puts -nonewline "Acquiring listing of data dirs..."
if { [catch { set defdirs [ListDataDirs] } err] } {
    puts "failed with error \"$err\""
    exit 1
}
puts "done"

# Collect data with one call
puts -nonewline "Fetching all def dir directory data at once..."
set dataCmd [list GetDirectoriesData]
foreach defdir $defdirs {
    lappend dataCmd DataDir $defdir
}
if { [catch { set defdirdata [eval $dataCmd] } err] } {
    puts "failed: error message \"$err\""
    exit 1
} else {
    puts "done"
}

# Collect data again with single calls
set defdirdata1 {}
foreach defdir $defdirs {
    # Def dir directory
    puts -nonewline "Directory for $defdir..."
    if { [catch { set dir [GetDataDir $defdir] } err] } {
	puts "failed: error message \"$err\""
	exit 1
    } else {
	puts "$dir"
    }
    # Store for now
    lappend defdirdata1 $dir
}

# Check that data is consistent
puts -nonewline "Checking number of data items matches..."
if { [llength $defdirdata] != [llength $defdirdata1] } {
    puts "failed: mismatch in number of data items"
    exit_test 1
} else {
    puts "ok"
}
puts -nonewline "Checking that values are consistent..."
set n_unequal 0
for { set i 0 } { $i < [llength $projectdata] } { incr i } {
    if { [lindex $projectdata $i] != [lindex $projectdata1 $i] } {
	# Increment count of unequal data items
	incr n_unequal
    }
}
if { $n_unequal > 0 } {
    puts "failed: $n_unequal data item(s) had different values"
    exit_test 1
} else {
    puts "ok"
}

# Finished
puts -nonewline "Disconnecting from handler..."
if { [catch { DbHandlerDisconnect } err] } {
    puts "failed: disconnection error \"$err\""
    exit_test 1
}
puts "done"

# Exit everything ok
exit_test 0