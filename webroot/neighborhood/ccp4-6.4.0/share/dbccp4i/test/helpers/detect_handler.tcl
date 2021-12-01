#############################################################
#
# detect_handler.tcl
#
# A helper script used by run_tests.tcl to determine if a
# handler is already running in the main area
#
# Exits abnormally if a handler is detected
#
# CVS_Id $Id: detect_handler.tcl,v 1.2 2008/08/12 10:48:33 pjx Exp $
#
#############################################################
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import dbClientAPI::*
if { [set port [db_get_handler_port -nowait]] < 0 } {
    puts "No handler detected"
    exit 0
} else {
    puts "Handler detected (port $port)"
    exit 1
}
#