#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
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

proc dm_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_dm.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Density modification" "dm" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-dm
    cd $step-dm
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    set ncycle 0
    set enant 1

    if { [info exists XMLParse([join "crank update solvent_content" __])] } {
	set solv $XMLParse(crank__update__solvent_content)
    } else {
	set solv $XMLParse(crank__parameters__solvent_content)
    }
    
    file mkdir hand1
    cd hand1
    runcommand [concat tclsh [file join $crankplugins dm xml2dmscript.tcl] $enant $solv 0 >& dm-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins dm xml2dmscript.tcl] $enant $solv 1 >& dm-command.tcl] $verbose

    runcommand [concat tclsh dm-command.tcl] 1

    cd ..

    if { [file exists [file join .. workdb crank.in.$tag.oh.mtz]] && (1 == 2)  } {
        file mkdir hand2
        cd hand2
        set enant 2

        runcommand [concat tclsh [file join $crankplugins dm xml2dmscript.tcl] $enant $solv 0 >& dm-command.com] $verbose
        runcommand [concat tclsh [file join $crankplugins dm xml2dmscript.tcl] $enant $solv 1 >& dm-command.tcl] $verbose
	
        runcommand [concat tclsh dm-command.tcl] 1

        cd ..
    }

    set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
    if { ![file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } {
	file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
	if { [file exists [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] ] } {
	    file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
	}
    }

    # Rename output columns to the names specified in the XML
    if { [file exists [file join hand1 dm.out.mtz]] } {
	runcommand [concat tclsh [file join $crankplugins dm crank-rename-dm-output.tcl] [file join hand1 dm.out.mtz] rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
	crank_error "crank::rundm:: dm.out.mtz file not present.  Exitting."
    }

    if { [file exists [file join hand2 dm.out.mtz]] } {
	runcommand [concat tclsh [file join $crankplugins dm crank-rename-dm-output.tcl] [file join hand2 dm.out.mtz] rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.oh.mtz]
	file delete rename.out.mtz
    }

    if { [file exists [file join hand1 dm-logfile]] } {
	set log [open [file join hand1 dm-logfile] r]
	set output [read $log]
	puts $output
	close $log
	
	file copy [file join hand1 dm-logfile] [file join .. log $step-dm-logfile]
    } else {
	crank_error "crank_dm.tcl::dm did not finish successfully"
    }

    if { [file exists [file join hand2 dm-logfile]] } {
	set log [open [file join hand2 dm-logfile] r]
	set output [read $log]
	puts $output
	close $log
	
	file copy [file join hand2 dm-logfile] [file join .. log $step-oh-dm-logfile]
    } 
    
    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc dm_dependencies { step } {
    global XMLParse

}

proc dm_input_check { step } {
    global XMLParse

}

proc dm_reference { } {
    global XMLParse
    
    puts "DM:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Cowtan K (1994) Joint CCP4 and ESF-EACBM Newsletter on Protein"
    puts "Crystallography. 31, 34-38.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
