#############################################################
#
# rude_client.tcl
#
# Client application that connects to the handler and then
# severs the connection without disconnecting
#
# CVS_Id $Id: rude_client.tcl,v 1.9 2008/08/12 10:48:30 pjx Exp $
#
#############################################################

# Announce yourself
puts "=========================================================="
puts " rude_client\n"
puts " Connect to the handler and then exit without"
puts " disconnecting"
puts "==========================================================\n"

# Acquire the handler client API functions
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*

# Start the handler
if { ![DbStartHandler] } {
    puts "Test failed: couldn't start the handler"
    exit 1
}

# Connect to the handler
if { ![DbHandlerConnect rude_client] } {
    puts "Test failed: couldn't connect to the handler"
    exit 1
}

# List the available projects
set projects [ListProjects]
puts "Projects: $projects\n"

# Wait for a while
puts "Waiting for 5 seconds...\n"
after 5000

# Exit without disconnecting
puts "Exiting prematurely on purpose"
exit 0

