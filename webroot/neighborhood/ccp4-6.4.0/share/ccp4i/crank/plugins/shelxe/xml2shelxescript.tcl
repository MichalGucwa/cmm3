#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
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

proc OutputShelxescript { phifile solvent tcl invert } {
    global XMLParse

    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    #
    # Setup shelxe command line parameters
    #

    set generateheavy ""
    if { [info exists XMLParse([join "crank soap run step=$step shelxe generate_heavy" __])] } {
	if { $XMLParse([join "crank soap run step=$step shelxe generate_heavy" __]) == "1" } {
	    set generateheavy "-b"
	}  
    }

    # Set heavy flag if there is no native data present
    set heavy "-h"
    set i 1 
    while { [info exists XMLParse([join "crank parameters crystal=$i native" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == "1"  } {
	    set heavy ""
	    break
	}
	incr i
    }

    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
	set amplitude ""
    } else {
	set amplitude "-f"
    }	

    set modelbuild ""
    if { [info exists XMLParse([join "crank soap run step=$step shelxe model_build" __])] } {
	if { $XMLParse([join "crank soap run step=$step shelxe model_build" __]) == "1" } {
	    set modelbuild "-a"
	}
    } 

    set freelunch ""
	if { [info exists XMLParse([join "crank soap run step=$step shelxe free_lunch" __])] } {
	    if { $XMLParse([join "crank soap run step=$step shelxe free_lunch" __]) == "1" } {
		set reso $XMLParse([join "crank soap run step=$step shelxe free_lunch_reso" __])
		set freelunch "-e$reso"
	    } 
	}
    
    # Number of cycles of density modification to run
    if { [info exists XMLParse([join "crank soap run step=$step shelxe ncycles" __])] } {
	set cycles $XMLParse([join "crank soap run step=$step shelxe ncycles" __])
    } else {
	set cycles 100
    }

    if { $tcl } {
 	puts "\#!/usr/bin/env tclsh\n"
 	puts "file copy [file join .. crank.hkl] crank.hkl"
	if { [file exists [file join .. $phifile]] } {
	    puts "file copy [file join .. crank_fa.ins] crank.ins"
	    puts "file copy [file join .. $phifile] crank.phi"
	    puts "set command \"shelxe crank.phi -s$solvent $heavy -m$cycles $amplitude $freelunch $modelbuild >> shelxe-logfile\""
	} else {
	    puts "file copy [file join .. crank_fa.hkl] crank_fa.hkl"
	    puts "file copy [file join .. crank_fa.res] crank_fa.res"
	    puts "file copy [file join .. crank_fa.ins] crank_fa.ins"
	    puts "set command \"shelxe crank crank_fa -s$solvent $heavy -m$cycles $generateheavy $invert $amplitude $freelunch $modelbuild >> shelxe-logfile\""
	}
	puts "eval exec \$command"
	if { [file exists [file join .. $phifile]] } {
	    puts "file delete crank.hkl crank.ins crank.phi"
	} else {
	    puts "file delete crank_fa.hkl crank.hkl crank_fa.res crank_fa.ins"
	}
    } else {
	puts "\#!/bin/sh"
	puts "/bin/cp -f [file join .. crank.hkl] crank.hkl"
	if { [file exists [file join .. $phifile]] } {
	    puts "/bin/cp -f [file join .. crank_fa.ins] crank.ins"
	    puts "/bin/cp -f [file join .. $phifile] crank.phi"
	    puts "shelxe crank.phi crank_fa -s$solvent $heavy -m$cycles $generateheavy $invert $amplitude $freelunch $modelbuild >> shelxe-logfile"
	} else {
	    puts "/bin/cp -f [file join .. crank_fa.hkl] crank_fa.hkl"
	    puts "/bin/cp -f [file join .. crank_fa.res] crank_fa.res"
	    puts "/bin/cp -f [file join .. crank_fa.ins] crank_fa.ins"
	    puts "shelxe crank crank_fa -s$solvent $heavy -m$cycles $generateheavy $invert $amplitude $freelunch $modelbuild >> shelxe-logfile"
	}
	if { [file exists [file join .. $phifile]] } {
	    puts "/bin/rm -f crank_fa.hkl crank.hkl crank_fa.res crank_fa.ins crank.ins crank.phi"
	} else {
	    puts "/bin/rm -f crank_fa.hkl crank.hkl crank_fa.res crank_fa.ins"
	}
    }
}

global env

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists [file join .. xml input.xml]] } {
    set inputxml [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml]] } {
    set inputxml [file join .. .. xml input.xml]
} else {
    crank_error "xml2shelxescript.tcl::inputxml file does not exist"
}

set solv     [lindex $argv 0]
set phifile  [lindex $argv 1]
set tcl      [lindex $argv 2]
set invert   [lindex $argv 3]


XMLParsefile $inputxml

OutputShelxescript $phifile $solv $tcl $invert
