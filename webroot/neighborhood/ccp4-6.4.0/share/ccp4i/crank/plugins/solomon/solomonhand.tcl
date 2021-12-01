#!/usr/bin/env tclsh
#
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

proc DetermineHand { step tag ncycles nomtz inccp4 bias } {
    global XMLParse
    global env

    set crankplugins [file join $env(CRANK) plugins]

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    if { [info exists XMLParse([join "crank soap run step=$step solomon hand_cycles" __])] } {
        set hcycles $XMLParse([join "crank soap run step=$step solomon hand_cycles" __])
    } else {
        set hcycles 2
    }

    # run cycles on the first hand

    file mkdir hand1
    cd hand1
    set enant 1

    set solv $XMLParse([join "crank parameters solvent_content" __])
    runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 0 $inccp4 1 0 1 $step >& solomon-command.py] $verbose
    runcommand [concat ccp4-python solomon-command.py >& solomon-logfile] 1
    cd ..

    if { ($XMLParse([join "crank soap run step=$step solomon no_hand" __]) == "0") } {
	
	# run cycles on the second hand
    
	set enant 2
	if { [file exists [file join .. workdb crank.in.$tag.oh.mtz] ] } { 
	    file mkdir hand2
	    cd hand2
	    runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 0 $inccp4 1 0 1 $step >& solomon-command.py] $verbose
	    runcommand [concat ccp4-python solomon-command.py >& solomon-logfile] 1
	    cd ..
	}

	# determine hand
	set tol $XMLParse([join "crank soap run step=$step solomon margin" __])
    

 	if { [file exists [file join .. workdb crank.in.$tag.oh.mtz] ] } { 
	    solomongraph [file join hand1 solomon-logfile] [file join hand2 solomon-logfile] [file join hand1 mapro.log] [file join hand2 mapro.log] $tol $hcycles
	}
    } else {
	solomongraph [file join hand1 solomon-logfile] "" "" "" 0 0
    }
}

global env

set ncycles      [lindex $argv 0]
set nomtz        [lindex $argv 1]
set inccp4       [lindex $argv 2]
set bias         [lindex $argv 3]

source           [file join $env(CRANK) bin crankutils.tcl]

if { [file exists [file join .. xml input.xml] ] } {
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } {
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::solomonhand.tcl:: input.xml file not found"
}
 
XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

DetermineHand $step $tag $ncycles $nomtz $inccp4 $bias
