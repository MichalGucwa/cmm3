#############################################################
#
# test_dbxml.tcl
#
# Test script for the dbxml.tcl functions
#
# To run do:
# > tclsh test_dbxml.tcl
#
# CVS_Id $Id: test_dbxml.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
##############################################################
#
puts "=============================================================="
puts "test_dbxml"
puts "=============================================================="
puts "Acquiring functions..."
# Acquire the functions
if { [catch { source \
		  [file join $env(DBCCP4I_TOP) ClientAPI dbxml.tcl] \
	      } err] } {
    puts "Failed to source dbxml.tcl: $err"
    exit 1
}

# Explicitly turn off debugging
DbXMLSetDebug 0

# Test escaping and unescaping special XML characters
puts "---------------------------------"
puts "Test (un)escaping special XML characters"
puts "---------------------------------"

set cdata "<This&that>&the other!"
if { [EscapeXmlChars $cdata] != "&lt;This&amp;that&gt;&amp;the other!" } {
    puts "Failed test 1"
    exit 1
}
set cdata "&lt;This&amp;that&gt;&amp;the other!"
if { [UnescapeXmlChars $cdata] != "<This&that>&the other!" } {
    puts "Failed test 2"
    exit 1
}
# Finished
puts "All tests successful"

# Test wrapping XML requests
puts "---------------------------------"
puts "Test XML wrapping (WrapDbRequest)"
puts "---------------------------------"

# Test a basic request
if { [WrapDbRequest "Req1" "GenericCmd" "Value1"] !=
     "<db_request><command>GenericCmd</command><argument>Value1</argument><request_id>Req1</request_id></db_request>" } {
    puts "Failed test 1"
    exit 1
}
# Test a request with two arguments
if { [WrapDbRequest "Req2" "GenericCmd" "Value1" "Value2"] !=
     "<db_request><command>GenericCmd</command><argument>Value1</argument><argument>Value2</argument><request_id>Req2</request_id></db_request>" } {
    puts "Failed test 2"
    exit 1
}
# Test a request with a list argument
if { [WrapDbRequest "Req3" "GenericCmd" -list "Value1 Value2"] !=
     "<db_request><command>GenericCmd</command><argument><list><item>Value1</item><item>Value2</item></list></argument><request_id>Req3</request_id></db_request>" } {
    puts "Failed test 3"
    exit 1
}
# Test a request with a list argument and two non-list arguments
if { [WrapDbRequest "Req4" "GenericCmd" "Value1" -list "Value2 Value3" "Value4"] !=
     "<db_request><command>GenericCmd</command><argument>Value1</argument><argument><list><item>Value2</item><item>Value3</item></list></argument><argument>Value4</argument><request_id>Req4</request_id></db_request>" } {
    puts "Failed test 4"
    exit 1
}
# Test a request with a list argument and special characters
if { [WrapDbRequest "Req3" "GenericCmd" -list "<Value1> <Value2>"] !=
     "<db_request><command>GenericCmd</command><argument><list><item>&lt;Value1&gt;</item><item>&lt;Value2&gt;</item></list></argument><request_id>Req3</request_id></db_request>" } {
    puts "Failed test 5"
    exit 1
}
# Test a request with a list argument and two non-list arguments
# with special XML characters
if { [WrapDbRequest "Req4" "GenericCmd" "Value1" -list "<Value2> &Value3&" "Value>&4"] !=
     "<db_request><command>GenericCmd</command><argument>Value1</argument><argument><list><item>&lt;Value2&gt;</item><item>&amp;Value3&amp;</item></list></argument><argument>Value&gt;&amp;4</argument><request_id>Req4</request_id></db_request>" } {
    puts "Failed test 6"
    exit 1
}
# Finished
puts "All tests successful"

# Test unwrapping XML responses
puts "---------------------------------"
puts "Test XML unwrapping (UnwrapDbResponse)"
puts "---------------------------------"

# Test basic response
if { ![UnwrapDbResponse "<db_response><status>OK</status><result>True</result><response_id>request#1</response_id></db_response>" status result id] } {
    puts "Failed test 1/1"
    exit 1
}
if { $status != "OK" || $result != "True" || $id != "request#1" } {
    puts "Failed test 1/2"
    exit 1
}

# Test response containing a list
if { ![UnwrapDbResponse "<db_response><status>OK</status><result><list><item>CSTAFF</item><item>JUNK</item><item>RCSB_DEMOS</item><item>CHOOCH</item><item>PROBLEMS</item><item>PROJECT</item><item>DYNDOM</item><item>SHELX</item><item>MR_TUTORIAL</item><item>EMPTY</item><item>SHELX_TEST</item></list></result><response_id>request#2</response_id></db_response>" status result id] } {
    puts "Failed test 2/1"
    exit 1
}
if { $status != "OK" || $result != "CSTAFF JUNK RCSB_DEMOS CHOOCH PROBLEMS PROJECT DYNDOM SHELX MR_TUTORIAL EMPTY SHELX_TEST" || $id != "request#2" } {
    puts "Failed test 2/2"
    exit 1
}

# Test basic response with escaped XML special characters
if { ![UnwrapDbResponse "<db_response><status>OK</status><result>&lt;True&gt;</result><response_id>request#1</response_id></db_response>" status result id] } {
    puts "Failed test 3/1"
    exit 1
}
#puts "status $status result $result id $id"
if { $status != "OK" || $result != "<True>" || $id != "request#1" } {
    puts "Failed test 3/2"
    exit 1
}

# Test response containing a list with escaped XML special characters
if { ![UnwrapDbResponse "<db_response><status>OK</status><result><list><item>&lt;CSTAFF&gt;</item><item>JUNK</item><item>RCSB_DEMOS</item><item>CHOOCH</item><item>PROBLEMS</item><item>PROJECT</item><item>DYNDOM</item><item>SHELX</item><item>MR_TUTORIAL</item><item>EMPTY</item><item>SHELX_TEST</item></list></result><response_id>request#2</response_id></db_response>" status result id] } {
    puts "Failed test 4/1"
    exit 1
}
#puts "status $status result $result id $id"
if { $status != "OK" || $result != "<CSTAFF> JUNK RCSB_DEMOS CHOOCH PROBLEMS PROJECT DYNDOM SHELX MR_TUTORIAL EMPTY SHELX_TEST" || $id != "request#2" } {
    puts "Failed test 4/2"
    exit 1
}
# Finished
puts "All tests successful"

# Test unwrapping XML broadcasts
puts "---------------------------------"
puts "Test XML unwrapping (UnwrapDbBroadcast)"
puts "---------------------------------"

# Test basic broadcast message
if { ![UnwrapDbBroadcast "<db_broadcast><message>Update JUNK 15</message><project>JUNK</project><jobid>15</jobid><operation>job created</operation><agent>dbconsole</agent></db_broadcast>" broadcast] } {
    puts "Failed test 5/1"
    exit 1
}
if { [llength $broadcast] != 5 } {
    puts "Failed test 5/2"
    exit 1
}   
if { [lindex $broadcast 0] != "Update JUNK 15" } {
    puts "Failed test 5/3"
    exit 1
}
if { [lindex $broadcast 1] != "JUNK" } {
    puts "Failed test 5/3"
    exit 1
}
if { [lindex $broadcast 2] != "15" } {
    puts "Failed test 5/4"
    exit 1
}
if { [lindex $broadcast 3] != "job created" } {
    puts "Failed test 5/5"
    exit 1
}
if { [lindex $broadcast 4] != "dbconsole" } {
    puts "Failed test 5/6"
    exit 1
}
# Finished
puts "All tests successful"
#
exit 0
