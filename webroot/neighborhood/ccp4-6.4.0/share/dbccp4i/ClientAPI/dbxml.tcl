#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - dbxml.tcl
#
# Core XML handling functions for the the Tcl database client API.
# 
# Peter Briggs
#
#====================================================================

#CCP4i_cvs_Id $Id: dbxml.tcl,v 1.9 2008/08/12 10:47:59 pjx Exp $

#d_index_title Handling dbCCP4i pseudo-XML (ClientAPI/dbxml.tcl)
#d_intro_title Internal Commands for Wrapping & Unwrapping pseudo-XML
#d_intro These are

# Fudge package loading in the absence of proper handling of
# external packages
package ifneeded xml 1.9 {
    if { [info exists env(CCP4I_TOP)] } {
	source [file join $env(CCP4I_TOP) src sgml.tcl]
	source [file join $env(CCP4I_TOP) src xml.tcl]
    } else {
	puts "CCP4I_TOP environment variable not found"
    }
}

# Make sure that the xml commands are available
package require xml 1.9

# XML debugging
set dbxml_data(DEBUG) 0

##################################################################
# Top level functions
##################################################################

#-----------------------------------------------------------
proc DbXMLSetDebug { { flag "" } } {
#-----------------------------------------------------------
#d_sum Query and optionally set the debug flag for DbXML
#d_desc The value of the debug flag determines whether \
diagnostic output is produced by the DbXML functions - if \
the flag is zero then no output is produced, otherwise \
diagnostics are printed to screen.
#d_desc The function always returns the current status of \
the debugging flag.
#d_arg flag (Optional) new value for the debug flag (0 or 1)
    global dbxml_data
    if { $flag != "" } {
	set dbxml_data(DEBUG) $flag
    }
    return $dbxml_data(DEBUG)
}

#-----------------------------------------------------------
proc DbXMLVersion { } {
#-----------------------------------------------------------
#d_sum  Returns the version of the XML functions
#d_desc Extract and return the version number from the RCS \
revision string (updated automatically by CVS) for this file.
  if { [regexp -- "(Revision: )(\[0-9\.\]+)" \
	  { $Revision: 1.9 $ } \
	  j j1 version] } {
      db_report "DbXMLVersion: $version"
      return $version
  }
  db_report "DbXMLVersion: version unknown"
  return {}
}

#-----------------------------------------------------------
proc WrapDbRequest { id command args } {
#-----------------------------------------------------------
#d_sum Wrap a db_request in pseudo-XML to send to the handler
#d_desc This command wraps the components of a request to the \
handler in the appropriate XML tags.
#d_desc Each argument in "args" is wrapped in <argument>...</argument> \
tags. However: if the argument should be treated as a list then it \
must be preceeded by a "-list" argument.
#d_arg command Handler command
#d_arg args List of arguments for the command
#d_arg id Request id string
  global dbxml_data

  # Start the command
  set xml_text "<db_request><command>$command</command>"
  # Process the arguments
  set i 0
  while { $i < [llength $args] } {
      set arg [lindex $args $i]
      if { $arg == "-list" } {
	  # The next element is a list
	  incr i
	  if { $i < [llength $args] } {
	      set arg "<list>"
	      foreach item [lindex $args $i] {
		  append arg "<item>[EscapeXmlChars $item]</item>"
	      }
	      append arg "</list>"
	  } else {
	      set arg ""
	  }
      } else {
	  set arg [EscapeXmlChars $arg]
      }
      # Add the argument
      append xml_text "<argument>$arg</argument>"
      # Go round again
      incr i
  }
  # Finish the command
  append xml_text "<request_id>$id</request_id></db_request>"
  if { $dbxml_data(DEBUG) } {
      puts "WrapDbRequest: $xml_text"
  }
  return $xml_text
}

#-----------------------------------------------------------
proc UnwrapDbRequest { line commandVar arglistVar idVar } {
#-----------------------------------------------------------
#d_sum Break a db_request pseudo-XML command into components
# Note that this version is untested
    upvar 1 $commandVar command
    upvar 1 $arglistVar arglist
    upvar 1 $idVar id

    set command ""
    set id ""
    set arglist ""

    if { ![unwrapXML $line "db_request" input] } {
	# Unable to unwrap the XML
	return 0
    } else {
	# Extract the data
	foreach pair $input {
	    set key [lindex $pair 0]
	    set value [lindex $pair 1]
	    switch -exact -- $key {
		command {
		    set command $value
		}
		arguments {
		    set arglist $value
		}
		request_id {
		    set id $value
		}
	    }
	}
    }
    # Success
    return 1
}

#-----------------------------------------------------------
proc WrapDbResponse { args } {
#-----------------------------------------------------------
#d_sum Wrap a db_response in pseudo-XML to send to the handler
# This function is not implemented
    puts "WrapDbResponse unimplemented"
    return 0
}

#-----------------------------------------------------------
proc UnwrapDbResponse { line statusVar resultVar idVar } {
#-----------------------------------------------------------
#d_sum Break a db_response pseudo-XML command into components
#d_desc Return 1 on success, 0 if there is an error
    upvar 1 $statusVar status
    upvar 1 $resultVar result
    upvar 1 $idVar id

    set status ""
    set id ""
    set result ""
    set nresults 0

    ##puts "UnwrapDbResponse: $line"

    if { ![unwrapXML $line "db_response" input] } {
	# Unable to unwrap the XML
	set status "ERROR"
	set result "Unable to unwrap response XML"
	return 0
    } else {
	# Extract the data
	##puts "Unwrapped: $input"
	foreach pair $input {
	    set key [lindex $pair 0]
	    set value [lindex $pair 1]
	    ##puts "* pair  = $pair"
	    ##puts "* key   = $key"
	    ##puts "* value = $value"
	    switch -exact -- $key {
		status {
		    set status $value
		}
		result {
		    # If there is more than one result tag then
		    # return a list rather a single value
		    incr nresults
		    if { $nresults == 1 } {
			set result $value
		    } elseif { $nresults == 2 } {
			set result [list $result $value]
		    } else {
			lappend result $value
		    }
		}
		response_id {
		    set id $value
		}
	    }
	}
    }
    # Success
    return 1
}

#-----------------------------------------------------------
proc WrapDbBroadcast { message } {
#-----------------------------------------------------------
#d_sum Wrap a broadcast message in pseudo-XML
  set arglist [list [list "message" $message]]
  return [wrapXML "db_broadcast" $arglist]
}

#-----------------------------------------------------------
proc UnwrapDbBroadcast { line broadcastVar } {
#-----------------------------------------------------------
#d_sum Break a db_broadcast pseudo-XML message into components
#d_desc Return 1 on success, 0 if there is an error
    upvar 1 $broadcastVar broadcast

    set message ""
    set project ""
    set jobid ""
    set operation ""
    set agent ""
  
    unwrapXML $line "db_broadcast" input
 
    if { ![unwrapXML $line "db_broadcast" input] } {
	# Unable to unwrap the XML
	return 0
    } else {
	# Extract the data
	foreach pair $input {
	    set key [lindex $pair 0]
	    set value [lindex $pair 1]
	    switch -exact -- $key {
		message {
		    set message $value
		}
		project {
		    set project $value
		}
		jobid {
		    set jobid $value
		}
		operation {
		    set operation $value
		}
		agent {
		    set agent $value
		}
	    }
	}
    }
    set broadcast [list $message $project $jobid $operation $agent]
    # Success
    return 1
}

##################################################################
# Top level generic wrap/unwrap functions
##################################################################

#-----------------------------------------------------------
proc wrapXML { tag arglist } {
#-----------------------------------------------------------
# Generic XML wrapping
#
# Input should be a primary tag plus a list of key-value pairs
# e.g. tag = "db_response" and arglist = "{status OK} {result 30}"
# wrap will return pseudo-XML of the form
# <tag><key1>value1</key1>...</tag>
# e.g. <db_request><command>OpenDatabase</command><argument>CHOOCH</argument></db_request>
# Note that it cannot currently deal with nested tags, so is only
# really useful for db_requests.
    global dbxml_data

    set xmltext "<$tag>"
    foreach pair $arglist {
	set key [lindex $pair 0]
	append xmltext "<$key>[lindex $pair 1]</$key>"
    }
    append xmltext "</$tag>"
    if { $dbxml_data(DEBUG) } {
	puts "wrapXML: $xmltext"
    }
    return $xmltext
}

#-----------------------------------------------------------
proc unwrapXML { xmltext tag resultVar } {
#-----------------------------------------------------------
# Generic XML unwrapping
#
# Given text in XML format plus the name of a top-level
# tag (can be either "db_response" or "db_broadcast", process
# the XML and return a list of key-value pairs in resultVar
#
# This function uses the xml.tcl and sgml.tcl libraries,
# with the callback functions HandleXmlStartTag, HandleXmlEndTag
# and HandleXmlCharacterData
#
    global dbxml_data
    upvar 1 $resultVar result

    if { $dbxml_data(DEBUG) } { 
	puts "unwrapXML: $xmltext"
	puts "unwrapXML: $tag"
    }

    # Initialise internals
    set dbxml_data(ERROR_STATUS) 0
    set dbxml_data(ERROR_MESSAGE) 0
    set dbxml_data(CONTEXT) {}
    set dbxml_data(N_LIST) 0
    set dbxml_data(PENDING_ITEM) 0
    set dbxml_data(PENDING_ITEM_DATA) {}
    set dbxml_data(DB_RESPONSE) 0
    set dbxml_data(RESPONSE_ID) {}
    set dbxml_data(STATUS) {}
    set dbxml_data(RESULT) {}
    set dbxml_data(DB_BROADCAST) 0
    set dbxml_data(MESSAGE) {}
    set dbxml_data(DB_REQUEST) 0
    set dbxml_data(COMMAND) 0
    set dbxml_data(ARGUMENTS) {}

    #################
    set dbxml_data(PROJECT) {}
    set dbxml_data(JOBID) {}
    set dbxml_data(OPERATION) {}
    set dbxml_data(AGENT) {}
    ###############

    # Initialise and configure the XML parser
    set parser [ xml::parser ]
    $parser configure -elementstartcommand HandleXmlStartTag
    $parser configure -elementendcommand HandleXmlEndTag
    $parser configure -characterdatacommand HandleXmlCharacterData

    # Read and parse the specified file
    if { [catch { $parser parse $xmltext } err] } {
	# This is severe error at the level of the
	# parser
	puts "unwrapXML: SEVERE ERROR"
	puts "unwrapXML: The XML parser has failed with the following error:"
	puts "unwrapXML: $err"
	puts "unwrapXML: failing XML (with newline appended):"
	puts "$xmltext\n"
	# Set ERROR_STATUS and ERROR_MESSAGE so that the existing
	# error handling can take over
	set dbxml_data(ERROR_STATUS) 1
	set dbxml_data(ERROR_MESSAGE) "$err"
    }

    # Write out results
    if { $dbxml_data(ERROR_STATUS) } {
	# An error occurred
	puts "Error parsing the XML: $dbxml_data(ERROR_MESSAGE)"
	set result "$dbxml_data(ERROR_MESSAGE)"
	return 0
    }

    if { $tag == "db_response" && $dbxml_data(DB_RESPONSE) } {
	#
	if { $dbxml_data(DEBUG) } {
	    puts "Response:"
	    puts "\tstatus = $dbxml_data(STATUS)"
	    puts "\tid     = $dbxml_data(RESPONSE_ID)"
	    puts "\tresult = $dbxml_data(RESULT)"
	}
	set result [list \
			[list "status" $dbxml_data(STATUS)] \
			[list "response_id" $dbxml_data(RESPONSE_ID)] \
			[list "result" $dbxml_data(RESULT)]]
	return 1
    }
    if { $tag == "db_broadcast" && $dbxml_data(DB_BROADCAST) } {
	#
	if { $dbxml_data(DEBUG) } {
	    puts "Broadcast:"
	    puts "\tmessage = $dbxml_data(MESSAGE)"
	}
	######################
	set result [list \
			[list "message" $dbxml_data(MESSAGE)] \
			[list "project" $dbxml_data(PROJECT)] \
			[list "jobid" $dbxml_data(JOBID)] \
			[list "operation" $dbxml_data(OPERATION)] \
			[list "agent" $dbxml_data(AGENT)]] 
	return 1
    }
    if { $tag == "db_request" && $dbxml_data(DB_REQUEST) } {
	#
	if { $dbxml_data(DEBUG) } {
	    puts "Request:"
	    puts "\tcommand = $dbxml_data(COMMAND)"
	}
	set result [list \
			[list "command" $dbxml_data(COMMAND)] \
			[list "request_id" $dbxml_data(REQUEST_ID)] \
			[list "arguments"  $dbxml_data(ARGUMENTS)]]
	return 1
    }

    # Nothing matched so must be an error
    return 0
}

#-----------------------------------------------------------
proc HandleXmlStartTag { name attlist } {
#-----------------------------------------------------------
    # Callback function used by the XML parser
    #
    # When the parser finds an opening tag it calls
    # this procedure with the tag name and the
    # attribute list
    #
    global dbxml_data
    ##puts "Encountered start tag \"$name\""

    # Clear any pending item data
    set dbxml_data(PENDING_ITEM) 0
    set dbxml_data(PENDING_ITEM_DATA) {}

    switch $name {
	db_response {
	    # Opening a db_response tag
	    set dbxml_data(DB_RESPONSE) 1
	    lappend dbxml_data(CONTEXT) "db_response"
	    return
	}
	result {
	    # Opening a result tag
	    # This can only be inside a db_response tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_response"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<result> encountered outside <db_response> context"
		return
	    }
	    # Open result context
	    lappend dbxml_data(CONTEXT) "result"
	    return
	}
	status {
	    # Opening a status tag
	    # This can only be inside a db_response tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_response"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<status> encountered outside <db_response> context"
		return
	    }
	    # Open status context
	    lappend dbxml_data(CONTEXT) "status"
	    return
	}
	response_id {
	    # Opening a response_id tag
	    # This can only be inside a db_response tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_response"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<response_id> encountered outside <db_response> context"
		return
	    }
	    # Open result context
	    lappend dbxml_data(CONTEXT) "response_id"
	    return
	}
	list {
	    # Opening a list tag
	    # This can only be inside a result tag or an item tag
	    if { [lsearch $dbxml_data(CONTEXT) "result"] < 0 && \
		     [lsearch $dbxml_data(CONTEXT) "item"] < 0 } {
		# Error[list "message" $dbxml_data(MESSAGE)] 
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<list> encountered outside <result> or <item> context"
		return
	    }
	    # Open list context
	    ##puts "Opening list context"
	    lappend dbxml_data(CONTEXT) "list"
	    set i [incr dbxml_data(N_LIST)]
	    ##puts "\tLevel $i"
	    set dbxml_data(CURRENT_LIST_$i) {}
	    return
	}
	item {
	    # Opening an item tag
	    # This can only be inside a list tag
	    if { [lsearch $dbxml_data(CONTEXT) "list"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<item> encountered outside <list> context"
		return
	    }
	    # Open list context
	    lappend dbxml_data(CONTEXT) "item"
	    set dbxml_data(PENDING_ITEM) 1
	    return
	}
	db_broadcast {
	    # Opening a db_broadcast tag
	    set dbxml_data(DB_BROADCAST) 1
	    lappend dbxml_data(CONTEXT) "db_broadcast"
	    return
	}
	message {
	    # Opening a message tag
	    # This can only be inside a db_broadcast tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_broadcast"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<message> encountered outside <db_broadcast> context"
		return
	    }
	    # Open message context
	    lappend dbxml_data(CONTEXT) "message"
	    return
	}
	project {
	    # Opening a message tag
	    # This can only be inside a db_broadcast tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_broadcast"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<project> encountered outside <db_broadcast> context"
		return
	    }
	    # Open message context
	    lappend dbxml_data(CONTEXT) "project"
	    return
	}
	jobid {
	    # Opening a message tag
	    # This can only be inside a db_broadcast tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_broadcast"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<jobid> encountered outside <db_broadcast> context"
		return
	    }
	    # Open message context
	    lappend dbxml_data(CONTEXT) "jobid"
	    return
	}
	operation {
	    # Opening a message tag
	    # This can only be inside a db_broadcast tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_broadcast"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<operation> encountered outside <db_broadcast> context"
		return
	    }
	    # Open message context
	    lappend dbxml_data(CONTEXT) "operation"
	    return
	}
	agent {
	    # Opening a message tag
	    # This can only be inside a db_broadcast tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_broadcast"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<agent> encountered outside <db_broadcast> context"
		return
	    }
	    # Open message context
	    lappend dbxml_data(CONTEXT) "agent"
	    return
	}
	db_request {
	    # Opening a db_request tag
	    set dbxml_data(DB_REQUEST) 1
	    lappend dbxml_data(CONTEXT) "db_request"
	    return
	}
	command {
	    # Opening a command tag
	    # This can only be inside a db_request tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_request"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<command> encountered outside <db_request> context"
		return
	    }
	    # Open list context
	    lappend dbxml_data(CONTEXT) "command"
	    return
	}
	argument {
	    # Opening an argument tag
	    # This can only be inside a db_request tag
	    if { [lsearch $dbxml_data(CONTEXT) "db_request"] < 0 } {
		# Error
		set dbxml_data(ERROR_STATUS) 1
		set dbxml_data(ERROR_MESSAGE) \
		    "<argument> encountered outside <db_request> context"
		return
	    }
	    # Open list context
	    lappend dbxml_data(CONTEXT) "argument"
	    return
	}
    }
    return
}

#-----------------------------------------------------------
proc HandleXmlEndTag { name } {
#-----------------------------------------------------------
    # Callback function used by the XML parser
    #
    # When the parser encounters a closing XML tag it
    # calls this function with the tag name
    #
    global dbxml_data
    ##puts "Encountered end tag \"$name\""
    ##puts "Current context: $dbxml_data(CONTEXT)"

    # Check the context is correct
    if { [lindex $dbxml_data(CONTEXT) end] != "$name" } {
	# Error - wrong context
	set dbxml_data(ERROR_STATUS) 1
	set dbxml_data(ERROR_MESSAGE) \
	    "</$name> encountered outside <$name> context"
	return
    }

    # Context is correct - perform any specialised
    # processing required for particular tags
    switch $name {
	item {
	    # Closing an item tag
	    # If there is pending character data then store this in
	    # the current list
	    if { $dbxml_data(PENDING_ITEM) } {
		set i $dbxml_data(N_LIST)
		lappend dbxml_data(CURRENT_LIST_$i) $dbxml_data(PENDING_ITEM_DATA)
		set dbxml_data(PENDING_ITEM) 0
		set dbxml_data(PENDING_ITEM_DATA) {}
		##puts "Item added to list at level $i: $dbxml_data(CURRENT_LIST_$i)"
	    }
	}
	list {
	    # Closing a list tag
	    set i $dbxml_data(N_LIST)
	    if { $i == 1 } {
		# This is the top level list
		set dbxml_data(RESULT) $dbxml_data(CURRENT_LIST_$i)
	    } else {
		# Nested list
		set j [incr dbxml_data(N_LIST) -1]
		lappend dbxml_data(CURRENT_LIST_$j) $dbxml_data(CURRENT_LIST_$i)
		unset dbxml_data(CURRENT_LIST_$i)
	    }
	}
    }

    # Adjust the current context
    set dbxml_data(CONTEXT) [lreplace $dbxml_data(CONTEXT) end end]
}

#-----------------------------------------------------------
proc HandleXmlCharacterData { cdata } {
#-----------------------------------------------------------
    # Callback function used by the XML parser
    #
    # When the parser encounters character data it
    # calls this function with the data as the argument
    #
    # Note that the xml.tcl functions automatically perform
    # unescaping of an escaped XML special characters
    global dbxml_data
    ##puts "Encountered character data:  \"$cdata\""
    ##puts "Current context: $dbxml_data(CONTEXT)"
    
    # Deal with character data based on the context

    # response status context
    if { [lindex $dbxml_data(CONTEXT) end] == "status" } {
	set dbxml_data(STATUS) "$cdata"
	return
    }

    # response result context
    if { [lindex $dbxml_data(CONTEXT) end] == "result" } {
	if { "$cdata" != "" } {
	    append dbxml_data(RESULT) "$cdata"
	}
	return
    }

    # response response_id context
    if { [lindex $dbxml_data(CONTEXT) end] == "response_id" } {
	set dbxml_data(RESPONSE_ID) "$cdata"
	return
    }

    # list item context
    if { [lindex $dbxml_data(CONTEXT) end] == "item" } {
	# Problem here is that if the data is blank then it could
	# be that it isn't "real" data i.e. the item just contains
        # more tags
	# Store it and then process it when the closing item tag
	# is encountered
	append dbxml_data(PENDING_ITEM_DATA) "$cdata"
	return
    }

    # broadcast message context
    if { [lindex $dbxml_data(CONTEXT) end] == "message" } {
	set dbxml_data(MESSAGE) "$cdata"
	return
    }

    ##################################
    if { [lindex $dbxml_data(CONTEXT) end] == "project" } {
	set dbxml_data(PROJECT) "$cdata"
	return
    }

    if { [lindex $dbxml_data(CONTEXT) end] == "jobid" } {
	set dbxml_data(JOBID) "$cdata"
	return
    }

    if { [lindex $dbxml_data(CONTEXT) end] == "operation" } {
	set dbxml_data(OPERATION) "$cdata"
	return
    }

    if { [lindex $dbxml_data(CONTEXT) end] == "agent" } {
	set dbxml_data(AGENT) "$cdata"
	return
    }
    ##################################
    

    # request command context
    if { [lindex $dbxml_data(CONTEXT) end] == "command" } {
	set dbxml_data(COMMAND) "$cdata"
	return
    }

    # request argument context
    if { [lindex $dbxml_data(CONTEXT) end] == "argument" } {
	lappend dbxml_data(ARGUMENTS) "$cdata"
	return
    }
}

#-----------------------------------------------------------
proc EscapeXmlChars { cdata } {
#-----------------------------------------------------------
#d_sum Convert special XML characters to their escaped form
#d_desc This function returns the cdata string with any XML \
special characters (<,> and &) converted to their escaped form \
("&lt;", "&gt;" and "&amp;" respectively).
#d_arg cdata The character data to be converted
    regsub -all "&" $cdata {\&amp;} cdata
    regsub -all "<" $cdata {\&lt;} cdata
    regsub -all ">" $cdata {\&gt;} cdata
    return $cdata
}

#-----------------------------------------------------------
proc UnescapeXmlChars { cdata } {
#-----------------------------------------------------------
#d_sum Convert escaped special XML characters to their original form
#d_desc This function returns the cdata string with any escaped XML \
special characters ("&lt;", "&gt;" and "&amp;") converted to their \
original (unescaped) form ("&lt;", "&gt;" and "&amp;" respectively).
#d_desc It turns out that the xml.tcl parser functions perform \
the unescaping functions automatically, so for now this function \
is not required. It is retained because it may be useful in future.
#d_arg cdata The character data to be converted
    regsub -all "&amp;" $cdata {\&} cdata
    regsub -all "&lt;" $cdata {<} cdata
    regsub -all "&gt;" $cdata {>} cdata
    return $cdata
}
