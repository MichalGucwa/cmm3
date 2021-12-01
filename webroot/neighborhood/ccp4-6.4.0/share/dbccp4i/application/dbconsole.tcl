#
#     Copyright (C) 2006-7
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - dbconsole.py
#
# An interactive "console" client application for dbccp4i
#
# Allow the user to issue commands to the database via
# the dbClientAPI.
#
# Usage:
# > tclsh[8.*] dbconsole.tcl
# 
# Peter Briggs
#
#====================================================================#
#
#Cvs_Id $Id: dbconsole.tcl,v 1.9 2008/08/12 10:48:04 pjx Exp $
#
######################################################################

# Acquire the client API for the handler
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::DbStartHandler
namespace import dbClientAPI::DbHandlerConnect
namespace import dbClientAPI::DbRemoteHandlerConnect
namespace import dbClientAPI::DbHandlerDisconnect

# Application globals
set ignore_broadcasts 0

#################################################################
# Application procedures
#################################################################


#----------------------------------------------------------------
proc get_available_commands { filen } {
#----------------------------------------------------------------
    # Make a list of commands that are acceptable
    if { ![file exists $filen] } {
	return {}
    }
    set cmds {}
    set fp [open $filen "r"]
    while { ![eof $fp] } {
	gets $fp line
	set line [string trim $line]
	# Acquire names of commands - ignore any containing underscores
	if { [regexp -- "^proc \:\:dbClientAPI\:\:(\[A-Za-z0-9\]*) " $line full name] } {
	    lappend cmds $name
	}
    }
    close $fp
    return $cmds
}

#----------------------------------------------------------------
proc print_available_commands { filen } {
#----------------------------------------------------------------
    # Print the available commands to screen
    puts "The following commands are available from the client API:"
    foreach cmd [get_available_commands $filen] {
	puts "\t $cmd"
    }
}

#----------------------------------------------------------------
proc handle_command_line_input { allowed } {
#----------------------------------------------------------------
    # Read commands typed in at the command line
    # and farm them out to the processing function
    if { ![eof stdin] } {
	gets stdin cmd
    } else {
	set cmd "exit"
    }
    process_command $cmd $allowed
    return
}

#----------------------------------------------------------------
proc process_command { cmd allowed } {
#----------------------------------------------------------------
    global env
    # Process an API command line
    if { [lsearch [list "stop" "quit" "exit"] $cmd] > -1 } {
	# User wants to finish
	fileevent stdin readable ""
	set ::termination 1
    } elseif { [regexp "^ *list" $cmd] } {
	# List commands again
	print_available_commands \
	    [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
	puts -nonewline "Enter commands:\n% "
    } elseif { [regexp "^ *wait" $cmd] } {
	# Wait for a period of time (ms)
	if { [llength $cmd] == 2 } {
	    set wait [lindex $cmd 1]
	    puts "dbconsole: waiting for $wait ms..."
	    after $wait
	    puts -nonewline "...done\n% "
	} else {
	    puts -nonewline "dbconsole: wait instruction should be \"wait <time>\"\n% "
	}
    } elseif { [regexp "^ *hide_xml" $cmd] } {
	# Hide the XML data passing between the handler and the client
	DbXMLSetDebug 0
	puts -nonewline "dbconsole: echoing of XML messages turned OFF\n% "
    } elseif { [regexp "^ *show_xml" $cmd] } {
	# Show the XML data passing between the handler and the client
	DbXMLSetDebug 1
	puts -nonewline "dbconsole: echoing of XML messages turned ON\n% "
    } elseif { [regexp "^ *ignore_broadcasts" $cmd] } {
	# Ignore broadcast messages from the handler
	global ignore_broadcasts
	set ignore_broadcasts 1
	puts -nonewline "dbconsole: reporting of broadcast messages turned OFF\n% "
    } elseif { [regexp "^ *report_broadcasts" $cmd] } {
	# Report broadcast messages from the handler
	global ignore_broadcasts
	set ignore_broadcasts 0
	puts -nonewline "dbconsole: reporting of broadcast messages turned ON\n% "
    } elseif { [regexp "^ *DbShutdown" $cmd] } {
	# Special action for DbShutdown
	# Stop reading from stdin
	fileevent stdin readable ""
	# Send the shutdown instruction
	puts "dbconsole: sending shutdown command to handler"
	catch { eval ::dbClientAPI::$cmd } msg
	puts "$cmd\nResult:\n$msg"
	# Terminate the console
	puts "dbconsole: exiting"
	set ::termination 1
    } elseif { [regexp "^ *@(.*)" $cmd m filen] } {
	# Line starts with @ symbol - indicates that commands
	# should be read from a file instead of stdin
	set filen [string trim $filen]
	puts "dbconsole: read commands from script file \"$filen\""
	readfromfile $filen $allowed
    } elseif { [regexp "^ *\#" $cmd] } {
	# Comment line
	puts -nonewline "dbconsole: comment line ignored\n% "
    } else {
	# Check if this is an allowed command
	if { [regexp -- "^\[ \t\n\]*\$" $cmd] } {
	    puts -nonewline "\n% "
	    return
	}
	set cmd1 [lindex $cmd 0]
	if { [lsearch $allowed $cmd1] > -1 } {
	    catch { eval ::dbClientAPI::$cmd } msg
	    if { $msg == "" } {
		set msg "<Empty string returned from client API>"
	    }
	    puts -nonewline "$cmd\nResult:\n$msg\n% "
	} else {
	    puts -nonewline "$cmd1: not an allowed command\n% "
	}
    }
}

#----------------------------------------------------------------
proc readfromfile { filen allowed } {
#----------------------------------------------------------------
    # Given a filename containing a "script" of API commands
    # execute these one at a time
    if { ![file exists $filen] } {
	# Duff file
	puts "dbconsole: error reading from file $filen (file not found)"
	return
    }
    set fp [open $filen "r"]
    while { [gets $fp cmd] > -1 } {
	puts "From script: $cmd"
	process_command $cmd $allowed
    }
    close $fp
    puts -nonewline "dbconsole: end of script file\n% "
    return
}   

#----------------------------------------------------------------
proc handlebroadcast { broadcast } {
#----------------------------------------------------------------
    # Handle broadcast message from the database handler
    global ignore_broadcasts
    if { ! $ignore_broadcasts } {
	if { [llength $broadcast] > 0 } {
	    set message [lindex $broadcast 0]
	} else {
	    set message "<No message>"
	}
	if { [llength $broadcast] > 1 } {
	    set project [lindex $broadcast 1]
	} else {
	    set project "<No project>"
	}
	if { [llength $broadcast] > 2 } {
	    set job_id [lindex $broadcast 2]
	} else {
	    set job_id "<No jobid>"
	}
	if { [llength $broadcast] > 3 } {
	    set operation [lindex $broadcast 3]
	} else {
	    set operation "<No operation>"
	}
	if { [llength $broadcast] > 4 } {
	    set agent [lindex $broadcast 4]
	} else {
	    set agent "<No agent>"
	}
	puts "******************************************************"
	puts "Received broadcast message:\n"
	puts "$broadcast\n"
	puts "Message  : \"$message\""
	puts "Project  : $project"
	puts "Job Id   : $job_id"
	puts "Operation: $operation"
	puts "Agent    : $agent"
	puts "******************************************************"
	puts -nonewline "\n% "
    }
}

#################################################################
# Top-level script below here
#################################################################

# Preamble
puts "=========================================================="
puts " dbconsole for pythonic handler"
puts ""
puts " This is a \"console\" client application for the database"
puts " handler. It allows you to enter commands from the"
puts " clientAPI and see the responses from the server."
puts ""
puts " Start up options:"
puts ""
puts " -remote <hostname>:<port> : connect to a handler on a"
puts "                             remote machine (default is"
puts "                             to run on localhost)"
puts " -directories <file> : read directories.def data from"
puts "                       <file> rather than the user's"
puts "                       default directories.def file"
puts ""
puts " Built-in console commands:"
puts " wait <ms> : pause the console for <ms> milliseconds"
puts " list      : list the available commands"
puts " report_broadcasts : report broadcast messages (default)"
puts " ignore_broadcasts : don't report broadcast messages"
puts " hide_xml : suppress echoing of XML messages (default)"
puts " show_xml : echo XML messages between handler and client"
puts ""
puts " Type stop, quit or exit to exit the console application."
puts "=========================================================="
puts ""

# Deal with command line options
set nargs [llength $argv]
set hostname "localhost"
set dirsfile ""
for { set i 0 } { $i < $nargs } { incr i } {
    set option [lindex $argv $i]
    switch -- $option {
	"-remote" {
	    # Should be followed by a hostname and port specification
	    # i.e. <host>:<port>
	    incr i
	    if { [regexp -- "(\[A-Za-z0-9\.\]+):(\[0-9\]+)" \
		      [lindex $argv $i] m remotehost port] } {
		puts "Remote host = $remotehost"
		puts "Port = $port"
		set hostname $remotehost
	    } else {
		puts "Failed to match: [lindex $argv $i]"
	    }
	}
	"-directories" {
	    # Should be followed by the name of the file to use
	    # instead of the default directories.def
	    incr i
	    set dirsfile [lindex $argv $i]
	    puts "Directories file = $dirsfile"
	}
	default {
	    puts "Unrecognised option: $option"
	}
    }
}

# Start/connect to the database server
set connectCmd "DbHandlerConnect dbconsole -broadcastHandler handlebroadcast"
if { $hostname != "localhost" } {
    append connectCmd " -host $hostname -port $port"
}
if { $dirsfile != "" } {
    append connectCmd " -directories $dirsfile"
}
if { ![eval $connectCmd] } {
    puts "Failed to connect to the handler"
    exit 1
}

# Get the available commands
set command_set [get_available_commands \
		     [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]]
DbXMLSetDebug 0
# Start the event handler
# Read commands from stdin and send them to the handler
puts -nonewline "Enter commands:\n% "
fconfigure stdin -blocking 0 -buffering line
fileevent stdin readable "handle_command_line_input \"$command_set\""
vwait termination

# Disconnect
puts "Disconnecting before exit, please wait..."
DbHandlerDisconnect

# Finished
puts "=========================================================="
puts " Finished"
puts "=========================================================="
exit
