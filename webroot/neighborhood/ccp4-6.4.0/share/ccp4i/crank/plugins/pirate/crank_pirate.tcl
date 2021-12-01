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

proc pirate_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_pirate.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Density modification" "Pirate" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }
    
    file mkdir $step-pirate
    cd $step-pirate
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    set ncycle 0
    set enant 1
    
    if { [file exists [file join $env(CLIBD) reference_structures reference-1ajr.mtz]] } {
	set ref [file join $env(CLIBD) reference_structures reference-1ajr.mtz] 
    } else {
	crank_error "crank::runpirate:: no reference-1ajr.mtz found in subdirectory reference_structures of $CLIBD"
    } 
    
    file mkdir hand1
    cd hand1

    runcommand [concat tclsh [file join $crankplugins pirate xml2piratescript.tcl] $enant $ref 0 >& pirate-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins pirate xml2piratescript.tcl] $enant $ref 1 >& pirate-command.tcl] $verbose

    runcommand [concat tclsh pirate-command.tcl] 1

    if { [file exists pirate-logfile] } {
	set log [open "pirate-logfile" r]
	set output [read $log]
	puts $output
	close $log
	file copy pirate-logfile [file join .. .. log $step-pirate-logfile]
    } else {
	crank_error "crank_pirate.tcl::pirate did not finish successfully"
    }

    if { [file exists pirate.mtz] } {
	runcommand [concat tclsh [file join $crankplugins pirate crank-rename-pirate-output.tcl] pirate.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
	crank_error "crank::runpirate::pirate.mtz file not present."
    }

    cd ..

    if { [file exists [file join .. workdb crank.in.$tag.oh.mtz] ] } { 
	# second hand
	set enant 2

	file mkdir hand2
	cd hand2

	runcommand [concat tclsh [file join $crankplugins pirate xml2piratescript.tcl] $enant $ref 0 >& pirate-command.com] $verbose
	runcommand [concat tclsh [file join $crankplugins pirate xml2piratescript.tcl] $enant $ref 1 >& pirate-command.tcl] $verbose

	runcommand [concat tclsh pirate-command.tcl] 1

	if { [file exists pirate-logfile] } {
	    set log [open "pirate-logfile" r]
	    set output [read $log]
	    puts $output
	    close $log
	    file copy pirate-logfile [file join .. .. log $step-oh-pirate-logfile]
	} else {
	    crank_error "crank_pirate.tcl::pirate did not finish successfully"
	}

	if { [file exists pirate.mtz] } {
	    runcommand [concat tclsh [file join $crankplugins pirate crank-rename-pirate-output.tcl] pirate.mtz rename.out.mtz] $verbose
	    file copy rename.out.mtz [file join .. .. workdb crank.out.$tag.oh.mtz]
	    file delete rename.out.mtz
	} else {
	    crank_error "crank::runpirate::pirate.mtz file not present."
	}

	cd ..
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc pirate_dependencies { step } {
    global XMLParse

}

proc pirate_input_check { step } {
    global XMLParse

}

proc pirate_reference { } {
    global XMLParse
    
    puts "Pirate:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Cowtan K (2000) General quadratic functions in real and reciprocal space and"
    puts "their applications to likelihood phasing. Acta Cryst. D56, 1612-1621.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
