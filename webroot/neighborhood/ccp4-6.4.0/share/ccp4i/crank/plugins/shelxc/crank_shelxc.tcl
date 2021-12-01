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

proc shelxc_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_shelxc.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Fa value calculation" "Shelxc" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-shelxc
    cd $step-shelxc
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { $inccp4 } {
        set mtz2hklcommand [file join $env(CBIN) gcx]
    } else {
        set mtz2hklcommand [file join $crankbin  gcx]
    }

    set inputmtz [file join .. workdb crank.out.IN.mtz]

    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {

	# Convert the input MTZ columns into Scalepack .sca format for SHELXC
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])
		set anomalous $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __])
		set outfilename "crank_${i}_${j}"

		# Do the actual data conversion from MTZ to .sca format
		if { [string compare $anomalous "0"] == 0 } {
		    set ip $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j i" __])
		    set sigip $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigi" __])
		    runcommand [concat tclsh [file join $crankplugins shelxc mtz2sca.tcl] 0 $mtz2hklcommand $inputmtz $outfilename $ip $sigip >> mtz2sca_${i}_${j}.log] $verbose
		} elseif { [string compare $anomalous "1"] == 0 } {
		    set i_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j i_plus" __])
		    set sigi_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigi_plus" __])
		    set i_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j i_minus" __])
		    set sigi_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigi_minus" __])
		    runcommand [concat tclsh [file join $crankplugins shelxc mtz2sca.tcl] 1 $mtz2hklcommand $inputmtz $outfilename $i_plus $sigi_plus $i_minus $sigi_minus >> mtz2sca_${i}_${j}.log] $verbose
		} else {
		    crank_error "crank::runshelxc::Error flag for anomalous/nonanomalous not found"
		}
		incr j
	    }
	    incr i
	}
    } else {
	# Convert the input MTZ columns into SHELXC .hkl format for SHELXC
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])
		set anomalous $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __])
		set outfilename "crank_${i}_${j}"
		if { [string compare $anomalous "0"] == 0 } {
		    set fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
		    set sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		    runcommand [concat tclsh [file join $crankplugins shelxc mtz2hkl.tcl] 0 $mtz2hklcommand $inputmtz $outfilename $fp $sigfp >> mtz2hkl_${i}_${j}.log] $verbose
		} elseif { [string compare $anomalous "1"] == 0 } {
		    set f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_plus" __])
		    set sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_plus" __])
		    set f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_minus" __])
		    set sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_minus" __])
		    runcommand [concat tclsh [file join $crankplugins shelxc mtz2hkl.tcl] 1 $mtz2hklcommand $inputmtz $outfilename $f_plus $sigf_plus $f_minus $sigf_minus >> mtz2hkl_${i}_${j}.log] $verbose
		} else {
		    crank_error "crank::runshelxc::Error flag for anomalous/nonanomalous not found"
		}
		incr j
	    }
	    incr i
	}	
    }
			
    # Run SHELXC
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 0 >& shelxc-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 1 >& shelxc-command.tcl] $verbose
 
    runcommand [concat tclsh shelxc-command.tcl] 1

    runcommand [concat tclsh [file join $crankplugins shelxc calc_resol.tcl] shelxc-logfile] $verbose

    set logfile [open shelxc-logfile r]
    set data [read $logfile]
    set data [split $data "\n"]
    set halfhigh ""
    set correlhigh ""

    foreach line $data {
	if { [ regexp {HALF added to the highest resolution limit is *([0-9.]*).*} $line junk halfhigh] } {
	    if { $halfhigh == "" } {
		crank_error "could not find HALF + highest resolution limit"
	    } 
	} elseif { [ regexp {Resolution when anomalous difference correlation goes under 0.30 is *([0-9.]*).*} $line junk correlhigh] } {
	    if { $correlhigh == "" } {
		crank_error "could not find HALF + highest resolution limit"
	    } 
	}
    }

    close $logfile

    if { ($correlhigh != "") || ($halfhigh != "") } {
	if { ($correlhigh != "") } {
	    set res $correlhigh 
	} elseif { ($halfhigh != "") } {
	    set res $halfhigh 
	} else {
	    crank_error "no resolution limit set"
	}
	set input [open "[file join .. xml input.xml]" a+]
	puts $input "<crank><update>"
	puts $input "<sub_hires>$res</sub_hires>"
	puts $input "</update></crank>"
	close $input
    }

    if { $inccp4 } {
       set afro_exec [file join $env(CBIN) afro]
    } else {
       set afro_exec [file join $crankbin  afro]
    }

    # Convert the SHELXC output to MTZ file format
    runcommand [concat tclsh [file join $crankplugins shelxc crank-rename-shelxc-output.tcl] crank.hkl crank_fa.hkl rename.out.mtz $afro_exec] $verbose
    file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
    file delete rename.out.mtz

    # Copy logfile to main log directory
    if { [file exists shelxc-logfile] } {
	set log [open "shelxc-logfile" r]
	set output [read $log]
	puts $output
 	close $log
	file copy shelxc-logfile [file join .. log $step-shelxc-logfile]
    } else {
	crank_error "crank_shelxc.tcl::shelxc did not finish successfully"
    }

    crank_ccp4_plugin_end $step "shelxc" [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc shelxc_dependencies { step } {
    global XMLParse

}

proc shelxc_input_check { step } {
    global XMLParse

}

proc shelxc_reference { } {

	puts "SHELXC:"
	puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
	puts "\$TEXT:Reference: \$\$ Please reference \$\$"
	puts "Sheldrick GM (2008) A short history of SHELX."
	puts "Acta Cryst. A64, 112-122."
	puts "\$\$\n"
	puts "<!--SUMMARY_END--></FONT></B>\n"
}
