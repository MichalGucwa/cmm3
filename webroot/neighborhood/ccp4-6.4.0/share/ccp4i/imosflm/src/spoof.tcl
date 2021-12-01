# $Id: spoof.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
proc accept {  a_sock an_addr a_port } {

    # close the server socket
    close $::server
    set ::server ""
    
    # record the name of the sock created
    set ::socket $a_sock
    
    # configure the newly created socket
    fconfigure $::socket -buffering line -translation lf -blocking false

    # appoint method to handle incoming methods
    fileevent $::socket "readable" processFeedback
}

proc processFeedback { } {
    if {[eof $::socket] || [catch {gets $::socket l_message}]} {
	# End of file or abnormal connection termination
	error "There has been a communication failure betwen mosflm and tcl.\nSorry."
    } elseif {$l_message != ""} {
	puts "Mosflm said: $l_message"
	set ::logfile [open $::filename a]
	puts $::logfile $l_message
	close $::logfile
    }
}

proc mosflm { { debug "" } } {
    set ::filename "spooflog[clock format [clock seconds] -format "%Y.%m.%d.%H%M"]"

    # create server socket
    set ::server [socket -server accept 0]
    # get the port
    set ::port [lindex [fconfigure $::server -sockname] 2]
    # launch mosflm and tell it to connect to the port
    if { $debug == "" } {
	set pid [exec $::env(MOSFLM_EXEC) spotod spotod.tmp coords coords.tmp MOSFLMSOCKET $::port &]
    } {
	set pid [exec xterm -eb "gdb --args $::env(MOSFLM_EXEC) MOSFLMSOCKET $::port" &]
    }
    # set pid [exec xterm -eb gdb $::env(MOSFLM_EXEC) &]
}

proc m { args } {
    if {[catch {puts $::socket "$args"}]} {
	error "Error sending command \"$args\" to mosflm"
    }
}

puts -nonewline "Enter any character to use gdb, otherwise just return: "
flush stdout
set debug [gets stdin]
if { $debug != "" } {
    puts "(1) use the gdb window to start Mosflm and for setting breakpoints"
    puts "(2) use this window for Mosflm commands (with preceding 'm ')"
}
mosflm $debug
