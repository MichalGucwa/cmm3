#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
#
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

proc molrep_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]


    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_molrep.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Molecular replacement" "MOLREP" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }
    
    file mkdir $step-molrep
    cd $step-molrep
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set executable [file join $crankbin  $executable]

    # Generate the MOLREP command file
    set pdb_tag $XMLParse([join "crank soap run step=$step input pdb" __])
    runcommand [concat tclsh [file join $crankplugins molrep xml2molrepscript.tcl] $inputxml [file join .. workdb crank.out.$pdb_tag.pdb] $executable $crankbin 0 >& molrep-command.com ] $verbose
    runcommand [concat tclsh [file join $crankplugins molrep xml2molrepscript.tcl] $inputxml [file join .. workdb crank.out.$pdb_tag.pdb] $executable $crankbin 1 >& molrep-command.tcl ] $verbose


    runcommand [concat tclsh molrep-command.tcl ] 1
    
    if { [file exists molrep-logfile] } {
	set log [open "molrep-logfile" r]
	set output [read $log]
	puts $output

	# Copy logfile to main log directory
	file copy molrep-logfile [file join .. log $step-molrep-logfile]

    } else {
	crank_error "crank_molrep.tcl::molrep did not finish successfully"
    }    
	
    # Rename output columns to the names specified in the XML
    if { [file exists molrep.pdb] } {
	file copy molrep.pdb [file join .. workdb crank.out.$tag.pdb]
    } else {
	crank_error "crank_molrep.tcl: molrep did not finish successfully"
    }

    # Rename output columns to the names specified in the XML
	set mtz_in [file join .. workdb crank.in.$tag.mtz]
    if { [file exists $mtz_in] } {
	runcommand [concat tclsh [file join $crankplugins molrep crank-rename-molrep-output.tcl] $inputxml $mtz_in rename.out.mtz $crankbin ] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
	crank_error "crank_molrep.tcl: molrep did not finish successfully"
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc molrep_dependencies { step } {
    global XMLParse

}

proc molrep_input_check { step } {
    global XMLParse

}

proc molrep_reference { } {
    global XMLParse    

    puts "MORLEP:"

    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "A.Vagin,A.Teplyakov, MOLREP: an automated program for molecular replacement, J. Appl. Cryst. (1997) 30, 1022-1025"
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}
