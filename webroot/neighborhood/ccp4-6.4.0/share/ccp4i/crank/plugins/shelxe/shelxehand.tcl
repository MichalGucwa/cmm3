#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006, Leiden University
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
#

proc DetermineHand { step tag } {
    global XMLParse
 
    set logfile1 [open [file join hand1 shelxe-logfile] r]

    if { [info exists XMLParse([join "crank soap run step=$step shelxe hand cycles" __])] } {
	set shelxecycle $XMLParse([join "crank soap run step=$step shelxe hand cycles" __])
    } else {
	set shelxecycle 25
    }

    set maxcycles 0

    set data [read $logfile1]
    set data [split $data "\n"]

# <wt> = 0.300, Contrast = 0.049, Connect. = 0.582 for dens.mod. cycle 1
# <wt> = 0.300, Contrast = 0.073, Connect. = 0.660 for dens.mod. cycle 2
# <wt> = 0.300, Contrast = 0.115, Connect. = 0.724 for dens.mod. cycle 3
# <wt> = 0.300, Contrast = 0.138, Connect. = 0.752 for dens.mod. cycle 4
# <wt> = 0.300, Contrast = 0.159, Connect. = 0.769 for dens.mod. cycle 5

    set 1contrast 0
    set found1 0

    foreach line $data {
	puts $line
	if { [regexp {<wt> = *([0-9.]*).*, Contrast = *([-0-9.]*).*, Connect. = *([-0-9.]*).* for dens.mod. cycle *([0-9]*).*} $line junk wt contrast connect number] } {
	    set maxcycles $number
	    set acontrast1($number) $contrast
	    set aconnect1($number) $connect
	    if { ($number == $shelxecycle) && !$found1 } {
#		puts "Contrast in the last cycle is  $contrast\n"
		set 1contrast $contrast
		set found1 1
	    }
	}
    }

    close $logfile1

    set logfile2 [open [file join hand2 shelxe-logfile] r]

    set data [read $logfile2]
    set data [split $data "\n"]

    set 2contrast 0
    set found2 0

    foreach line $data {
	puts $line
	if { [regexp {<wt> = *([0-9.]*).*, Contrast = *([-0-9.]*).*, Connect. = *([-0-9.]*).* for dens.mod. cycle *([0-9.]*).*} $line junk wt contrast connect number] } {
	    set maxcycles $number
	    set acontrast2($number) $contrast
	    set aconnect2($number) $connect
	    if { ($number == $shelxecycle) && !$found2 } {
		set 2contrast $contrast
		set found2 1
	    }
	}
    }
    close $logfile2

    if { $maxcycles < $shelxecycle } {
	set 1contrast acontrast1($maxcycles)
	set 2contrast acontrast2($maxcycles)
    }
 
    puts "\n\$TABLE: SHELXE Contrast and Connect. for each hand versus cycle:"
    puts "\$GRAPHS : Contrast for each hand per cycle :A:1,2,3:"
    puts "         : Connect. for each hand per cycle :A:1,4,5:"
    puts "\$\$"
    puts "Cycle     Contrast_1     Contrast_2      Connect_1     Connect_2 \$\$ \$\$"
    for {set i 1} {$i <= $maxcycles} {incr i} {
	puts [format "  %3d       %5.3f          %5.3f          %5.3f          %5.3f" $i $acontrast1($i) $acontrast2($i) $aconnect1($i) $aconnect2($i)]
    }
    puts  "\$\$\n"
    puts "\$TEXT:Result: \$\$ Final result \$\$"
    puts "Contrast for 1st hand at cycle $maxcycles is $acontrast1($maxcycles) for 2nd hand is $acontrast2($maxcycles)"
    if { $1contrast > $2contrast } {
      puts "First hand has higher contrast."
#     if { $XMLParse([join "crank soap run step=$step shelxe determine_hand" __]) == "1" } {
#       puts "The input hand will be kept."
#     } else {
#       puts "Option for hand determination not selected, but original hand has higher contrast!"
#}
    } elseif { $2contrast > $1contrast } {
      puts "Second hand has higher contrast."
#	if { $XMLParse([join "crank soap run step=$step shelxe determine_hand" __]) == "1" } {
#    puts "The input hand will be inverted."
#} else {
#    puts "Option for hand determination not selected, but enantiomorph hand has higher contrast!"
#}
    }
    puts "Total number of cycles: $maxcycles."
    puts "\$\$\n"


}

global env

set inputxml [file join .. xml input.xml]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "shelxe_hand.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

DetermineHand $step $tag
