#
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

proc resolvedm_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_resolvedm.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Density modifcation" "Resolve" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-resolvedm
    cd $step-resolvedm
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { [info exists XMLParse([join "crank update solvent_content" __])] } {
	set solv $XMLParse(crank__update__solvent_content)
    } else {
	set solv $XMLParse(crank__parameters__solvent_content)
    }
    
    if { [info exists XMLParse([join "crank parameters sequence" __])] } {
	set seq [open seq.dat w+]
	puts $seq "$XMLParse([join "crank parameters sequence" __])"
	flush $seq
	close $seq
    }

    set substructure_tag $XMLParse([join "crank soap run step=$step input substructure" __])

    set sfile [file join .. workdb crank.out.$substructure_tag.substructure.pdb] 
	
    runcommand [concat tclsh [file join $crankplugins resolvedm xml2resolvedmscript.tcl] $sfile $solv 0 >& resolvedm-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins resolvedm xml2resolvedmscript.tcl] $sfile $solv 1 >& resolvedm-command.tcl] $verbose

    runcommand [concat tclsh resolvedm-command.tcl] $verbose

    # Rename output columns to the names specified in the XML
    if { [file exists resolvedm.out.mtz] } {
        runcommand [concat tclsh [file join $crankplugins resolvedm crank-rename-resolvedm-output.tcl] resolvedm.out.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
        crank_error "crank::runresolvedm:: resolvedm.out.mtz file not present.  Exitting."
    }

    if { [file exists resolvedm-logfile] } {

	set log [open "resolvedm-logfile" r]
	set output [read $log]
	puts $output
	close $log

	file copy resolvedm-logfile [file join .. log $step-resolvedm-logfile]
    } else {
        crank_error "crank::runresolvedm:: resolvedm-logfile file not present.  Exitting."
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc resolvedm_dependencies { step } {
    global XMLParse

    set rcommand "resolve_giant"
    set script "END\n"
    set command "$rcommand << \"$script\""
    catch {eval exec $command } output 
    set err [lindex $::errorCode 0]
    # Check to see if the executable is found
    if { [string compare $err "POSIX"] == 0 } {
	crank_error "crank::crankutils.tcl::Error resolve_giant executable not found.  Please install RESOLVE or make sure it is in your PATH - see http://www.solve.lanl.gov/ for more info."
    } else {
	puts "Found resolve_giant binary\n"
	if { [file exists resolve.ok] } {
	    file delete resolve.ok
	}
	if { [file exists resolve.plots] } {
	    file delete resolve.plots
	}
    }
}

proc resolvedm_input_check { step } {
    global XMLParse

}

proc resolvedm_reference { } {
    global XMLParse
    
    puts "RESOLVEDM:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Terwilliger TC (2000) Maximum likelihood density modification."
    puts "Acta Cryst. D56, 965-972.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
