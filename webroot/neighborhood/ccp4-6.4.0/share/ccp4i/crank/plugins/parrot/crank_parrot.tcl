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

proc parrot_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_parrot.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Density modification" "Parrot" $crankplugins $xmlversion

    set verbose 0
    
    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    set ex [file join $env(CBIN) cparrot]

    file mkdir $step-parrot
    cd $step-parrot
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    
    set enant 1
	

   if { [info exists XMLParse([join "crank soap run step=$step parrot ncycles" __])] } {
        set ncycles $XMLParse([join "crank soap run step=$step parrot ncycles" __])
    } else {
        set ncycles 20
    }

    set nomtz 1
    if { $XMLParse([join "crank soap run step=$step parrot keep_mtz" __]) == "1" } {
       set nomtz 0
    }

    file mkdir hand1
    cd hand1

    if { [file exists [file join $env(CLIBD) reference_structures reference-1ajr.mtz]] } {
	set ref [file join $env(CLIBD) reference_structures reference-1ajr.mtz] 
	set refpdb [file join $env(CLIBD) reference_structures reference-1ajr.pdb]
    } else {
	crank_error "crank::runparrot:: no reference-1ajr.mtz found in subdirectory reference_structures of $CLIBD"
    } 

    set solv $XMLParse([join "crank parameters solvent_content" __])

    # ***NSP - probably should add parrot version control...
    set bias 1

    if { [info exists XMLParse([join "crank soap run step=$step parrot bias" __]) ] } {
	if { $XMLParse([join "crank soap run step=$step parrot bias" __]) == "0" } {
	    set bias 0
	}
    }    

    if { $bias } {

	runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 1 $inccp4 0 $bias 0 $step >& parrot-command.py] $verbose
	runcommand [concat ccp4-python parrot-command.py >& parrot-logfile] 1
#	catch { solomongraph [file join solomon-$solv parrot-logfile] "" 0 0 } output
#	set log [open "parrot-logfile" a+]
#	puts $log $output
#	close $log
#	set solomonmtz "[file join hand1 parrot.mtz]"
#	file copy parrot_cycle_$ncycles.mtz parrot.mtz

    } else {
	#runcommand [concat tclsh [file join $crankplugins parrot xml2parrotscript.tcl] $enant $ref $refpdb 0 >& parrot-command.com] $verbose
	runcommand [concat tclsh [file join $crankplugins parrot xml2parrotscript.tcl] $enant $ref $refpdb 1 >& parrot-command.py] $verbose
	runcommand [concat ccp4-python parrot-command.py >& parrot-logfile] 1
    }

    if { [file exists parrot-logfile] } {
	set log [open "parrot-logfile" r]
	set output [read $log]
	puts $output
	close $log
	file copy parrot-logfile [file join .. .. log $step-parrot-logfile]
    } else { 
	crank_error "crank_parrot.tcl::parrot did not finish successfully"
    }

    if { [file exists parrot.mtz] } {
	runcommand [concat tclsh [file join $crankplugins parrot crank-rename-parrot-output.tcl] parrot.mtz rename.out.mtz $bias $ncycles] $verbose
	file copy rename.out.mtz [file join .. .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
	crank_error "crank::runparrot:: parrot.mtz file not present."
    }
	
    cd ..

    set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
    if { ![file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } {
	file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
	if { [file exists [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] ] } {
	    file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
	}
    }

# ***NSP
    if { [file exists [file join .. workdb crank.in.$tag.oh.mtz] ] && ( 1 == 2) } { 
	# second hand
	set enant 2

	file mkdir hand2
	cd hand2

	if { $bias } {

	    runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 1 $inccp4 0 0 $step >& parrot-command.py] $verbose
	    runcommand [concat ccp4-python parrot-command.py >& parrot-logfile] 1
# 	    catch { solomongraph [file join solomon-$solv solomon-logfile] "" 0 0 } output
# 	    set log [open "parrot-logfile" a+]
#	    puts $log $output
#	    close $log
#	    set solomonmtz "[file join solomon-$solv solomon_cycle$ncycles.mtz]"
#	    file copy parrot_cycle_$ncycles.mtz parrot.mtz

	} else {
	    runcommand [concat tclsh [file join $crankplugins parrot xml2parrotscript.tcl] $enant $ref $refpdb 0 >& parrot-command.com] $verbose
	    runcommand [concat tclsh [file join $crankplugins parrot xml2parrotscript.tcl] $enant $ref $refpdb 1 >& parrot-command.tcl] $verbose
	    runcommand [concat tclsh parrot-command.tcl] 1
	}

	if { [file exists parrot-logfile] } {
	    set log [open "parrot-logfile" r]
	    set output [read $log]
	    puts $output
	    close $log
	    file copy parrot-logfile [file join .. .. log $step-oh-parrot-logfile]
	} else {
	    crank_error "crank_parrot.tcl::parrot did not finish successfully"
	}

	if { [file exists parrot.mtz] } {
	    runcommand [concat tclsh [file join $crankplugins parrot crank-rename-parrot-output.tcl] parrot.mtz rename.out.mtz $bias $ncycles] $verbose
	    file copy rename.out.mtz [file join .. .. workdb crank.out.$tag.oh.mtz]
	    file delete rename.out.mtz
	} else {
	    crank_error "crank::runparrot:: parrot.mtz file not present."
	}

	cd ..

	set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
	if { ![file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } {
	    file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
	    if { [file exists [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] ] } {
		file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
	    }
	}

    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc parrot_dependencies { step } {
    global XMLParse
    
    set cparrot_check 1

#    for { set i 1 } { [info exists XMLParse([join "crank soap run step=$i name" __])] } { incr i } {
#	set step [string tolower $XMLParse([join "crank soap run step=$i name" __])]

#	if { [string compare $step "parrot"] == 0 } {
#	    if { ($XMLParse([join "crank soap run step=$i parrot phase_restrain" __]) == "SADH") ||
#                 ($XMLParse([join "crank soap run step=$i parrot phase_restrain" __]) == "SAD") } {
#		break
#            } elseif { $XMLParse([join "crank soap run step=$i parrot phase_restrain" __]) == "MLHL" } {
#		break
#	    }
#        }
#    }


    if { $cparrot_check } {
	# create and run cparrot command line
	set cparrot_command "cparrot"
	set cparrot_script "\n"
	set command "$cparrot_command << \"$cparrot_script\""
	catch {eval exec $command } output
	set err [lindex $::errorCode 0]

	# Check to see if the executable is found
	if { [string compare $err "POSIX"] == 0 } {
	    crank_error "crank::crankutils.tcl::cparrot not found"
	}

	# Check to see if we have the correct version
	if { [regexp {.*version *([0-9.]*)} $output match version1]} {
	    set version [string range $version1 0 2]
	    if { $version >= 1.0 } {
		set subversion [string range $version1 4 4]
		if { ($subversion < 1) && ($version == 1.0 ) } {
		    crank_error "crank::crankutils.tcl:Error cparrot version 1.0.1 or greater is needed"
		}
	    } else {
		crank_error "crank::crankutils.tcl::Error cparrot version 1.0.1 or greater is needed"
	    }
	    puts "\nFound cparrot version $version1\n"
	} else {
	    crank_error "crank::crankutils.tcl::Error finding version string from cparrot exectuable"
	}
    }
}

proc parrot_input_check { step } {
    global XMLParse

}

proc parrot_reference { } {
    global XMLParse
    
    puts "Parrot:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Cowtan K (2000) General quadratic functions in real and reciprocal space and"
    puts "their applications to likelihood phasing. Acta Cryst. D56, 1612-1621.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 

