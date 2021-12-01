#
# Copyright (C) Navraj Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj Pannu 2006-2008, Leiden University
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

proc afro_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

   if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_afro.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Fa value calculation" "afro" "$crankplugins" $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-afro
    cd $step-afro
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    runcommand [concat tclsh [file join $crankplugins afro xml2afroscript.tcl] $inccp4 0 > afro-command.com ] $verbose
    runcommand [concat tclsh [file join $crankplugins afro xml2afroscript.tcl] $inccp4 1 > afro-command.tcl ] $verbose

    runcommand [concat tclsh afro-command.tcl] 1

    # Copy logfile to main log directory

    if { [file exists afro-logfile] } {
	set log [open "afro-logfile" r]
	set output [read $log]
	puts $output
	close $log

	file copy afro-logfile [file join .. log $step-afro-logfile]
    } else {
	crank_error "crank_afro.tcl::afro did not finish successfully"
    }
    
    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc afro_dependencies { step } {
    global XMLParse

}

proc afro_input_check { step } {
    global XMLParse

}

proc afro_reference { } {
    global XMLParse

    puts "Afro:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Pannu NS, Waterreus WJ,  Skubak P, Sikharulidze I, Abrahams JP &"
    puts "de Graaff RAG (2011) Recent advances in the CRANK software suite"
    puts "for experimental phasing. Acta Cryst. D67, 331-337."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}
