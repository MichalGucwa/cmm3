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

proc buccaneer_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_buccaneer.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Automated model building and refinement" "buccaneer" "[file join $crankplugins]" $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }


    file mkdir $step-buccaneer
    cd $step-buccaneer
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]    

    if { [info exists XMLParse([join "crank parameters sequence" __])] } {
	set seq [open input.seq w+]
        regsub -all {[^a-zA-Z]} $XMLParse([join "crank parameters sequence" __]) "" sequence
        for {set i 0 } { $i < [string length $sequence] } { incr i 60 } {
            if { [expr $i + 59] <  [string length $sequence] } {
                puts $seq "[string range $sequence $i [expr $i + 59] ]"
            } else {
                puts $seq "[string range $sequence $i  end]"
            }
        }
	flush $seq
	close $seq
    }

    set final_model_pdb "temporary_refmac.pdb"
    set final_mtz "temporary_refmac.mtz"
    set final_substr_pdb "heavy.pdb"

	set combined 0
    if { [info exists XMLParse([join "crank soap run step=$step buccaneer combined_dmmb" __])] } {
      set combined [string trim $XMLParse([join "crank soap run step=$step buccaneer combined_dmmb" __])]
    }
    
	if { $combined } {
      set dm_step [expr $step-1]
      set solomon 0
      set denmod "parrot"
      if {$XMLParse([join "crank soap run step=$step name" __]) == "SOLOMON" } {
        set solomon 1
        set denmod "solomon"
	  }
	  set solv $XMLParse([join "crank parameters solvent_content" __])
      set nomtz $XMLParse([join "crank soap run step=$dm_step $denmod keep_mtz" __])
      set bias 1
      if { [ info exists XMLParse([join "crank soap run step=$dm_step $denmod bias" __]) ] } {
	    set bias $XMLParse([join "crank soap run step=$dm_step $denmod bias" __])
      }
      set dm_cyc 7
      if { [ info exists XMLParse([join "crank soap run step=$dm_step $denmod init_dm_cycles" __]) ] } {
	    set dm_cyc $XMLParse([join "crank soap run step=$dm_step $denmod init_dm_cycles" __])
      }
      set final_model_pdb "refmac.pdb"
      set final_mtz "refmac.mtz"
      runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $dm_cyc $solv 1 $nomtz 0 $inccp4 0 $bias $solomon $dm_step >& buccaneer-command.py ] $verbose
	  runcommand [concat ccp4-python buccaneer-command.py >& buccaneer-logfile] 1
    } else {
      runcommand [concat tclsh [file join $crankplugins buccaneer xml2buccaneerscript.tcl] $inccp4 0 >& buccaneer-command.com ] $verbose
      runcommand [concat tclsh [file join $crankplugins buccaneer xml2buccaneerscript.tcl] $inccp4 1 >& buccaneer-command.tcl ] $verbose
      runcommand [concat tclsh buccaneer-command.tcl ] 1
    }

    if { [file exists buccaneer-logfile] } {
	set log [open "buccaneer-logfile" r]
	set output [read $log]
	puts $output
	close $log
	file copy buccaneer-logfile [file join .. log $step-buccaneer-logfile]
    } else {
	crank_error "crank_buccaneer.tcl::buccaneer did not finish successfully - no log created"
    }

    if { [file exists $final_model_pdb] } {
	file copy $final_model_pdb [file join .. workdb crank.out.$tag.pdb]
# 	file delete $final_model_pdb
    } else {
	crank_error "crank::runbuccaneer:: $final_model_pdb file not present.  Exitting."
    }

    if { [file exists $final_substr_pdb] } {
	file copy $final_substr_pdb [file join .. workdb crank.out.$tag.substructure.pdb]
#	file delete $final_substr_pdb
    }

    if { [file exists $final_mtz] } {
	runcommand [concat tclsh [file join $crankplugins buccaneer crank-rename-buccaneer-output.tcl] $final_mtz [file join .. workdb crank.out.$tag.mtz] ] $verbose
#	file delete $final_mtz
     } 

     if { [file exists temporary_buccaneer.pdb] } {
 	file delete temporary_buccaneer.pdb
     } 

     if { [file exists buccaneer.out.pdb] } {
 	file delete buccaneer.out.pdb 
     } 

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}


proc buccaneer_dependencies { step } {
    global XMLParse

    set command "cbuccaneer"
    catch {eval exec $command } output 
    set err [lindex $::errorCode 0]
    # Check to see if the executable is found
    if { [string compare $err "POSIX"] == 0 } {
	crank_error "crank::crankutils.tcl::Error cbuccaneer executable not found.  Please install BUCCANEER or make sure it is in your PATH - see http://www.ysbl.york.ac.uk/~cowtan/ for more info."
    } else {
	puts "Found cbuccaneer binary\n"
    }

    check_new_refmac
}

proc buccaneer_input_check { step } {
    global XMLParse

}

proc buccaneer_reference { } {
    global XMLParse
    
    puts "Buccaneer:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Cowtan K. (2006) The Buccaneer software for automated model building. 1."
    puts "Tracing protein chains. Acta Cryst. D62, 1002-1011."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
