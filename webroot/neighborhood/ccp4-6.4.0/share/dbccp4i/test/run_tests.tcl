#############################################################
#
# run_tests.tcl
#
# A portable platform for running the dbccp4i tests on different
# systems
#
# The script relies on a number of helper scripts:
#
# detect_handler.tcl: invoked to see if a handler is already
#                     running on the system.
# get_tclsh_version.tcl: return the version number for a tclsh
#                     executable.
#
# These scripts live in the "helpers" subdirectory of the test
# directory.
#
# CVS_Id $Id: run_tests.tcl,v 1.2 2008/08/12 10:48:30 pjx Exp $
#
#############################################################
#
# Globals (used to count number of tests, successes & failures)
#
set ntests 0
set nsuccess 0
set nfail 0
#
# Specify default executables to use in tests
#
set pythonExe python
set tclshExe tclsh
#
# Procedures
#
#------------------------------------------------------------
proc incr_ntests { } {
#------------------------------------------------------------
    # Increment the count of tests run
    global ntests
    incr ntests
}
#
#------------------------------------------------------------
proc incr_nsuccess { } {
#------------------------------------------------------------
    # Increment the count of tests that succeeded
    global nsuccess
    incr nsuccess
}
#
#------------------------------------------------------------
proc incr_nfail { } {
#------------------------------------------------------------
    # Increment the count of tests that failed
    global nfail
    incr nfail
}
#
#------------------------------------------------------------
proc run_script { interp script args } {
#------------------------------------------------------------
    # Run a script with the specified interpreter and
    # optional arguments
    # Return 1 on success, 0 on failure
    set cmd [list exec $interp $script]
    if { [llength $args] > 0 } {
	set cmd [concat $cmd $args]
    }
    if { [catch $cmd msg ] } {
	# Error whilst running the script
	puts "$msg"
	return 0
    } else {
	return 1
    }
}
#
#------------------------------------------------------------
proc run_script_no_output { interp script args } {
#------------------------------------------------------------
    # Run a script with the specified interpreter and
    # optional arguments
    # This differs from run_script in that in the event
    # of an error, no output is printed.
    # Return 1 on success, 0 on failure
    set cmd [list exec $interp $script]
    if { [llength $args] > 0 } {
	set cmd [concat $cmd $args]
    }
    if { [catch $cmd msg ] } {
	# Error whilst running the script
	return 0
    } else {
	return 1
    }
}
#
#------------------------------------------------------------
proc run_python_unit_test { script } {
#------------------------------------------------------------
    # Run a Python unit test
    # These always appear to fail according to catch, so
    # we need to check the actual output - does it end
    # with "OK"?
    global dbccp4i_top
    global pythonExe
    incr_ntests
    puts -nonewline "$script: "
    catch [list exec "$pythonExe" "[file join $dbccp4i_top test $script]"] output
    if { ![regexp -- "OK\$" $output] } { 
	puts "ERROR"
	puts "$output"
	incr_nfail
	return 0
    } else {
	puts "completed ok"
	incr_nsuccess
	return 1
    }
}
#
#------------------------------------------------------------
proc run_python_test { script args } {
#------------------------------------------------------------
    # Run a Python test script
    global dbccp4i_top
    global pythonExe
    incr_ntests
    puts -nonewline "$script $args: "
    set cmd [list exec "$pythonExe" "[file join $dbccp4i_top test $script]"]
    if { [llength $args] > 0 } {
	set cmd [concat $cmd $args]
    }
    if { [catch $cmd msg ] } {
	# Error whilst running the test
	puts "ERROR"
	puts "$msg"
	incr_nfail
	return 0
    } else {
	puts "completed ok"
	incr_nsuccess
	return 1
    }
}
#
#------------------------------------------------------------
proc run_tclsh_test { script args } {
#------------------------------------------------------------
    # Run a Tcl test script
    global dbccp4i_top
    global tclshExe
    incr_ntests
    puts -nonewline "$script $args: "
    set cmd [list exec "$tclshExe" "[file join $dbccp4i_top test $script]"]
    if { [llength $args] > 0 } {
	set cmd [concat $cmd $args]
    }
    if { [catch $cmd msg ] } {
	# Error whilst running the test
	puts "ERROR"
	puts "$msg"
	incr_nfail
	return 0
    } else {
	puts "completed ok"
	incr_nsuccess
	return 1
    }
}
#
#------------------------------------------------------------
proc get_unique_project_name { } {
#------------------------------------------------------------
    # Return a unique name for a new project
    set project "TEST_[clock format [clock seconds] -format %G%j%H%M%S]"
    puts "Project name: $project"
    return $project
}
#
#------------------------------------------------------------
proc get_temp_project_dir { project } {
#------------------------------------------------------------
    # Return a temporary project directory for the supplied name
    global env
    set project_dir [file join $env(CCP4_SCR) $project]
    puts "Project dir : $project_dir"
    return $project_dir
}
#
#------------------------------------------------------------
proc finish_tests { { status "" } } {
#------------------------------------------------------------
    # Report the outcomes and exit the test script
    global nsuccess nfail ntests
    puts "FINISHED: Ran $ntests tests ($nsuccess ok $nfail failed)"
    if { $status == "" } {
	if { $nfail > 0 } {
	    # Exit with non-zero status to indicate errors
	    exit 1
	} else {
	    # Exit with zero status to indicate everything is fine
	    exit 0
	}
    } else {
	# Use the supplied exit status
	exit $status
    }
}
#
# Top-level script
#
puts "==================================="
puts " run_tests.tcl"
puts "==================================="
#
# Acquire or set the environment
#
if { [info exists env(DBCCP4I_TOP)] } {
    set dbccp4i_top $env(DBCCP4I_TOP)
    puts "DBCCP4I_TOP already set to $dbccp4i_top"
} else {
    puts "DBCCP4I_TOP not set"
    puts "Assuming we are in test directory"
    set dbccp4i_top [file join [pwd] ..]
    puts "Setting DBCCP4I_TOP to $dbccp4i_top"
    set env(DBCCP4I_TOP) $dbccp4i_top
}   
#
# Move to the test directory
#
set dbccp4i_test [file join $dbccp4i_top test]
if { ![file isdirectory $dbccp4i_test] } {
    puts "Cannot find test directory \"$dbccp4i_test\""
    puts "ABORTED: no tests were run"
    exit 1
} else {
    puts "Moving to test directory \"$dbccp4i_test\""
    cd $dbccp4i_test
}
#
# Report versions
puts -nonewline "Tclsh : $tclshExe"
if { [catch { puts " ([exec $tclshExe [file join helpers get_tclsh_version.tcl]])" } msg] } {
    puts " ($msg)"
}
puts -nonewline "Python: $pythonExe"
if { [catch { puts " ([exec $pythonExe -V])" } msg] } {
    puts " ($msg)"
}
#
# Check if a handler instance is already running
# Abort if one is detected
#
set runningHandler [catch { exec \
				"$tclshExe" [file join helpers detect_handler.tcl] \
			    } msg]
if { $runningHandler } {
    puts "A handler instance already appears to be running"
    puts "ABORTED: no tests were run"
    exit 1
}
#
# Run Python unit tests
puts "------------------------------"
puts " Basic Python test scripts"
puts "------------------------------"
run_python_unit_test test_ccp4i.py
run_python_unit_test test_dbsocket.py
run_python_test dbccp4i_test_client.py
#
# Run the Tcl test scripts
puts "------------------------------"
puts " Basic Tcl test scripts"
puts "------------------------------"
run_tclsh_test test_dbxml.tcl
run_tclsh_test dbccp4i_test_client.tcl
run_tclsh_test broadcast_test_client.tcl
run_tclsh_test dirlock_client.tcl
run_tclsh_test rude_client.tcl
run_tclsh_test test_directories_client.tcl
#
# Run the MrBUMP compatibility tests
puts "------------------------------"
puts " MrBUMP compatibility tests"
puts "------------------------------"
if { $tcl_platform(platform) == "windows" } {
    # Windows
    set directories_mr [file join $env(USERPROFILE) CCP4 directories_mr.def]
} else {
    # Assume UNIX or Linux
    set directories_mr [file join $env(HOME) .CCP4 directories_mr.def]
}
run_tclsh_test dbccp4i_test_client.tcl -directories $directories_mr
run_python_test test_directories_mr.py
#
# Run the tests that require a project
puts "------------------------------"
puts " Setting up temporary project"
puts "------------------------------"
set project [get_unique_project_name]
set project_dir [get_temp_project_dir $project]
if { ![run_script tclsh [file join $env(DBCCP4I_TOP) test setup_test_project.tcl] \
	   $project $project_dir] } {
    puts "Failed to make test project"
    finish_tests 1
}
#
puts "------------------------------"
puts " Tests using temporary project"
puts "------------------------------"
run_tclsh_test bigrequest_client.tcl $project -limit 10000
run_tclsh_test ccp4icompat_client.tcl $project
run_tclsh_test openclose_client.tcl $project
run_tclsh_test opendb_client.tcl $project
run_tclsh_test demanding_client.tcl $project
run_tclsh_test dbitems_client.tcl $project
run_python_test test_addfiles.py $project 1 test.dat
puts "------------------------------"
puts " Simulate Python client crash"
puts "------------------------------"
puts -nonewline "dbsocket_crash.py: "
run_script_no_output python dbsocket_crash.py $project 1
puts "finished"
#
puts "------------------------------"
puts " Removing temporary project"
puts "------------------------------"
if { ![run_script tclsh [file join $env(DBCCP4I_TOP) test teardown_test_project.tcl] \
	   $project $project_dir] } {
    puts "Warning: failed to remove test project"
}
finish_tests
#
