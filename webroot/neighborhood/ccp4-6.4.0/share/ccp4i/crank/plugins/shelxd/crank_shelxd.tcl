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

proc shelxd_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
        crank_error "crank_shelxd.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Substructure detection" "Shelxd" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-shelxd
    cd $step-shelxd
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set inputmtz [file join .. workdb crank.in.$tag.mtz]

    set executable [file join $crankplugins shelxd $executable]

    set fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
    set sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
    set alpha $XMLParse([join "crank soap run step=$step input alpha_columns alpha" __])
    runcommand [concat tclsh [file join $crankplugins shelxd mtz2hkl_fa.tcl] $inputmtz crank_fa.hkl $fa $sigfa $alpha] $verbose

    # Run SHELXC to generate SHELXD command file 
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 0 >& shelxc-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 1 >& shelxc-command.tcl] $verbose

    runcommand [concat tclsh shelxc-command.tcl] $verbose

    # Delete the crank.hkl file that was just created, since 
    # it could mislead SHELXD
    file delete crank.hkl
    file delete crank_fa.hkl

    set fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
    set sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
    set alpha $XMLParse([join "crank soap run step=$step input alpha_columns alpha" __])
    runcommand [concat tclsh [file join $crankplugins shelxd mtz2hkl_fa.tcl] $inputmtz crank_fa.hkl $fa $sigfa $alpha] $verbose

    set ccweak_threshold $XMLParse([join "crank soap run step=$step shelx ccweak_threshold" __])

    set min_trials $XMLParse([join "crank soap run step=$step shelx min_trials" __])

    set max_trials $XMLParse([join "crank soap run step=$step shelx ntry" __])
   
    runcommand [concat tclsh $executable $ccweak_threshold $min_trials $max_trials >& shelxd-logfile] 1
    
    check_atom crank_fa.pdb crank.out.$tag.substructure.pdb 1 0 "shelxd-logfile"

    file rename crank.out.$tag.substructure.pdb [file join .. workdb crank.out.$tag.substructure.pdb]

    if { [file exists shelxd-logfile] } {
	set log [open "shelxd-logfile" r]
	set output [read $log]
	set data [split $output "\n"]
	foreach line $data {
            regsub -all {\s+} $line " " line
	    if { [regexp {Try *([0-9]*), CC All\/Weak ([-0-9.]*) \/ *([-0-9.]*).*} $line all try cc ccweak] ||
		 [regexp {Try *([0-9]*), CPU *([0-9]*), CC All\/Weak ([-0-9.]*) \/ *([-0-9.]*).*} $line all try cpu cc ccweak] } {
		set ntrial $try
		set acc($try) $cc
		set accweak($try) $ccweak
  		if { ($ccweak >= $ccweak_threshold) && ($try > $min_trials) } {
		    set result "CCweak threshold reached"
		}
		if { ($try >= $max_trials) } {
		    set result "Maximum number of trials reached"
		}
	    }
	}
	close $log
        if { ![info exists ntrial] } {
           crank_error "crank_shelxd.tcl: shelxd-logfile was not read correctly"
        }
	set maxaccweak 0
	set trialmaxaccweak 0
	set maxacc 0
	set smalllog [open "shelxd-logfile" a]
	puts $smalllog "\n\$TABLE : SHELXD CC versus trial:"
        puts $smalllog "\$SCATTER"
        puts $smalllog " : CCweak and CC per trial :A:1,2,3:"
        puts $smalllog "\$\$"
        puts $smalllog "Trial       CCweak       CC   \$\$ \$\$"
        for {set i 1} {$i <= $ntrial} {incr i} {
	    if { [info exists accweak($i)] && [info exists acc($i)] } {
		if { $accweak($i) > $maxaccweak } {
		    set maxaccweak $accweak($i)
		    set trialmaxaccweak $i
		    set maxacc $acc($i)
		}
		puts $smalllog [format " %4d       %5.2f      %5.2f   " $i $accweak($i) $acc($i)]
	    } else {
		set zero "0.00"
		puts $smalllog [format " %4d       %5.2f      %5.2f   " $i $zero $zero ]
	    }
        }
        puts $smalllog "\$\$\n"
        puts $smalllog "\$TEXT:Result: \$\$ Final result \$\$"
	if { [info exists result] } {
            puts $smalllog "$result"
        }
        puts $smalllog "Total number of trials: $ntrial, Maximum CCweak/CC: $maxaccweak/$maxacc occurring at Trial $trialmaxaccweak."
        puts $smalllog "\$\$\n"
	close $smalllog

 	set log [open "shelxd-logfile" r]
	set output [read $log]
	puts $output
	close $log

	file copy shelxd-logfile [file join .. log $step-shelxd-logfile]
    } else {
	crank_error "crank_shelxd.tcl::shelxd did not finish successfully"
    }

    crank_ccp4_plugin_end $step "shelxd" [expr ([clock clicks -millisec ]-$t0)/1000.]
	
    cd ..
}

proc shelxd_dependencies { step } {
    global XMLParse

}

proc shelxd_input_check { step } {
    global XMLParse

}

proc shelxd_reference { } {

	puts "SHELXD:"
	puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
	puts "\$TEXT:Reference: \$\$ Please reference \$\$"
        puts "Sheldrick GM (2008) A short history of SHELX."
        puts "Acta Cryst. A64, 112-122."
        puts "\$\$\n"
	puts "<!--SUMMARY_END--></FONT></B>\n"
    }
