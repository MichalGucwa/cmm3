# $Id: userprofile.tcl,v 1.11 2012/05/21 13:23:39 ccb Exp $
package provide userprofile 1.0

class UserProfile {

    private variable profile_file ""
    private variable recent_sessions {}

    private variable save_queue ""
    private variable queue_time ""

    private method pruneRecentSessions
    private method trimRecentSessions

    public method getRecentSessions
    public method addRecentSession

    public method queueSave
    public method serialize

    constructor { a_file } { }
}

body UserProfile::constructor { a_file } {
#	puts "IN CONSTRUCTOR"
    # Store session file
    set profile_file $a_file

    if {[file exists $a_file]} {

	# open the file and read the entire content
	set l_file_handle [::open $a_file r]
	set content [::read $l_file_handle]
	::close $l_file_handle

	# parse the xml into a DOM tree
	if {[catch {set dom [dom parse $content]} result]} {
	    puts "Error parsing user profile stored in: $a_file\nError message: $result"
	    puts "Bad xml: $content"
	    .m confirm \
		-type "1button" \
		-title "Error" \
		-text "Could not parse file:\n\"$a_file\"" \
		-button1of1 "Dismiss"
	    return 0
	}

	# Get the user_profile node - new from Chas 16.07.2007
	set doc [$dom documentElement]
        # Get the user_profile node
	set profile_node [$doc selectNodes /user_profile]

	# Parse list of recent sessions
	foreach i_node [$profile_node selectNodes {//recent_session}] {
	    lappend recent_sessions [namespace current]::[RecentSession \#auto "xml" $i_node]
	}
	# Prune list of recent sessions
	pruneRecentSessions

	# Parse the batch destinations
	foreach i_node [$profile_node selectNodes {//batch_destination}] {
	    set l_type [$i_node getAttribute "type"]
	    set l_name [$i_node getAttribute "name"]	    
	    if {$l_type == "local"} {
		set l_destination [namespace current]::[BatchLocal \#auto $l_name]
	    } elseif {$l_type == "remote"} {
		set l_destination [namespace current]::[BatchRemote \#auto $l_name]
		$l_destination setExecutable [$i_node getAttribute "executable"]
		$l_destination setHost [$i_node getAttribute "host"]
		$l_destination setUsername [$i_node getAttribute "username"]
		$l_destination setProtocol [$i_node getAttribute "protocol"]
	    } elseif {$l_type == "farm"} {
		set l_destination [namespace current]::[BatchFarm \#auto $l_name]
		$l_destination setCommand [$i_node getAttribute "command"]
	    } else {
		error "Unknown batch destination type in user profile"
	    }
	    $l_destination setExecutable [$i_node getAttribute "executable"]
	}
	# More than a few GUI settings here will need a function call
	set gui_pref ""
	set i_node [$profile_node selectNodes {//autoindex_relay}]
	if {$i_node != ""} {
	    set gui_pref [$i_node getAttribute "status"]
	    if {$gui_pref != ""} {
		.ats component indexing setAutoindexingRelayBool $gui_pref
	    } else {
#	puts "GUIPREF IS BLANK"
	    } 
	}
	set gui_pref ""
	set i_node [$profile_node selectNodes {//spotfinding_relay}]
	if {$i_node != ""} {
	    set gui_pref [$i_node getAttribute "status"]
	    if {$gui_pref != ""} {
		.ats component spotfinding setSpotfindingRelayBool $gui_pref
	    } else {
#	puts "GUIPREF IS BLANK"
	    } 
	}
	set gui_pref ""
	set i_node [$profile_node selectNodes {//use_scala}]
	if {$i_node != ""} {
	    set gui_pref [$i_node getAttribute "status"]
	    if {$gui_pref != ""} {
		.ats component advanced_integration setUseScalaBool $gui_pref
	    } else {
#	puts "GUIPREF IS BLANK"
	    } 
	}
    }
}

body UserProfile::pruneRecentSessions { } {
    set l_new_recent_session_list {}
    foreach i_recent_session $recent_sessions {
	if {[file exists [$i_recent_session getFilename]]} {
	    lappend l_new_recent_session_list $i_recent_session
	} else {
	    delete object $i_recent_session
	}
    }
    set recent_sessions $l_new_recent_session_list
}

body UserProfile::getRecentSessions { } {
    set l_file_list {}
    foreach i_recent_session [lsort -command RecentSession::sortByName $recent_sessions] {
	lappend l_file_list [$i_recent_session getFilename]
    }
    return $l_file_list
}

body UserProfile::addRecentSession { a_file } {
    # Create new recent session object
    set l_new_recent_session [namespace current]::[RecentSession \#auto "build" $a_file]
    # add it to list
    set recent_sessions [linsert $recent_sessions 0 $l_new_recent_session]
    # Get rid of duplicate file entries, keeping the most recent only
    set recent_sessions [lsort -unique -command RecentSession::sortByName [lsort -command RecentSession::sortByTime $recent_sessions]]
    # Trim the list (in case it's too long
    trimRecentSessions
    # Save the user profile
    serialize
}

body UserProfile::trimRecentSessions { { a_length 5 } } {
    set recent_sessions [lrange [lsort -decreasing -command RecentSession::sortByTime $recent_sessions] 0 [expr $a_length - 1]]
}

body UserProfile::queueSave { } {
    # check queue time
    if {$queue_time == ""} {
	# if there was none record time and queue save
	set queue_time [clock clicks -milliseconds]
	set save_queue [after 5000 [code $this serialize]]
    } else {
	# check time since last uncompleted queued save
	set l_time [clock clicks -milliseconds]
	set l_wait [expr $l_time - $queue_time]
	# else if it's less than 30 seconds ago, requeue
	if {$l_wait < 30000} {
	    after cancel $save_queue
	    set save_queue [after 5000 [code $this serialize]]
	} else {
	    # if it was more than 30 seconds ago, save now and clear count
	    serialize
	}
    }
}

body UserProfile::serialize { } {
    # cancel any queued save
    after cancel $save_queue
    # clear queue time
    set queue_time ""
    # open the file for writing
    set l_file_handle [::open $profile_file w]
    # write main tag, and recent_sessions tag
    puts $l_file_handle "<?xml version='1.0'?><!DOCTYPE user_profile>"
    puts $l_file_handle "<user_profile><recent_sessions>"
    # write each sesison tag
    foreach i_recent_session $recent_sessions {
	puts $l_file_handle [$i_recent_session serialize]
    }
    # close recent_sessions tag and open batch destinations tags
    puts $l_file_handle "</recent_sessions>"
    puts $l_file_handle "<batch_destinations>"
    # write batch destination tags
    foreach i_destination [BatchDestination::getDestinations] {
	puts $l_file_handle [$i_destination serialize]
    }
    # close batch destinations tag and user_profile tag
    puts $l_file_handle "</batch_destinations>"
    puts $l_file_handle "<gui_preferences>"
    puts $l_file_handle "<autoindex_relay status=\"[.ats component indexing getAutoindexingRelayBool]\"/>"
    puts $l_file_handle "<spotfinding_relay status=\"[.ats component spotfinding getSpotfindingRelayBool]\"/>"
    puts $l_file_handle "<use_scala status=\"[.ats component advanced_integration getUseScalaBool]\"/>"
    puts $l_file_handle "</gui_preferences>"
    puts $l_file_handle "</user_profile>"
#	puts "[.c getAutoindexingRelayBool]"
#	puts $l_file_handle "lalalalalalalala"
    # close file
    ::close $l_file_handle
}

# CLASS : RecentSession ############################################

class RecentSession {
    private variable filename ""
    private variable time ""

    proc sortByMethod
    proc sortByTime
    proc sortByName
    
    constructor { a_method args } {
	if {$a_method == "build"} {
	    set filename $args
	    set time [clock seconds]
	} elseif {$a_method == "xml"} {
	    set filename [$args getAttribute "filename"]
	    set time [$args getAttribute "time"]
	}
    }

    public method getFilename { } { return $filename }
    public method getTime { } { return $time }
    public method serialize { } {return "<recent_session filename=\"$filename\" time=\"$time\"/>"}
}

body RecentSession::sortByMethod { method a b } {
    if {[$a $method] < [$b $method]} {
	set result -1
    } elseif {[$a $method] > [$b $method]} {
	set result 1
    } else {
	set result 0
    }
    return $result
}

body RecentSession::sortByTime { a b } {
    return [RecentSession::sortByMethod getTime $a $b]
}

body RecentSession::sortByName { a b } {
    return [RecentSession::sortByMethod getFilename $a $b]
}
