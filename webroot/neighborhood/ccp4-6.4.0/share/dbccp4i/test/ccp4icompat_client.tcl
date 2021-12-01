#############################################################
#
# ccp4icompat_client.tcl
#
# Client application that connects to the handler, opens a
# project and then:
# 1. overrides the lock file
# 2. changes the database.def file modification time
# in order to test compatibility with CCP4i.
#
# CVS_Id $Id: ccp4icompat_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " ccp4icompat_client\n"
puts " Connect to the handler, open a project and then:"
puts " 1. override the lock file"
puts " 2. changes the database.def file modification time"
puts " in order to test compatibility with CCP4i."
puts " 3. changes the directories.def file modification time."
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Define internal utility procedures
proc update_file_mtime { filen } {
    # Update the modification time of a file
    # This is very crude - it copies the file and then
    # overwrites the original with the copy.
    puts "Updating $filen: mtime = [file mtime $filen]"
    if { ![file exists $filen] || ![file isfile $filen] } {
	# Nothing to do
	puts "Error: file not found, or is not a file"
	return
    }
    set filen_copy "[subst $filen].copy"
    after 1000
    set fdf [open $filen "r"]
    set fcp [open $filen_copy "w"]
    while { [gets $fdf line] >= 0 } {
	puts $fcp $line
    }
    close $fdf
    close $fcp
    file rename -force $filen_copy $filen
    puts "$filen: final mtime = [file mtime $filen]"
    return
}

proc change_last_job_status { db_filen } {
    # Change the status of the last job in
    # a database.def file
    puts "Updating database.def file: $db_filen"
    if { ![file exists $db_filen] || ![file isfile $db_filen] } {
	# Nothing to do
	puts "Error: file not found, or is not a file"
	return
    }
    set db_filen_copy "[subst $db_filen].copy"
    after 1000
    set fdf [open $db_filen "r"]
    set fcp [open $db_filen_copy "w"]
    set njobs 0
    while { [gets $fdf line] >= 0 } {
	if { [regexp -- "^NJOBS +(\[0-9\]+)" $line m njobs] } {
	    puts "NJOBS = $njobs"
	}
	if { $njobs != 0 } {
	    if { [regexp -- "^STATUS,$njobs +(\[A-Z\]+)" $line m status] } {
		puts "STATUS of job $njobs = $status"
		set line "STATUS\tFINISHED"
	    }
	}
	puts $fcp $line
    }
    close $fdf
    close $fcp
    file rename -force $db_filen_copy $db_filen
    return
}

# Get command line argument
if { [llength $argv] == 1 } {
    set project [lindex $argv 0]
    puts "Making fake lock on database in project \"$project\"\n"
} else {
    puts "Usage: tclsh ccp4icompat_client.tcl <project_name>"
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
if { ![DbHandlerConnect ccp4icompat_client] } {
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

# Test for an existing lock on the project
set projectdir [GetProjectDir $project]
set lockfile [file join $projectdir CCP4_DATABASE database.LOCK]
if { [file exists $lockfile] } {
    puts "Test failed: $project already has a lockfile"
    DbHandlerDisconnect
    exit 1
}

# Attempt to open the database
puts "----------------------------------------------------------"
puts " Opening project database..."
puts "----------------------------------------------------------"
if { [OpenProject $project msg] } {
    puts "Test succeeded: open succeeded"
} else {
    puts "Test failed: open failed ($msg)\n"
    if { [file exists $lockfile] } {
	file delete $lockfile
    }
    DbHandlerDisconnect
    exit 1
}

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

# Simulate CCP4i overriding the lock by writing a new file
puts "----------------------------------------------------------"
puts " Overwriting lockfile in project..."
puts "----------------------------------------------------------"
file delete $lockfile
set fp [open $lockfile "w"]
puts $fp "Lock file for $project"
puts $fp "Created by nobody"
puts $fp "Date 31 Oct 2006  16:02:27"
puts $fp "Owned by pid 0"
close $fp

# Try to obtain and verify data once again
set njobs1 [GetNJOB $project]
puts "NJOBS(1): $njobs1\n"
if { $njobs != $njobs1 } {
    # This should agree with the previous value
    puts "Test failed: njobs should agree with the previous value"
} else {
    set joblist [ListJobs $project]
    puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
    if { $njobs1 > 0 && [llength $joblist] == 0 } {
	puts "Test encountered inconsistency in data!"
    }
}

# Simulate CCP4i overwriting database by rewriting the database file
puts "----------------------------------------------------------"
puts " Updating database.def file in project..."
puts "----------------------------------------------------------"
set db_file [file join $projectdir CCP4_DATABASE database.def]
update_file_mtime $db_file

# Try to obtain and verify data once again
# The handler should update the project to be read-only
set njobs2 [GetNJOB $project]
puts "NJOBS(2): $njobs2\n"
if { $njobs != 0 } {
    if { $njobs != $njobs2 } {
	# NJOBS should be zero if data is no longer readable
	puts "Test failed: njobs is no longer correct"
    } else {
	# A few more checks
	puts "Test succeeded: njobs is consistent"
	set joblist [ListJobs $project]
	puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
	if { $njobs2 > 0 && [llength $joblist] == 0 } {
	    puts "*** Test encountered inconsistency in data! ***"
	}
    }
} else {
    puts "Not possible to check - project contains no jobs"
}

# Simulate CCP4i updating directories by rewriting the directories file
puts "----------------------------------------------------------"
puts " Updating directories.def file..."
puts "----------------------------------------------------------"
# Update directories file
set dir_file [file join [GetDotCCP4] \
		  [string tolower $tcl_platform(platform)] \
		  directories.def]
puts "directories data file: $dir_file"
set project_list1 [ListProjects]
puts "Initial list of projects: $project_list1"
update_file_mtime $dir_file
set project_list2 [ListProjects]
puts "List of projects after modification: $project_list2"
if { $project_list1 != $project_list2 } {
    # The lists should be the same
    puts "Test failed: list of projects is not consistent"
} else {
    puts "Test succeeded: list of projects is consistent"
}

# Simulate CCP4i changing the project directory
# This involves updates to both directories.def and database.def
puts "----------------------------------------------------------"
puts " Updating directories.def and database.def for project..."
puts "----------------------------------------------------------"
update_file_mtime $dir_file
update_file_mtime $db_file

# Try to obtain and verify data once again
# The handler should update the project to be read-only
set njobs2 [GetNJOB $project]
puts "NJOBS(2): $njobs2\n"
if { $njobs != 0 } {
    if { $njobs != $njobs2 } {
	# NJOBS should be zero if data is no longer readable
	puts "Test failed: njobs is no longer correct"
    } else {
	# A few more checks
	puts "Test succeeded: njobs is consistent"
	set joblist [ListJobs $project]
	puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
	if { $njobs2 > 0 && [llength $joblist] == 0 } {
	    puts "*** Test encountered inconsistency in data! ***"
	}
    }
} else {
    puts "Not possible to check - project contains no jobs"
}

# Simulate CCP4i changing the project directory
# This involves updates to both directories.def and database.def
puts "----------------------------------------------------------"
puts " Updating directories.def and modifying database.def..."
puts "----------------------------------------------------------"
update_file_mtime $dir_file
change_last_job_status $db_file

# Wait for a while
puts "Waiting..."
after 35000
puts "Restarted"

# Try to obtain and verify data once again
# The handler should update the project to be read-only
set njobs2 [GetNJOB $project]
puts "NJOBS(2): $njobs2\n"
if { $njobs != 0 } {
    if { $njobs != $njobs2 } {
	# NJOBS should be zero if data is no longer readable
	puts "Test failed: njobs is no longer correct"
    } else {
	# A few more checks
	puts "Test succeeded: njobs is consistent"
	set joblist [ListJobs $project]
	puts "Joblist: \"$joblist\" (number of jobs = [llength $joblist])\n"
	if { $njobs2 > 0 && [llength $joblist] == 0 } {
	    puts "*** Test encountered inconsistency in data! ***"
	}
    }
} else {
    puts "Not possible to check - project contains no jobs"
}

# Finished
CloseProject $project
DbHandlerDisconnect
if { [file exists $lockfile] } {
    file delete $lockfile
}
puts "=========================================================="
puts " ccp4icompat_client: finished"
puts "=========================================================="
exit 0