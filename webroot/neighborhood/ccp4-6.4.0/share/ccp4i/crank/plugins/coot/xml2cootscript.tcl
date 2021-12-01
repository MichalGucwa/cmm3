#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2007-2009 Leiden University
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
#
proc OutputCootscriptfile { tcl } {
    global XMLParse

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    puts " "

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set cootargs ""

    if { [info exists XMLParse([join "crank soap run step=$step input substructure" __])] } {
	if { $XMLParse([join "crank soap run step=$step coot substructure" __]) == "1" } {
	    set sub_tag $XMLParse([join "crank soap run step=$step input substructure" __])
	    if { [file exists [file join .. workdb crank.out.$sub_tag.substructure.pdb] ] } {
		set cootargs "$cootargs --pdb [file join .. workdb crank.out.$sub_tag.substructure.pdb] "
	    }
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step input pdb" __])] } {
	if { $XMLParse([join "crank soap run step=$step coot pdb" __]) == "1" } {
	    set p_tag $XMLParse([join "crank soap run step=$step input pdb" __])
	    if { [file exists [file join .. workdb crank.out.$p_tag.pdb] ] } {
		set cootargs "$cootargs --pdb [file join .. workdb crank.out.$p_tag.pdb] "
	    }
	}
    }

    if { $XMLParse([join "crank soap run step=$step coot map" __]) == "1" } {
   	if { [file exists map.mtz]  && [file exists crank-script.scm] } {
	    set cootargs "$cootargs --script crank-script.scm "
	}
    }

    if { $tcl } {
	puts "set command \"coot $cootargs \""
	puts "eval exec \$command &"
    } else {
	puts "coot $cootargs &"
    }
}

global env

set inputxml [file join .. xml input.xml]

source [file join $env(CRANK) bin crankutils.tcl]

set tcl      [lindex $argv 0]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2cootscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputCootscriptfile $tcl 
