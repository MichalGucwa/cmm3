#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
#
# dbobserver.tcl
#
# An "observer" client application for dbccp4i
#
# Monitors the user's projects and reports any broadcasts
# received from the handler.
#
# Usage:
# > tclsh[8.*] dbobserver.tcl
#
#====================================================================
#
#Cvs_Id $Id: dbobserver.tcl,v 1.9 2008/08/12 10:48:04 pjx Exp $
#
#####################################################################

# Acquire the external database procedures from the CCP4i core
#source [file join $env(CCP4I_TOP) src database.tcl]
#source [file join $env(CCP4I_TOP) src dbClientAPI.tcl]
source [file join $env(BIOXHIT_TOP) dbccp4i/ClientAPI dbClientAPI.tcl]

#################################################################
# Application procedures
#################################################################

#----------------------------------------------------------------
proc handlebroadcast { broadcast } {
#----------------------------------------------------------------
    # Handle broadcast message from the database handler
    puts "******************************************************"
    puts "Received broadcast message:\n\n$broadcast"
    puts "******************************************************"
}

#################################################################
# Top-level script below here
#################################################################

# Preamble
puts "=========================================================="
puts " dbobserver"
puts ""
puts " This is an \"observer\" client application for the"
puts " database handler. It echoes broadcasts received from the"
puts " handler."
puts "=========================================================="
puts ""

# Start/connect to the database server
if { ![DbStartHandler handlebroadcast] } {
    puts "Failed to start the handler"
    exit 1
}
if { ![DbHandlerConnect] } {
    puts "Failed to connect to the handler"
    exit 1
}

# Report that we're connected
puts "Connected to handler"

# Get a list of all projects
set projects [ListProjects]
puts "Available projects: $projects"

# Open all projects
foreach project $projects {
    puts "Opening $project"
    OpenDatabase $project msg
}
puts "Waiting for broadcasts..."

# Enter the event loop
vwait termination

# Disconnect
DbHandlerDisconnect

# Finished
puts "=========================================================="
puts " Finished"
puts "=========================================================="
exit
