#!/bin/sh
# $Id: expectBatch.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
# Relaunch in Mosflm's wish exectuable (don't delete backslash!) \
exec $MOSFLM_WISH "$0" ${1+"$@"}

# hide main window
wm withdraw .

# intialize dialog wait variable
set result 0

# initialize password
set password ""

# get hostname from command line arguments
set host [lindex $argv 0]

# Get username from environment variables
set user $::tcl_platform(user)

# Build pasword dialog
label .label \
    -text "Enter password for ${user}@${host}:"
entry .entry \
    -background white \
    -highlightbackground [. cget -highlightbackground] \
    -width 16 \
    -textvariable password \
    -show *
bind . <Return> [list ok]
frame .frame
button .cancel \
    -text "Cancel" \
    -width 7 \
    -pady 2 \
    -command cancel
button .ok \
    -text "Ok" \
    -width 7 \
    -pady 2 \
    -command ok \
    -default active
pack .label -fill x -padx 7 -pady 7
pack .entry -fill x -padx 7
pack .frame -fill x -pady 7
pack .ok .cancel -side right -padx [list 0 7]

# Proc to prompt user to enter password
#  - password stored in global variable "password"
#  - returns 1 if Okayed or 0 if cancelled.
proc getPassword { } {
    set ::password ""
    centreOnScreen .
    wm deiconify .
    focus .entry
    raise .
    tkwait variable ::result
    wm withdraw .
    return $::result
}

# Procs for returning from password dialog
#  = set result variable, releasing getPassword's tkwait
proc ok { } {
    set ::result 1
}
proc cancel { } {
    set ::result 0
}

# Proc to centre a window on the screen
proc centreOnScreen { a_toplevel } {
    update idletasks
    set wd [winfo reqwidth $a_toplevel]
    set ht [winfo reqheight $a_toplevel]
    set x [expr ([winfo screenwidth $a_toplevel]-$wd)/2]
    set y [expr ([winfo screenheight $a_toplevel]-$ht)/2]
    wm minsize $a_toplevel $wd $ht
    wm geometry $a_toplevel ${wd}x$ht+$x+$y
}

# Main script

# Only proceed if Expect is installed
if {![catch {package require Expect}]} {

    # set up timeout for expect
    set timeout 10

    # Spaen the ssh job
    exp_spawn -noecho ssh ${user}@${host} /ss2/geoff/bin/probe.tcl

    # Expect password promt
    expect {
	"assword:" {
	    # prompt user for password via dialog
	    if {[getPassword]} {
		# Send password, and expect eof
		exp_send "${password}\r"
		exp_continue
	    } else {
		# ...unless cancelled
		puts "Cancelled"
	    }
	}
	"try again" {
	    # prompt user for password via dialog
	    if {[getPassword]} {
		# Send password, and expect eof
		exp_send "${password}\r"
		exp_continue
	    } else {
		# ...unless cancelled
		puts "Cancelled"
	    }
	}
	"denied" {
	    tk_messageBox \
		-type ok \
		-icon error \
		-message "Permission denied to connect to $host."
	}
	"refused" {
	    tk_messageBox \
		-type ok \
		-icon error \
		-message "Connection to $host refused."
	}
	timeout {
	    tk_messageBox \
		-type ok \
		-icon error \
		-message "Timed out trying to connect to $host."
	}
    }
} else {
    tk_messageBox \
	-type ok \
	-icon error \
	-message "You need to install the tcl/tk extension \"Expect\". "
}
exit
