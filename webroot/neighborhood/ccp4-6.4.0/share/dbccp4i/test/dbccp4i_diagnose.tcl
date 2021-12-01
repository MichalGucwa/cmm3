#############################################################
#
# dbccp4i_diagnose.tcl
#
# This intended to be a diagnostic/benchmarking tool which
# should check basic stuff like "can I connect to a handler?"
# and then give an idea of the performance of the system.
#
# CVS_Id $Id: dbccp4i_diagnose.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################
#
# Procedures
#
proc report_tcl_version { } {
    global tcl_version
    puts "Tcl version: $tcl_version"
}
proc report_environment { } {
    # Reports on key environment variables
    global env
    # CCP4, CCP4I_TOP and DBCCP4I_TOP information
    puts "Environment variables:"
    foreach var [list CCP4 CCP4I_TOP DBCCP4I_TOP] {
	puts -nonewline "- $var: "
	if { [info exists env($var)] } {
	    puts "$env($var)"
	} else {
	    puts "not found"
	}
    }
}
#
proc report_api_error { } {
    # Print the last error message and response data
    # from the client API
    set error_message [db_client_error]
    if { $error_message != "" } {
	puts "Error from client API: \"$error_message\""
    }
    set response_data [db_client_response_data]
    if { [llength $response_data] == 2 } {
	set response_status [lindex $response_data 0]
	set response_message [lindex $response_data 1]
	puts "\tResponse status : \"$response_status\""
	puts "\tResponse message: \"$response_message\""
    } else {
	puts "\tCouldn't deconvolute response from client API"
	puts "\tRaw data: \"$response_data\""
    }
}
#
proc report_api_response { } {
    # Print the last status from the client API
    set response_data [db_client_response_data]
    if { [llength $response_data] == 2 } {
	puts "Status of last API response: [lindex $response_data 0]"
    } else {
	puts "Raw API data: $response_data"
    }
}
#
proc time_get_description { project joblist items format count } {
    # Run "count" iterations of the GetDescription command and
    # return timing info (from Tcl's "time" command) plus number
    # that actually succeeded
    set nsuccess 0
    set njobs [llength $joblist]
    set nitems [llength $items]
    set result [time {
	set descr [GetDescription $project $joblist $items $format]
	if { $njobs > 1 && [llength $descr] == $njobs} {
	    incr nsuccess
	} else {
	    # A single job - assume that it worked
	    incr nsuccess
	}
    } $count]
    return "$result ($nsuccess/$count succeeded)"
}
#
# TOP-LEVEL SCRIPT STARTS HERE
#
puts "=========================================="
puts " DbCCP4i Diagnostic and Benchmarking Tool"
puts "=========================================="
#
# Background information
#
puts "------------------------------------------"
puts " Background information"
puts "------------------------------------------"
#
# Tcl version
report_tcl_version
#
# Environment variables
report_environment
#
#
# Import the client API
#
puts "------------------------------------------"
puts " Importing Client API"
puts "------------------------------------------"
puts -nonewline "Acquiring the client API commands..."
if { [catch { source [file join $env(DBCCP4I_TOP) \
			  ClientAPI dbClientAPI.tcl] } err ] } {
    puts "failed"
    puts "Error from catch: \"$err\""
    exit 1
}
puts "ok"
namespace import dbClientAPI::*
#
# Check that we can start the handler
#
puts "------------------------------------------"
puts " Starting/connecting to the handler"
puts "------------------------------------------"
puts -nonewline "Connecting to handler..."
set connectCmd [list DbHandlerConnect dbccp4i_diagnose]
if { ![eval $connectCmd] } {
    puts "failed: couldn't connect to the handler"
    report_api_error
    exit 1
}
puts "ok"
#
# Information on handler
#
puts -nonewline "Fetching DbCCP4i info..."
puts "[DbInfo]"
puts -nonewline "Timeout in client API..."
puts "[DbGetTimeout] milliseconds"
#
# Find out what we're dealing with - are there are any projects?
# Open if possible and characterise
#
puts "------------------------------------------"
puts " Examining data"
puts "------------------------------------------"
puts -nonewline "Acquiring project data..."
if { [catch { set projects [ListProjects] } err] } {
    # Error listing projects
    puts "failed: disconnection error \"$err\""
    report_api_error
} else {
    puts "ok"
    if { [llength $projects] > 0 } {
	# There is at least one project
	puts "Found [llength $projects] projects:"
	foreach project $projects {
	    puts "\t$project"
	}
	foreach project $projects {
	    # Open the project
	    puts "------------------------------------------"
	    puts " Examining project $project"
	    puts "------------------------------------------"
	    puts -nonewline "Opening project \"$project\"..."
	    if { [catch { set status [OpenProject $project] } err ] } {
		# Open failed
		puts "failed: caught open error \"$err\""
		report_api_error
	    } else {
		# Check the status
		puts "returned status $status"
		if { ! $status } {
		    puts "*** Problem opening project ***"
		    report_api_error
		} else {
		    # Check whether read/write is possible
		    puts "- Project readable: [ProjectReadable $project]"
		    puts "- Project writable: [ProjectWriteable $project]"
		    # Number of jobs
		    set joblist [ListJobs $project]
		    set njobs [llength $joblist]
		    puts "- Found $njobs jobs"
		    # If there are jobs then characterise the
		    # performance for reading data
		    if { $njobs > 0 } {
			puts -nonewline "Fetching some job descriptions..."
			set result  [time_get_description $project $joblist \
					 [list JOB_ID DATE TASKNAME TITLE] \
					 [list 5 10 15 25] 10]
			puts "$result"
			puts -nonewline "Fetching individual data items..."
			puts [time {
			    foreach jobid $joblist {
				foreach item [list DATE TASKNAME TITLE] {
				    GetData $project $item
				}
			    }
			} 10]
			puts -nonewline "Testing limits..."
			# Make a list with a thousand job #1
			set onethousand {}
			for { set i 0 } { $i < 1000 } { incr i } {
			    lappend onethousand [lindex $joblist 0]
			}
			set exceeded 0
			set largest_number 0
			set largest_size_sent 0
			set largest_size_back 0
			set testjoblist {}
			while { ! $exceeded } {
			    set testjoblist [concat $testjoblist $onethousand]
			    set result [GetDescription $project $testjoblist \
					    [list TASKNAME] [list 15]]
			    if { [llength $result] != \
				     [llength $testjoblist] } {
				# Reached a failure point
				set exceeded 1
				puts "reached/exceeded limit"
				report_api_response

			    } else {
				# Successfully returned correct number
				set largest_number [llength $testjoblist]
				set largest_size [string length $testjoblist]
				set largest_back [string length $result]
			    }
			}
			puts "$largest_number maximum attempted before failure"
			puts "- Largest size of request : $largest_size"
			puts "- Largest size of response: $largest_back"
			# Get a timing for the largest non-failing request
			set testjoblist {}
			for { set i 0 } { $i < $largest_number } { incr i } {
			    lappend testjoblist [lindex $joblist 0]
			}
			puts -nonewline "Timing for $largest_number..."
			set result [time_get_description \
					$project $testjoblist \
					[list TASKNAME] [list 15] 10]
			puts "$result"
			# Get a timing for the failing request
			set testjoblist [concat $testjoblist $onethousand]
			puts -nonewline "Timing for [llength $testjoblist]..."
			set result [time_get_description \
					$project $testjoblist \
					[list TASKNAME] [list 15] 10]
			puts "$result"
		    }
		}
		# Close the connection to this project
		CloseProject $project
	    }
	}
    }
}
#
# Disconnect
#
puts "------------------------------------------"
puts " Finishing up"
puts "------------------------------------------"
puts -nonewline "Disconnecting from handler..."
if { [catch { DbHandlerDisconnect } err] } {
    puts "failed: disconnection error \"$err\""
    report_api_error
    exit 1
}
puts "ok"
puts "Finished"
exit 0
