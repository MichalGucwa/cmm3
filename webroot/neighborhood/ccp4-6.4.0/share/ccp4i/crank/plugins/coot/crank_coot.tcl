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

proc coot_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_coot.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Model visualization" "coot" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }


    
    file mkdir $step-coot
    cd $step-coot
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { $XMLParse([join "crank soap run step=$step coot map" __]) == "1" } {
   	if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
	    set in_f $XMLParse([join "crank soap run step=$step input phase_columns f" __])
	    set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
	    set in_fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])
	    set cad_script "labin file_number 1 E1 = $in_f E2 = $in_phib E3 = $in_fom\n"
	    set cad_script "$cad_script xname file_number 1 E1 = XREF E2 = XREF E3 = XREF\n"
	    set cad_script "$cad_script dname file_number 1 E1 = DREF E2 = DREF E3 = DREF\n"
	    set command "cad HKLIN1 [file join .. workdb crank.in.$tag.mtz] HKLOUT map.mtz << \"$cad_script\" "
	    catch {eval exec $command } output 
#           puts $output
	    set script [open crank-script.scm w+]
	    puts $script "(make-and-draw-map"
	    puts $script "\"map.mtz\" \"/XREF/DREF/$in_f\""
	    puts $script "\"/XREF/DREF/$in_phib\" \"/XREF/DREF/$in_fom\" 1 0)"
	    flush $script
	    close $script
	}
    }    

    runcommand [concat tclsh [file join $crankplugins coot xml2cootscript.tcl]  0 >& coot-command.com ] $verbose
    runcommand [concat tclsh [file join $crankplugins coot xml2cootscript.tcl]  1 >& coot-command.tcl ] $verbose

    runcommand [concat tclsh coot-command.tcl ] 1

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc coot_dependencies { step } {
    global XMLParse

}

proc coot_input_check { step } {
    global XMLParse

}

proc coot_reference { } {
    global XMLParse
    
    puts "Coot:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Emsley, P. and Cowtan, K. (2004) Coot: Model-building tools for molecular"
    puts "graphics. Acta Cryst. D60, 2126-2132.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
