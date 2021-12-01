#!/usr/bin/env tclsh

# Copyright (C) Steven Ness and Navraj S. Pannu 2005, Leiden University 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Usage:
#   shelxd.tcl ccweak_threshold min_trials
#
# Where:
#   ccweak_threshold - Score at which to terminate SHELXD run
#   shelxd_script - SHELXD script to run
#

set ccweak_threshold [lindex $argv 0]
set min_trials [lindex $argv 1]
set max_trials [expr [lindex $argv 2] - 1]

#
# Run SHELXD
#
#puts "Running ./shelxd.tcl ccweak_threshold=($ccweak_threshold) min_trials=($min_trials)"

set shelxd_pid [exec shelxd crank_fa &]

set done 0

while { !$done } {
    after 2500
    set logfile_id [open "shelxd-logfile" r]
    set data [read $logfile_id]
    set data [split $data "\n"]
    foreach line $data {
        regsub -all {\s+} $line " " line
	if { [regexp {Try *([0-9]*), CC All\/Weak ([-0-9.]*) \/ *([-0-9.]*).*} $line all try cc ccweak] || 
             [regexp {Try *([0-9]*), CPU *([0-9]*), CC All\/Weak ([-0-9.]*) \/ *([-0-9.]*).*} $line all try cpu cc ccweak]  } {
	    if { ($ccweak >= $ccweak_threshold) && ($try > $min_trials) } {
#		puts "CCweak threshold reached"
		set done 1
		break
	    }
	    if { ($try >= $max_trials) } {
#		puts "Maximum number of trials reached"
		set done 1
		break
	    }
	} elseif { [regexp {.*SHELXD finished at.*} $line all ] } {
	    set done 1
	    break
	}
    }
    close $logfile_id
}


#
# Stop SHELXD by creating a file called "crank.fin"
#
set fin_file [open "crank_fa.fin" w]
puts $fin_file "fin."
close $fin_file
