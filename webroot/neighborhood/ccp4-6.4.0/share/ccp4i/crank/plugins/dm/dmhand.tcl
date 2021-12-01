#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006,  Leiden University
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


proc DetermineHand { step tag tol } {
    global XMLParse

    set logfile1 [open "[file join hand1 dm-logfile]" r]

    puts "Looking at the dm logfile for the first hand\n"

    set data [read $logfile1]
    set data [split $data "\n"]

#
# Cycle_number  Free_R_factor Real_Space_Free_R $$
# $$
#          1      0.000     0.146
#          2      0.000     0.100
# $$
    array set rfree1 {}

    foreach line $data {
	if { [regexp {          *([0-9]*)      0.000     *([-0-9.]*).*} $line junk number rfree] } {
	    if { $number != "" } {
		puts "Real space Free R in cycle $number is $rfree\n"
		set rfree1($number) $rfree
	    }
        }	    
    }

    close $logfile1

    puts "Looking at the density modification logfile for the second hand\n"

    set logfile2 [open "[file join hand2 dm-logfile]" r]

    set data [read $logfile2]
    set data [split $data "\n"]

    array set rfree2 {}

    foreach line $data {
	if { [regexp {          *([0-9]*)      0.000     *([-0-9.]*).*} $line junk number rfree] } {
	    if { $number != "" } {
		puts "Real space Free R in the cycle $number is $rfree\n"
		set rfree2($number) $rfree
	    }
	}
    }

    puts "Total number of dm cycles in first  hand: [array size rfree1]\n"
    puts "Total number of dm cycles in second hand: [array size rfree2]\n"

    close $logfile2

    set gcd [array size rfree1]
    if { [array size rfree2] < [array size rfree1] } {
	set gcd [array size rfree2]
    }

    if { ($gcd > 3) } {
	set gcd 3
    }

    set hand1 0
    set hand2 0

    if {  $rfree2($gcd) >= $rfree1($gcd)  } {
	set hand1 1
	if { ($gcd > 1) } {
	    if { [expr $rfree2(2) - $rfree1(2) ] < $tol } {
		puts "Determination of hand may be incorrect - please check logfile\n"
	    }
	}
    } else {
	set hand2 1
	if { ($gcd > 1) } {
	    if { [expr $rfree1(2) - $rfree2(2) ] < $tol } {
		puts "Determination of hand may be incorrect - please check logfile\n"
	    }
	}
    }   

    set temptag [string trim $XMLParse([join "crank soap run step=$step input phase_columns f" __])]
    set bp3tag [string trim $temptag _F]

    if {       ($hand1 == 1) } {
	puts "First hand selected\n"
	file copy [file join .. workdb crank.out.$bp3tag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
    } elseif { ($hand2 == 1) } {
	puts "Second hand selected\n"
	file copy [file join .. workdb crank.out.$bp3tag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
    } else {
	crank_error "dm_hand.tcl::Correct hand could not be determined\n"
    }
}

set inputxml [lindex $argv 0]
set crankbin [lindex $argv 1]
set margin   [lindex $argv 2]

if { [file exists $inputxml] == 0 } {
    crank_error "dmhand.tcl::inputxml file does not exist"
}

source [file join $crankbin crankutils.tcl]

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

DetermineHand $step $tag $margin
