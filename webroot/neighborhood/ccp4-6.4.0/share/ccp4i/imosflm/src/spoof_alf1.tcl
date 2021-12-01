# $Id: spoof_alf1.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
proc accept {  a_sock an_addr a_port } {

    puts "Accepting connection from mosflm"

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
    if {[catch {gets $::socket l_message} result]} {
	# End of file or abnormal connection termination
	puts "Reading from socket failed: $result"
    } else {
	puts "Mosflm said: $l_message"
    }
}

proc mosflm { { debug "" } } {
    # create server socket
    set ::server [socket -server accept 0]
    # get the port
    set ::port [lindex [fconfigure $::server -sockname] 2]
    # launch mosflm and tell it to connect to the port
    
    if {$debug != "d"} {
	set pid [exec xterm -eb /andrewgrp0/andrew/mosflm/standard/mosflm/bin/mosflm MOSFLMSOCKET $::port &]
    } else {
	puts "Port: $::port"
	set pid [exec xterm -eb ladebug /andrewgrp0/andrew/mosflm/standard/mosflm/bin/mosflm &]
    }
}

proc m { args } {
    if {[catch {puts $::socket "$args"} result]} {
	error "Error sending command \"$args\" to mosflm\n$result"
    }
}


#mosflm d
